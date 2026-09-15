#include "GroupComposerCommand.h"

#include "RaidRosterComp.h"
#include "RaidRosterConfig.h"
#include "RaidRosterEra.h"
#include "RaidRosterGear.h"
#include "RaidRosterStore.h"

#include "AiFactory.h"
#include "CharacterCache.h"
#include "Containers.h"
#include "DatabaseEnv.h"
#include "EraTalentBots.h"
#include "Group.h"
#include "Ai/Base/Actions/InviteToGroupAction.h"
#include "ObjectAccessor.h"
#include "Player.h"
#include "PlayerbotAI.h"
#include "PlayerbotAIConfig.h"
#include "PlayerbotFactory.h"
#include "PlayerbotMgr.h"
#include "Playerbots.h"
#include "QueryResult.h"
#include "RandomPlayerbotMgr.h"
#include "ScriptMgr.h"
#include "SharedDefines.h"
#include "WorldSession.h"

#include <algorithm>
#include <array>
#include <cctype>
#include <cstdint>
#include <limits>
#include <map>
#include <set>
#include <sstream>
#include <stdexcept>
#include <string>
#include <unordered_map>
#include <unordered_set>
#include <utility>
#include <vector>

using namespace Acore::ChatCommands;

namespace
{
constexpr uint8 ROLE_TANK = 0;
constexpr uint8 ROLE_HEALER = 1;
constexpr uint8 ROLE_DPS = 2;
constexpr uint8 ANY_SPEC = 0xFF;

struct ComposerPreference
{
    uint8 role = ROLE_DPS;
    uint8 cls = 0;
    uint8 spec = ANY_SPEC;
    bool required = false;
};

struct ComposerConfig
{
    std::string mode = "dungeon";
    std::string activity = "random";
    std::string difficulty = "heroic";
    uint8 size = 5;
    uint8 tanks = 1;
    uint8 healers = 1;
    uint8 dps = 3;
    bool preferGuild = true;
    bool fillWorld = true;
    bool keepMe = true;
    bool balanceClasses = true;
    bool avoidDuplicates = false;
    uint16 minimumItemLevel = 0;
    std::vector<ComposerPreference> preferences;
};

struct ComposerCandidate
{
    ObjectGuid guid;
    std::string name;
    uint8 cls = 0;
    uint8 role = ROLE_DPS;
    uint8 spec = ANY_SPEC;
    bool guild = false;
    bool online = false;
    bool managed = false;
    bool alreadyGrouped = false;
    float itemLevel = 0.0f;
};

struct ComposerMember
{
    ObjectGuid guid;
    std::string name;
    uint8 cls = 0;
    uint8 role = ROLE_DPS;
    uint8 spec = ANY_SPEC;
    uint8 subgroup = 1;
    bool human = false;
    bool locked = false;
    bool guild = false;
    bool managed = false;
};

struct ComposerPlan
{
    ComposerConfig config;
    std::vector<ComposerMember> members;
    std::vector<std::string> warnings;
    bool valid = false;
    bool assembling = false;
    uint32 assembleElapsed = 0;
};

struct PendingSync
{
    uint32 ownerGuid = 0;
    uint8 spec = ANY_SPEC;
};

std::unordered_map<uint32, ComposerConfig> s_drafts;
std::unordered_map<uint32, ComposerPlan> s_plans;
std::unordered_map<uint32, PendingSync> s_pendingSync;
uint32 s_worldTick = 0;

std::string Lower(std::string value)
{
    std::transform(value.begin(), value.end(), value.begin(), [](unsigned char c) { return static_cast<char>(std::tolower(c)); });
    return value;
}

std::string Sanitize(std::string value)
{
    std::replace(value.begin(), value.end(), '|', '/');
    std::replace(value.begin(), value.end(), '\n', ' ');
    std::replace(value.begin(), value.end(), '\r', ' ');
    return value;
}

char const* RoleToken(uint8 role)
{
    if (role == ROLE_TANK) return "TANK";
    if (role == ROLE_HEALER) return "HEALER";
    return "DPS";
}

bool ParseRole(std::string value, uint8& role)
{
    value = Lower(value);
    if (value == "tank") { role = ROLE_TANK; return true; }
    if (value == "heal" || value == "healer") { role = ROLE_HEALER; return true; }
    if (value == "dps" || value == "dd") { role = ROLE_DPS; return true; }
    return false;
}

uint8 ClassFromToken(std::string value)
{
    value = Lower(value);
    if (value == "any") return 0;
    if (value == "warrior") return CLASS_WARRIOR;
    if (value == "paladin") return CLASS_PALADIN;
    if (value == "hunter") return CLASS_HUNTER;
    if (value == "rogue") return CLASS_ROGUE;
    if (value == "priest") return CLASS_PRIEST;
    if (value == "deathknight" || value == "death_knight" || value == "dk") return CLASS_DEATH_KNIGHT;
    if (value == "shaman") return CLASS_SHAMAN;
    if (value == "mage") return CLASS_MAGE;
    if (value == "warlock") return CLASS_WARLOCK;
    if (value == "druid") return CLASS_DRUID;
    return 0xFF;
}

char const* ClassToken(uint8 cls)
{
    switch (cls)
    {
        case CLASS_WARRIOR: return "WARRIOR";
        case CLASS_PALADIN: return "PALADIN";
        case CLASS_HUNTER: return "HUNTER";
        case CLASS_ROGUE: return "ROGUE";
        case CLASS_PRIEST: return "PRIEST";
        case CLASS_DEATH_KNIGHT: return "DEATHKNIGHT";
        case CLASS_SHAMAN: return "SHAMAN";
        case CLASS_MAGE: return "MAGE";
        case CLASS_WARLOCK: return "WARLOCK";
        case CLASS_DRUID: return "DRUID";
        default: return "UNKNOWN";
    }
}

char const* SpecName(uint8 cls, uint8 spec)
{
    switch (cls)
    {
        case CLASS_WARRIOR:
            if (spec == 0) return "Arms"; if (spec == 1) return "Fury"; if (spec == 2) return "Protection"; break;
        case CLASS_PALADIN:
            if (spec == 0) return "Holy"; if (spec == 1) return "Protection"; if (spec == 2) return "Retribution"; break;
        case CLASS_HUNTER:
            if (spec == 0) return "Beast Mastery"; if (spec == 1) return "Marksmanship"; if (spec == 2) return "Survival"; break;
        case CLASS_ROGUE:
            if (spec == 0) return "Assassination"; if (spec == 1) return "Combat"; if (spec == 2) return "Subtlety"; break;
        case CLASS_PRIEST:
            if (spec == 0) return "Discipline"; if (spec == 1) return "Holy"; if (spec == 2) return "Shadow"; break;
        case CLASS_DEATH_KNIGHT:
            if (spec == 0) return "Blood"; if (spec == 1) return "Frost"; if (spec == 2) return "Unholy"; break;
        case CLASS_SHAMAN:
            if (spec == 0) return "Elemental"; if (spec == 1) return "Enhancement"; if (spec == 2) return "Restoration"; break;
        case CLASS_MAGE:
            if (spec == 0) return "Arcane"; if (spec == 1) return "Fire"; if (spec == 2) return "Frost"; break;
        case CLASS_WARLOCK:
            if (spec == 0) return "Affliction"; if (spec == 1) return "Demonology"; if (spec == 2) return "Destruction"; break;
        case CLASS_DRUID:
            if (spec == 0) return "Balance"; if (spec == 1) return "Feral"; if (spec == 2) return "Restoration"; break;
    }
    return "Any";
}

uint8 InferRole(Player* player)
{
    if (PlayerbotAI::IsTank(player, true)) return ROLE_TANK;
    if (PlayerbotAI::IsHeal(player, true)) return ROLE_HEALER;
    return ROLE_DPS;
}

bool IsBotCharacter(ObjectGuid guid)
{
    if (Player* player = ObjectAccessor::FindConnectedPlayer(guid))
        return GET_PLAYERBOT_AI(player) != nullptr;

    uint32 account = sCharacterCache->GetCharacterAccountIdByGuid(guid);
    return (account && sPlayerbotAIConfig.IsInRandomAccountList(account)) || sRandomPlayerbotMgr.IsAddclassBot(guid.GetCounter());
}

bool PreferenceMatches(uint8 role, uint8 cls, uint8 spec, ComposerPreference const& pref)
{
    if (role != pref.role) return false;
    if (pref.cls && cls != pref.cls) return false;
    if (pref.spec != ANY_SPEC && spec != pref.spec) return false;
    return true;
}

bool MemberMatches(ComposerMember const& member, ComposerPreference const& pref)
{
    return PreferenceMatches(member.role, member.cls, member.spec, pref);
}

bool CandidateMatches(ComposerCandidate const& candidate, ComposerPreference const& pref)
{
    return PreferenceMatches(candidate.role, candidate.cls, candidate.spec, pref);
}

Player* CommandPlayer(ChatHandler* handler)
{
    return handler && handler->GetSession() ? handler->GetSession()->GetPlayer() : nullptr;
}

void SendError(ChatHandler* handler, std::string const& text)
{
    handler->PSendSysMessage("[GC]|ERROR|{}", Sanitize(text));
}

void AddHumanMembers(Player* master, ComposerPlan& plan, std::array<uint8, 3>& roleCounts, std::array<uint8, 12>& classCounts)
{
    std::unordered_set<uint32> added;
    Group* group = master->GetGroup();

    auto addLiveHuman = [&](Player* player)
    {
        if (!player || GET_PLAYERBOT_AI(player)) return;
        uint32 low = player->GetGUID().GetCounter();
        if (!added.insert(low).second) return;

        ComposerMember member;
        member.guid = player->GetGUID();
        member.name = player->GetName();
        member.cls = player->getClass();
        member.role = InferRole(player);
        member.spec = AiFactory::GetPlayerSpecTab(player);
        member.human = true;
        member.locked = true;
        member.guild = master->GetGuildId() && player->GetGuildId() == master->GetGuildId();
        plan.members.push_back(member);
        ++roleCounts[member.role];
        if (member.cls < classCounts.size()) ++classCounts[member.cls];
    };

    if (!group)
    {
        addLiveHuman(master);
        return;
    }

    for (Group::MemberSlot const& slot : group->GetMemberSlots())
    {
        Player* player = ObjectAccessor::FindConnectedPlayer(slot.guid);
        if (player)
        {
            addLiveHuman(player);
            continue;
        }

        if (!IsBotCharacter(slot.guid))
        {
            std::string name = "offline human";
            sCharacterCache->GetCharacterNameByGuid(slot.guid, name);
            plan.warnings.push_back("Offline human group member '" + name + "' has an unknown role. Have them reconnect or leave before composing.");
        }
    }

    addLiveHuman(master);
}

void AddCandidate(std::vector<ComposerCandidate>& out, std::unordered_set<uint32>& seen, ComposerCandidate candidate)
{
    if (candidate.guid.IsEmpty()) return;
    if (!seen.insert(candidate.guid.GetCounter()).second) return;
    out.push_back(std::move(candidate));
}

std::vector<ComposerCandidate> BuildCandidates(Player* master, ComposerConfig const& config)
{
    std::vector<ComposerCandidate> out;
    std::unordered_set<uint32> seen;
    Group* masterGroup = master->GetGroup();
    uint32 guildId = master->GetGuildId();

    auto makeOnline = [&](Player* bot, bool alreadyGrouped)
    {
        if (!bot || !GET_PLAYERBOT_AI(bot) || bot == master) return;
        if (bot->InBattleground() || bot->InBattlegroundQueue()) return;
        if (bot->GetGroup() && bot->GetGroup() != masterGroup) return;
        if (!alreadyGrouped && bot->GetInstanceId() != 0) return;
        if (bot->GetLevel() + 3 < master->GetLevel()) return;

        ComposerCandidate c;
        c.guid = bot->GetGUID();
        c.name = bot->GetName();
        c.cls = bot->getClass();
        c.role = InferRole(bot);
        c.spec = AiFactory::GetPlayerSpecTab(bot);
        c.guild = guildId && bot->GetGuildId() == guildId;
        c.online = true;
        c.managed = false;
        c.alreadyGrouped = alreadyGrouped;
        c.itemLevel = bot->GetAverageItemLevel();
        if (config.minimumItemLevel && c.itemLevel + 0.001f < config.minimumItemLevel) return;
        if (!c.guild && !config.fillWorld && !alreadyGrouped) return;
        AddCandidate(out, seen, std::move(c));
    };

    if (masterGroup)
    {
        for (Group::MemberSlot const& slot : masterGroup->GetMemberSlots())
            makeOnline(ObjectAccessor::FindConnectedPlayer(slot.guid), true);
    }

    if (guildId)
    {
        if (QueryResult result = CharacterDatabase.Query("SELECT guid FROM guild_member WHERE guildid = {}", guildId))
        {
            do
            {
                ObjectGuid guid = ObjectGuid::Create<HighGuid::Player>(result->Fetch()[0].Get<uint32>());
                if (sRandomPlayerbotMgr.IsAddclassBot(guid.GetCounter())) continue;
                Player* bot = ObjectAccessor::FindConnectedPlayer(guid);
                if (bot) makeOnline(bot, masterGroup && bot->GetGroup() == masterGroup);
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

    uint8 masterLevel = master->GetLevel();
    for (RaidRosterRow const& row : RaidRosterStore::Load(master->GetGUID().GetCounter()))
    {
        if (!RaidCompEligible(row.band, masterLevel)) continue;
        ObjectGuid guid = ObjectGuid::Create<HighGuid::Player>(row.botGuid);
        if (seen.count(row.botGuid))
        {
            for (ComposerCandidate& existing : out)
                if (existing.guid == guid) { existing.managed = true; break; }
            continue;
        }

        Player* online = ObjectAccessor::FindConnectedPlayer(guid);
        if (online && online->GetGroup() && online->GetGroup() != masterGroup) continue;

        ComposerCandidate c;
        c.guid = guid;
        c.cls = row.cls;
        c.role = row.role;
        c.spec = row.specTab;
        c.guild = guildId && sCharacterCache->GetCharacterGuildIdByGuid(guid) == guildId;
        c.online = online != nullptr;
        c.managed = true;
        c.alreadyGrouped = online && masterGroup && online->GetGroup() == masterGroup;
        if (online)
        {
            c.name = online->GetName();
            if (c.alreadyGrouped)
            {
                c.role = InferRole(online);
                c.spec = AiFactory::GetPlayerSpecTab(online);
            }
            c.itemLevel = online->GetAverageItemLevel();
        }
        else
        {
            sCharacterCache->GetCharacterNameByGuid(guid, c.name);
        }
        if (c.name.empty()) c.name = "Bot" + std::to_string(row.botGuid);
        if (!c.guild && !config.fillWorld) continue;
        AddCandidate(out, seen, std::move(c));
    }

    return out;
}

int CandidateScore(ComposerCandidate const& candidate, ComposerConfig const& config,
    std::array<uint8, 12> const& classCounts, std::vector<ComposerPreference> const& preferences)
{
    int score = 0;
    if (candidate.alreadyGrouped) score += 2000;
    if (config.preferGuild && candidate.guild) score += 1000;
    if (candidate.online) score += 25;
    if (config.balanceClasses && candidate.cls < classCounts.size() && classCounts[candidate.cls] == 0) score += 140;
    if (config.avoidDuplicates && candidate.cls < classCounts.size() && classCounts[candidate.cls] > 0) score -= 300;

    for (ComposerPreference const& pref : preferences)
    {
        if (pref.required || !CandidateMatches(candidate, pref)) continue;
        score += 180;
        if (pref.cls) score += 40;
        if (pref.spec != ANY_SPEC) score += 25;
    }
    return score;
}

int FindCandidate(std::vector<ComposerCandidate> const& candidates, std::vector<bool> const& used,
    uint8 role, ComposerConfig const& config, std::array<uint8, 12> const& classCounts,
    ComposerPreference const* required = nullptr)
{
    int best = -1;
    int bestScore = std::numeric_limits<int>::min();
    for (size_t i = 0; i < candidates.size(); ++i)
    {
        if (used[i]) continue;
        ComposerCandidate const& candidate = candidates[i];
        if (candidate.role != role) continue;
        if (required && !CandidateMatches(candidate, *required)) continue;
        int score = CandidateScore(candidate, config, classCounts, config.preferences);
        if (required) score += 5000;
        if (score > bestScore || (score == bestScore && (best < 0 || candidate.name < candidates[best].name)))
        {
            best = static_cast<int>(i);
            bestScore = score;
        }
    }
    return best;
}

void SelectCandidate(ComposerPlan& plan, ComposerCandidate const& candidate,
    std::array<uint8, 3>& roleCounts, std::array<uint8, 12>& classCounts)
{
    ComposerMember member;
    member.guid = candidate.guid;
    member.name = candidate.name;
    member.cls = candidate.cls;
    member.role = candidate.role;
    member.spec = candidate.spec;
    member.guild = candidate.guild;
    member.managed = candidate.managed;
    plan.members.push_back(std::move(member));
    ++roleCounts[candidate.role];
    if (candidate.cls < classCounts.size()) ++classCounts[candidate.cls];
}

void ArrangePlan(ComposerPlan& plan)
{
    if (plan.members.empty()) return;
    uint8 groupCount = plan.config.size <= 5 ? 1 : static_cast<uint8>((plan.config.size + 4) / 5);
    groupCount = std::min<uint8>(8, std::max<uint8>(1, groupCount));

    std::array<uint8, 8> total{};
    std::array<uint8, 8> healers{};

    auto assignTo = [&](ComposerMember& member, uint8 group)
    {
        group = std::min<uint8>(group, groupCount - 1);
        member.subgroup = group + 1;
        ++total[group];
        if (member.role == ROLE_HEALER) ++healers[group];
    };

    uint8 tankIndex = 0;
    for (ComposerMember& member : plan.members)
        if (member.role == ROLE_TANK)
        {
            uint8 target = tankIndex % groupCount;
            while (target < groupCount && total[target] >= 5) target = (target + 1) % groupCount;
            assignTo(member, target);
            ++tankIndex;
        }

    for (ComposerMember& member : plan.members)
        if (member.role == ROLE_HEALER)
        {
            uint8 best = 0;
            for (uint8 g = 1; g < groupCount; ++g)
                if (total[g] < 5 && (total[best] >= 5 || healers[g] < healers[best] ||
                    (healers[g] == healers[best] && total[g] < total[best]))) best = g;
            assignTo(member, best);
        }

    for (ComposerMember& member : plan.members)
        if (member.role == ROLE_DPS)
        {
            uint8 best = 0;
            for (uint8 g = 1; g < groupCount; ++g)
                if (total[g] < 5 && (total[best] >= 5 || total[g] < total[best])) best = g;
            assignTo(member, best);
        }
}

void SendPlan(ChatHandler* handler, ComposerPlan const& plan)
{
    handler->SendSysMessage("[GC]|RESET");
    handler->PSendSysMessage("[GC]|META|{}|{}|{}|{}|{}|{}|{}",
        plan.config.mode, plan.config.activity, plan.config.difficulty,
        uint32(plan.config.size), uint32(plan.config.tanks), uint32(plan.config.healers), uint32(plan.config.dps));

    uint32 humans = 0, guild = 0, world = 0;
    for (ComposerMember const& member : plan.members)
    {
        char const* source = member.human ? "HUMAN" : (member.guild ? "GUILD" : "WORLD");
        if (member.human) ++humans; else if (member.guild) ++guild; else ++world;
        handler->PSendSysMessage("[GC]|MEMBER|{}|{}|{}|{}|{}|{}|{}|{}",
            uint32(member.subgroup), Sanitize(member.name), RoleToken(member.role), ClassToken(member.cls),
            SpecName(member.cls, member.spec), source, member.human ? 1 : 0, member.locked ? 1 : 0);
    }
    for (std::string const& warning : plan.warnings)
        handler->PSendSysMessage("[GC]|WARN|{}", Sanitize(warning));
    handler->PSendSysMessage("[GC]|READY|{}|{}|{}|{}|{}", plan.valid ? 1 : 0, guild, world, humans, uint32(plan.members.size()));
}

bool BuildPlan(Player* master, ComposerConfig const& config, ComposerPlan& plan)
{
    plan = ComposerPlan{};
    plan.config = config;

    if (config.size < 1 || config.size > 40 || uint32(config.tanks) + config.healers + config.dps != config.size)
    {
        plan.warnings.push_back("Invalid role totals for the requested group size.");
        return false;
    }

    if (config.mode == "dungeon" && config.size != 5)
    {
        plan.warnings.push_back("Dungeon mode currently expects a 5-player party.");
        return false;
    }

    Group* existingGroup = master->GetGroup();
    if (existingGroup && existingGroup->GetMembersCount() > 1 && !existingGroup->IsLeader(master->GetGUID()))
    {
        plan.warnings.push_back("You must be the current group/raid leader to assemble or rearrange this roster.");
        return false;
    }

    if (!config.keepMe)
        plan.warnings.push_back("The local player must remain in an assembled WoW group, so Keep Me In Roster is enforced for assembly.");

    std::array<uint8, 3> roleCounts{};
    std::array<uint8, 12> classCounts{};
    AddHumanMembers(master, plan, roleCounts, classCounts);

    if (plan.members.size() > config.size)
    {
        plan.warnings.push_back("There are more locked human players than the requested group size.");
        return false;
    }
    if (roleCounts[ROLE_TANK] > config.tanks || roleCounts[ROLE_HEALER] > config.healers || roleCounts[ROLE_DPS] > config.dps)
    {
        plan.warnings.push_back("Locked human roles exceed one of the requested raid-wide role totals. Adjust the role targets or a human role assignment.");
        return false;
    }

    std::array<uint8, 3> requiredCounts{};
    for (ComposerPreference const& pref : config.preferences)
        if (pref.required) ++requiredCounts[pref.role];
    if (requiredCounts[ROLE_TANK] > config.tanks || requiredCounts[ROLE_HEALER] > config.healers || requiredCounts[ROLE_DPS] > config.dps)
    {
        plan.warnings.push_back("Required class/spec preferences exceed the available slots for their role.");
        return false;
    }

    std::vector<ComposerCandidate> candidates = BuildCandidates(master, config);
    std::vector<bool> used(candidates.size(), false);
    std::vector<bool> requirementMemberUsed(plan.members.size(), false);

    for (ComposerPreference const& pref : config.preferences)
    {
        if (!pref.required) continue;
        bool satisfied = false;
        for (size_t i = 0; i < plan.members.size() && i < requirementMemberUsed.size(); ++i)
        {
            if (!requirementMemberUsed[i] && MemberMatches(plan.members[i], pref))
            {
                requirementMemberUsed[i] = true;
                satisfied = true;
                break;
            }
        }
        if (satisfied) continue;

        uint8 target = pref.role == ROLE_TANK ? config.tanks : (pref.role == ROLE_HEALER ? config.healers : config.dps);
        if (roleCounts[pref.role] >= target)
        {
            plan.warnings.push_back(std::string("Required ") + RoleToken(pref.role) + " preference cannot fit inside the configured role total.");
            return false;
        }

        int index = FindCandidate(candidates, used, pref.role, config, classCounts, &pref);
        if (index < 0)
        {
            std::ostringstream out;
            out << "Required " << RoleToken(pref.role) << " preference is unavailable";
            if (pref.cls) out << " (" << ClassToken(pref.cls) << (pref.spec != ANY_SPEC ? std::string(" / ") + SpecName(pref.cls, pref.spec) : "") << ")";
            out << ".";
            plan.warnings.push_back(out.str());
            return false;
        }
        used[index] = true;
        SelectCandidate(plan, candidates[index], roleCounts, classCounts);
        requirementMemberUsed.push_back(true);
    }

    auto fillRole = [&](uint8 role, uint8 target)
    {
        while (roleCounts[role] < target)
        {
            int index = FindCandidate(candidates, used, role, config, classCounts);
            if (index < 0) return false;
            used[index] = true;
            SelectCandidate(plan, candidates[index], roleCounts, classCounts);
        }
        return true;
    };

    bool complete = fillRole(ROLE_TANK, config.tanks) && fillRole(ROLE_HEALER, config.healers) && fillRole(ROLE_DPS, config.dps);
    if (!complete || plan.members.size() != config.size)
    {
        std::ostringstream out;
        out << "Could not find enough suitable candidates. Built " << plan.members.size() << "/" << uint32(config.size)
            << " players (T " << uint32(roleCounts[ROLE_TANK]) << "/" << uint32(config.tanks)
            << ", H " << uint32(roleCounts[ROLE_HEALER]) << "/" << uint32(config.healers)
            << ", DPS " << uint32(roleCounts[ROLE_DPS]) << "/" << uint32(config.dps) << ").";
        plan.warnings.push_back(out.str());
        ArrangePlan(plan);
        return false;
    }

    uint32 worldCount = 0, guildCount = 0;
    for (ComposerMember const& member : plan.members)
        if (!member.human) { if (member.guild) ++guildCount; else ++worldCount; }
    if (config.preferGuild && worldCount)
        plan.warnings.push_back("Guild candidates filled " + std::to_string(guildCount) + " bot slot(s); " + std::to_string(worldCount) + " remaining slot(s) use safe world-bot fallback.");

    ArrangePlan(plan);
    plan.valid = true;
    return true;
}

void SyncManagedBot(Player* master, Player* bot, uint8 specTab)
{
    if (!master || !bot || specTab == ANY_SPEC) return;

    PlayerbotFactory factory(bot, master->GetLevel(), ITEM_QUALITY_LEGENDARY, 0);
    factory.Randomize(false);
    if (!EraTalentBots::FactoryReconcile(bot, specTab))
        PlayerbotFactory::InitTalentsBySpecNo(bot, specTab, true);
    if (PlayerbotAI* ai = GET_PLAYERBOT_AI(bot)) ai->ResetStrategies(false);
    RaidRosterGear::EquipForSpec(bot, master, specTab);
    factory.ApplyEnchantAndGemsNew();
    factory.InitAmmo();

    if (bot->IsClass(CLASS_DEATH_KNIGHT))
    {
        uint32 quest = bot->GetTeamId(true) == TEAM_ALLIANCE ? 13188 : 13189;
        if (!bot->IsQuestRewarded(quest)) bot->SetRewardedQuest(quest);
    }
    RaidRosterEra::SyncBotToMaster(master, bot);
}

void ApplyRaidDifficulty(Group* group, ComposerConfig const& config)
{
    if (!group || config.mode != "raid") return;
    if (config.size != 10 && config.size != 25) return;
    bool heroic = config.difficulty == "heroic";
    if (config.size == 10)
        group->SetRaidDifficulty(heroic ? RAID_DIFFICULTY_10MAN_HEROIC : RAID_DIFFICULTY_10MAN_NORMAL);
    else
        group->SetRaidDifficulty(heroic ? RAID_DIFFICULTY_25MAN_HEROIC : RAID_DIFFICULTY_25MAN_NORMAL);
}

uint32 ApplyArrangement(Player* master, ComposerPlan const& plan)
{
    Group* group = master ? master->GetGroup() : nullptr;
    if (!group) return 0;
    if (plan.config.size > 5 && !group->isRaidGroup() && group->IsLeader(master->GetGUID()))
        group->ConvertToRaid();
    ApplyRaidDifficulty(group, plan.config);
    if (!group->isRaidGroup()) return group->GetMembersCount();

    uint32 present = 0;
    for (ComposerMember const& member : plan.members)
    {
        if (!group->IsMember(member.guid)) continue;
        ++present;
        uint8 subgroup = member.subgroup > 0 ? member.subgroup - 1 : 0;
        if (subgroup < 8 && group->GetMemberGroup(member.guid) != subgroup)
            group->ChangeMembersGroup(member.guid, subgroup);
    }
    return present;
}

class GroupComposerWorldScript : public WorldScript
{
public:
    GroupComposerWorldScript() : WorldScript("GroupComposerWorldScript", { WORLDHOOK_ON_UPDATE }) { }

    void OnUpdate(uint32 diff) override
    {
        s_worldTick += diff;
        if (s_worldTick < 750) return;
        uint32 elapsed = s_worldTick;
        s_worldTick = 0;

        for (auto it = s_pendingSync.begin(); it != s_pendingSync.end(); )
        {
            ObjectGuid botGuid = ObjectGuid::Create<HighGuid::Player>(it->first);
            ObjectGuid ownerGuid = ObjectGuid::Create<HighGuid::Player>(it->second.ownerGuid);
            Player* bot = ObjectAccessor::FindConnectedPlayer(botGuid);
            Player* owner = ObjectAccessor::FindConnectedPlayer(ownerGuid);
            if (bot && owner && GET_PLAYERBOT_AI(bot))
            {
                SyncManagedBot(owner, bot, it->second.spec);
                it = s_pendingSync.erase(it);
            }
            else
                ++it;
        }

        for (auto& [ownerLow, plan] : s_plans)
        {
            if (!plan.assembling) continue;
            plan.assembleElapsed += elapsed;
            Player* owner = ObjectAccessor::FindConnectedPlayer(ObjectGuid::Create<HighGuid::Player>(ownerLow));
            if (!owner) continue;
            uint32 present = ApplyArrangement(owner, plan);
            Group* group = owner->GetGroup();
            if (group && present >= plan.members.size())
            {
                plan.assembling = false;
                ChatHandler ch(owner->GetSession());
                ch.PSendSysMessage("[GC]|DONE|Roster assembled: {}/{} players present and arranged.", present, uint32(plan.members.size()));
            }
            else if (plan.assembleElapsed >= 30000)
            {
                plan.assembling = false;
                ChatHandler ch(owner->GetSession());
                uint32 current = group ? group->GetMembersCount() : 1;
                ch.PSendSysMessage("[GC]|DONE|Assembly is still incomplete after 30 seconds ({}/{} present). Re-open the preview to see which bots did not join.", current, uint32(plan.members.size()));
            }
        }
    }
};
}

ChatCommandTable GroupComposerCommand::GetCommands() const
{
    static ChatCommandTable sub =
    {
        { "begin",    HandleBegin,      SEC_PLAYER, Console::No },
        { "pref",     HandlePreference, SEC_PLAYER, Console::No },
        { "find",     HandleFind,       SEC_PLAYER, Console::No },
        { "arrange",  HandleArrange,    SEC_PLAYER, Console::No },
        { "assemble", HandleAssemble,   SEC_PLAYER, Console::No },
        { "clear",    HandleClear,      SEC_PLAYER, Console::No },
        { "status",   HandleStatus,     SEC_PLAYER, Console::No },
    };
    static ChatCommandTable root = { { "groupcomposer", sub } };
    return root;
}

bool GroupComposerCommand::HandleBegin(ChatHandler* handler, std::string mode, std::string activity, std::string difficulty,
    uint32 size, uint32 tanks, uint32 healers, uint32 dps, uint32 preferGuild, uint32 fillWorld,
    uint32 keepMe, uint32 balanceClasses, uint32 avoidDuplicates, uint32 minimumItemLevel)
{
    if (!g_RaidRosterEnable) { SendError(handler, "RaidRoster backend is disabled."); return true; }
    Player* master = CommandPlayer(handler);
    if (!master) return true;

    mode = Lower(mode);
    difficulty = Lower(difficulty);
    if (mode != "dungeon" && mode != "raid") { SendError(handler, "Mode must be dungeon or raid."); return true; }
    if (size < 1 || size > 40 || tanks > 40 || healers > 40 || dps > 40 || tanks + healers + dps != size)
    {
        SendError(handler, "Invalid group size or role totals.");
        return true;
    }

    ComposerConfig config;
    config.mode = mode;
    config.activity = activity;
    config.difficulty = difficulty;
    config.size = static_cast<uint8>(size);
    config.tanks = static_cast<uint8>(tanks);
    config.healers = static_cast<uint8>(healers);
    config.dps = static_cast<uint8>(dps);
    config.preferGuild = preferGuild != 0;
    config.fillWorld = fillWorld != 0;
    config.keepMe = keepMe != 0;
    config.balanceClasses = balanceClasses != 0;
    config.avoidDuplicates = avoidDuplicates != 0;
    config.minimumItemLevel = static_cast<uint16>(std::min<uint32>(minimumItemLevel, 1000));

    uint32 owner = master->GetGUID().GetCounter();
    s_drafts[owner] = std::move(config);
    s_plans.erase(owner);
    return true;
}

bool GroupComposerCommand::HandlePreference(ChatHandler* handler, std::string roleText, std::string classText,
    std::string specText, std::string strength)
{
    Player* master = CommandPlayer(handler);
    if (!master) return true;
    uint32 owner = master->GetGUID().GetCounter();
    auto draft = s_drafts.find(owner);
    if (draft == s_drafts.end()) { SendError(handler, "Start a composition draft before adding preferences."); return true; }

    ComposerPreference pref;
    if (!ParseRole(roleText, pref.role)) { SendError(handler, "Unknown preference role."); return true; }
    pref.cls = ClassFromToken(classText);
    if (pref.cls == 0xFF) { SendError(handler, "Unknown preference class."); return true; }

    if (Lower(specText) == "any") pref.spec = ANY_SPEC;
    else
    {
        try
        {
            unsigned long parsed = std::stoul(specText);
            if (parsed > 2) throw std::out_of_range("spec");
            pref.spec = static_cast<uint8>(parsed);
        }
        catch (...) { SendError(handler, "Spec must be ANY, 0, 1, or 2."); return true; }
    }
    pref.required = Lower(strength) == "r" || Lower(strength) == "required";
    if (draft->second.preferences.size() >= 24) { SendError(handler, "Too many class/spec preferences (max 24)."); return true; }
    draft->second.preferences.push_back(pref);
    return true;
}

bool GroupComposerCommand::HandleFind(ChatHandler* handler)
{
    Player* master = CommandPlayer(handler);
    if (!master) return true;
    uint32 owner = master->GetGUID().GetCounter();
    auto draft = s_drafts.find(owner);
    if (draft == s_drafts.end()) { SendError(handler, "No draft. Re-open Group Composer and try again."); return true; }

    ComposerPlan plan;
    BuildPlan(master, draft->second, plan);
    s_plans[owner] = plan;
    SendPlan(handler, s_plans[owner]);
    return true;
}

bool GroupComposerCommand::HandleArrange(ChatHandler* handler)
{
    Player* master = CommandPlayer(handler);
    if (!master) return true;
    uint32 owner = master->GetGUID().GetCounter();
    auto it = s_plans.find(owner);
    if (it == s_plans.end()) { SendError(handler, "Find a roster first."); return true; }
    ArrangePlan(it->second);
    ApplyArrangement(master, it->second);
    SendPlan(handler, it->second);
    return true;
}

bool GroupComposerCommand::HandleAssemble(ChatHandler* handler)
{
    Player* master = CommandPlayer(handler);
    if (!master) return true;
    uint32 owner = master->GetGUID().GetCounter();
    auto it = s_plans.find(owner);
    if (it == s_plans.end() || !it->second.valid) { SendError(handler, "Find a valid roster before assembling."); return true; }
    ComposerPlan& plan = it->second;

    Group* group = master->GetGroup();
    if (group && group->GetMembersCount() > 1 && !group->IsLeader(master->GetGUID()))
    {
        SendError(handler, "You must be group/raid leader to assemble this roster.");
        return true;
    }

    std::unordered_set<uint32> selected;
    for (ComposerMember const& member : plan.members) selected.insert(member.guid.GetCounter());

    if (group)
    {
        std::vector<ObjectGuid> remove;
        for (Group::MemberSlot const& slot : group->GetMemberSlots())
            if (slot.guid != master->GetGUID() && !selected.count(slot.guid.GetCounter()) && IsBotCharacter(slot.guid))
                remove.push_back(slot.guid);
        for (ObjectGuid guid : remove)
            if (master->GetGroup()) master->GetGroup()->RemoveMember(guid, GROUP_REMOVEMETHOD_KICK, master->GetGUID());
    }

    PlayerbotMgr* mgr = GET_PLAYERBOT_MGR(master);
    if (!mgr) { SendError(handler, "Playerbot manager is unavailable."); return true; }
    uint32 masterAccount = master->GetSession()->GetAccountId();
    uint32 loginRequests = 0, inviteRequests = 0, alreadyPresent = 0;

    for (ComposerMember const& member : plan.members)
    {
        if (member.human) continue;
        Player* bot = ObjectAccessor::FindConnectedPlayer(member.guid);
        if (bot && master->GetGroup() && master->GetGroup()->IsMember(member.guid))
        {
            ++alreadyPresent;
            if (member.managed) SyncManagedBot(master, bot, member.spec);
            continue;
        }

        if (member.managed)
            s_pendingSync[member.guid.GetCounter()] = PendingSync{ owner, member.spec };

        if (!bot)
        {
            mgr->AddPlayerBot(member.guid, masterAccount);
            ++loginRequests;
        }
        else if (!bot->GetGroup())
        {
            InviteToGroupAction invite(GET_PLAYERBOT_AI(bot));
            if (invite.Invite(master, bot)) ++inviteRequests;
        }
    }

    plan.assembling = true;
    plan.assembleElapsed = 0;
    ApplyArrangement(master, plan);
    handler->PSendSysMessage("[GC]|DONE|Assembly started: {} already present, {} bot login(s), {} guild/world invite(s). Groups will auto-arrange as members join.",
        alreadyPresent, loginRequests, inviteRequests);
    return true;
}

bool GroupComposerCommand::HandleClear(ChatHandler* handler)
{
    Player* master = CommandPlayer(handler);
    if (!master) return true;
    uint32 owner = master->GetGUID().GetCounter();
    s_drafts.erase(owner);
    s_plans.erase(owner);
    for (auto it = s_pendingSync.begin(); it != s_pendingSync.end(); )
        if (it->second.ownerGuid == owner) it = s_pendingSync.erase(it); else ++it;
    handler->SendSysMessage("[GC]|RESET");
    handler->SendSysMessage("[GC]|DONE|Composer draft cleared. No players or bots were removed.");
    return true;
}

bool GroupComposerCommand::HandleStatus(ChatHandler* handler)
{
    Player* master = CommandPlayer(handler);
    if (!master) return true;
    uint32 owner = master->GetGUID().GetCounter();
    auto it = s_plans.find(owner);
    if (it == s_plans.end())
    {
        handler->SendSysMessage("[GC]|STATUS|Backend ready. No roster preview is currently stored.");
        return true;
    }
    SendPlan(handler, it->second);
    return true;
}

void AddGroupComposerScripts()
{
    new GroupComposerWorldScript();
}
