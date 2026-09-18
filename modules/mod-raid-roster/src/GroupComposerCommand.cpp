#include "GroupComposerCommand.h"

#include "GroupComposerPlanner.h"
#include "GroupComposerReserve.h"
#include "GroupComposerTypes.h"
#include "RaidRosterEra.h"
#include "RaidRosterGear.h"

#include "CharacterCache.h"
#include "DBCStores.h"
#include "EraTalentBots.h"
#include "Group.h"
#include "GroupMgr.h"
#include "LFG.h"
#include "LFGMgr.h"
#include "Map.h"
#include "MapMgr.h"
#include "ObjectAccessor.h"
#include "ObjectMgr.h"
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
#include "TitanRuneSystem.h"
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
    uint8 role = ROLE_DPS;
    uint8 spec = ANY_SPEC;
    bool fullRebuild = false;
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

void SendProgress(Player* player, char const* phase, uint32 current, uint32 total, std::string const& detail)
{
    if (!player || !player->GetSession()) return;
    ChatHandler handler(player->GetSession());
    handler.PSendSysMessage("[GC]|PROGRESS|{}|{}|{}|{}", phase, current, total, Sanitize(detail));
}

char const* SourceToken(Member const& member)
{
    if (member.human) return "HUMAN";
    if (member.guild) return "GUILD";
    if (member.reserve) return "RESERVE";
    if (member.managed) return "ROSTER";
    return "WORLD";
}

void SendPlan(ChatHandler* handler, Plan const& plan)
{
    if (!handler) return;
    handler->SendSysMessage("[GC]|RESET");
    handler->PSendSysMessage("[GC]|META|{}|{}|{}|{}|{}|{}|{}|{}",
        plan.config.mode, plan.config.activity, plan.config.difficulty,
        uint32(plan.config.size), uint32(plan.config.tanks), uint32(plan.config.healers), uint32(plan.config.dps),
        uint32(plan.config.requiredLevel));

    Player* viewer = handler->GetSession() ? handler->GetSession()->GetPlayer() : nullptr;
    uint32 guild = 0, world = 0, humans = 0;
    for (Member const& member : plan.members)
    {
        if (member.human) ++humans;
        else if (member.guild) ++guild;
        else ++world;
        handler->PSendSysMessage("[GC]|MEMBER|{}|{}|{}|{}|{}|{}|{}|{}|{}|{}|{}|{}|{}",
            uint32(member.subgroup), Sanitize(member.name), RoleToken(member.role), ClassToken(member.cls),
            SpecName(member.cls, member.spec), SourceToken(member), member.human ? 1 : 0,
            member.locked ? 1 : 0, member.pinned ? 1 : 0, member.needsPreparation ? 1 : 0,
            member.reserve ? 1 : 0, viewer && member.guid == viewer->GetGUID() ? 1 : 0, uint32(member.level));
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

bool UsesWrathRaidDifficulty(std::string const& activity)
{
    // Wrath introduced the 10/25-player raid difficulty split used by Group::SetRaidDifficulty.
    // TBC/Classic raids use the legacy regular raid difficulty even when their roster size is 25/40.
    static std::unordered_set<std::string> const raids = {
        "naxxramas", "obsidian_sanctum", "eye_of_eternity", "ulduar", "trial_crusader",
        "onyxia", "vault_archavon", "icecrown", "ruby_sanctum"
    };
    return raids.count(activity) != 0;
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

uint32 RaidMapId(std::string const& activity)
{
    static std::unordered_map<std::string, uint32> const maps = {
        { "naxxramas", 533 }, { "obsidian_sanctum", 615 }, { "eye_of_eternity", 616 },
        { "ulduar", 603 }, { "trial_crusader", 649 }, { "onyxia", 249 },
        { "vault_archavon", 624 }, { "icecrown", 631 }, { "ruby_sanctum", 724 },
        { "karazhan", 532 }, { "zulaman", 568 }, { "gruul", 565 }, { "magtheridon", 544 },
        { "serpentshrine", 548 }, { "tempest_keep", 550 }, { "hyjal", 534 },
        { "black_temple", 564 }, { "sunwell", 580 }, { "zul_gurub", 309 }, { "aq20", 509 },
        { "molten_core", 409 }, { "blackwing_lair", 469 }, { "aq40", 531 },
    };
    auto itr = maps.find(activity);
    return itr == maps.end() ? 0 : itr->second;
}

uint32 ActivityMapId(Plan const& plan)
{
    if (plan.config.mode == "dungeon") return DungeonMapId(plan.config.activity);
    if (plan.config.mode == "raid") return RaidMapId(plan.config.activity);
    return 0;
}

uint8 RequiredActivityLevel(Player* master, Config const& config)
{
    if (config.mode == "raid")
    {
        if (UsesWrathRaidDifficulty(config.activity)) return 80;

        static std::unordered_set<std::string> const tbcRaids = {
            "karazhan", "zulaman", "gruul", "magtheridon", "serpentshrine",
            "tempest_keep", "hyjal", "black_temple", "sunwell"
        };
        if (tbcRaids.count(config.activity)) return 70;
        return 60;
    }

    // Random WotLK Normal begins with Utgarde Keep. Heroic and Titan Rune modes are level 80.
    if (config.activity == "random")
        return config.difficulty == "normal" ? 68 : 80;

    uint32 mapId = DungeonMapId(config.activity);
    Difficulty difficulty = config.difficulty == "normal" ? DUNGEON_DIFFICULTY_NORMAL : DUNGEON_DIFFICULTY_HEROIC;
    if (LFGDungeonEntry const* dungeon = GetLFGDungeon(mapId, difficulty))
        return std::max<uint8>(1, static_cast<uint8>(dungeon->MinLevel));

    return difficulty == DUNGEON_DIFFICULTY_HEROIC ? 80 : (master ? std::min<uint8>(master->GetLevel(), 80) : 80);
}

bool IsBotGuid(ObjectGuid guid)
{
    if (Player* player = ObjectAccessor::FindConnectedPlayer(guid)) return GET_PLAYERBOT_AI(player) != nullptr;
    uint32 account = sCharacterCache->GetCharacterAccountIdByGuid(guid);
    return (account && sPlayerbotAIConfig.IsInRandomAccountList(account)) || sRandomPlayerbotMgr.IsAddclassBot(guid.GetCounter());
}

bool BotHasOtherGameClientMaster(Player* master, Player* bot)
{
    if (!master || !bot) return false;
    PlayerbotAI* ai = GET_PLAYERBOT_AI(bot);
    return ai && ai->HasGameClientMaster() && ai->GetMaster() != master;
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

void SyncManagedBot(Player* master, Player* bot, uint8 role, uint8 spec, bool fullRebuild)
{
    if (!master || !bot) return;
    if (spec > 2) spec = Planner::InferSpec(bot);
    if (spec > 2) return;

    // Disposable world/reserve bodies may be rebuilt for deterministic roster readiness.
    // Persistent guild companions are different: Group Composer may retask their combat
    // build, but must not replace their earned gear, inventory, quests or progression.
    PlayerbotFactory factory(bot, master->GetLevel(), ITEM_QUALITY_LEGENDARY, 0);
    if (fullRebuild) factory.Randomize(false);

    // Playerbots / Era Talents use pseudo-spec 3 for Feral Cat PvE. Keep the
    // public Composer spec as Feral (1) and use role only for build selection.
    uint8 buildSpec = spec;
    if (bot->IsClass(CLASS_DRUID) && spec == 1 && role == ROLE_DPS) buildSpec = 3;

    if (!EraTalentBots::FactoryReconcile(bot, buildSpec))
        PlayerbotFactory::InitTalentsBySpecNo(bot, buildSpec, true);
    if (PlayerbotAI* ai = GET_PLAYERBOT_AI(bot)) ai->ResetStrategies(false);
    factory.InitGlyphs(false);

    if (fullRebuild)
    {
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
}

bool FullProvisionFor(Member const& member)
{
    // Persistent guild identities never receive synthetic Composer gear. Ordinary world
    // bots and explicit reserve/legacy managed bodies are disposable capacity and can be
    // fully provisioned when the requested role/spec requires preparation.
    return member.reserve || (!member.guild && (member.managed || member.needsPreparation));
}

void ApplyGroupSettings(Player* master, Plan const& plan)
{
    Group* group = master ? master->GetGroup() : nullptr;
    if (!group) return;
    if (plan.config.size > 5 && !group->isRaidGroup()) group->ConvertToRaid();

    if (plan.config.mode == "raid")
    {
        if (!UsesWrathRaidDifficulty(plan.config.activity))
        {
            // Classic/TBC raids have one regular instance difficulty. Their 20/25/40-player
            // roster size must not leak a previous Wrath 25/Heroic difficulty into the live group.
            group->SetRaidDifficulty(RAID_DIFFICULTY_10MAN_NORMAL);
        }
        else if (plan.config.size == 10)
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

char const* EnterStateReason(Map::EnterState state)
{
    switch (state)
    {
        case Map::CANNOT_ENTER_NO_ENTRY: return "the instance map is unavailable";
        case Map::CANNOT_ENTER_UNINSTANCED_DUNGEON: return "the instance template is unavailable";
        case Map::CANNOT_ENTER_DIFFICULTY_UNAVAILABLE: return "that difficulty is unavailable";
        case Map::CANNOT_ENTER_NOT_IN_RAID: return "the player is not in a valid raid group";
        case Map::CANNOT_ENTER_CORPSE_IN_DIFFERENT_INSTANCE: return "their corpse belongs to another instance";
        case Map::CANNOT_ENTER_INSTANCE_BIND_MISMATCH: return "their saved lockout conflicts with the group instance";
        case Map::CANNOT_ENTER_TOO_MANY_INSTANCES: return "they have entered too many instances recently";
        case Map::CANNOT_ENTER_MAX_PLAYERS: return "the target instance is already full";
        case Map::CANNOT_ENTER_ZONE_IN_COMBAT: return "an encounter is already in progress in the target instance";
        default: return "AzerothCore rejected instance entry";
    }
}

bool ResolveTitanTravelMode(Plan const& plan, uint32 mapId, TitanRuneMode& mode, std::string& error)
{
    mode = TitanRuneMode::Off;
    if (plan.config.mode != "dungeon") return true;

    bool requested = true;
    if (plan.config.difficulty == "alpha") mode = TitanRuneMode::Alpha;
    else if (plan.config.difficulty == "beta") mode = TitanRuneMode::Beta;
    else if (plan.config.difficulty == "gamma") mode = TitanRuneMode::Gamma;
    else requested = false;

    if (requested && !TitanRune::IsSupportedDungeon(mapId, mode))
    {
        error = std::string("Defense Protocol ") + TitanRune::ModeName(mode) +
            " is not supported by the selected dungeon on this realm.";
        return false;
    }
    return true;
}

bool TeleportCompletedPlan(Player* master, Plan const& plan, std::string& detail, std::string& error)
{
    if (!master)
    {
        error = "Group Composer lost the live group leader before travel.";
        return false;
    }

    uint32 mapId = ActivityMapId(plan);
    if (!mapId)
    {
        // Random Dungeon has no destination until Dungeon Finder chooses one. Named activities are
        // always mapped and travel automatically after Assemble.
        if (plan.config.mode == "dungeon" && plan.config.activity == "random")
        {
            detail = "Roster assembled. Random Dungeon is ready for Dungeon Finder.";
            return true;
        }
        error = "The selected activity has no configured instance map for automatic travel.";
        return false;
    }

    Group* group = master->GetGroup();
    if (!group || group->GetMembersCount() != plan.members.size())
    {
        error = "Automatic travel requires the complete reviewed roster to still be grouped.";
        return false;
    }

    // Composer may be operated by a real raid assistant, but instance ownership and Titan Rune
    // authority belong to the actual live group leader. Resolve that player explicitly instead of
    // accidentally treating the assistant who opened Composer as the leader.
    Player* travelLeader = group->GetLeader();
    if (!travelLeader || GET_PLAYERBOT_AI(travelLeader))
    {
        error = "Automatic travel requires the real group leader to be online.";
        return false;
    }
    bool leaderReviewed = false;
    for (Member const& member : plan.members)
        if (member.guid == travelLeader->GetGUID()) { leaderReviewed = true; break; }
    if (!leaderReviewed)
    {
        error = "The current group leader is not part of the reviewed roster. Build & Prepare again so every human anchor is included.";
        return false;
    }

    AreaTriggerTeleport const* destination = sObjectMgr->GetMapEntranceTrigger(mapId);
    if (!destination || destination->target_mapId != mapId)
    {
        error = "AzerothCore has no canonical entrance trigger for the selected instance.";
        return false;
    }

    TitanRuneMode titanMode = TitanRuneMode::Off;
    if (!ResolveTitanTravelMode(plan, mapId, titanMode, error)) return false;

    std::vector<Player*> travelers;
    travelers.reserve(plan.members.size());
    for (Member const& member : plan.members)
    {
        Player* player = ObjectAccessor::FindConnectedPlayer(member.guid);
        if (!player)
        {
            error = "'" + member.name + "' went offline before automatic instance travel.";
            return false;
        }
        if (player->GetGroup() != group)
        {
            error = "'" + member.name + "' left the reviewed group before automatic instance travel.";
            return false;
        }
        if (player->IsBeingTeleported())
        {
            error = "'" + member.name + "' is already being teleported; wait a moment and Assemble again.";
            return false;
        }
        if (player->IsInCombat())
        {
            error = "'" + member.name + "' is in combat. Automatic instance travel waits until the full group is out of combat.";
            return false;
        }
        if (player->InBattleground() || player->IsSpectator())
        {
            error = "'" + member.name + "' is in a battleground/spectator state and cannot enter the selected instance.";
            return false;
        }

        Map::EnterState state = sMapMgr->PlayerCannotEnter(mapId, player);
        if (state != Map::CAN_ENTER && state != Map::CANNOT_ENTER_ALREADY_IN_MAP)
        {
            error = "'" + member.name + "' cannot enter the selected instance because " + EnterStateReason(state) + ".";
            return false;
        }
        travelers.push_back(player);
    }

    // The explicit Composer selection must beat any stale personal setting. Heroic/Normal turns the
    // next-dungeon protocol off; Alpha/Beta/Gamma persists the selected protocol on the actual group
    // leader before entry so TitanRune::ActivateForPlayer reads the same authority as normal play.
    if (plan.config.mode == "dungeon")
        TitanRune::SaveSelectedMode(travelLeader, titanMode);

    auto teleport = [&](Player* player)
    {
        if (!player) return;
        if (player->IsInFlight())
        {
            player->GetMotionMaster()->MovementExpired();
            player->CleanupAfterTaxiFlight();
        }
        else
            player->SaveRecallPosition();

        player->TeleportTo(destination->target_mapId, destination->target_X, destination->target_Y,
            destination->target_Z, destination->target_Orientation);
    };

    // Start with the authoritative group leader, then move every other reviewed member. This keeps
    // raid lockouts and instance ownership on AzerothCore's normal group path instead of binding them
    // to whichever assistant happened to operate Composer.
    teleport(travelLeader);
    for (Player* player : travelers)
        if (player != travelLeader) teleport(player);

    detail = std::string("Roster assembled and entering the selected ") +
        (plan.config.mode == "raid" ? "raid." : "dungeon.");
    return true;
}

void PruneUnselectedBots(Player* master, Plan const& plan)
{
    Group* group = master ? master->GetGroup() : nullptr;
    if (!group) return;
    std::vector<ObjectGuid> remove;
    for (Group::MemberSlot const& slot : group->GetMemberSlots())
    {
        if (Selected(plan, slot.guid) || !IsBotGuid(slot.guid)) continue;
        if (Player* bot = ObjectAccessor::FindConnectedPlayer(slot.guid))
            if (BotHasOtherGameClientMaster(master, bot)) continue;
        remove.push_back(slot.guid);
    }
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

        // Humans are never silently pruned. Playerbots actively controlled by another real client
        // are protected for the same reason: they belong to that player's current play session, not
        // to this composer's disposable candidate pool.
        for (Group::MemberSlot const& slot : group->GetMemberSlots())
        {
            if (Selected(plan, slot.guid)) continue;
            if (!IsBotGuid(slot.guid))
            {
                error = "The group gained a real player after the preview. Run Find Roster again so every human is locked into the composition.";
                return false;
            }
            if (Player* bot = ObjectAccessor::FindConnectedPlayer(slot.guid))
            {
                if (BotHasOtherGameClientMaster(master, bot))
                {
                    error = "Playerbot '" + bot->GetName() + "' is controlled by another active player and cannot be silently removed. Reform the party or let that player manage their bot, then Find Roster again.";
                    return false;
                }
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
                if (live->GetLevel() < plan.config.requiredLevel)
                {
                    error = "Your character fell below the selected activity's required level.";
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
            if (live->GetLevel() < plan.config.requiredLevel)
            {
                error = "Human player '" + member.name + "' is below the selected activity's required level " +
                    std::to_string(unsigned(plan.config.requiredLevel)) + ".";
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
            if (!member.managed && !member.reserve)
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
        if (live->GetLevel() < plan.config.requiredLevel)
        {
            error = "Selected bot '" + member.name + "' is level " + std::to_string(unsigned(live->GetLevel())) +
                ", below the selected activity's required level " + std::to_string(unsigned(plan.config.requiredLevel)) + ".";
            return false;
        }
        if (BotHasOtherGameClientMaster(master, live))
        {
            error = "Selected bot '" + member.name + "' is now controlled by another active player. Run Find Roster again.";
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
        if (!member.managed && !member.needsPreparation && !member.reserve)
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

bool BotHasPendingSync(ObjectGuid guid)
{
    return s_pendingSync.count(guid.GetCounter()) != 0;
}

void ClearPendingSync(uint32 ownerLow)
{
    for (auto itr = s_pendingSync.begin(); itr != s_pendingSync.end(); )
    {
        if (itr->second.ownerGuid == ownerLow) itr = s_pendingSync.erase(itr);
        else ++itr;
    }
}

std::vector<uint32> UnreadyBotGuids(Plan const& plan)
{
    std::vector<uint32> failed;
    for (Member const& member : plan.members)
    {
        if (member.human) continue;
        Player* bot = ObjectAccessor::FindConnectedPlayer(member.guid);
        if (!bot || !GET_PLAYERBOT_AI(bot) || BotHasPendingSync(member.guid))
            failed.push_back(member.guid.GetCounter());
    }
    return failed;
}

uint32 SelectedBotCount(Plan const& plan)
{
    uint32 total = 0;
    for (Member const& member : plan.members) if (!member.human) ++total;
    return total;
}

uint32 PreparedBotCount(Plan const& plan)
{
    uint32 ready = 0;
    for (Member const& member : plan.members)
    {
        if (member.human) continue;
        Player* bot = ObjectAccessor::FindConnectedPlayer(member.guid);
        if (bot && GET_PLAYERBOT_AI(bot) && !BotHasPendingSync(member.guid)) ++ready;
    }
    return ready;
}

bool PreparePlan(Player* master, Plan& plan, std::string& error)
{
    if (!master) { error = "Composer preparation has no live owner."; return false; }
    uint32 owner = master->GetGUID().GetCounter();

    if (!Reserve::AcquirePlan(master, plan, error)) return false;

    bool needsManagedLogin = false;
    for (Member const& member : plan.members)
        if (!member.human && member.managed && !member.reserve && !ObjectAccessor::FindConnectedPlayer(member.guid)) { needsManagedLogin = true; break; }

    PlayerbotMgr* mgr = needsManagedLogin ? GET_PLAYERBOT_MGR(master) : nullptr;
    if (needsManagedLogin && !mgr) { error = "Playerbot manager is unavailable for an offline managed roster bot."; return false; }

    uint32 account = master->GetSession()->GetAccountId();
    for (Member const& member : plan.members)
    {
        if (member.human) continue;
        bool ownsPreparation = member.reserve || member.managed || member.needsPreparation;
        if (!ownsPreparation) continue;

        Player* bot = ObjectAccessor::FindConnectedPlayer(member.guid);
        if (bot)
        {
            // Preserve persistent guild identity until the user actually commits the roster. They
            // are deliberately ranked below disposable fallbacks when a spec swap would be needed.
            if (!(member.guild && member.needsPreparation))
                SyncManagedBot(master, bot, member.role, member.spec, FullProvisionFor(member));
            continue;
        }

        if (!member.reserve)
            // Keep Composer preparation quiet and non-destructive. The patched Playerbots login path
            // still gives the bot its normal master/AI, but skips the login greeting and automatic
            // group invite. Composer owns membership later, during the reviewed Assemble commit.
            mgr->AddPlayerBot(member.guid, account, true);
        s_pendingSync[member.guid.GetCounter()] = { owner, member.role, member.spec, FullProvisionFor(member), 0 };
    }

    plan.prepareElapsed = 0;
    plan.prepareProgressElapsed = 0;
    plan.preparing = OwnerHasPendingSync(owner);
    plan.prepared = !plan.preparing;
    return true;
}

bool ReplaceUnreadyCandidates(Player* master, Plan& plan, std::string& detail)
{
    if (!master) { detail = "Composer lost its owner while replacing unavailable bots."; return false; }
    if (plan.prepareAttempts >= 3)
    {
        detail = "Composer exhausted three automatic replacement attempts.";
        return false;
    }

    std::vector<uint32> failed = UnreadyBotGuids(plan);
    if (failed.empty())
    {
        detail = "No replaceable unavailable bot was identified.";
        return false;
    }

    std::string firstFailed = "bot";
    for (Member const& member : plan.members)
        if (std::find(failed.begin(), failed.end(), member.guid.GetCounter()) != failed.end()) { firstFailed = member.name; break; }

    std::unordered_set<uint32> rejected = plan.rejectedCandidates;
    for (uint32 low : failed) rejected.insert(low);
    Config config = plan.config;
    uint8 nextAttempt = static_cast<uint8>(plan.prepareAttempts + 1);
    uint32 ownerLow = master->GetGUID().GetCounter();

    ClearPendingSync(ownerLow);
    Reserve::ReleaseUnjoined(master);

    Plan replacement;
    std::string buildError;
    if (!Planner::Build(master, config, replacement, buildError, rejected))
    {
        detail = "Could not replace unavailable '" + firstFailed + "': " + buildError;
        return false;
    }
    replacement.prepareAttempts = nextAttempt;
    replacement.rejectedCandidates = std::move(rejected);

    std::string prepareError;
    if (!PreparePlan(master, replacement, prepareError))
    {
        detail = "Replacement roster could not reserve/prepare fresh capacity: " + prepareError;
        return false;
    }

    plan = std::move(replacement);
    ChatHandler handler(master->GetSession());
    SendPlan(&handler, plan);
    detail = "Replaced unavailable '" + firstFailed + "' automatically; preparing fresh capacity (attempt "
        + std::to_string(unsigned(plan.prepareAttempts)) + "/3).";
    SendProgress(master, plan.prepared ? "READY" : "PREPARING", PreparedBotCount(plan), SelectedBotCount(plan), detail);
    return true;
}

bool EnsureComposerGroup(Player* master, Plan const& plan, Group*& group, std::string& error)
{
    if (!master) { error = "Group Composer lost the live owner while assembling."; return false; }
    group = master->GetGroup();
    if (!group)
    {
        group = new Group();
        if (!group->Create(master))
        {
            delete group;
            group = nullptr;
            error = "AzerothCore could not create the live Composer group.";
            return false;
        }
        sGroupMgr->AddGroup(group);
    }
    if (plan.config.size > 5 && !group->isRaidGroup()) group->ConvertToRaid();
    ApplyGroupSettings(master, plan);
    return true;
}

uint32 JoinedPlanMembers(Player* master, Plan const& plan)
{
    if (!master) return 0;
    Group* group = master->GetGroup();
    if (!group) return 1;
    uint32 joined = 0;
    for (Member const& member : plan.members) if (group->IsMember(member.guid)) ++joined;
    return joined;
}

std::string FirstMissingMember(Player* master, Plan const& plan)
{
    Group* group = master ? master->GetGroup() : nullptr;
    for (Member const& member : plan.members)
    {
        if (member.guid == (master ? master->GetGUID() : ObjectGuid::Empty)) continue;
        if (!group || !group->IsMember(member.guid)) return member.name;
    }
    return "member";
}

void TryAttachMissing(Player* master, Plan& plan)
{
    if (!master) return;
    Group* group = master->GetGroup();
    std::string createError;

    // Playerbots are server-owned actors. Bypass the player-style invite/accept handshake and its
    // chatter entirely; only real humans receive normal invitations.
    bool hasBotToAttach = false;
    for (Member const& member : plan.members)
        if (!member.human && member.guid != master->GetGUID()) { hasBotToAttach = true; break; }
    if (hasBotToAttach && !EnsureComposerGroup(master, plan, group, createError)) return;

    for (Member const& member : plan.members)
    {
        if (member.human || member.guid == master->GetGUID()) continue;
        Player* bot = ObjectAccessor::FindConnectedPlayer(member.guid);
        if (!bot || !GET_PLAYERBOT_AI(bot) || BotHasOtherGameClientMaster(master, bot)) continue;
        group = master->GetGroup();
        if (!group) continue;
        if (group->IsMember(member.guid)) continue;
        if (bot->GetGroup() && bot->GetGroup() != group) continue;
        if (group->IsFull()) break;
        group->AddMember(bot);
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
        if (current && current->IsFull()) break;
        InviteHuman(master, player);
        plan.humanInvitesSent.insert(member.guid.GetCounter());
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
        Reserve::Update(diff);
        for (auto itr = s_pendingSync.begin(); itr != s_pendingSync.end(); )
        {
            itr->second.elapsed += diff;
            ObjectGuid botGuid = ObjectGuid::Create<HighGuid::Player>(itr->first);
            ObjectGuid ownerGuid = ObjectGuid::Create<HighGuid::Player>(itr->second.ownerGuid);
            Player* bot = ObjectAccessor::FindConnectedPlayer(botGuid);
            Player* master = ObjectAccessor::FindConnectedPlayer(ownerGuid);
            if (bot && master)
            {
                SyncManagedBot(master, bot, itr->second.role, itr->second.spec, itr->second.fullRebuild);
                itr = s_pendingSync.erase(itr);
            }
            else if (itr->second.elapsed > 60000) itr = s_pendingSync.erase(itr);
            else ++itr;
        }

        for (auto& entry : s_plans)
        {
            uint32 ownerLow = entry.first;
            Plan& plan = entry.second;
            Player* master = ObjectAccessor::FindConnectedPlayer(ObjectGuid::Create<HighGuid::Player>(ownerLow));

            if (plan.preparing)
            {
                plan.prepareElapsed += diff;
                plan.prepareProgressElapsed += diff;
                uint32 totalBots = SelectedBotCount(plan);
                uint32 readyBots = PreparedBotCount(plan);

                if (master && plan.prepareProgressElapsed >= 500)
                {
                    plan.prepareProgressElapsed = 0;
                    SendProgress(master, "PREPARING", readyBots, totalBots,
                        readyBots == totalBots ? "Finalizing prepared roster..." : "Logging in and preparing selected bots...");
                }

                if (!OwnerHasPendingSync(ownerLow) && readyBots == totalBots)
                {
                    plan.preparing = false;
                    plan.prepared = true;
                    if (master) SendProgress(master, "READY", readyBots, totalBots, "All selected bots are online and ready to assemble.");
                }
                else if (plan.prepareElapsed > 12000 && master)
                {
                    std::string replacementDetail;
                    if (!ReplaceUnreadyCandidates(master, plan, replacementDetail))
                    {
                        plan.preparing = false;
                        plan.prepared = false;
                        Reserve::ReleaseUnjoined(master);
                        ClearPendingSync(ownerLow);
                        SendProgress(master, "ERROR", readyBots, totalBots, replacementDetail);
                        SendProtocol(master, "ERROR", replacementDetail);
                    }
                    // Successful replacement resets the new plan's preparation timers internally.
                    continue;
                }
            }

            if (plan.travelPending)
            {
                if (!master)
                {
                    plan.travelElapsed += diff;
                    if (plan.travelElapsed > 10000) plan.travelPending = false;
                    continue;
                }

                plan.travelElapsed += diff;
                if (plan.travelElapsed < 450) continue;
                plan.travelElapsed = 0;
                ++plan.travelAttempts;

                std::string travelDetail, travelError;
                if (TeleportCompletedPlan(master, plan, travelDetail, travelError))
                {
                    plan.travelPending = false;
                    SendProgress(master, "DONE", uint32(plan.members.size()), uint32(plan.members.size()), travelDetail);
                    SendProtocol(master, "DONE", travelDetail);
                }
                else if (plan.travelAttempts >= 8)
                {
                    plan.travelPending = false;
                    SendProtocol(master, "STATUS", travelError);
                    SendProgress(master, "READY", uint32(plan.members.size()), uint32(plan.members.size()),
                        "Group is assembled. Automatic entry could not complete; clear the blocker and press Enter Activity to retry.");
                }
                else
                {
                    SendProgress(master, "TRAVEL", uint32(plan.members.size()), uint32(plan.members.size()),
                        "Roster complete. Waiting for instance entry to become available...");
                }
                continue;
            }

            if (!plan.assembling) continue;
            plan.assembleElapsed += diff;
            plan.assembleProgressElapsed += diff;

            if (!master)
            {
                if (plan.assembleElapsed > 45000) plan.assembling = false;
                continue;
            }

            TryAttachMissing(master, plan);
            if (plan.assembleProgressElapsed >= 350)
            {
                plan.assembleProgressElapsed = 0;
                uint32 joined = JoinedPlanMembers(master, plan);
                SendProgress(master, "ASSEMBLING", joined, uint32(plan.members.size()),
                    joined == plan.members.size() ? "Finalizing subgroup layout..." : "Adding " + FirstMissingMember(master, plan) + "...");
            }
            if (PlanMembershipComplete(master, plan) && !OwnerHasPendingSync(ownerLow))
            {
                // The roster can drift while invitations and managed logins are completing. Re-run
                // the same authoritative snapshot checks immediately before reporting success so a
                // disconnect, role/spec change or late human join cannot slip through the assembly window.
                std::string completionValidationError;
                if (!ValidateAssemblySnapshot(master, plan, completionValidationError))
                {
                    plan.assembling = false;
                    Reserve::ReleaseUnjoined(master);
                    SendProtocol(master, "ERROR", completionValidationError);
                    continue;
                }

                std::string arrangementError;
                plan.assembling = false;
                if (ApplyArrangement(master, plan, arrangementError))
                {
                    if (ActivityMapId(plan))
                    {
                        // Group creation/conversion and difficulty changes finish on this same world
                        // update. Give AzerothCore a few ticks to settle the live group before entry,
                        // then retry transient PlayerCannotEnter/instance-state races automatically.
                        plan.travelPending = true;
                        plan.travelElapsed = 0;
                        plan.travelAttempts = 0;
                        SendProgress(master, "TRAVEL", uint32(plan.members.size()), uint32(plan.members.size()),
                            "Roster complete. Entering the selected instance...");
                    }
                    else
                    {
                        // Random Dungeon has no fixed map. Finish assembly cleanly; the client
                        // immediately hands the full party to Dungeon Finder when auto-queue is on.
                        std::string travelDetail, travelError;
                        if (TeleportCompletedPlan(master, plan, travelDetail, travelError))
                        {
                            SendProgress(master, "DONE", uint32(plan.members.size()), uint32(plan.members.size()), travelDetail);
                            SendProtocol(master, "DONE", travelDetail);
                        }
                        else
                        {
                            SendProtocol(master, "STATUS", travelError);
                            SendProgress(master, "READY", uint32(plan.members.size()), uint32(plan.members.size()),
                                "Group is assembled. Select a named activity or use Dungeon Finder.");
                        }
                    }
                }
                else
                    SendProtocol(master, "ERROR", arrangementError);
            }
            else if (plan.assembleElapsed > 45000)
            {
                plan.assembling = false;
                Reserve::ReleaseUnjoined(master);
                uint32 joined = JoinedPlanMembers(master, plan);
                SendProgress(master, "ERROR", joined, uint32(plan.members.size()), "Assembly could not complete; the unavailable slot was " + FirstMissingMember(master, plan) + ".");
                SendProtocol(master, "ERROR", "Assembly could not complete because '" + FirstMissingMember(master, plan) + "' never became joinable. Joined members were kept; Build & Prepare will choose fresh capacity.");
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
    config.requiredLevel = RequiredActivityLevel(master, config);

    if (master->GetLevel() < config.requiredLevel)
    {
        SendError(handler, "The selected activity requires level " + std::to_string(unsigned(config.requiredLevel)) +
            ", but your character is only level " + std::to_string(unsigned(master->GetLevel())) + ".");
        return true;
    }

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
    if (cls && spec == ANY_SPEC && !Planner::CanClassFillRole(cls, role))
    { SendError(handler, "That class cannot fill the selected role."); return true; }
    if (cls && spec != ANY_SPEC && !SpecCanFillRole(cls, spec, role))
    { SendError(handler, "That class/spec cannot fill the selected role."); return true; }

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
    Plan& stored = s_plans[owner];
    std::string prepareError;
    if (!PreparePlan(master, stored, prepareError))
    {
        Reserve::ReleaseUnjoined(master);
        handler->SendSysMessage("[GC]|RESET");
        SendError(handler, prepareError);
        s_plans.erase(owner);
        return true;
    }

    SendPlan(handler, stored);
    uint32 totalBots = SelectedBotCount(stored);
    uint32 readyBots = PreparedBotCount(stored);
    SendProgress(master, stored.prepared ? "READY" : "PREPARING", readyBots, totalBots,
        stored.prepared ? "All selected bots are online and ready to assemble." : "Logging in and preparing selected bots...");
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
    if (plan.travelPending) { handler->SendSysMessage("[GC]|STATUS|Instance entry is already in progress."); return true; }
    if (plan.assembling) { handler->SendSysMessage("[GC]|STATUS|Assembly is already in progress."); return true; }

    if (!plan.prepared || plan.preparing || OwnerHasPendingSync(owner))
    {
        handler->SendSysMessage("[GC]|STATUS|Roster preparation is still running. Assemble unlocks automatically when every selected bot is ready.");
        SendProgress(master, "PREPARING", PreparedBotCount(plan), SelectedBotCount(plan), "Waiting for selected bots to finish preparation...");
        return true;
    }

    std::string validationError;
    if (!ValidateAssemblySnapshot(master, plan, validationError))
    {
        SendError(handler, validationError);
        return true;
    }

    std::string reserveError;
    if (!Reserve::AcquirePlan(master, plan, reserveError))
    {
        SendError(handler, reserveError);
        return true;
    }

    plan.humanInvitesSent.clear();

    // First destructive step: remove only unselected Playerbots. Real humans are protected by
    // ValidateAssemblySnapshot. All disposable bot preparation happened during Build & Prepare.
    PruneUnselectedBots(master, plan);

    // A specifically pinned persistent guild companion can still require a deliberate spec retask.
    // Apply that narrow combat-build change at commit time, preserving its gear/inventory/history.
    for (Member const& member : plan.members)
    {
        if (member.human || !member.guild || !member.needsPreparation) continue;
        if (Player* bot = ObjectAccessor::FindConnectedPlayer(member.guid))
            SyncManagedBot(master, bot, member.role, member.spec, false);
    }

    plan.travelPending = false;
    plan.travelElapsed = 0;
    plan.travelAttempts = 0;
    plan.assembling = true;
    plan.assembleElapsed = 0;
    plan.assembleProgressElapsed = 0;
    TryAttachMissing(master, plan);
    SendProgress(master, "ASSEMBLING", JoinedPlanMembers(master, plan), uint32(plan.members.size()), "Committing prepared roster to the live group...");
    handler->SendSysMessage("[GC]|STATUS|Assembly started. Prepared Playerbots are attached server-side; real players accept normally.");
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
    Reserve::ReleaseUnjoined(master);
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
        if (plan->second.travelPending)
            SendProgress(master, "TRAVEL", uint32(plan->second.members.size()), uint32(plan->second.members.size()), "Entering the selected instance...");
        else if (plan->second.assembling)
            SendProgress(master, "ASSEMBLING", JoinedPlanMembers(master, plan->second), uint32(plan->second.members.size()), "Assembly in progress...");
        else
            SendProgress(master, plan->second.prepared ? "READY" : plan->second.preparing ? "PREPARING" : "IDLE",
                PreparedBotCount(plan->second), SelectedBotCount(plan->second),
                plan->second.prepared ? "Prepared roster synchronized from server." : "Roster preparation status synchronized.");
        handler->PSendSysMessage("[GC]|STATUS|{}", plan->second.travelPending ? "Instance entry in progress." :
            plan->second.assembling ? "Assembly in progress." : "Preview synchronized from server.");
        return true;
    }
    handler->PSendSysMessage("[GC]|DIAG|{}", Sanitize(Reserve::Status(owner)));
    if (s_drafts.count(owner)) handler->SendSysMessage("[GC]|STATUS|Configuration draft exists; press Find Roster to build a preview.");
    else handler->SendSysMessage("[GC]|STATUS|Group Composer backend ready.");
    return true;
}

void AddGroupComposerScripts()
{
    new GroupComposerCommand();
    new GroupComposerWorld();
}
