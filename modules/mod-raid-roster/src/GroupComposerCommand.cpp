#include "GroupComposerCommand.h"

#include "GroupComposerPlanner.h"
#include "GroupComposerTypes.h"
#include "RaidRosterEra.h"
#include "RaidRosterGear.h"

#include "Ai/Base/Actions/InviteToGroupAction.h"
#include "CharacterCache.h"
#include "DBCStores.h"
#include "EraTalentBots.h"
#include "Group.h"
#include "LFG.h"
#include "LFGMgr.h"
#include "ObjectAccessor.h"
#include "Player.h"
#include "PlayerbotAI.h"
#include "PlayerbotAIConfig.h"
#include "PlayerbotFactory.h"
#include "PlayerbotMgr.h"
#include "Playerbots.h"
#include "RandomPlayerbotMgr.h"
#include "RBAC.h"
#include "ScriptMgr.h"
#include "SharedDefines.h"
#include "World.h"
#include "WorldPacket.h"
#include "WorldSession.h"

#include <algorithm>
#include <array>
#include <cctype>
#include <cstdint>
#include <string>
#include <unordered_map>
#include <unordered_set>
#include <utility>
#include <vector>

using namespace Acore::ChatCommands;
using namespace GroupComposer;

namespace
{
struct PendingSync
{
    uint32 ownerGuid = 0;
    uint8 spec = ANY_SPEC;
    uint32 elapsed = 0;
};

std::unordered_map<uint32, Config> s_drafts;
std::unordered_map<uint32, Plan> s_plans;
std::unordered_map<uint32, PendingSync> s_pendingSync;

void ClearPendingForOwner(uint32 owner)
{
    for (auto itr = s_pendingSync.begin(); itr != s_pendingSync.end(); )
        if (itr->second.ownerGuid == owner) itr = s_pendingSync.erase(itr); else ++itr;
}

std::string Lower(std::string value)
{
    std::transform(value.begin(), value.end(), value.begin(), [](unsigned char c) { return static_cast<char>(std::tolower(c)); });
    return value;
}

std::string CanonicalName(std::string value)
{
    if (value.empty()) return value;
    value = Lower(value);
    value[0] = static_cast<char>(std::toupper(static_cast<unsigned char>(value[0])));
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

bool SpecCanFillRole(uint8 cls, uint8 spec, uint8 role)
{
    if (spec == ANY_SPEC) return Planner::CanClassFillRole(cls, role);
    switch (cls)
    {
        case CLASS_WARRIOR:      return (spec == 2 && role == ROLE_TANK) || (spec <= 1 && role == ROLE_DPS);
        case CLASS_PALADIN:      return (spec == 0 && role == ROLE_HEALER) || (spec == 1 && role == ROLE_TANK) || (spec == 2 && role == ROLE_DPS);
        case CLASS_HUNTER:       return role == ROLE_DPS;
        case CLASS_ROGUE:        return role == ROLE_DPS;
        case CLASS_PRIEST:       return ((spec == 0 || spec == 1) && role == ROLE_HEALER) || (spec == 2 && role == ROLE_DPS);
        case CLASS_DEATH_KNIGHT: return (spec == 0 && role == ROLE_TANK) || ((spec == 1 || spec == 2) && role == ROLE_DPS);
        case CLASS_SHAMAN:       return (spec == 2 && role == ROLE_HEALER) || ((spec == 0 || spec == 1) && role == ROLE_DPS);
        case CLASS_MAGE:         return role == ROLE_DPS;
        case CLASS_WARLOCK:      return role == ROLE_DPS;
        case CLASS_DRUID:        return (spec == 2 && role == ROLE_HEALER) || (spec == 1 && (role == ROLE_TANK || role == ROLE_DPS)) || (spec == 0 && role == ROLE_DPS);
        default:                 return false;
    }
}

Player* CommandPlayer(ChatHandler* handler)
{
    return handler && handler->GetSession() ? handler->GetSession()->GetPlayer() : nullptr;
}

void SendError(ChatHandler* handler, std::string const& text)
{
    if (handler) handler->PSendSysMessage("[GC]|ERROR|{}", Sanitize(text));
}

void SendProtocol(Player* player, char const* kind, std::string const& text)
{
    if (!player || !player->GetSession()) return;
    ChatHandler handler(player->GetSession());
    handler.PSendSysMessage("[GC]|{}|{}", kind, Sanitize(text));
}

char const* SourceToken(Member const& member)
{
    if (member.human) return "HUMAN";
    if (member.guild) return "GUILD";
    if (member.managed) return "ROSTER";
    return "WORLD";
}

void SendPlan(ChatHandler* handler, Plan const& plan)
{
    if (!handler) return;
    handler->SendSysMessage("[GC]|RESET");
    handler->PSendSysMessage("[GC]|META|{}|{}|{}|{}|{}|{}|{}",
        plan.config.mode, plan.config.activity, plan.config.difficulty,
        uint32(plan.config.size), uint32(plan.config.tanks), uint32(plan.config.healers), uint32(plan.config.dps));

    uint32 guild = 0, world = 0, humans = 0;
    for (Member const& member : plan.members)
    {
        if (member.human) ++humans;
        else if (member.guild) ++guild;
        else ++world;
        handler->PSendSysMessage("[GC]|MEMBER|{}|{}|{}|{}|{}|{}|{}|{}|{}",
            uint32(member.subgroup), Sanitize(member.name), RoleToken(member.role), ClassToken(member.cls),
            SpecName(member.cls, member.spec), SourceToken(member), member.human ? 1 : 0,
            member.locked ? 1 : 0, member.pinned ? 1 : 0);
    }

    handler->PSendSysMessage("[GC]|COVERAGE|{}|{}|{}", uint32(plan.coverage.rangedDps),
        uint32(plan.coverage.meleeDps), Sanitize(Planner::CoverageSummary(plan)));
    for (std::string const& warning : plan.warnings)
        handler->PSendSysMessage("[GC]|WARN|{}", Sanitize(warning));
    handler->PSendSysMessage("[GC]|READY|{}|{}|{}|{}|{}", plan.valid ? 1 : 0, guild, world, humans, uint32(plan.members.size()));
}

bool RaidSupports(std::string const& activity, uint8 size, bool heroic)
{
    struct RaidRule { char const* id; uint8 a; uint8 b; bool heroic; };
    static std::array<RaidRule, 21> const rules = {{
        { "naxxramas", 10, 25, false }, { "obsidian_sanctum", 10, 25, false },
        { "eye_of_eternity", 10, 25, false }, { "ulduar", 10, 25, false },
        { "trial_crusader", 10, 25, true }, { "onyxia", 10, 25, false },
        { "vault_archavon", 10, 25, false }, { "icecrown", 10, 25, true },
        { "ruby_sanctum", 10, 25, true }, { "karazhan", 10, 0, false },
        { "zulaman", 10, 0, false }, { "gruul", 25, 0, false },
        { "magtheridon", 25, 0, false }, { "serpentshrine", 25, 0, false },
        { "tempest_keep", 25, 0, false }, { "hyjal", 25, 0, false },
        { "black_temple", 25, 0, false }, { "sunwell", 25, 0, false },
        { "zul_gurub", 20, 0, false }, { "aq20", 20, 0, false },
        { "molten_core", 40, 0, false },
    }};
    for (RaidRule const& rule : rules)
        if (activity == rule.id)
            return (size == rule.a || (rule.b && size == rule.b)) && (!heroic || rule.heroic);
    if (activity == "blackwing_lair" || activity == "aq40") return size == 40 && !heroic;
    return false;
}

uint32 DungeonMapId(std::string const& activity)
{
    static std::unordered_map<std::string, uint32> const maps = {
        { "utgarde_keep", 574 }, { "nexus", 576 }, { "azjol_nerub", 601 }, { "ahnkahet", 619 },
        { "drak_tharon", 600 }, { "violet_hold", 608 }, { "gundrak", 604 }, { "halls_of_stone", 599 },
        { "halls_of_lightning", 602 }, { "oculus", 578 }, { "culling", 595 }, { "utgarde_pinnacle", 575 },
        { "trial_champion", 650 }, { "forge_souls", 632 }, { "pit_saron", 658 }, { "halls_reflection", 668 },
    };
    auto itr = maps.find(activity);
    return itr == maps.end() ? 0 : itr->second;
}

bool IsBotGuid(ObjectGuid guid)
{
    if (Player* player = ObjectAccessor::FindConnectedPlayer(guid)) return GET_PLAYERBOT_AI(player) != nullptr;
    uint32 account = sCharacterCache->GetCharacterAccountIdByGuid(guid);
    return (account && sPlayerbotAIConfig.IsInRandomAccountList(account)) || sRandomPlayerbotMgr.IsAddclassBot(guid.GetCounter());
}

bool Selected(Plan const& plan, ObjectGuid guid)
{
    for (Member const& member : plan.members) if (member.guid == guid) return true;
    return false;
}

bool CrossFactionBlocked(Player* master, Player* other)
{
    if (!master || !other || master->IsGameMaster()) return false;
    return !sWorld->getBoolConfig(CONFIG_ALLOW_TWO_SIDE_INTERACTION_GROUP) && master->GetTeamId() != other->GetTeamId();
}

bool ConflictingInstances(Player* master, Player* other)
{
    if (!master || !other) return false;
    return master->GetInstanceId() != 0 && other->GetInstanceId() != 0
        && master->GetInstanceId() != other->GetInstanceId() && master->GetMapId() == other->GetMapId();
}

void SyncManagedBot(Player* master, Player* bot, uint8 spec)
{
    if (!master || !bot) return;
    if (spec > 2) spec = Planner::InferSpec(bot);
    if (spec > 2) return;

    PlayerbotFactory factory(bot, master->GetLevel(), ITEM_QUALITY_LEGENDARY, 0);
    factory.Randomize(false);
    if (!EraTalentBots::FactoryReconcile(bot, spec)) PlayerbotFactory::InitTalentsBySpecNo(bot, spec, true);
    if (PlayerbotAI* ai = GET_PLAYERBOT_AI(bot)) ai->ResetStrategies(false);
    RaidRosterGear::EquipForSpec(bot, master, spec);
    factory.ApplyEnchantAndGemsNew();
    factory.InitAmmo();

    if (bot->IsClass(CLASS_DEATH_KNIGHT))
    {
        uint32 quest = bot->GetTeamId(true) == TEAM_ALLIANCE ? 13188 : 13189;
        if (!bot->IsQuestRewarded(quest)) bot->SetRewardedQuest(quest);
    }
    RaidRosterEra::SyncBotToMaster(master, bot);
}

void ApplyGroupSettings(Player* master, Plan const& plan)
{
    Group* group = master ? master->GetGroup() : nullptr;
    if (!group) return;
    if (plan.config.size > 5 && !group->isRaidGroup()) group->ConvertToRaid();

    if (plan.config.mode == "raid")
    {
        if (plan.config.size == 10)
            group->SetRaidDifficulty(plan.config.difficulty == "heroic" ? RAID_DIFFICULTY_10MAN_HEROIC : RAID_DIFFICULTY_10MAN_NORMAL);
        else if (plan.config.size == 25)
            group->SetRaidDifficulty(plan.config.difficulty == "heroic" ? RAID_DIFFICULTY_25MAN_HEROIC : RAID_DIFFICULTY_25MAN_NORMAL);
    }
    else
    {
        bool heroicBase = plan.config.difficulty != "normal";
        group->SetDungeonDifficulty(heroicBase ? DUNGEON_DIFFICULTY_HEROIC : DUNGEON_DIFFICULTY_NORMAL);
    }
}

bool ApplyArrangement(Player* master, Plan const& plan, std::string& error)
{
    Group* group = master ? master->GetGroup() : nullptr;
    if (!group) { error = "The assembled roster has no live group."; return false; }
    ApplyGroupSettings(master, plan);
    if (!group->isRaidGroup()) return true;

    // Resolve the preview layout as a permutation. Full 25/40-player raids have no spare subgroup
    // slot, so a normal one-way ChangeMembersGroup cannot realize a swap. The tracked core patch
    // provides an atomic SwapMembersGroup operation specifically for this case.
    std::size_t maxPasses = std::max<std::size_t>(1, plan.members.size() * 2);
    for (std::size_t pass = 0; pass < maxPasses; ++pass)
    {
        bool mismatch = false;
        bool progress = false;

        for (Member const& member : plan.members)
        {
            if (member.subgroup < 1 || member.subgroup > 8 || !group->IsMember(member.guid)) continue;
            uint8 current = group->GetMemberGroup(member.guid);
            uint8 target = member.subgroup - 1;
            if (current == target) continue;
            mismatch = true;

            if (group->HasFreeSlotSubGroup(target))
            {
                group->ChangeMembersGroup(member.guid, target);
                progress = true;
                continue;
            }

            Member const* swap = nullptr;
            for (Member const& candidate : plan.members)
            {
                if (candidate.guid == member.guid || candidate.subgroup < 1 || candidate.subgroup > 8 || !group->IsMember(candidate.guid)) continue;
                if (group->GetMemberGroup(candidate.guid) != target) continue;
                uint8 candidateTarget = candidate.subgroup - 1;
                if (candidateTarget == current) { swap = &candidate; break; }
                if (candidateTarget != target && !swap) swap = &candidate;
            }

            if (swap)
            {
                group->SwapMembersGroup(member.guid, swap->guid);
                progress = true;
            }
        }

        if (!mismatch) { group->SendUpdate(); return true; }
        if (!progress) break;
    }

    for (Member const& member : plan.members)
    {
        if (member.subgroup < 1 || member.subgroup > 8 || !group->IsMember(member.guid)) continue;
        if (group->GetMemberGroup(member.guid) != member.subgroup - 1)
        {
            error = "The live raid subgroup layout changed while assembly was finishing. Re-run Find Roster and retry.";
            return false;
        }
    }
    group->SendUpdate();
    return true;
}

void PruneUnselectedBots(Player* master, Plan const& plan)
{
    Group* group = master ? master->GetGroup() : nullptr;
    if (!group) return;
    std::vector<ObjectGuid> remove;
    for (Group::MemberSlot const& slot : group->GetMemberSlots())
        if (!Selected(plan, slot.guid) && IsBotGuid(slot.guid)) remove.push_back(slot.guid);
    for (ObjectGuid guid : remove) group->RemoveMember(guid);
}

bool ValidateAssemblySnapshot(Player* master, Plan const& plan, std::string& error)
{
    if (!master || !plan.valid || plan.members.size() != plan.config.size)
    {
        error = "The roster preview is no longer structurally valid. Run Find Roster again.";
        return false;
    }

    Member const* self = nullptr;
    for (Member const& member : plan.members) if (member.guid == master->GetGUID()) { self = &member; break; }
    if (!self || !self->human || !self->locked)
    {
        error = "Your character is missing from the reviewed roster. Run Find Roster again.";
        return false;
    }

    Group* group = master->GetGroup();
    if (group)
    {
        if (!group->IsLeader(master->GetGUID()) && !group->IsAssistant(master->GetGUID()))
        {
            error = "You must still be group leader or assistant to assemble this roster.";
            return false;
        }
        if (group->isBFGroup() || group->isBGGroup())
        {
            error = "Battleground/Battlefield groups cannot be modified by Group Composer.";
            return false;
        }

        // Humans are never silently pruned. If somebody joined after preview, force a new preview so
        // the human becomes an explicit locked anchor before any bot is removed.
        for (Group::MemberSlot const& slot : group->GetMemberSlots())
        {
            if (!Selected(plan, slot.guid) && !IsBotGuid(slot.guid))
            {
                error = "The group gained a real player after the preview. Run Find Roster again so every human is locked into the composition.";
                return false;
            }
        }
    }

    for (Member const& member : plan.members)
    {
        Player* live = ObjectAccessor::FindConnectedPlayer(member.guid);
        bool alreadyWithMaster = group && group->IsMember(member.guid);

        if (member.human)
        {
            if (member.guid == master->GetGUID())
            {
                if (!live || GET_PLAYERBOT_AI(live))
                {
                    error = "Your character is no longer available as the live human roster anchor.";
                    return false;
                }
                continue;
            }

            // Group membership persists for an offline character, so checking IsMember() first can
            // make a disconnected friend look assembled. Preserve the human anchor, but require the
            // real player to be online before committing the reviewed adventure roster.
            if (!live || GET_PLAYERBOT_AI(live))
            {
                error = "Human player '" + member.name + "' is offline. They remain a locked roster anchor, but the group cannot be assembled until they return or you explicitly reform the party and Find Roster again.";
                return false;
            }
            if (alreadyWithMaster) continue;
            if (live->GetGroup() && live->GetGroup() != group)
            {
                error = "Human player '" + member.name + "' joined another group after the preview.";
                return false;
            }
            if (live->IsSpectator() || live->IsBeingTeleported() || !live->IsAcceptGroupInvites() || live->GetGroupInvite())
            {
                error = "Human player '" + member.name + "' is no longer ready to receive this group invite.";
                return false;
            }
            if (CrossFactionBlocked(master, live))
            {
                error = "Human player '" + member.name + "' cannot join while cross-faction groups are disabled.";
                return false;
            }
            if (ConflictingInstances(master, live))
            {
                error = "Human player '" + member.name + "' is in a different copy of the same instance.";
                return false;
            }
            continue;
        }

        if (!live)
        {
            if (!member.managed)
            {
                error = "Selected bot '" + member.name + "' went offline after the preview. Run Find Roster again.";
                return false;
            }
            continue;
        }
        if (!GET_PLAYERBOT_AI(live))
        {
            error = "Selected bot identity '" + member.name + "' is no longer controlled by Playerbots.";
            return false;
        }
        if (live->GetGroup() && live->GetGroup() != group)
        {
            error = "Selected bot '" + member.name + "' joined another group after the preview.";
            return false;
        }
        if (!alreadyWithMaster && (live->InBattleground() || live->InBattlegroundQueue() || live->IsSpectator() || live->IsBeingTeleported()))
        {
            error = "Selected bot '" + member.name + "' is no longer available. Run Find Roster again.";
            return false;
        }

        // Ordinary guild/world bots are selected from their live state and are not rewritten by
        // Group Composer. Revalidate the reviewed role/spec/item-level snapshot immediately before
        // any pruning. Managed RaidRoster bots are intentionally excluded because Assemble owns
        // their controlled talent/gear reconciliation lifecycle.
        if (!member.managed)
        {
            uint8 liveRole = Planner::InferRole(live);
            if (liveRole != member.role)
            {
                error = "Selected bot '" + member.name + "' changed active role after the preview. Run Find Roster again.";
                return false;
            }

            uint8 liveSpec = Planner::InferSpec(live);
            if (member.spec != ANY_SPEC && liveSpec != ANY_SPEC && liveSpec != member.spec)
            {
                error = "Selected bot '" + member.name + "' changed specialization after the preview. Run Find Roster again.";
                return false;
            }

            if (plan.config.minimumItemLevel && live->GetAverageItemLevel() + 0.001f < plan.config.minimumItemLevel)
            {
                error = "Selected bot '" + member.name + "' fell below the configured minimum item level after the preview. Run Find Roster again.";
                return false;
            }
        }
    }
    return true;
}

void InviteHuman(Player* master, Player* target)
{
    if (!master || !target || !master->GetSession()) return;
    WorldPacket packet;
    packet << target->GetName();
    packet << uint32(0);
    master->GetSession()->HandleGroupInviteOpcode(packet);
}

bool InviteBot(Player* master, Player* bot)
{
    if (!master || !bot) return false;
    PlayerbotAI* ai = GET_PLAYERBOT_AI(bot);
    if (!ai) return false;
    InviteToGroupAction action(ai);
    return action.Invite(master, bot);
}

bool PlanMembershipComplete(Player* master, Plan const& plan)
{
    Group* group = master ? master->GetGroup() : nullptr;
    if (!group) return plan.members.size() == 1 && plan.members[0].guid == master->GetGUID();
    for (Member const& member : plan.members) if (!group->IsMember(member.guid)) return false;
    return group->GetMembersCount() == plan.members.size();
}

bool OwnerHasPendingSync(uint32 ownerLow)
{
    for (auto const& entry : s_pendingSync) if (entry.second.ownerGuid == ownerLow) return true;
    return false;
}

void TryInviteMissing(Player* master, Plan& plan)
{
    if (!master) return;
    Group* group = master->GetGroup();
    if (group) ApplyGroupSettings(master, plan);

    auto canInvite = [&]() -> bool
    {
        Group* current = master->GetGroup();
        return !current || !current->IsFull();
    };

    for (Member const& member : plan.members)
    {
        if (member.human || member.guid == master->GetGUID()) continue;
        Player* bot = ObjectAccessor::FindConnectedPlayer(member.guid);
        if (!bot || !GET_PLAYERBOT_AI(bot)) continue;
        Group* current = master->GetGroup();
        if (current && current->IsMember(member.guid)) continue;
        if (bot->GetGroup() && bot->GetGroup() != current) continue;
        if (bot->GetGroupInvite()) continue;
        if (!canInvite()) break;
        bool hadGroup = current != nullptr;
        InviteBot(master, bot);
        if (!hadGroup) return;
    }

    group = master->GetGroup();
    if (group) ApplyGroupSettings(master, plan);

    for (Member const& member : plan.members)
    {
        if (!member.human || member.guid == master->GetGUID()) continue;
        if (plan.humanInvitesSent.count(member.guid.GetCounter())) continue;
        Player* player = ObjectAccessor::FindConnectedPlayer(member.guid);
        if (!player) continue;
        Group* current = master->GetGroup();
        if (current && current->IsMember(member.guid)) continue;
        if (player->GetGroup() && player->GetGroup() != current) continue;
        if (player->GetGroupInvite()) continue;
        if (!canInvite()) break;
        bool hadGroup = current != nullptr;
        InviteHuman(master, player);
        plan.humanInvitesSent.insert(member.guid.GetCounter());
        if (!hadGroup) return;
    }
}

uint8 LfgRole(uint8 role, bool leader)
{
    uint8 value = role == ROLE_TANK ? lfg::PLAYER_ROLE_TANK : role == ROLE_HEALER ? lfg::PLAYER_ROLE_HEALER : lfg::PLAYER_ROLE_DAMAGE;
    if (leader) value |= lfg::PLAYER_ROLE_LEADER;
    return value;
}

void SendAnchor(ChatHandler* handler, Player* master, ObjectGuid guid, uint8 subgroup, std::unordered_set<uint32>& sent)
{
    if (!handler || !master || guid.IsEmpty() || !sent.insert(guid.GetCounter()).second) return;
    if (IsBotGuid(guid)) return;

    Player* live = ObjectAccessor::FindConnectedPlayer(guid);
    std::string name;
    uint8 cls = 0;
    bool online = live != nullptr;
    char const* roleToken = "AUTO";

    if (live)
    {
        name = live->GetName();
        cls = live->getClass();
        roleToken = RoleToken(Planner::InferRole(live));
    }
    else
    {
        CharacterCacheEntry const* cache = sCharacterCache->GetCharacterCacheByGuid(guid);
        if (!cache) return;
        name = cache->Name;
        cls = cache->Class;

        auto draft = s_drafts.find(master->GetGUID().GetCounter());
        if (draft != s_drafts.end())
        {
            auto overrideItr = draft->second.humanRoles.find(Lower(name));
            if (overrideItr != draft->second.humanRoles.end()) roleToken = RoleToken(overrideItr->second);
        }
    }

    handler->PSendSysMessage("[GC]|ANCHOR|{}|{}|{}|{}|{}|{}", Sanitize(name), ClassToken(cls), roleToken,
        online ? 1 : 0, uint32(subgroup + 1), guid == master->GetGUID() ? 1 : 0);
}

class GroupComposerWorld : public WorldScript
{
public:
    GroupComposerWorld() : WorldScript("GroupComposerWorld") { }

    void OnUpdate(uint32 diff) override
    {
        for (auto itr = s_pendingSync.begin(); itr != s_pendingSync.end(); )
        {
            itr->second.elapsed += diff;
            ObjectGuid botGuid = ObjectGuid::Create<HighGuid::Player>(itr->first);
            ObjectGuid ownerGuid = ObjectGuid::Create<HighGuid::Player>(itr->second.ownerGuid);
            Player* bot = ObjectAccessor::FindConnectedPlayer(botGuid);
            Player* master = ObjectAccessor::FindConnectedPlayer(ownerGuid);
            if (bot && master)
            {
                SyncManagedBot(master, bot, itr->second.spec);
                itr = s_pendingSync.erase(itr);
            }
            else if (itr->second.elapsed > 30000) itr = s_pendingSync.erase(itr);
            else ++itr;
        }

        for (auto& entry : s_plans)
        {
            uint32 ownerLow = entry.first;
            Plan& plan = entry.second;
            if (!plan.assembling) continue;
            plan.assembleElapsed += diff;

            Player* master = ObjectAccessor::FindConnectedPlayer(ObjectGuid::Create<HighGuid::Player>(ownerLow));
            if (!master)
            {
                if (plan.assembleElapsed > 30000) plan.assembling = false;
                continue;
            }

            TryInviteMissing(master, plan);
            if (PlanMembershipComplete(master, plan) && !OwnerHasPendingSync(ownerLow))
            {
                // The roster can drift while invitations and managed logins are completing. Re-run
                // the same authoritative snapshot checks immediately before reporting success so a
                // disconnect, role/spec change or late human join cannot slip through the assembly window.
                std::string completionValidationError;
                if (!ValidateAssemblySnapshot(master, plan, completionValidationError))
                {
                    plan.assembling = false;
                    SendProtocol(master, "ERROR", completionValidationError);
                    continue;
                }

                std::string arrangementError;
                plan.assembling = false;
                if (ApplyArrangement(master, plan, arrangementError))
                    SendProtocol(master, "DONE", "Roster assembled and subgroup layout applied.");
                else
                    SendProtocol(master, "ERROR", arrangementError);
            }
            else if (plan.assembleElapsed > 30000)
            {
                plan.assembling = false;
                SendProtocol(master, "ERROR", "Assembly timed out. Accepted humans and joined bots were kept; review availability and retry.");
            }
        }
    }
};
}

ChatCommandTable GroupComposerCommand::GetCommands() const
{
    static ChatCommandTable sub =
    {
        { "begin",       HandleBegin,             SEC_PLAYER, Console::No },
        { "pref",        HandlePreference,        SEC_PLAYER, Console::No },
        { "humanrole",   HandleHumanRole,         SEC_PLAYER, Console::No },
        { "human",       HandleHuman,             SEC_PLAYER, Console::No },
        { "pin",         HandlePin,               SEC_PLAYER, Console::No },
        { "arrangepref", HandleArrangePreference, SEC_PLAYER, Console::No },
        { "find",        HandleFind,              SEC_PLAYER, Console::No },
        { "arrange",     HandleArrange,           SEC_PLAYER, Console::No },
        { "move",        HandleMove,              SEC_PLAYER, Console::No },
        { "assemble",    HandleAssemble,          SEC_PLAYER, Console::No },
        { "queue",       HandleQueue,             SEC_PLAYER, Console::No },
        { "anchors",     HandleAnchors,           SEC_PLAYER, Console::No },
        { "diagnostics", HandleDiagnostics,       SEC_PLAYER, Console::No },
        { "clear",       HandleClear,             SEC_PLAYER, Console::No },
        { "status",      HandleStatus,            SEC_PLAYER, Console::No },
    };
    static ChatCommandTable root = { { "groupcomposer", sub } };
    return root;
}

bool GroupComposerCommand::HandleBegin(ChatHandler* handler, std::string mode, std::string activity, std::string difficulty,
    uint32 size, uint32 tanks, uint32 healers, uint32 dps, uint32 preferGuild, uint32 fillWorld,
    uint32 keepMe, uint32 balanceClasses, uint32 balanceUtility, uint32 balanceRange,
    uint32 avoidDuplicates, uint32 minimumItemLevel)
{
    Player* master = CommandPlayer(handler);
    if (!master) { SendError(handler, "Run Group Composer in-world as a player."); return true; }
    uint32 owner = master->GetGUID().GetCounter();
    auto currentPlan = s_plans.find(owner);
    if (currentPlan != s_plans.end() && currentPlan->second.assembling)
    {
        s_drafts.erase(owner);
        SendError(handler, "Wait for the current assembly to finish before starting a new search.");
        return true;
    }

    mode = Lower(mode); activity = Lower(activity); difficulty = Lower(difficulty);
    if (mode != "dungeon" && mode != "raid") { SendError(handler, "Mode must be dungeon or raid."); return true; }
    if (size < 1 || size > 40 || tanks > 40 || healers > 40 || dps > 40 || tanks + healers + dps != size)
    { SendError(handler, "Role totals must exactly equal the requested group size."); return true; }
    if (mode == "dungeon" && size != 5) { SendError(handler, "Dungeon mode requires size 5."); return true; }

    if (mode == "raid")
    {
        bool heroic = difficulty == "heroic";
        if (difficulty != "normal" && !heroic) { SendError(handler, "Raid difficulty must be normal or heroic."); return true; }
        if (!RaidSupports(activity, static_cast<uint8>(size), heroic)) { SendError(handler, "That raid, size and difficulty combination is not supported."); return true; }
    }
    else
    {
        if (activity != "random" && !DungeonMapId(activity)) { SendError(handler, "Unknown dungeon selection."); return true; }
        if (difficulty != "normal" && difficulty != "heroic" && difficulty != "alpha" && difficulty != "beta" && difficulty != "gamma")
        { SendError(handler, "Unknown dungeon difficulty."); return true; }
    }

    Config config;
    config.mode = mode; config.activity = activity; config.difficulty = difficulty;
    config.size = static_cast<uint8>(size); config.tanks = static_cast<uint8>(tanks);
    config.healers = static_cast<uint8>(healers); config.dps = static_cast<uint8>(dps);
    config.preferGuild = preferGuild != 0; config.fillWorld = fillWorld != 0;
    (void)keepMe; config.keepMe = true;
    config.balanceClasses = balanceClasses != 0; config.balanceUtility = balanceUtility != 0; config.balanceRange = balanceRange != 0;
    config.avoidDuplicates = avoidDuplicates != 0;
    config.minimumItemLevel = static_cast<uint16>(std::min<uint32>(1000, minimumItemLevel));

    ClearPendingForOwner(owner);
    s_drafts[owner] = std::move(config);
    s_plans.erase(owner);
    handler->SendSysMessage("[GC]|STATUS|Composer request accepted. Applying preferences...");
    return true;
}

bool GroupComposerCommand::HandlePreference(ChatHandler* handler, std::string roleText, std::string classText,
    std::string specText, std::string strength)
{
    Player* master = CommandPlayer(handler);
    if (!master) return true;
    auto draft = s_drafts.find(master->GetGUID().GetCounter());
    if (draft == s_drafts.end()) { SendError(handler, "Start a composer request before adding preferences."); return true; }
    if (draft->second.preferences.size() >= 36) { SendError(handler, "Too many class/spec preferences (maximum 36)."); return true; }

    uint8 role;
    if (!ParseRole(roleText, role)) { SendError(handler, "Unknown preference role."); return true; }
    uint8 cls = ClassFromToken(classText);
    if (cls == 0xFF) { SendError(handler, "Unknown preference class."); return true; }

    uint8 spec = ANY_SPEC;
    if (Lower(specText) != "any")
    {
        if (specText.size() != 1 || specText[0] < '0' || specText[0] > '2') { SendError(handler, "Spec must be ANY or talent tab 0-2."); return true; }
        spec = static_cast<uint8>(specText[0] - '0');
        if (!cls) { SendError(handler, "A specific spec requires a specific class."); return true; }
    }
    if (cls && !SpecCanFillRole(cls, spec, role)) { SendError(handler, "That class/spec cannot fill the selected role."); return true; }

    strength = Lower(strength);
    if (strength != "r" && strength != "p") { SendError(handler, "Preference strength must be R or P."); return true; }
    draft->second.preferences.push_back({ role, cls, spec, strength == "r" });
    return true;
}

bool GroupComposerCommand::HandleHumanRole(ChatHandler* handler, std::string name, std::string roleText)
{
    Player* master = CommandPlayer(handler);
    if (!master) return true;
    auto draft = s_drafts.find(master->GetGUID().GetCounter());
    if (draft == s_drafts.end()) { SendError(handler, "Start a composer request first."); return true; }
    uint8 role;
    if (!ParseRole(roleText, role)) { SendError(handler, "Human role must be tank, healer or dps."); return true; }
    name = CanonicalName(name);
    if (name.empty()) { SendError(handler, "Human name cannot be empty."); return true; }
    draft->second.humanRoles[Lower(name)] = role;
    return true;
}

bool GroupComposerCommand::HandleHuman(ChatHandler* handler, std::string name, std::string roleText)
{
    Player* master = CommandPlayer(handler);
    if (!master) return true;
    auto draft = s_drafts.find(master->GetGUID().GetCounter());
    if (draft == s_drafts.end()) { SendError(handler, "Start a composer request first."); return true; }
    uint8 role;
    if (!ParseRole(roleText, role)) { SendError(handler, "Human role must be tank, healer or dps."); return true; }
    name = CanonicalName(name);
    if (name.empty()) { SendError(handler, "Human name cannot be empty."); return true; }

    for (AddedHuman& entry : draft->second.extraHumans)
        if (Lower(entry.name) == Lower(name)) { entry.role = role; return true; }
    if (draft->second.extraHumans.size() >= 39) { SendError(handler, "Too many manually added humans."); return true; }
    draft->second.extraHumans.push_back({ name, role });
    return true;
}

bool GroupComposerCommand::HandlePin(ChatHandler* handler, std::string name, std::string roleText, std::string strength)
{
    Player* master = CommandPlayer(handler);
    if (!master) return true;
    auto draft = s_drafts.find(master->GetGUID().GetCounter());
    if (draft == s_drafts.end()) { SendError(handler, "Start a composer request first."); return true; }
    uint8 role;
    if (!ParseRole(roleText, role)) { SendError(handler, "Pinned role must be tank, healer or dps."); return true; }
    strength = Lower(strength);
    if (strength != "r" && strength != "p") { SendError(handler, "Pin strength must be R or P."); return true; }
    name = CanonicalName(name);
    if (name.empty()) { SendError(handler, "Pinned name cannot be empty."); return true; }

    for (Pin& pin : draft->second.pins)
        if (Lower(pin.name) == Lower(name)) { pin.role = role; pin.required = strength == "r"; return true; }
    if (draft->second.pins.size() >= 40) { SendError(handler, "Too many pinned members."); return true; }
    draft->second.pins.push_back({ name, role, strength == "r" });
    return true;
}

bool GroupComposerCommand::HandleArrangePreference(ChatHandler* handler, std::string name, uint32 subgroup)
{
    Player* master = CommandPlayer(handler);
    if (!master) return true;
    auto draft = s_drafts.find(master->GetGUID().GetCounter());
    if (draft == s_drafts.end()) { SendError(handler, "Start a composer request first."); return true; }
    if (subgroup < 1 || subgroup > 8) { SendError(handler, "Subgroup must be 1-8."); return true; }
    name = CanonicalName(name);
    if (!name.empty()) draft->second.arrangement[Lower(name)] = static_cast<uint8>(subgroup);
    return true;
}

bool GroupComposerCommand::HandleFind(ChatHandler* handler)
{
    Player* master = CommandPlayer(handler);
    if (!master) return true;
    uint32 owner = master->GetGUID().GetCounter();
    auto draft = s_drafts.find(owner);
    if (draft == s_drafts.end()) { SendError(handler, "No composer request. Configure the addon and press Find Roster again."); return true; }

    Plan plan;
    std::string error;
    if (!Planner::Build(master, draft->second, plan, error))
    {
        handler->SendSysMessage("[GC]|RESET");
        SendError(handler, error);
        s_plans.erase(owner);
        return true;
    }

    s_plans[owner] = std::move(plan);
    SendPlan(handler, s_plans[owner]);
    return true;
}

bool GroupComposerCommand::HandleArrange(ChatHandler* handler)
{
    Player* master = CommandPlayer(handler);
    if (!master) return true;
    auto itr = s_plans.find(master->GetGUID().GetCounter());
    if (itr == s_plans.end() || !itr->second.valid) { SendError(handler, "Find a valid roster before arranging it."); return true; }
    if (itr->second.assembling) { SendError(handler, "Wait for the current assembly to finish before changing the preview."); return true; }
    Planner::Arrange(itr->second);
    SendPlan(handler, itr->second);
    handler->SendSysMessage("[GC]|DONE|Preview auto-arranged. Assemble applies the subgroup layout to the live raid.");
    return true;
}

bool GroupComposerCommand::HandleMove(ChatHandler* handler, std::string name, uint32 subgroup)
{
    Player* master = CommandPlayer(handler);
    if (!master) return true;
    auto itr = s_plans.find(master->GetGUID().GetCounter());
    if (itr == s_plans.end() || !itr->second.valid) { SendError(handler, "Find a valid roster before moving members."); return true; }
    if (itr->second.assembling) { SendError(handler, "Wait for the current assembly to finish before changing the preview."); return true; }
    std::string detail;
    if (!Planner::Move(itr->second, CanonicalName(name), static_cast<uint8>(subgroup), detail)) { SendError(handler, detail); return true; }
    SendPlan(handler, itr->second);
    handler->PSendSysMessage("[GC]|DONE|{} Preview only; Assemble applies it to the live raid.", Sanitize(detail));
    return true;
}

bool GroupComposerCommand::HandleAssemble(ChatHandler* handler)
{
    Player* master = CommandPlayer(handler);
    if (!master) return true;
    uint32 owner = master->GetGUID().GetCounter();
    auto itr = s_plans.find(owner);
    if (itr == s_plans.end() || !itr->second.valid) { SendError(handler, "Find a valid roster before assembling it."); return true; }
    Plan& plan = itr->second;
    if (plan.assembling) { handler->SendSysMessage("[GC]|STATUS|Assembly is already in progress."); return true; }

    std::string validationError;
    if (!ValidateAssemblySnapshot(master, plan, validationError))
    {
        SendError(handler, validationError);
        return true;
    }

    bool needsManagedLogin = false;
    for (Member const& member : plan.members)
        if (!member.human && member.managed && !ObjectAccessor::FindConnectedPlayer(member.guid)) { needsManagedLogin = true; break; }

    PlayerbotMgr* mgr = needsManagedLogin ? GET_PLAYERBOT_MGR(master) : nullptr;
    if (needsManagedLogin && !mgr) { SendError(handler, "Playerbot manager is unavailable for the offline managed bot(s) in this roster."); return true; }

    // A fresh explicit Assemble is also the explicit retry boundary for human invitations. During
    // this attempt each real player receives at most one invite, so a decline is never turned into
    // an invite storm by the world-update retry loop.
    plan.humanInvitesSent.clear();

    // This is the first destructive step. Everything above it only revalidates the reviewed snapshot.
    PruneUnselectedBots(master, plan);

    uint32 account = master->GetSession()->GetAccountId();
    for (Member const& member : plan.members)
    {
        if (member.human || !member.managed) continue;
        Player* bot = ObjectAccessor::FindConnectedPlayer(member.guid);
        if (bot)
        {
            SyncManagedBot(master, bot, member.spec);
            continue;
        }
        mgr->AddPlayerBot(member.guid, account);
        s_pendingSync[member.guid.GetCounter()] = { owner, member.spec, 0 };
    }

    plan.assembling = true;
    plan.assembleElapsed = 0;
    TryInviteMissing(master, plan);
    handler->SendSysMessage("[GC]|STATUS|Assembly started. Bots will auto-join; invited real players must accept normally.");
    return true;
}

bool GroupComposerCommand::HandleQueue(ChatHandler* handler)
{
    Player* master = CommandPlayer(handler);
    if (!master) return true;
    auto itr = s_plans.find(master->GetGUID().GetCounter());
    if (itr == s_plans.end() || !itr->second.valid) { SendError(handler, "Find a valid dungeon roster first."); return true; }
    Plan& plan = itr->second;
    if (plan.config.mode != "dungeon") { SendError(handler, "Dungeon Finder handoff is only available in Dungeon mode."); return true; }
    if (plan.assembling || !PlanMembershipComplete(master, plan)) { SendError(handler, "Assemble the complete 5-player party before queueing it."); return true; }

    Group* group = master->GetGroup();
    if (!group || group->GetMembersCount() != 5) { SendError(handler, "Dungeon Finder handoff requires exactly five assembled group members."); return true; }
    if (group->isRaidGroup()) { SendError(handler, "Stock Dungeon Finder cannot queue a raid-format group. Reform the party as a normal 5-player group first."); return true; }
    if (!group->IsLeader(master->GetGUID())) { SendError(handler, "Only the party leader can queue the assembled party."); return true; }
    if (plan.config.difficulty == "alpha" || plan.config.difficulty == "beta" || plan.config.difficulty == "gamma")
    { SendError(handler, "Titan Rune queue handoff is not represented by stock 3.3.5a RDF difficulty IDs. Use the realm's Titan Rune entry flow after assembly."); return true; }

    for (Member const& member : plan.members)
        if (!ObjectAccessor::FindConnectedPlayer(member.guid)) { SendError(handler, "Every party member must be online before entering Dungeon Finder."); return true; }

    lfg::LfgDungeonSet dungeons;
    bool heroic = plan.config.difficulty == "heroic";
    if (plan.config.activity == "random")
    {
        bool wotlk = master->GetLevel() >= 71;
        dungeons.insert(wotlk ? (heroic ? lfg::RANDOM_DUNGEON_HEROIC_WOTLK : lfg::RANDOM_DUNGEON_NORMAL_WOTLK)
                              : (heroic ? lfg::RANDOM_DUNGEON_HEROIC_TBC : lfg::RANDOM_DUNGEON_NORMAL_TBC));
    }
    else
    {
        uint32 mapId = DungeonMapId(plan.config.activity);
        Difficulty difficulty = heroic ? DUNGEON_DIFFICULTY_HEROIC : DUNGEON_DIFFICULTY_NORMAL;
        LFGDungeonEntry const* entry = GetLFGDungeon(mapId, difficulty);
        if (!entry) { SendError(handler, "The selected dungeon/difficulty has no stock RDF entry on this client/server build."); return true; }
        dungeons.insert(entry->ID);
    }

    ApplyGroupSettings(master, plan);
    uint8 leaderRole = lfg::PLAYER_ROLE_DAMAGE | lfg::PLAYER_ROLE_LEADER;
    for (Member const& member : plan.members)
        if (member.guid == master->GetGUID()) { leaderRole = LfgRole(member.role, true); break; }

    sLFGMgr->JoinLfg(master, leaderRole, dungeons, "Group Composer");
    for (Member const& member : plan.members)
        sLFGMgr->UpdateRoleCheck(group->GetGUID(), member.guid, LfgRole(member.role, member.guid == master->GetGUID()));
    master->UpdateLFGChannel();
    handler->SendSysMessage("[GC]|DONE|Party handed to Dungeon Finder with the composed roles.");
    return true;
}

bool GroupComposerCommand::HandleAnchors(ChatHandler* handler)
{
    Player* master = CommandPlayer(handler);
    if (!master) return true;
    handler->SendSysMessage("[GC]|ANCHORRESET");

    std::unordered_set<uint32> sent;
    Group* group = master->GetGroup();
    if (group)
    {
        for (Group::MemberSlot const& slot : group->GetMemberSlots()) SendAnchor(handler, master, slot.guid, slot.group, sent);
    }
    SendAnchor(handler, master, master->GetGUID(), 0, sent);
    handler->SendSysMessage("[GC]|ANCHORDONE");
    return true;
}

bool GroupComposerCommand::HandleDiagnostics(ChatHandler* handler)
{
    Player* master = CommandPlayer(handler);
    if (!master) return true;
    auto itr = s_plans.find(master->GetGUID().GetCounter());
    if (itr == s_plans.end())
    {
        handler->SendSysMessage("[GC]|DIAG|No preview exists yet. Press Find Roster to collect candidate diagnostics.");
        return true;
    }
    handler->PSendSysMessage("[GC]|DIAG|{}", Sanitize(Planner::Diagnostics(itr->second)));
    return true;
}

bool GroupComposerCommand::HandleClear(ChatHandler* handler)
{
    Player* master = CommandPlayer(handler);
    if (!master) return true;
    uint32 owner = master->GetGUID().GetCounter();
    auto plan = s_plans.find(owner);
    if (plan != s_plans.end() && plan->second.assembling)
    {
        SendError(handler, "Wait for the active assembly to finish before clearing the preview.");
        return true;
    }
    s_drafts.erase(owner);
    s_plans.erase(owner);
    ClearPendingForOwner(owner);
    handler->SendSysMessage("[GC]|RESET");
    handler->SendSysMessage("[GC]|DONE|Composer preview cleared. No group members were removed.");
    return true;
}

bool GroupComposerCommand::HandleStatus(ChatHandler* handler)
{
    Player* master = CommandPlayer(handler);
    if (!master) return true;
    uint32 owner = master->GetGUID().GetCounter();
    auto plan = s_plans.find(owner);
    if (plan != s_plans.end())
    {
        SendPlan(handler, plan->second);
        handler->PSendSysMessage("[GC]|STATUS|{}", plan->second.assembling ? "Assembly in progress." : "Preview synchronized from server.");
        return true;
    }
    if (s_drafts.count(owner)) handler->SendSysMessage("[GC]|STATUS|Configuration draft exists; press Find Roster to build a preview.");
    else handler->SendSysMessage("[GC]|STATUS|Group Composer backend ready.");
    return true;
}

void AddGroupComposerScripts()
{
    new GroupComposerCommand();
    new GroupComposerWorld();
}
