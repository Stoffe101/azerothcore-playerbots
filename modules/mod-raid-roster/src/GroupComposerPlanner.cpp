#include "GroupComposerPlanner.h"

#include "RaidRosterComp.h"
#include "RaidRosterStore.h"

#include "AiFactory.h"
#include "CharacterCache.h"
#include "DatabaseEnv.h"
#include "Group.h"
#include "ObjectAccessor.h"
#include "Player.h"
#include "PlayerbotAI.h"
#include "PlayerbotAIConfig.h"
#include "Playerbots.h"
#include "QueryResult.h"
#include "RandomPlayerbotMgr.h"
#include "SharedDefines.h"
#include "World.h"

#include <algorithm>
#include <array>
#include <cctype>
#include <cmath>
#include <limits>
#include <set>
#include <sstream>
#include <unordered_set>
#include <utility>

namespace GroupComposer
{
namespace
{
std::string Lower(std::string value)
{
    std::transform(value.begin(), value.end(), value.begin(), [](unsigned char c) { return static_cast<char>(std::tolower(c)); });
    return value;
}

bool IsBotCharacter(ObjectGuid guid)
{
    if (Player* player = ObjectAccessor::FindConnectedPlayer(guid))
        return GET_PLAYERBOT_AI(player) != nullptr;

    uint32 account = sCharacterCache->GetCharacterAccountIdByGuid(guid);
    return (account && sPlayerbotAIConfig.IsInRandomAccountList(account)) || sRandomPlayerbotMgr.IsAddclassBot(guid.GetCounter());
}

bool PreferenceMatches(uint8 role, uint8 cls, uint8 spec, Preference const& pref)
{
    if (role != pref.role) return false;
    if (pref.cls && cls != pref.cls) return false;
    if (pref.spec != ANY_SPEC && spec != pref.spec) return false;
    return true;
}

bool MemberMatches(Member const& member, Preference const& pref)
{
    return PreferenceMatches(member.role, member.cls, member.spec, pref);
}

bool CandidateMatches(Candidate const& candidate, Preference const& pref)
{
    return PreferenceMatches(candidate.role, candidate.cls, candidate.spec, pref);
}

void AddWarningOnce(Plan& plan, std::string const& warning)
{
    if (std::find(plan.warnings.begin(), plan.warnings.end(), warning) == plan.warnings.end())
        plan.warnings.push_back(warning);
}

uint8 PopCount(uint32 value)
{
    uint8 out = 0;
    while (value)
    {
        out += static_cast<uint8>(value & 1u);
        value >>= 1u;
    }
    return out;
}

bool MemberIsStable(Member const& member)
{
    return member.human || member.pinned;
}

bool CrossFactionBlocked(Player* master, Player* other)
{
    if (!master || !other || master->IsGameMaster()) return false;
    return !sWorld->getBoolConfig(CONFIG_ALLOW_TWO_SIDE_INTERACTION_GROUP) && master->GetTeamId() != other->GetTeamId();
}

bool ConflictingInstances(Player* master, Player* other)
{
    if (!master || !other) return false;
    uint32 masterInstance = master->GetInstanceId();
    uint32 otherInstance = other->GetInstanceId();
    return masterInstance && otherInstance && masterInstance != otherInstance
        && master->GetMapId() == other->GetMapId();
}

void AddCoverage(Coverage& coverage, Member const& member)
{
    coverage.utilityMask |= member.utilityMask;
    if (member.role == ROLE_DPS)
    {
        if (member.rangedDps) ++coverage.rangedDps;
        else ++coverage.meleeDps;
    }
}

void AddSelectedMember(Plan& plan, Candidate const& candidate, bool pinned,
    std::array<uint8, 3>& roleCounts, std::array<uint8, 12>& classCounts,
    std::unordered_set<uint32>& used)
{
    Member member;
    member.guid = candidate.guid;
    member.name = candidate.name;
    member.cls = candidate.cls;
    member.role = candidate.role;
    member.spec = candidate.spec;
    member.guild = candidate.guild;
    member.managed = candidate.managed;
    member.reserve = candidate.reserve;
    member.needsPreparation = candidate.needsPreparation;
    member.pinned = pinned;
    member.online = candidate.online;
    member.utilityMask = candidate.utilityMask;
    member.rangedDps = candidate.rangedDps;
    plan.members.push_back(member);

    used.insert(candidate.guid.GetCounter());
    ++roleCounts[member.role];
    if (member.cls < classCounts.size()) ++classCounts[member.cls];
    AddCoverage(plan.coverage, member);
}

bool HumanRoleFor(Config const& config, std::string const& name, uint8 inferred, uint8& role)
{
    auto itr = config.humanRoles.find(Lower(name));
    if (itr != config.humanRoles.end())
    {
        role = itr->second;
        return true;
    }
    role = inferred;
    return false;
}

bool AddHumanMembers(Player* master, Config const& config, Plan& plan,
    std::array<uint8, 3>& roleCounts, std::array<uint8, 12>& classCounts,
    std::string& error)
{
    std::unordered_set<uint32> added;
    std::unordered_map<std::string, uint8> requested;
    for (AddedHuman const& request : config.extraHumans)
        requested[Lower(request.name)] = request.role;

    auto addLive = [&](Player* player, Optional<uint8> forcedRole) -> bool
    {
        if (!player || GET_PLAYERBOT_AI(player)) return true;
        uint32 low = player->GetGUID().GetCounter();
        if (!added.insert(low).second) return true;

        uint8 role = Planner::InferRole(player);
        if (forcedRole)
            role = *forcedRole;
        else
            HumanRoleFor(config, player->GetName(), role, role);

        if (!Planner::CanClassFillRole(player->getClass(), role))
        {
            error = player->GetName() + " cannot fill the requested " + std::string(role == ROLE_TANK ? "tank" : role == ROLE_HEALER ? "healer" : "DPS") + " role with this class.";
            return false;
        }

        Member member;
        member.guid = player->GetGUID();
        member.name = player->GetName();
        member.cls = player->getClass();
        member.role = role;
        member.spec = Planner::InferSpec(player);
        member.human = true;
        member.locked = true;
        member.online = true;
        member.guild = master->GetGuildId() && player->GetGuildId() == master->GetGuildId();
        member.utilityMask = Planner::UtilityMask(member.cls, member.spec, member.role);
        member.rangedDps = Planner::IsRangedDps(member.cls, member.spec, member.role);
        plan.members.push_back(member);
        ++roleCounts[member.role];
        if (member.cls < classCounts.size()) ++classCounts[member.cls];
        AddCoverage(plan.coverage, member);
        return true;
    };

    auto addOfflineExistingHuman = [&](Group::MemberSlot const& slot) -> bool
    {
        if (IsBotCharacter(slot.guid)) return true;
        CharacterCacheEntry const* cache = sCharacterCache->GetCharacterCacheByGuid(slot.guid);
        if (!cache)
        {
            error = "An offline human group member could not be resolved from the character cache.";
            return false;
        }
        if (!added.insert(slot.guid.GetCounter()).second) return true;

        auto overrideItr = config.humanRoles.find(Lower(cache->Name));
        if (overrideItr == config.humanRoles.end())
        {
            error = "Offline human '" + cache->Name + "' needs a manual Tank/Healer/DPS role override before composing.";
            return false;
        }
        uint8 role = overrideItr->second;
        if (!Planner::CanClassFillRole(cache->Class, role))
        {
            error = "Offline human '" + cache->Name + "' cannot fill that requested role with this class.";
            return false;
        }

        Member member;
        member.guid = slot.guid;
        member.name = cache->Name;
        member.cls = cache->Class;
        member.role = role;
        member.spec = ANY_SPEC;
        member.human = true;
        member.locked = true;
        member.online = false;
        member.guild = master->GetGuildId() && cache->GuildId == master->GetGuildId();
        member.utilityMask = Planner::UtilityMask(member.cls, member.spec, member.role);
        member.rangedDps = Planner::IsRangedDps(member.cls, member.spec, member.role);
        plan.members.push_back(member);
        ++roleCounts[member.role];
        if (member.cls < classCounts.size()) ++classCounts[member.cls];
        AddCoverage(plan.coverage, member);
        AddWarningOnce(plan, "Offline human '" + cache->Name + "' is preserved using the saved manual role override.");
        return true;
    };

    Group* group = master->GetGroup();
    if (group)
    {
        for (Group::MemberSlot const& slot : group->GetMemberSlots())
        {
            if (Player* player = ObjectAccessor::FindConnectedPlayer(slot.guid))
            {
                if (GET_PLAYERBOT_AI(player)) continue;
                auto req = requested.find(Lower(player->GetName()));
                if (!addLive(player, req != requested.end() ? Optional<uint8>(req->second) : Optional<uint8>())) return false;
            }
            else if (!addOfflineExistingHuman(slot))
                return false;
        }
    }

    if (!addLive(master, Optional<uint8>())) return false;

    for (AddedHuman const& request : config.extraHumans)
    {
        ObjectGuid guid = sCharacterCache->GetCharacterGuidByName(request.name);
        if (guid.IsEmpty())
        {
            error = "Human player '" + request.name + "' does not exist.";
            return false;
        }
        Player* player = ObjectAccessor::FindConnectedPlayer(guid);
        if (!player || GET_PLAYERBOT_AI(player))
        {
            error = "Human player '" + request.name + "' must be online and must be a real player before being added.";
            return false;
        }
        bool alreadyWithMaster = master->GetGroup() && player->GetGroup() == master->GetGroup();
        if (player->GetGroup() && !alreadyWithMaster)
        {
            error = "Human player '" + request.name + "' is already in another group.";
            return false;
        }
        if (!alreadyWithMaster)
        {
            if (player->IsSpectator())
            {
                error = "Human player '" + request.name + "' is currently spectating and cannot be invited.";
                return false;
            }
            if (!player->IsAcceptGroupInvites())
            {
                error = "Human player '" + request.name + "' has group invites disabled.";
                return false;
            }
            if (player->GetGroupInvite())
            {
                error = "Human player '" + request.name + "' already has a pending group invite.";
                return false;
            }
            if (CrossFactionBlocked(master, player))
            {
                error = "Human player '" + request.name + "' is on the opposite faction while cross-faction groups are disabled.";
                return false;
            }
            if (ConflictingInstances(master, player))
            {
                error = "Human player '" + request.name + "' is locked to a different active instance.";
                return false;
            }
            if (player->IsBeingTeleported())
            {
                error = "Human player '" + request.name + "' is being teleported; wait a moment and search again.";
                return false;
            }
        }
        if (!addLive(player, Optional<uint8>(request.role))) return false;
    }

    return true;
}

void AddCandidate(std::vector<Candidate>& out, std::unordered_set<uint32>& seen, Candidate candidate)
{
    if (candidate.guid.IsEmpty()) return;
    if (!seen.insert(candidate.guid.GetCounter()).second) return;
    out.push_back(std::move(candidate));
}

std::vector<Candidate> BuildCandidates(Player* master, Config const& config, Plan& plan)
{
    std::vector<Candidate> out;
    std::unordered_set<uint32> seen;
    Group* masterGroup = master->GetGroup();
    uint32 guildId = master->GetGuildId();

    auto makeOnline = [&](Player* bot, bool alreadyGrouped)
    {
        PlayerbotAI* botAI = bot ? GET_PLAYERBOT_AI(bot) : nullptr;
        if (!bot || !botAI || bot == master) return;

        // Playerbots that currently belong to another game-client master are somebody else's
        // companion, not part of this composer's available world/guild pool. Never hijack them.
        if (botAI->HasGameClientMaster() && botAI->GetMaster() != master) return;

        if (bot->InBattleground() || bot->InBattlegroundQueue() || bot->IsSpectator()) return;
        if (bot->GetGroup() && bot->GetGroup() != masterGroup) return;
        if (!alreadyGrouped && bot->GetGroupInvite()) return;
        if (!alreadyGrouped && bot->IsBeingTeleported()) return;
        if (!alreadyGrouped && bot->GetInstanceId() != 0) return;
        if (!alreadyGrouped && std::abs(int(bot->GetLevel()) - int(master->GetLevel())) > 3) return;
        if (CrossFactionBlocked(master, bot)) return;

        Candidate c;
        c.guid = bot->GetGUID();
        c.name = bot->GetName();
        c.cls = bot->getClass();
        c.role = Planner::InferRole(bot);
        c.spec = Planner::InferSpec(bot);
        c.guild = guildId && bot->GetGuildId() == guildId;
        c.online = true;
        c.alreadyGrouped = alreadyGrouped;
        c.itemLevel = bot->GetAverageItemLevel();
        c.utilityMask = Planner::UtilityMask(c.cls, c.spec, c.role);
        c.rangedDps = Planner::IsRangedDps(c.cls, c.spec, c.role);
        if (config.minimumItemLevel && c.itemLevel + 0.001f < config.minimumItemLevel) return;
        if (!c.guild && !config.fillWorld && !alreadyGrouped) return;
        AddCandidate(out, seen, std::move(c));
    };

    // Existing group bots remain eligible so an otherwise equal composition does not churn for no
    // reason. They are not locked anchors, however; Prefer Guild must still be able to replace an
    // ordinary world bot with a suitable persistent guild companion.
    if (masterGroup)
    {
        for (Group::MemberSlot const& slot : masterGroup->GetMemberSlots())
            makeOnline(ObjectAccessor::FindConnectedPlayer(slot.guid), true);
    }

    // Persistent guild community. Only currently online Playerbots are taken from the ordinary guild
    // population; Group Composer never force-logs arbitrary random-bot accounts.
    if (guildId)
    {
        if (QueryResult result = CharacterDatabase.Query("SELECT guid FROM guild_member WHERE guildid = {}", guildId))
        {
            do
            {
                ObjectGuid guid = ObjectGuid::Create<HighGuid::Player>(result->Fetch()[0].Get<uint32>());
                if (sRandomPlayerbotMgr.IsAddclassBot(guid.GetCounter())) continue;
                if (Player* bot = ObjectAccessor::FindConnectedPlayer(guid))
                    makeOnline(bot, masterGroup && bot->GetGroup() == masterGroup);
            } while (result->NextRow());
        }
    }

    if (config.fillWorld)
    {
        for (Player* bot : sRandomPlayerbotMgr.GetPlayers())
        {
            if (!bot || sRandomPlayerbotMgr.IsAddclassBot(bot)) continue;
            makeOnline(bot, masterGroup && bot->GetGroup() == masterGroup);
        }
    }

    // Group Composer reserve pool. The population controller provisions every RNDbot account with
    // broad WotLK class coverage, so an exact composition must be able to draw a suitable CLASS
    // body even when that character is currently offline. Build preparation owns the eventual
    // level/spec/gear rewrite; this candidate pass only establishes safe identity/class/faction.
    //
    // Never force-login persistent guild identities through this fallback. Guild members are
    // handled by the normal guild path above, and bots already grouped elsewhere are protected.
    if (config.fillWorld && !sPlayerbotAIConfig.randomBotAccounts.empty())
    {
        std::string accountList;
        for (uint32 accountId : sPlayerbotAIConfig.randomBotAccounts)
        {
            if (!accountList.empty()) accountList += ',';
            accountList += std::to_string(accountId);
        }

        if (!accountList.empty())
        {
            QueryResult reserveRows = CharacterDatabase.Query(
                "SELECT guid, name, class FROM characters WHERE account IN ({}) ORDER BY guid", accountList);
            if (reserveRows)
            {
                do
                {
                    Field* fields = reserveRows->Fetch();
                    uint32 low = fields[0].Get<uint32>();
                    if (seen.count(low)) continue;

                    ObjectGuid guid = ObjectGuid::Create<HighGuid::Player>(low);
                    if (ObjectAccessor::FindConnectedPlayer(guid)) continue;
                    if (!sCharacterCache->GetCharacterGroupGuidByGuid(guid).IsEmpty()) continue;
                    if (sCharacterCache->GetCharacterGuildIdByGuid(guid)) continue;
                    if (!master->IsGameMaster() && !sWorld->getBoolConfig(CONFIG_ALLOW_TWO_SIDE_INTERACTION_GROUP)
                        && sCharacterCache->GetCharacterTeamByGuid(guid) != master->GetTeamId()) continue;

                    Candidate c;
                    c.guid = guid;
                    c.name = fields[1].Get<std::string>();
                    c.cls = fields[2].Get<uint8>();
                    c.role = ROLE_DPS;
                    c.spec = ANY_SPEC;
                    c.online = false;
                    c.managed = true;       // offline lifecycle is controlled by assembly
                    c.reserve = true;       // consumes a Composer lease when assembled
                    c.needsPreparation = true;
                    c.utilityMask = Planner::UtilityMask(c.cls, c.spec, c.role);
                    c.rangedDps = Planner::IsRangedDps(c.cls, c.spec, c.role);
                    AddCandidate(out, seen, std::move(c));
                } while (reserveRows->NextRow());
            }
        }
    }

    // The legacy RaidRoster pool is a safe, explicitly reserved fallback. Those addclass bots have a
    // known owner and a known login/spec/gear lifecycle, so offline members may be selected here.
    uint8 masterLevel = master->GetLevel();
    for (RaidRosterRow const& row : RaidRosterStore::Load(master->GetGUID().GetCounter()))
    {
        if (!RaidCompEligible(row.band, masterLevel)) continue;
        ObjectGuid guid = ObjectGuid::Create<HighGuid::Player>(row.botGuid);
        if (seen.count(row.botGuid))
        {
            for (Candidate& existing : out)
                if (existing.guid == guid) { existing.managed = true; break; }
            continue;
        }

        if (!master->IsGameMaster() && !sWorld->getBoolConfig(CONFIG_ALLOW_TWO_SIDE_INTERACTION_GROUP)
            && sCharacterCache->GetCharacterTeamByGuid(guid) != master->GetTeamId()) continue;

        Player* online = ObjectAccessor::FindConnectedPlayer(guid);
        PlayerbotAI* onlineAI = online ? GET_PLAYERBOT_AI(online) : nullptr;
        if (online && !onlineAI) continue;
        if (onlineAI && onlineAI->HasGameClientMaster() && onlineAI->GetMaster() != master) continue;
        if (online && (online->InBattleground() || online->InBattlegroundQueue() || online->IsSpectator())) continue;
        if (online && online->GetGroup() && online->GetGroup() != masterGroup) continue;

        // Offline managed bots can still have persisted group membership in CharacterCache. Never
        // log in a reserve bot that belongs to another group, and correctly retain one that is
        // already a member of this composer's live group.
        ObjectGuid cachedGroup = online ? ObjectGuid::Empty : sCharacterCache->GetCharacterGroupGuidByGuid(guid);
        bool cachedWithMaster = !online && masterGroup && !cachedGroup.IsEmpty() && cachedGroup == masterGroup->GetGUID();
        if (!online && !cachedGroup.IsEmpty() && !cachedWithMaster) continue;

        bool alreadyGrouped = online ? (masterGroup && online->GetGroup() == masterGroup) : cachedWithMaster;
        if (online && !alreadyGrouped && (online->GetGroupInvite() || online->IsBeingTeleported() || online->GetInstanceId() != 0)) continue;
        if (!online && config.minimumItemLevel) continue; // unknown gear may not satisfy an explicit floor

        Candidate c;
        c.guid = guid;
        c.cls = row.cls;
        c.role = row.role;
        c.spec = row.specTab;
        c.guild = guildId && sCharacterCache->GetCharacterGuildIdByGuid(guid) == guildId;
        c.online = online != nullptr;
        c.managed = true;
        c.alreadyGrouped = alreadyGrouped;
        // Fill World is the user's fallback boundary. A non-guild managed reserve bot counts as
        // fallback just like an ordinary random-world bot unless it is already in the live group.
        if (!c.guild && !config.fillWorld && !c.alreadyGrouped) continue;
        if (online)
        {
            c.name = online->GetName();
            if (c.alreadyGrouped)
            {
                c.role = Planner::InferRole(online);
                c.spec = Planner::InferSpec(online);
            }
            c.itemLevel = online->GetAverageItemLevel();
            if (config.minimumItemLevel && c.itemLevel + 0.001f < config.minimumItemLevel) continue;
        }
        else
        {
            sCharacterCache->GetCharacterNameByGuid(guid, c.name);
        }
        c.utilityMask = Planner::UtilityMask(c.cls, c.spec, c.role);
        c.rangedDps = Planner::IsRangedDps(c.cls, c.spec, c.role);
        AddCandidate(out, seen, std::move(c));
    }

    for (Candidate const& candidate : out)
    {
        if (candidate.guild) ++plan.guildCandidates;
        else ++plan.worldCandidates;
        if (candidate.managed) ++plan.managedCandidates;
    }
    return out;
}

int CandidateScore(Candidate const& candidate, Config const& config,
    std::array<uint8, 12> const& classCounts, Coverage const& coverage)
{
    int score = 0;
    // Guild preference is a product-level priority. Existing bots get a meaningful churn bonus, but
    // that bonus must not overpower "Prefer Guild Members" and turn the option into a cosmetic flag.
    if (config.preferGuild && candidate.guild) score += 5000;
    if (candidate.alreadyGrouped) score += 1200;
    if (candidate.online) score += 250;
    if (candidate.managed) score += 80;

    if (config.balanceClasses && candidate.cls < classCounts.size())
    {
        if (classCounts[candidate.cls] == 0) score += 220;
        else score -= 45 * classCounts[candidate.cls];
    }
    if (config.avoidDuplicates && candidate.cls < classCounts.size() && classCounts[candidate.cls] > 0)
        score -= 1200;

    if (config.balanceUtility)
    {
        uint32 newUtility = candidate.utilityMask & ~coverage.utilityMask;
        score += 75 * PopCount(newUtility);
    }

    if (config.balanceRange && candidate.role == ROLE_DPS)
    {
        if (candidate.rangedDps)
            score += coverage.rangedDps <= coverage.meleeDps ? 150 : 0;
        else
            score += coverage.meleeDps <= coverage.rangedDps ? 150 : 0;
    }

    for (Preference const& pref : config.preferences)
        if (!pref.required && CandidateMatches(candidate, pref)) score += 120;

    return score;
}

bool SpecCanFillRole(uint8 cls, uint8 spec, uint8 role)
{
    if (spec == ANY_SPEC) return false;
    switch (cls)
    {
        case CLASS_WARRIOR:      return (spec == 2 && role == ROLE_TANK) || (spec <= 1 && role == ROLE_DPS);
        case CLASS_PALADIN:      return (spec == 0 && role == ROLE_HEALER) || (spec == 1 && role == ROLE_TANK) || (spec == 2 && role == ROLE_DPS);
        case CLASS_HUNTER:       return role == ROLE_DPS && spec <= 2;
        case CLASS_ROGUE:        return role == ROLE_DPS && spec <= 2;
        case CLASS_PRIEST:       return ((spec == 0 || spec == 1) && role == ROLE_HEALER) || (spec == 2 && role == ROLE_DPS);
        case CLASS_DEATH_KNIGHT: return (spec == 0 && role == ROLE_TANK) || ((spec == 1 || spec == 2) && role == ROLE_DPS);
        case CLASS_SHAMAN:       return (spec == 2 && role == ROLE_HEALER) || ((spec == 0 || spec == 1) && role == ROLE_DPS);
        case CLASS_MAGE:         return role == ROLE_DPS && spec <= 2;
        case CLASS_WARLOCK:      return role == ROLE_DPS && spec <= 2;
        case CLASS_DRUID:        return (spec == 2 && role == ROLE_HEALER) || (spec == 1 && (role == ROLE_TANK || role == ROLE_DPS)) || (spec == 0 && role == ROLE_DPS);
        default:                 return false;
    }
}

uint8 DefaultSpecForRole(uint8 cls, uint8 role, uint8 currentSpec)
{
    if (SpecCanFillRole(cls, currentSpec, role)) return currentSpec;
    switch (cls)
    {
        case CLASS_WARRIOR:      return role == ROLE_TANK ? 2 : role == ROLE_DPS ? 1 : ANY_SPEC;
        case CLASS_PALADIN:      return role == ROLE_TANK ? 1 : role == ROLE_HEALER ? 0 : role == ROLE_DPS ? 2 : ANY_SPEC;
        case CLASS_HUNTER:       return role == ROLE_DPS ? 0 : ANY_SPEC;
        case CLASS_ROGUE:        return role == ROLE_DPS ? 0 : ANY_SPEC;
        case CLASS_PRIEST:       return role == ROLE_HEALER ? 1 : role == ROLE_DPS ? 2 : ANY_SPEC;
        case CLASS_DEATH_KNIGHT: return role == ROLE_TANK ? 0 : role == ROLE_DPS ? 1 : ANY_SPEC;
        case CLASS_SHAMAN:       return role == ROLE_HEALER ? 2 : role == ROLE_DPS ? 0 : ANY_SPEC;
        case CLASS_MAGE:         return role == ROLE_DPS ? 0 : ANY_SPEC;
        case CLASS_WARLOCK:      return role == ROLE_DPS ? 0 : ANY_SPEC;
        case CLASS_DRUID:        return role == ROLE_TANK ? 1 : role == ROLE_HEALER ? 2 : role == ROLE_DPS ? 0 : ANY_SPEC;
        default:                 return ANY_SPEC;
    }
}

bool ProjectCandidateForRole(Candidate const& candidate, uint8 role, Preference const* required, Candidate& projected)
{
    if (!Planner::CanClassFillRole(candidate.cls, role)) return false;
    if (required && required->cls && candidate.cls != required->cls) return false;

    uint8 desiredSpec = DefaultSpecForRole(candidate.cls, role, candidate.spec);
    if (required && required->spec != ANY_SPEC)
    {
        if (!SpecCanFillRole(candidate.cls, required->spec, role)) return false;
        desiredSpec = required->spec;
    }
    if (desiredSpec == ANY_SPEC) return false;

    projected = candidate;
    projected.role = role;
    projected.spec = desiredSpec;
    projected.utilityMask = Planner::UtilityMask(projected.cls, projected.spec, projected.role);
    projected.rangedDps = Planner::IsRangedDps(projected.cls, projected.spec, projected.role);

    // Retasking is an explicit Composer action. Selection only projects the desired final state;
    // Assemble must really rebuild talents/AI/gear before the bot is invited.
    if (candidate.role != projected.role || candidate.spec != projected.spec)
        projected.needsPreparation = true;

    return !required || CandidateMatches(projected, *required);
}

bool BestCandidate(std::vector<Candidate> const& candidates, Config const& config,
    uint8 role, Preference const* required, std::unordered_set<uint32> const& used,
    std::array<uint8, 12> const& classCounts, Coverage const& coverage, Candidate& result)
{
    bool found = false;
    int bestScore = std::numeric_limits<int>::min();
    for (Candidate const& candidate : candidates)
    {
        if (used.count(candidate.guid.GetCounter())) continue;

        Candidate projected;
        if (!ProjectCandidateForRole(candidate, role, required, projected)) continue;

        int score = CandidateScore(projected, config, classCounts, coverage);
        // Existing role/spec is cheapest and therefore preferred, but capability is enough. This is
        // what lets a 500-bot world satisfy a roster immediately even when the right hybrid happens
        // to be wandering around in a DPS setup at the moment Find Roster is pressed.
        if (candidate.role != projected.role) score -= 400;
        if (candidate.spec != projected.spec) score -= 100;

        // Prefer a role-ready or safely rebuildable world/reserve bot over changing the active
        // specialization of a persistent guild companion. Guild companions keep their earned gear,
        // so a forced spec swap could otherwise create a Protection tank in Retribution gear (or
        // the equivalent mismatch for another hybrid). This is only a ranking penalty: if world
        // fallback is disabled, or a named pin explicitly requests the companion, the guild bot can
        // still be selected and retasked.
        if (projected.guild && candidate.spec != projected.spec) score -= 10000;

        if (!found || score > bestScore || (score == bestScore && projected.name < result.name))
        {
            result = std::move(projected);
            bestScore = score;
            found = true;
        }
    }
    return found;
}

bool FindNamedCandidate(std::vector<Candidate> const& candidates, std::string const& name,
    uint8 role, std::unordered_set<uint32> const& used, Candidate& result)
{
    std::string needle = Lower(name);
    for (Candidate const& candidate : candidates)
    {
        if (used.count(candidate.guid.GetCounter()) || Lower(candidate.name) != needle) continue;
        if (ProjectCandidateForRole(candidate, role, nullptr, result)) return true;
    }
    return false;
}

uint8 UniqueClassCount(Plan const& plan)
{
    std::set<uint8> classes;
    for (Member const& member : plan.members) if (member.cls) classes.insert(member.cls);
    return static_cast<uint8>(classes.size());
}

void AddCoverageWarnings(Plan& plan)
{
    if (plan.config.size >= 10 && plan.config.balanceRange && plan.config.dps > 0)
    {
        if (!plan.coverage.rangedDps) AddWarningOnce(plan, "No ranged DPS selected; consider adjusting preferences if the encounter benefits from ranged coverage.");
        if (!plan.coverage.meleeDps) AddWarningOnce(plan, "No melee DPS selected; consider adjusting preferences if the encounter benefits from melee coverage.");
    }
    if (plan.config.balanceUtility && plan.config.size >= 5)
    {
        if (!(plan.coverage.utilityMask & UTILITY_INTERRUPT)) AddWarningOnce(plan, "No reliable interrupt capability detected in the selected roster.");
        if (!(plan.coverage.utilityMask & UTILITY_DISPEL)) AddWarningOnce(plan, "No broad dispel/cleanse capability detected in the selected roster.");
    }
}
}

uint8 Planner::InferRole(Player* player)
{
    if (!player) return ROLE_DPS;

    // A live Playerbot's current strategies describe the role it is actually configured to
    // perform. Humans have no bot strategies, so infer their role from the active talent spec
    // and let explicit human-role overrides resolve hybrids/edge cases in the composer UI.
    bool bySpec = GET_PLAYERBOT_AI(player) == nullptr;
    if (PlayerbotAI::IsTank(player, bySpec)) return ROLE_TANK;
    if (PlayerbotAI::IsHeal(player, bySpec)) return ROLE_HEALER;
    return ROLE_DPS;
}

uint8 Planner::InferSpec(Player* player)
{
    if (!player) return ANY_SPEC;
    int spec = AiFactory::GetPlayerSpecTab(player);
    return spec >= 0 && spec <= 2 ? static_cast<uint8>(spec) : ANY_SPEC;
}

bool Planner::CanClassFillRole(uint8 cls, uint8 role)
{
    switch (cls)
    {
        case CLASS_WARRIOR:      return role == ROLE_TANK || role == ROLE_DPS;
        case CLASS_PALADIN:      return true;
        case CLASS_HUNTER:       return role == ROLE_DPS;
        case CLASS_ROGUE:        return role == ROLE_DPS;
        case CLASS_PRIEST:       return role == ROLE_HEALER || role == ROLE_DPS;
        case CLASS_DEATH_KNIGHT: return role == ROLE_TANK || role == ROLE_DPS;
        case CLASS_SHAMAN:       return role == ROLE_HEALER || role == ROLE_DPS;
        case CLASS_MAGE:         return role == ROLE_DPS;
        case CLASS_WARLOCK:      return role == ROLE_DPS;
        case CLASS_DRUID:        return true;
        default:                 return false;
    }
}

uint32 Planner::UtilityMask(uint8 cls, uint8 spec, uint8 /*role*/)
{
    // These are broad WotLK class/spec capabilities used only as a soft optimization signal.
    // They never make an otherwise role-correct roster invalid.
    switch (cls)
    {
        case CLASS_WARRIOR:
            return UTILITY_INTERRUPT | UTILITY_RAID_BUFF | UTILITY_THREAT;
        case CLASS_PALADIN:
            return UTILITY_DISPEL | UTILITY_RAID_BUFF | UTILITY_THREAT;
        case CLASS_HUNTER:
            return UTILITY_CC | UTILITY_RAID_BUFF | (spec == 1 ? UTILITY_INTERRUPT : 0);
        case CLASS_ROGUE:
            return UTILITY_INTERRUPT | UTILITY_CC | UTILITY_THREAT;
        case CLASS_PRIEST:
            return UTILITY_DISPEL | UTILITY_RAID_BUFF | UTILITY_CC;
        case CLASS_DEATH_KNIGHT:
            return UTILITY_INTERRUPT | UTILITY_RAID_BUFF | UTILITY_THREAT;
        case CLASS_SHAMAN:
            return UTILITY_INTERRUPT | UTILITY_DISPEL | UTILITY_RAID_BUFF | UTILITY_HEROISM;
        case CLASS_MAGE:
            return UTILITY_INTERRUPT | UTILITY_RAID_BUFF | UTILITY_CC;
        case CLASS_WARLOCK:
            // WotLK Soulstone is not an on-demand combat resurrection of an already-dead ally.
            // Do not let a warlock satisfy the planner's battle-rez coverage signal.
            return UTILITY_CC;
        case CLASS_DRUID:
            return UTILITY_DISPEL | UTILITY_RAID_BUFF | UTILITY_BATTLE_REZ | UTILITY_CC;
        default:
            return 0;
    }
}

bool Planner::IsRangedDps(uint8 cls, uint8 spec, uint8 role)
{
    if (role != ROLE_DPS) return false;
    switch (cls)
    {
        case CLASS_HUNTER:
        case CLASS_MAGE:
        case CLASS_WARLOCK:
        case CLASS_PRIEST:
            return true;
        case CLASS_SHAMAN:
            return spec == 0; // Elemental
        case CLASS_DRUID:
            return spec == 0; // Balance
        default:
            return false;
    }
}

bool Planner::Build(Player* master, Config const& config, Plan& out, std::string& error)
{
    out = Plan{};
    out.config = config;
    if (!master)
    {
        error = "Composer requires an in-world player.";
        return false;
    }
    if (!config.keepMe)
    {
        error = "The composing player must remain in the roster; disable 'Keep Me' is not supported for an assembled in-world group.";
        return false;
    }
    if (config.size < 1 || config.size > 40 || uint16(config.tanks) + config.healers + config.dps != config.size)
    {
        error = "Invalid raid size or role totals.";
        return false;
    }
    if (config.mode == "dungeon" && config.size != 5)
    {
        error = "Dungeon mode requires a 5-player roster.";
        return false;
    }
    if (Group* group = master->GetGroup())
    {
        if (!group->IsLeader(master->GetGUID()) && !group->IsAssistant(master->GetGUID()))
        {
            error = "You must be group leader or assistant to compose this roster.";
            return false;
        }
        if (group->isBFGroup() || group->isBGGroup())
        {
            error = "Battleground/Battlefield groups are managed by their own queue systems.";
            return false;
        }
    }

    std::array<uint8, 3> roleCounts{};
    std::array<uint8, 12> classCounts{};
    if (!AddHumanMembers(master, config, out, roleCounts, classCounts, error)) return false;
    if (out.members.size() > config.size)
    {
        error = "There are more real human roster anchors than the requested group size.";
        return false;
    }

    std::array<uint8, 3> targets = { config.tanks, config.healers, config.dps };
    for (uint8 role = 0; role < 3; ++role)
    {
        if (roleCounts[role] > targets[role])
        {
            error = "Existing human roles already exceed the requested " + std::string(role == ROLE_TANK ? "tank" : role == ROLE_HEALER ? "healer" : "DPS") + " count. Change a human role override or increase that role target.";
            return false;
        }
    }

    std::vector<Candidate> candidates = BuildCandidates(master, config, out);
    std::unordered_set<uint32> used;
    for (Member const& member : out.members) used.insert(member.guid.GetCounter());

    // Required pins are hard constraints and are resolved before any soft preferences. Preferred
    // pins are deliberately deferred until required class/spec rows are satisfied so a familiar
    // guild member can never consume the last slot needed by an explicit hard requirement.
    for (Pin const& pin : config.pins)
    {
        if (!pin.required) continue;
        Candidate candidate;
        if (!FindNamedCandidate(candidates, pin.name, pin.role, used, candidate))
        {
            error = "Required pinned member '" + pin.name + "' is unavailable in the requested role.";
            return false;
        }
        if (roleCounts[pin.role] >= targets[pin.role])
        {
            error = "Required pinned member '" + pin.name + "' has no remaining slot in the requested role.";
            return false;
        }
        AddSelectedMember(out, candidate, true, roleCounts, classCounts, used);
    }

    // Every Required preference row consumes one unique roster member. This avoids one Mage silently
    // satisfying multiple independently requested Mage slots.
    std::unordered_set<uint32> requiredMemberUsed;
    for (Preference const& pref : config.preferences)
    {
        if (!pref.required) continue;

        bool satisfied = false;
        for (Member const& member : out.members)
        {
            uint32 low = member.guid.GetCounter();
            if (!requiredMemberUsed.count(low) && MemberMatches(member, pref))
            {
                requiredMemberUsed.insert(low);
                satisfied = true;
                break;
            }
        }
        if (satisfied) continue;
        if (roleCounts[pref.role] >= targets[pref.role])
        {
            error = "A required class/spec preference cannot fit inside the requested role totals.";
            return false;
        }

        Candidate candidate;
        if (!BestCandidate(candidates, config, pref.role, &pref, used, classCounts, out.coverage, candidate))
        {
            error = "A required class/spec preference has no eligible candidate.";
            return false;
        }
        AddSelectedMember(out, candidate, false, roleCounts, classCounts, used);
        requiredMemberUsed.insert(candidate.guid.GetCounter());
    }

    // Preferred pins remain stronger than ordinary score-based filling, but only after every hard
    // constraint is secured. If a hard class/spec requirement already selected the same character,
    // mark that member pinned so subgroup persistence and the UI still treat them as a familiar pin.
    for (Pin const& pin : config.pins)
    {
        if (pin.required) continue;

        bool alreadySelected = false;
        for (Member& member : out.members)
        {
            if (member.role == pin.role && Lower(member.name) == Lower(pin.name))
            {
                member.pinned = true;
                alreadySelected = true;
                break;
            }
        }
        if (alreadySelected) continue;

        Candidate candidate;
        if (!FindNamedCandidate(candidates, pin.name, pin.role, used, candidate))
        {
            AddWarningOnce(out, "Preferred pinned member '" + pin.name + "' is unavailable; a fallback may be used.");
            continue;
        }
        if (roleCounts[pin.role] >= targets[pin.role])
        {
            AddWarningOnce(out, "Preferred pinned member '" + pin.name + "' could not fit because that role is already full.");
            continue;
        }
        AddSelectedMember(out, candidate, true, roleCounts, classCounts, used);
    }

    for (uint8 role = 0; role < 3; ++role)
    {
        while (roleCounts[role] < targets[role])
        {
            Candidate candidate;
            if (!BestCandidate(candidates, config, role, nullptr, used, classCounts, out.coverage, candidate))
            {
                error = "Not enough eligible " + std::string(role == ROLE_TANK ? "tanks" : role == ROLE_HEALER ? "healers" : "DPS") + " to complete the roster.";
                return false;
            }
            AddSelectedMember(out, candidate, false, roleCounts, classCounts, used);
        }
    }

    if (out.members.size() != config.size)
    {
        error = "Internal validation failed: selected roster does not match the target size.";
        return false;
    }

    uint32 worldSelected = 0, managedSelected = 0;
    for (Member const& member : out.members)
    {
        if (member.human) continue;
        if (member.guild) continue;
        if (member.managed) ++managedSelected;
        else ++worldSelected;
    }
    uint32 fallbackSelected = worldSelected + managedSelected;
    if (config.preferGuild && fallbackSelected)
        AddWarningOnce(out, std::to_string(fallbackSelected) + " non-guild fallback bot(s) were used because the guild pool could not satisfy every slot.");
    if (config.balanceClasses && config.size >= 10 && UniqueClassCount(out) < 5)
        AddWarningOnce(out, "Class diversity is limited; the roster is role-correct but could not cover many different classes.");

    AddCoverageWarnings(out);
    Arrange(out);
    out.valid = true;
    return true;
}

void Planner::Arrange(Plan& plan)
{
    uint8 groupCount = plan.config.size <= 5 ? 1 : std::min<uint8>(8, static_cast<uint8>((plan.config.size + 4) / 5));
    std::array<uint8, 8> count{};
    std::array<uint8, 8> tanks{};
    std::array<uint8, 8> healers{};
    std::array<uint8, 8> ranged{};
    std::array<uint8, 8> melee{};
    std::vector<bool> placed(plan.members.size(), false);

    for (Member& member : plan.members) member.subgroup = 0;

    auto place = [&](std::size_t index, uint8 group) -> bool
    {
        if (group < 1 || group > groupCount || count[group - 1] >= 5) return false;
        Member& member = plan.members[index];
        member.subgroup = group;
        placed[index] = true;
        ++count[group - 1];
        if (member.role == ROLE_TANK) ++tanks[group - 1];
        if (member.role == ROLE_HEALER) ++healers[group - 1];
        if (member.role == ROLE_DPS)
        {
            if (member.rangedDps) ++ranged[group - 1];
            else ++melee[group - 1];
        }
        return true;
    };

    // Saved subgroup preferences are honored only for stable identities (humans and explicit pins).
    for (std::size_t i = 0; i < plan.members.size(); ++i)
    {
        Member const& member = plan.members[i];
        if (!MemberIsStable(member)) continue;
        auto itr = plan.config.arrangement.find(Lower(member.name));
        if (itr == plan.config.arrangement.end()) continue;
        if (!place(i, itr->second))
            AddWarningOnce(plan, "Saved subgroup preference for '" + member.name + "' could not be honored because that group is unavailable/full.");
    }

    auto bestGroup = [&](Member const& member) -> uint8
    {
        uint8 best = 1;
        int bestScore = std::numeric_limits<int>::max();
        for (uint8 g = 0; g < groupCount; ++g)
        {
            if (count[g] >= 5) continue;
            int score = int(count[g]) * 20;
            if (member.role == ROLE_TANK) score += int(tanks[g]) * 120;
            else if (member.role == ROLE_HEALER) score += int(healers[g]) * 90;
            else if (plan.config.balanceRange)
            {
                if (member.rangedDps) score += int(ranged[g]) * 35 - int(melee[g]) * 10;
                else score += int(melee[g]) * 35 - int(ranged[g]) * 10;
            }
            if (score < bestScore) { bestScore = score; best = g + 1; }
        }
        return best;
    };

    // Role passes make the layout stable and readable: tanks first, healers second, DPS last.
    for (uint8 role = ROLE_TANK; role <= ROLE_DPS; ++role)
        for (std::size_t i = 0; i < plan.members.size(); ++i)
            if (!placed[i] && plan.members[i].role == role)
                place(i, bestGroup(plan.members[i]));

    // Defensive fallback; valid target sizes should never reach this.
    for (std::size_t i = 0; i < plan.members.size(); ++i)
        if (!placed[i])
            for (uint8 g = 1; g <= groupCount; ++g)
                if (place(i, g)) break;
}

bool Planner::Move(Plan& plan, std::string const& name, uint8 subgroup, std::string& detail)
{
    uint8 groupCount = plan.config.size <= 5 ? 1 : std::min<uint8>(8, static_cast<uint8>((plan.config.size + 4) / 5));
    if (subgroup < 1 || subgroup > groupCount)
    {
        detail = "Target subgroup is outside this roster's valid group range.";
        return false;
    }

    std::size_t source = plan.members.size();
    std::string needle = Lower(name);
    for (std::size_t i = 0; i < plan.members.size(); ++i)
        if (Lower(plan.members[i].name) == needle) { source = i; break; }
    if (source == plan.members.size())
    {
        detail = "Roster member not found.";
        return false;
    }

    Member& moving = plan.members[source];
    uint8 oldGroup = moving.subgroup;
    if (oldGroup == subgroup)
    {
        detail = moving.name + " is already in Group " + std::to_string(subgroup) + ".";
        return true;
    }

    std::vector<std::size_t> targetMembers;
    for (std::size_t i = 0; i < plan.members.size(); ++i)
        if (i != source && plan.members[i].subgroup == subgroup) targetMembers.push_back(i);

    if (targetMembers.size() < 5)
    {
        moving.subgroup = subgroup;
        detail = "Moved " + moving.name + " to Group " + std::to_string(subgroup) + ".";
    }
    else
    {
        std::size_t swap = targetMembers.back();
        for (std::size_t i : targetMembers)
            if (plan.members[i].role == moving.role) { swap = i; break; }
        std::string swappedName = plan.members[swap].name;
        plan.members[swap].subgroup = oldGroup;
        moving.subgroup = subgroup;
        detail = "Moved " + moving.name + " to Group " + std::to_string(subgroup) + " and swapped " + swappedName + " to Group " + std::to_string(oldGroup) + ".";

        if (MemberIsStable(plan.members[swap]))
            plan.config.arrangement[Lower(plan.members[swap].name)] = oldGroup;
    }

    if (MemberIsStable(moving)) plan.config.arrangement[Lower(moving.name)] = subgroup;
    return true;
}

std::string Planner::CoverageSummary(Plan const& plan)
{
    std::vector<std::string> labels;
    uint32 mask = plan.coverage.utilityMask;
    if (mask & UTILITY_INTERRUPT) labels.emplace_back("interrupt");
    if (mask & UTILITY_DISPEL) labels.emplace_back("dispel");
    if (mask & UTILITY_RAID_BUFF) labels.emplace_back("buffs");
    if (mask & UTILITY_HEROISM) labels.emplace_back("heroism");
    if (mask & UTILITY_BATTLE_REZ) labels.emplace_back("battle-rez");
    if (mask & UTILITY_CC) labels.emplace_back("cc");
    if (mask & UTILITY_THREAT) labels.emplace_back("threat");
    if (labels.empty()) return "none";

    std::ostringstream out;
    for (std::size_t i = 0; i < labels.size(); ++i)
    {
        if (i) out << ',';
        out << labels[i];
    }
    return out.str();
}

std::string Planner::Diagnostics(Plan const& plan)
{
    uint32 humans = 0, guild = 0, world = 0, managed = 0;
    for (Member const& member : plan.members)
    {
        if (member.human) ++humans;
        else if (member.guild) ++guild;
        else if (member.managed) ++managed;
        else ++world;
    }
    std::ostringstream out;
    out << "candidates guild=" << plan.guildCandidates << " world=" << plan.worldCandidates
        << " managed=" << plan.managedCandidates << "; selected humans=" << humans
        << " guild=" << guild << " managed=" << managed << " world=" << world
        << "; dps ranged=" << unsigned(plan.coverage.rangedDps) << " melee=" << unsigned(plan.coverage.meleeDps)
        << "; utility=" << CoverageSummary(plan) << "; validation=" << (plan.valid ? "PASS" : "FAIL");
    return out.str();
}
}
