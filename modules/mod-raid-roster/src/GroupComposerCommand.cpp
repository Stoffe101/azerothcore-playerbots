#include "GroupComposerCommand.h"

#include "AdventureCatalog.h"
#include "AdventureStartControl.h"
#include "GroupComposerPlanner.h"
#include "GroupComposerReserve.h"
#include "GroupComposerTypes.h"
#include "RaidRosterEra.h"
#include "RaidRosterGear.h"

#include "CharacterCache.h"
#include "DatabaseEnv.h"
#include "DBCStores.h"
#include "EraTalentBots.h"
#include "EraTransition.h"
#include "Group.h"
#include "GroupMgr.h"
#include "InstanceSaveMgr.h"
#include "LFG.h"
#include "LFGMgr.h"
#include "Map.h"
#include "MapMgr.h"
#include "ObjectAccessor.h"
#include "ObjectMgr.h"
#include "Player.h"
#include "QuestDef.h"
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
    uint8 targetLevel = 1;
    uint16 minimumItemLevel = 0;
    uint16 targetItemLevel = 0;
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

std::string MemberUtilitySummary(uint32 mask)
{
    std::vector<std::string> labels;
    if (mask & UTILITY_INTERRUPT) labels.emplace_back("interrupt");
    if (mask & UTILITY_DISPEL) labels.emplace_back("dispel/cleanse");
    if (mask & UTILITY_RAID_BUFF) labels.emplace_back("group buffs");
    if (mask & UTILITY_HEROISM) labels.emplace_back("Heroism/Bloodlust");
    if (mask & UTILITY_BATTLE_REZ) labels.emplace_back("battle resurrection");
    if (mask & UTILITY_CC) labels.emplace_back("crowd control");
    if (mask & UTILITY_THREAT) labels.emplace_back("threat support");
    if (labels.empty()) return "";

    std::string out;
    for (std::size_t i = 0; i < labels.size(); ++i)
    {
        if (i) out += ", ";
        out += labels[i];
    }
    return out;
}

std::string MemberSelectionReason(Member const& member, Config const& config)
{
    if (member.human)
        return "Real-player anchor. Composer preserves this player and fills the remaining " +
            std::string(RoleToken(member.role)) + " slots around them.";

    std::vector<std::string> reasons;
    reasons.emplace_back("Fills a " + std::string(RoleToken(member.role)) + " slot as " +
        std::string(SpecName(member.cls, member.spec)) + " " + ClassToken(member.cls));

    if (member.locked) reasons.emplace_back("already in your live group, so Composer kept it as a sticky anchor");
    if (member.pinned) reasons.emplace_back("explicitly pinned by you");
    if (member.guild)
        reasons.emplace_back(config.preferGuild ? "guild member matched your Prefer Guild Bots setting" : "eligible guild member");
    else if (member.reserve)
        reasons.emplace_back("safe Composer reserve capacity");
    else if (member.managed)
        reasons.emplace_back("managed Composer capacity that can be prepared safely");
    else
        reasons.emplace_back("available world bot");

    if (member.online) reasons.emplace_back("already online");
    if (member.needsPreparation) reasons.emplace_back("Composer can reconcile its role/spec/build before assembly");

    std::string utility = MemberUtilitySummary(member.utilityMask);
    if (!utility.empty()) reasons.emplace_back("utility: " + utility);

    if (Player* live = ObjectAccessor::FindConnectedPlayer(member.guid))
        reasons.emplace_back("current ilvl " + std::to_string(uint32(live->GetAverageItemLevel() + 0.5f)));

    reasons.emplace_back("level " + std::to_string(unsigned(member.level)) +
        " is inside the activity peer band");

    std::string out;
    for (std::size_t i = 0; i < reasons.size(); ++i)
    {
        if (i) out += " • ";
        out += reasons[i];
    }
    return out;
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
        handler->PSendSysMessage("[GC]|MEMBER|{}|{}|{}|{}|{}|{}|{}|{}|{}|{}|{}|{}|{}|{}",
            uint32(member.subgroup), Sanitize(member.name), RoleToken(member.role), ClassToken(member.cls),
            SpecName(member.cls, member.spec), SourceToken(member), member.human ? 1 : 0,
            member.locked ? 1 : 0, member.pinned ? 1 : 0, member.needsPreparation ? 1 : 0,
            member.reserve ? 1 : 0, viewer && member.guid == viewer->GetGUID() ? 1 : 0, uint32(member.level),
            Sanitize(MemberSelectionReason(member, plan.config)));
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
    AdventureActivity const* entry = AdventureCatalog::FindComposer(activity);
    return entry && entry->kind == AdventureActivityKind::Dungeon ? entry->instanceMap : 0;
}

uint32 RaidMapId(std::string const& activity)
{
    AdventureActivity const* entry = AdventureCatalog::FindComposer(activity);
    return entry && entry->kind == AdventureActivityKind::Raid ? entry->instanceMap : 0;
}

uint32 ActivityMapId(Plan const& plan)
{
    if (plan.config.mode == "dungeon") return DungeonMapId(plan.config.activity);
    if (plan.config.mode == "raid") return RaidMapId(plan.config.activity);
    return 0;
}

bool FrozenHallsAccessRequirement(Config const& config, Player* player, uint32& questId, char const*& questName)
{
    questId = 0;
    questName = "";
    if (!player || config.mode != "dungeon")
        return false;

    bool const alliance = player->GetTeamId() == TEAM_ALLIANCE;
    if (config.activity == "pit_saron")
    {
        questId = alliance ? 24499u : 24511u;
        questName = "Echoes of Tortured Souls";
        return true;
    }
    if (config.activity == "halls_reflection")
    {
        questId = alliance ? 24710u : 24712u;
        questName = "Deliverance from the Pit";
        return true;
    }
    return false;
}

void EnsureComposerInstanceAccess(Player* master, Player* bot, Config const& config)
{
    if (!master || !bot)
        return;

    // Composer bots follow their real player's progression so a reviewed roster never reaches the
    // door with stage-13 reserve bots while the owner is legitimately on Ulduar/ToC/ICC content.
    RaidRosterEra::SyncBotToMaster(master, bot);

    uint32 questId = 0;
    char const* questName = "";
    if (!FrozenHallsAccessRequirement(config, bot, questId, questName))
        return;

    // Frozen Halls adds ordinary AzerothCore quest requirements on top of Individual Progression.
    // Repair those access flags only for Composer-owned Playerbots; human progression is never forged.
    if (AdventureStartControl::EnsureRaidReadyAccess(bot, AdventureStartProfile::WotlkRaidReady))
        bot->SaveToDB(false, false);
}

std::string SpecificInstanceAccessHint(Player* player, Config const& config)
{
    uint32 questId = 0;
    char const* questName = "";
    if (!FrozenHallsAccessRequirement(config, player, questId, questName) || player->IsQuestRewarded(questId))
        return "";

    return std::string("the required quest \"") + questName + "\" is not complete. "
        "Complete the Frozen Halls chain normally, or use Admin Panel -> Make THIS char WotLK Raid Ready.";
}

uint8 RequiredActivityLevel(Player* master, Config const& config)
{
    AdventureActivity const* activity = AdventureCatalog::FindComposer(config.activity);
    if (activity)
    {
        if (config.mode == "dungeon" && config.difficulty != "normal")
        {
            uint8 const heroicFloor = activity->era == AdventureEra::Wotlk ? 80 : 70;
            return std::max<uint8>(activity->minLevel, heroicFloor);
        }
        return activity->minLevel;
    }

    // Random Dungeon follows the live era. Classic random is normal-only; TBC/WotLK Heroic
    // randoms unlock at their era cap. Titan Rune is WotLK-only and therefore level 80.
    if (config.mode == "dungeon" && config.activity == "random")
    {
        AdventureEra const era = AdventureCatalog::CurrentRealmEra();
        if (config.difficulty != "normal")
            return AdventureCatalog::EraLevelCap(era);
        return era == AdventureEra::Vanilla ? 15 : (era == AdventureEra::Tbc ? 60 : 68);
    }

    return master ? master->GetLevel() : 1;
}

void ApplyBotLevelPolicy(Player* master, Config& config)
{
    if (!master)
    {
        config.botTargetLevel = config.requiredLevel;
        config.maxBotLevel = config.requiredLevel;
        return;
    }

    AdventureEra activityEra = AdventureCatalog::CurrentRealmEra();
    if (AdventureActivity const* activity = AdventureCatalog::FindComposer(config.activity))
        activityEra = activity->era;

    uint8 const eraCap = AdventureCatalog::EraLevelCap(activityEra);
    uint8 const ownerLevelInEra = std::min<uint8>(master->GetLevel(), eraCap);
    config.botTargetLevel = std::max<uint8>(config.requiredLevel, ownerLevelInEra);

    uint16 const peerCeiling = std::min<uint16>(eraCap, uint16(ownerLevelInEra) + 2);
    config.maxBotLevel = std::max<uint8>(config.requiredLevel, static_cast<uint8>(peerCeiling));
}

uint8 RequiredProgressionFor(Config const& config)
{
    AdventureActivity const* activity = AdventureCatalog::FindComposer(config.activity);
    if (!activity)
        return AdventureStartControl::ProgressionStart;

    if (config.activity == "zulaman")
        return AdventureStartControl::RequiredZulAmanProgression();
    if (config.activity == "zul_gurub")
        return AdventureStartControl::RequiredZulGurubProgression();
    return activity->minProgression;
}

std::string ProgressionUnlockHint(uint8 required)
{
    return AdventureCatalog::ProgressionRequirementText(required);
}

Difficulty ActivityDifficulty(Config const& config)
{
    if (config.mode == "dungeon")
        return config.difficulty == "normal" ? DUNGEON_DIFFICULTY_NORMAL : DUNGEON_DIFFICULTY_HEROIC;

    if (!UsesWrathRaidDifficulty(config.activity))
        return RAID_DIFFICULTY_10MAN_NORMAL;

    bool const heroic = config.difficulty == "heroic";
    if (config.size >= 25)
        return heroic ? RAID_DIFFICULTY_25MAN_HEROIC : RAID_DIFFICULTY_25MAN_NORMAL;
    return heroic ? RAID_DIFFICULTY_10MAN_HEROIC : RAID_DIFFICULTY_10MAN_NORMAL;
}

bool RequirementApplies(Player* player, ProgressionRequirement const* requirement)
{
    return player && requirement &&
        (requirement->faction == TEAM_NEUTRAL || requirement->faction == player->GetTeamId(true));
}

std::string QuestTitle(uint32 questId)
{
    if (Quest const* quest = sObjectMgr->GetQuestTemplate(questId))
        return quest->GetTitle();
    return "Quest " + std::to_string(questId);
}

std::string QuestChainReason(Player* player, uint32 questId)
{
    std::vector<uint32> chain;
    std::unordered_set<uint32> seen;
    uint32 cursor = questId;
    for (uint8 depth = 0; cursor && depth < 24 && seen.insert(cursor).second; ++depth)
    {
        chain.push_back(cursor);
        Quest const* quest = sObjectMgr->GetQuestTemplate(cursor);
        if (!quest)
            break;
        int32 const previous = quest->GetPrevQuestId();
        cursor = previous < 0 ? uint32(-previous) : uint32(previous);
    }
    std::reverse(chain.begin(), chain.end());

    uint32 nextMissing = questId;
    for (uint32 id : chain)
    {
        if (!player->IsQuestRewarded(id))
        {
            nextMissing = id;
            break;
        }
    }

    std::string text = "Requires quest chain ending in \"" + QuestTitle(questId) + "\".";
    if (nextMissing)
        text += " Next missing quest: \"" + QuestTitle(nextMissing) + "\" (quest " + std::to_string(nextMissing) + ").";
    return text;
}

std::string DetailedCoreAccessRequirement(Player* player, uint32 mapId, Difficulty difficulty)
{
    if (!player || !mapId)
        return "";

    DungeonProgressionRequirements const* requirements = sObjectMgr->GetAccessRequirement(mapId, difficulty);
    if (!requirements)
        return "";

    if (requirements->levelMin && player->GetLevel() < requirements->levelMin)
        return "Requires level " + std::to_string(unsigned(requirements->levelMin)) + ".";

    for (ProgressionRequirement const* requirement : requirements->quests)
        if (RequirementApplies(player, requirement) && !player->GetQuestRewardStatus(requirement->id))
        {
            std::string reason = QuestChainReason(player, requirement->id);
            if (!requirement->note.empty())
                reason += " " + requirement->note;
            return reason;
        }

    for (ProgressionRequirement const* requirement : requirements->items)
        if (RequirementApplies(player, requirement) && !player->HasItemCount(requirement->id, 1))
        {
            std::string name = "item " + std::to_string(requirement->id);
            if (ItemTemplate const* item = sObjectMgr->GetItemTemplate(requirement->id))
                name = item->Name1;
            std::string reason = "Requires item \"" + name + "\".";
            if (!requirement->note.empty())
                reason += " " + requirement->note;
            return reason;
        }

    for (ProgressionRequirement const* requirement : requirements->achievements)
        if (RequirementApplies(player, requirement) && !player->HasAchieved(requirement->id))
        {
            std::string name = "achievement " + std::to_string(requirement->id);
            if (AchievementEntry const* achievement = sAchievementStore.LookupEntry(requirement->id))
                if (achievement->name[0] && *achievement->name[0])
                    name = achievement->name[0];
            std::string reason = "Requires achievement \"" + name + "\".";
            if (!requirement->note.empty())
                reason += " " + requirement->note;
            return reason;
        }

    if (requirements->reqItemLevel && player->GetAverageItemLevelForDF() < requirements->reqItemLevel)
        return "Requires average item level " + std::to_string(unsigned(requirements->reqItemLevel)) +
            "; yours is " + std::to_string(unsigned(player->GetAverageItemLevelForDF())) + ".";

    return "";
}

std::string KnownAccessRequirement(Player* player, Config const& config)
{
    if (!player)
        return "Character is not available.";

    if (config.mode == "dungeon")
    {
        if (player->IsClass(CLASS_DEATH_KNIGHT) &&
            !player->IsQuestRewarded(13188u) && !player->IsQuestRewarded(13189u))
            return "Complete the Death Knight starting campaign before using Dungeon Finder.";

        uint32 questId = 0;
        char const* questName = "";
        if (FrozenHallsAccessRequirement(config, player, questId, questName) && !player->IsQuestRewarded(questId))
            return std::string("Complete quest \"") + questName + "\" first.";
        return "";
    }

    // These IDs are the exact access gates used by mod-individual-progression. Keep the constants
    // local so its legacy header never collides with PlayerbotAI.h in this translation unit.
    static constexpr uint32 TempestKey = 31704u;
    static constexpr uint32 TrialMagtheridon = 10888u;
    static constexpr uint32 CudgelOfKardesh = 10901u;
    static constexpr uint32 VialsOfEternity = 10445u;
    static constexpr uint32 MedallionOfKarabor = 32649u;
    static constexpr uint32 BlessedMedallionOfKarabor = 32757u;

    if (config.activity == "tempest_keep")
    {
        if (!player->HasItemCount(TempestKey))
            return "Obtain the Tempest Key first.";
        if (!player->IsQuestRewarded(TrialMagtheridon))
            return "Complete Trial of the Naaru: Magtheridon first.";
    }
    else if (config.activity == "serpentshrine" && !player->IsQuestRewarded(CudgelOfKardesh))
        return "Complete The Cudgel of Kar'desh first.";
    else if (config.activity == "hyjal" && !player->IsQuestRewarded(VialsOfEternity))
        return "Complete The Vials of Eternity first.";
    else if (config.activity == "black_temple" &&
        !player->HasItemCount(MedallionOfKarabor) &&
        !player->HasItemCount(BlessedMedallionOfKarabor))
        return "Obtain the Medallion of Karabor first.";

    if (config.difficulty == "heroic" && config.activity == "trial_crusader")
    {
        uint32 const achievement = config.size >= 25 ? 3916u : 3917u;
        if (!player->HasAchieved(achievement))
            return "Complete the prerequisite Trial of the Crusader achievement before Heroic.";
    }
    if (config.difficulty == "heroic" && config.activity == "icecrown")
    {
        uint32 const achievement = config.size >= 25 ? 4597u : 4530u;
        if (!player->HasAchieved(achievement))
            return "Complete the prerequisite Icecrown Citadel achievement before Heroic.";
    }
    return "";
}

bool ActivityEligible(Player* player, Config const& config, std::string& reason)
{
    reason.clear();
    if (!player || !player->IsInWorld())
    {
        reason = "Character must be online.";
        return false;
    }

    AdventureActivity const* activity = AdventureCatalog::FindComposer(config.activity);
    AdventureEra const realmEra = AdventureCatalog::CurrentRealmEra();

    if (activity)
    {
        if ((config.mode == "dungeon" && activity->kind != AdventureActivityKind::Dungeon) ||
            (config.mode == "raid" && activity->kind != AdventureActivityKind::Raid))
        {
            reason = "That activity does not match the selected group type.";
            return false;
        }

        if (!AdventureCatalog::IsEraReleased(activity->era))
        {
            reason = std::string(AdventureCatalog::EraName(activity->era)) +
                " content is locked until that expansion is released.";
            return false;
        }

        std::string catalogReason;
        if (!AdventureCatalog::IsUnlocked(player, *activity, catalogReason))
        {
            reason = catalogReason;
            return false;
        }
    }

    if (config.mode == "dungeon")
    {
        bool const titan = config.difficulty == "alpha" || config.difficulty == "beta" || config.difficulty == "gamma";
        if (realmEra == AdventureEra::Vanilla && config.difficulty != "normal")
        {
            reason = "Vanilla dungeons only use Normal difficulty on this realm.";
            return false;
        }
        if (realmEra == AdventureEra::Tbc && titan)
        {
            reason = "Titan Rune Alpha/Beta/Gamma unlock only in Wrath of the Lich King.";
            return false;
        }
        if (realmEra == AdventureEra::Vanilla && config.activity == "random" && config.difficulty != "normal")
        {
            reason = "Vanilla Random Dungeon is Normal-only.";
            return false;
        }
    }

    uint8 const level = RequiredActivityLevel(player, config);
    if (player->GetLevel() < level)
    {
        reason = "Requires level " + std::to_string(unsigned(level)) + ".";
        return false;
    }

    uint8 const requiredProgression = RequiredProgressionFor(config);
    if (requiredProgression != AdventureStartControl::ProgressionStart &&
        !AdventureStartControl::HasPassedProgression(player, requiredProgression))
    {
        uint8 const current = AdventureStartControl::CurrentProgression(player);
        reason = ProgressionUnlockHint(requiredProgression) + " Your progression is " +
            std::to_string(unsigned(current)) + "; required stage is " +
            std::to_string(unsigned(requiredProgression)) + ".";
        return false;
    }

    std::string const known = KnownAccessRequirement(player, config);
    if (!known.empty())
    {
        reason = known;
        return false;
    }

    if (config.mode == "dungeon" && config.activity == "random")
        return true;

    uint32 const mapId = config.mode == "dungeon" ? DungeonMapId(config.activity) : RaidMapId(config.activity);
    if (!mapId)
    {
        reason = "No instance map is configured for this activity.";
        return false;
    }

    Difficulty const difficulty = ActivityDifficulty(config);
    if (!player->Satisfy(sObjectMgr->GetAccessRequirement(mapId, difficulty), mapId, false))
    {
        reason = DetailedCoreAccessRequirement(player, mapId, difficulty);
        if (reason.empty())
            reason = "The server's instance access requirements are not met.";
        return false;
    }
    return true;
}

uint8 BrowserRaidSize(std::string const& activity, uint32 requested)
{
    if (activity == "karazhan" || activity == "zulaman") return 10;
    if (activity == "zul_gurub" || activity == "aq20") return 20;
    if (activity == "molten_core" || activity == "blackwing_lair" || activity == "aq40") return 40;
    if (UsesWrathRaidDifficulty(activity)) return requested == 25 ? 25 : 10;
    return 25;
}

void SendActivityEligibility(ChatHandler* handler, Player* master, std::string const& mode,
    std::string difficulty, uint32 requestedSize)
{
    if (!handler || !master) return;

    std::string const normalizedMode = Lower(mode) == "raid" ? "raid" : "dungeon";
    difficulty = Lower(difficulty);
    if (normalizedMode == "raid" && difficulty != "heroic") difficulty = "normal";
    if (normalizedMode == "dungeon" && difficulty != "heroic" && difficulty != "alpha" &&
        difficulty != "beta" && difficulty != "gamma") difficulty = "normal";

    char const* modeToken = normalizedMode == "raid" ? "RAID" : "DUNGEON";
    handler->PSendSysMessage("[GC]|ACTIVITYRESET|{}", modeToken);
    handler->PSendSysMessage("[GC]|REALM|{}|{}|{}",
        AdventureCatalog::EraName(AdventureCatalog::CurrentRealmEra()),
        uint32(AdventureCatalog::EraLevelCap(AdventureCatalog::CurrentRealmEra())),
        uint32(AdventureStartControl::CurrentProgression(master)));

    auto sendConfig = [&](std::string const& id, AdventureActivity const* activity)
    {
        Config config;
        config.mode = normalizedMode;
        config.activity = id;
        config.difficulty = difficulty;
        config.size = normalizedMode == "raid" ? BrowserRaidSize(id, requestedSize) : 5;
        if (normalizedMode == "raid" && config.difficulty == "heroic" &&
            !RaidSupports(id, config.size, true))
            config.difficulty = "normal";

        std::string reason;
        bool const eligible = ActivityEligible(master, config, reason);

        char const* label = activity ? activity->name : "Random Dungeon";
        char const* era = activity ? AdventureCatalog::EraName(activity->era) :
            AdventureCatalog::EraName(AdventureCatalog::CurrentRealmEra());
        uint32 const minLevel = activity ? activity->minLevel : RequiredActivityLevel(master, config);
        uint32 const minProgression = activity ? RequiredProgressionFor(config) : 0;
        uint32 const preferredSize = activity ? activity->preferredSize : 5;
        char const* support = activity ? AdventureCatalog::SupportLabel(activity->support) : "Guild Ready";
        uint32 const mapId = activity ? activity->instanceMap : 0;

        handler->PSendSysMessage("[GC]|ACTIVITY|{}|{}|{}|{}|{}|{}|{}|{}|{}|{}|{}|{}",
            modeToken, id, eligible ? 1 : 0, Sanitize(eligible ? "Available" : reason),
            Sanitize(label), era, minLevel, minProgression, preferredSize, Sanitize(support), mapId);
    };

    if (normalizedMode == "dungeon")
        sendConfig("random", nullptr);

    for (AdventureActivity const& activity : AdventureCatalog::All())
    {
        bool const matches = normalizedMode == "raid"
            ? activity.kind == AdventureActivityKind::Raid
            : activity.kind == AdventureActivityKind::Dungeon;
        if (matches)
            sendConfig(activity.composerId, &activity);
    }

    handler->PSendSysMessage("[GC]|ACTIVITYDONE|{}|{}",
        modeToken, uint32(AdventureStartControl::CurrentProgression(master)));
}

struct ActivityClearStats
{
    uint32 personalCount = 0;
    uint32 guildCount = 0;
    std::string personalFirst;
    std::string guildFirst;
};

ActivityClearStats ClearStats(Player* player, AdventureActivity const& activity)
{
    ActivityClearStats stats;
    if (!player || !activity.finalBossEntry)
        return stats;

    uint32 const playerGuid = player->GetGUID().GetCounter();
    if (QueryResult result = CharacterDatabase.Query(
        "SELECT COUNT(*), COALESCE(DATE_FORMAT(MIN(killed_at), '%Y-%m-%d'), '') "
        "FROM mod_adventure_progression_event "
        "WHERE player_guid = {} AND map_id = {} AND creature_entry = {}",
        playerGuid, activity.instanceMap, activity.finalBossEntry))
    {
        Field* fields = result->Fetch();
        stats.personalCount = fields[0].Get<uint32>();
        stats.personalFirst = fields[1].Get<std::string>();
    }

    if (uint32 guildId = player->GetGuildId())
    {
        if (QueryResult result = CharacterDatabase.Query(
            "SELECT COUNT(DISTINCT instance_id), COALESCE(DATE_FORMAT(MIN(killed_at), '%Y-%m-%d'), '') "
            "FROM mod_adventure_progression_event "
            "WHERE guild_id = {} AND map_id = {} AND creature_entry = {}",
            guildId, activity.instanceMap, activity.finalBossEntry))
        {
            Field* fields = result->Fetch();
            stats.guildCount = fields[0].Get<uint32>();
            stats.guildFirst = fields[1].Get<std::string>();
        }
    }

    // Compatibility with test realms that have old one-time bounty history from before this ledger.
    if (!stats.personalCount && CharacterDatabase.Query(
        "SELECT 1 FROM mod_adventure_boss_bounty WHERE player_guid = {} AND map_id = {} "
        "AND creature_entry = {} LIMIT 1",
        playerGuid, activity.instanceMap, activity.finalBossEntry))
        stats.personalCount = 1;

    if (!stats.guildCount && player->GetGuildId() && CharacterDatabase.Query(
        "SELECT 1 FROM mod_adventure_boss_bounty b "
        "INNER JOIN guild_member gm ON gm.guid = b.player_guid "
        "WHERE gm.guildid = {} AND b.map_id = {} AND b.creature_entry = {} LIMIT 1",
        player->GetGuildId(), activity.instanceMap, activity.finalBossEntry))
        stats.guildCount = 1;

    return stats;
}

struct RaidLockoutState
{
    bool bound = false;
    bool permanent = false;
    bool extended = false;
    uint32 instanceId = 0;
    uint32 completedEncounters = 0;
};

uint32 CountBits(uint32 value)
{
    uint32 count = 0;
    while (value)
    {
        count += value & 1u;
        value >>= 1u;
    }
    return count;
}

RaidLockoutState CurrentRaidLockout(Player* player, AdventureActivity const& activity, Config const& config)
{
    RaidLockoutState state;
    if (!player || activity.kind != AdventureActivityKind::Raid || !activity.instanceMap)
        return state;

    InstancePlayerBind* bind = sInstanceSaveMgr->PlayerGetBoundInstance(
        player->GetGUID(), activity.instanceMap, ActivityDifficulty(config));
    if (!bind || !bind->save)
        return state;

    state.bound = true;
    state.permanent = bind->perm;
    state.extended = bind->extended;
    state.instanceId = bind->save->GetInstanceId();
    state.completedEncounters = CountBits(bind->save->GetCompletedEncounterMask());
    return state;
}

uint8 ProgressionCompletionStage(std::string const& id)
{
    if (id == "molten_core") return 1;
    if (id == "blackwing_lair") return 3;
    if (id == "aq40") return 6;
    if (id == "karazhan") return 9;
    if (id == "tempest_keep") return 10;
    if (id == "black_temple") return 12;
    if (id == "sunwell") return 13;
    if (id == "naxxramas") return 14;
    if (id == "ulduar") return 15;
    if (id == "trial_crusader") return 16;
    if (id == "icecrown") return 17;
    if (id == "ruby_sanctum") return 18;
    return 0;
}

bool PlayerRaidComplete(Player* player, AdventureActivity const& activity)
{
    if (!player)
        return false;
    if (ClearStats(player, activity).personalCount > 0)
        return true;

    uint8 const completionStage = ProgressionCompletionStage(activity.composerId);
    return completionStage && AdventureStartControl::CurrentProgression(player) >= completionStage;
}

void ApplyRecommendationRoleTargets(Config& config)
{
    if (config.mode == "dungeon")
    {
        config.size = 5;
        config.tanks = 1;
        config.healers = 1;
        config.dps = 3;
        return;
    }

    if (config.size <= 10)
    {
        config.tanks = 2;
        config.healers = 2;
    }
    else if (config.size <= 20)
    {
        config.tanks = 2;
        config.healers = 4;
    }
    else if (config.size <= 25)
    {
        config.tanks = 2;
        config.healers = 5;
    }
    else
    {
        config.tanks = 4;
        config.healers = 8;
    }
    config.dps = config.size - config.tanks - config.healers;
}

struct RecommendationCapacity
{
    bool feasible = false;
    uint32 guildBots = 0;
    uint32 selectedBots = 0;
    uint32 guildCandidates = 0;
    std::string detail;
};

RecommendationCapacity EvaluateRecommendationCapacity(Player* master, AdventureActivity const& activity)
{
    RecommendationCapacity result;
    if (!master)
    {
        result.detail = "No online player is available for a roster preview.";
        return result;
    }

    Config config;
    config.mode = activity.kind == AdventureActivityKind::Raid ? "raid" : "dungeon";
    config.activity = activity.composerId;
    config.difficulty = "normal";
    config.size = activity.kind == AdventureActivityKind::Raid
        ? BrowserRaidSize(activity.composerId, activity.preferredSize)
        : 5;
    ApplyRecommendationRoleTargets(config);
    config.requiredLevel = RequiredActivityLevel(master, config);
    ApplyBotLevelPolicy(master, config);
    config.preferGuild = true;
    config.fillWorld = true;
    config.keepMe = true;

    Plan preview;
    std::string error;
    result.feasible = Planner::Build(master, config, preview, error);
    result.guildCandidates = preview.guildCandidates;

    if (!result.feasible)
    {
        result.detail = error.empty()
            ? "Composer could not build the standard role layout from currently available players/bots."
            : error;
        return result;
    }

    for (Member const& member : preview.members)
    {
        if (member.human)
            continue;
        ++result.selectedBots;
        if (member.guild)
            ++result.guildBots;
    }

    result.detail = "Composer can build a standard " + std::to_string(unsigned(config.size)) +
        "-player roster now: " + std::to_string(result.selectedBots) + " bot(s) selected, " +
        std::to_string(result.guildBots) + " from your guild, with " +
        std::to_string(result.guildCandidates) + " eligible guild candidate(s) seen.";
    return result;
}

void SendJourney(ChatHandler* handler, Player* master)
{
    if (!handler || !master)
        return;

    uint8 const progression = AdventureStartControl::CurrentProgression(master);
    AdventureEra const liveEra = AdventureCatalog::CurrentRealmEra();
    handler->SendSysMessage("[GC]|JOURNEYRESET");
    handler->PSendSysMessage("[GC]|JOURNEYSTATE|{}|{}|{}|{}",
        AdventureCatalog::EraName(liveEra), uint32(progression), uint32(master->GetLevel()), master->GetGuildId());

    struct Recommendation
    {
        AdventureActivity const* activity = nullptr;
        int score = 0;
        std::string why;
        bool available = true;
    };
    std::vector<Recommendation> recommendations;

    for (AdventureActivity const& activity : AdventureCatalog::All())
    {
        if (activity.kind != AdventureActivityKind::Raid)
            continue;

        Config config;
        config.mode = "raid";
        config.activity = activity.composerId;
        config.difficulty = "normal";
        config.size = BrowserRaidSize(activity.composerId, activity.preferredSize);

        std::string reason;
        bool const available = ActivityEligible(master, config, reason);
        ActivityClearStats const clears = ClearStats(master, activity);
        RaidLockoutState const lockout = CurrentRaidLockout(master, activity, config);
        bool const personalComplete = PlayerRaidComplete(master, activity);
        bool const guildComplete = clears.guildCount > 0;

        handler->PSendSysMessage("[GC]|JOURNEYRAID|{}|{}|{}|{}|{}|{}|{}|{}|{}|{}|{}|{}|{}|{}|{}|{}|{}",
            activity.composerId, Sanitize(activity.name), AdventureCatalog::EraName(activity.era),
            uint32(RequiredProgressionFor(config)), available ? 1 : 0, personalComplete ? 1 : 0,
            guildComplete ? 1 : 0, Sanitize(AdventureCatalog::SupportLabel(activity.support)),
            Sanitize(available ? activity.supportNote : reason),
            clears.personalCount, Sanitize(clears.personalFirst), clears.guildCount, Sanitize(clears.guildFirst),
            lockout.bound ? 1 : 0, lockout.instanceId, lockout.completedEncounters, lockout.extended ? 1 : 0);

        if (activity.era == liveEra && activity.support == AdventureSupport::Ready && available && !personalComplete)
        {
            if (lockout.bound)
                recommendations.push_back({ &activity, 160 + int(activity.minProgression),
                    "Resume your active raid lockout; " + std::to_string(lockout.completedEncounters) +
                    " encounter(s) are already recorded in this instance.", true });
            else
                recommendations.push_back({ &activity, 100 + int(activity.minProgression),
                    "Available progression raid you have not completed yet.", true });
        }
        else if (activity.era == liveEra && activity.support == AdventureSupport::Ready && !available && !personalComplete)
        {
            int const distance = std::max<int>(0, int(RequiredProgressionFor(config)) - int(progression));
            int const score = 42 - std::min(28, distance * 4);
            recommendations.push_back({ &activity, score, "Next unlock: " + reason, false });
        }
    }

    for (AdventureActivity const& activity : AdventureCatalog::All())
    {
        if (activity.kind != AdventureActivityKind::Dungeon || activity.era != liveEra ||
            activity.support != AdventureSupport::Ready)
            continue;

        Config config;
        config.mode = "dungeon";
        config.activity = activity.composerId;
        config.difficulty = "normal";
        config.size = 5;
        std::string reason;
        bool const available = ActivityEligible(master, config, reason);
        if (!available)
        {
            int const levelGap = std::max<int>(0, int(activity.minLevel) - int(master->GetLevel()));
            int const score = 34 - std::min(24, levelGap * 3);
            recommendations.push_back({ &activity, score, "Next unlock: " + reason, false });
            continue;
        }

        int const levelDistance = std::max<int>(0, int(master->GetLevel()) - int(activity.minLevel));
        int score = 80 - std::min(40, levelDistance * 4);
        if (master->GetLevel() >= AdventureCatalog::EraLevelCap(liveEra) && activity.minLevel >= AdventureCatalog::EraLevelCap(liveEra) - 5)
            score += 25;
        recommendations.push_back({ &activity, score, "Available dungeon that fits your current era and level.", true });
    }

    std::stable_sort(recommendations.begin(), recommendations.end(), [](Recommendation const& a, Recommendation const& b)
    {
        return a.score > b.score;
    });

    uint8 sent = 0;
    std::unordered_set<std::string> seen;
    for (Recommendation const& recommendation : recommendations)
    {
        if (!recommendation.activity || !seen.insert(recommendation.activity->composerId).second)
            continue;
        RecommendationCapacity capacity;
        if (recommendation.available)
            capacity = EvaluateRecommendationCapacity(master, *recommendation.activity);
        else
            capacity.detail = "Unlock this activity before Composer evaluates a roster for it.";

        handler->PSendSysMessage("[GC]|RECOMMEND|{}|{}|{}|{}|{}|{}|{}|{}|{}|{}|{}",
            recommendation.activity->composerId,
            recommendation.activity->kind == AdventureActivityKind::Raid ? "RAID" : "DUNGEON",
            Sanitize(recommendation.activity->name),
            AdventureCatalog::EraName(recommendation.activity->era),
            Sanitize(recommendation.why),
            recommendation.available ? 1 : 0,
            capacity.feasible ? 1 : 0,
            capacity.guildBots,
            capacity.selectedBots,
            capacity.guildCandidates,
            Sanitize(capacity.detail));
        if (++sent >= 6)
            break;
    }

    handler->SendSysMessage("[GC]|JOURNEYDONE");
}

void SendCatalogDiagnostics(ChatHandler* handler)
{
    if (!handler)
        return;

    handler->SendSysMessage("[GC]|CATDIAGRESET");
    uint32 pass = 0;
    uint32 warn = 0;
    uint32 fail = 0;
    std::unordered_set<std::string> ids;

    for (AdventureActivity const& activity : AdventureCatalog::All())
    {
        uint8 severity = 0; // 0 pass, 1 warn, 2 fail
        std::string detail;
        auto note = [&](uint8 nextSeverity, std::string const& text)
        {
            severity = std::max<uint8>(severity, nextSeverity);
            if (!detail.empty()) detail += " • ";
            detail += text;
        };

        std::string const id = activity.composerId ? activity.composerId : "";
        std::string const label = activity.name ? activity.name : "";
        if (id.empty()) note(2, "Missing Composer activity ID.");
        else if (!ids.insert(id).second) note(2, "Duplicate Composer activity ID.");
        if (label.empty()) note(2, "Missing display name.");

        MapEntry const* map = activity.instanceMap ? sMapStore.LookupEntry(activity.instanceMap) : nullptr;
        if (!activity.instanceMap || !map)
            note(2, "Instance map " + std::to_string(activity.instanceMap) + " is not present in Map.dbc.");
        else if (!sObjectMgr->GetMapEntranceTrigger(activity.instanceMap))
            note(2, "No canonical AzerothCore entrance trigger; explicit Teleport to Instance cannot be trusted.");

        uint8 const eraCap = AdventureCatalog::EraLevelCap(activity.era);
        if (!activity.minLevel || activity.minLevel > eraCap)
            note(2, "Minimum level " + std::to_string(unsigned(activity.minLevel)) +
                " is outside the " + AdventureCatalog::EraName(activity.era) +
                " cap of " + std::to_string(unsigned(eraCap)) + ".");

        if (!activity.preferredSize || activity.preferredSize > 40)
            note(2, "Invalid preferred group size " + std::to_string(unsigned(activity.preferredSize)) + ".");

        if (activity.kind == AdventureActivityKind::Dungeon)
        {
            if (activity.preferredSize != 5)
                note(2, "Dungeon preferred size must be 5.");
            if (map && !GetLFGDungeon(activity.instanceMap, DUNGEON_DIFFICULTY_NORMAL))
                note(1, "No stock Normal Dungeon Finder entry; fixed-instance travel can still be used.");
        }
        else
        {
            if (!RaidSupports(id, activity.preferredSize, false))
                note(2, "Preferred raid size is not accepted by Group Composer's raid-size contract.");
            if (!activity.finalBossEntry)
                note(1, "No final boss configured; clear-history completion cannot be recorded for this raid.");
            else if (!sObjectMgr->GetCreatureTemplate(activity.finalBossEntry))
                note(2, "Configured final boss entry " + std::to_string(activity.finalBossEntry) + " is missing from creature_template.");
        }

        if (!activity.supportNote || !*activity.supportNote)
            note(1, "Playerbots support note is empty.");
        if (activity.support == AdventureSupport::Playable)
            note(1, "Catalog marks this activity Playable / experimental.");
        else if (activity.support == AdventureSupport::NotReady)
            note(1, "Catalog marks this activity Not Ready.");

        char const* status = "PASS";
        if (severity >= 2) { status = "FAIL"; ++fail; }
        else if (severity == 1) { status = "WARN"; ++warn; }
        else { ++pass; detail = "Catalog, map, entrance and clear-history metadata are structurally valid."; }

        handler->PSendSysMessage("[GC]|CATDIAG|{}|{}|{}|{}|{}|{}",
            Sanitize(id), Sanitize(label), AdventureCatalog::EraName(activity.era),
            activity.kind == AdventureActivityKind::Raid ? "RAID" : "DUNGEON",
            status, Sanitize(detail));
    }

    handler->PSendSysMessage("[GC]|CATDIAGDONE|{}|{}|{}", pass, warn, fail);
}

struct ComposerGearProfile
{
    uint16 minimum = 0;
    uint16 target = 0;
};

ComposerGearProfile GearProfileFor(Config const& config)
{
    ComposerGearProfile profile;
    profile.minimum = config.minimumItemLevel;
    uint16 floor = 0;
    uint16 target = 0;

    if (config.mode == "dungeon")
    {
        if (config.difficulty == "gamma") { floor = 225; target = 232; }
        else if (config.difficulty == "beta") { floor = 213; target = 225; }
        else if (config.difficulty == "alpha") { floor = 200; target = 213; }
        else if (config.requiredLevel >= 80)
        {
            bool const finalFive =
                config.activity == "trial_champion" || config.activity == "forge_souls" ||
                config.activity == "pit_saron" || config.activity == "halls_reflection";
            if (config.difficulty == "heroic")
            {
                floor = finalFive ? 200 : 187;
                target = finalFive ? 213 : 200;
            }
            else
            {
                floor = finalFive ? 187 : 174;
                target = finalFive ? 200 : 187;
            }
        }
    }
    else if (config.mode == "raid")
    {
        bool heroic = config.difficulty == "heroic";
        if (config.activity == "molten_core")             { floor = 58;  target = 65; }
        else if (config.activity == "zul_gurub")          { floor = 58;  target = 65; }
        else if (config.activity == "aq20")               { floor = 60;  target = 68; }
        else if (config.activity == "blackwing_lair")     { floor = 62;  target = 70; }
        else if (config.activity == "aq40")               { floor = 65;  target = 75; }
        else if (config.activity == "karazhan")           { floor = 105; target = 115; }
        else if (config.activity == "gruul" ||
                 config.activity == "magtheridon")        { floor = 110; target = 120; }
        else if (config.activity == "serpentshrine" ||
                 config.activity == "tempest_keep" ||
                 config.activity == "zulaman")            { floor = 118; target = 128; }
        else if (config.activity == "hyjal" ||
                 config.activity == "black_temple")       { floor = 128; target = 141; }
        else if (config.activity == "sunwell")            { floor = 141; target = 154; }
        else if (config.activity == "naxxramas" ||
                 config.activity == "obsidian_sanctum" ||
                 config.activity == "eye_of_eternity" ||
                 config.activity == "vault_archavon")
        {
            floor = config.size >= 25 ? 187 : 174;
            target = config.size >= 25 ? 200 : 187;
        }
        else if (config.activity == "ulduar")
        {
            floor = config.size >= 25 ? 200 : 187;
            target = config.size >= 25 ? 213 : 200;
        }
        else if (config.activity == "trial_crusader")
        {
            if (heroic)
            {
                floor = config.size >= 25 ? 232 : 219;
                target = config.size >= 25 ? 245 : 232;
            }
            else
            {
                floor = config.size >= 25 ? 219 : 200;
                target = config.size >= 25 ? 226 : 219;
            }
        }
        else if (config.activity == "onyxia")
        {
            floor = config.size >= 25 ? 219 : 200;
            target = config.size >= 25 ? 226 : 219;
        }
        else if (config.activity == "icecrown" || config.activity == "ruby_sanctum")
        {
            if (heroic)
            {
                floor = config.size >= 25 ? 245 : 232;
                target = config.size >= 25 ? 251 : 245;
            }
            else
            {
                floor = config.size >= 25 ? 232 : 219;
                target = config.size >= 25 ? 245 : 232;
            }
        }
    }

    profile.minimum = std::max<uint16>(profile.minimum, floor);
    profile.target = std::max<uint16>(profile.minimum, target);
    return profile;
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

void SyncManagedBot(Player* master, Player* bot, uint8 role, uint8 spec, uint8 targetLevel,
    uint16 minimumItemLevel, uint16 targetItemLevel, bool fullRebuild)
{
    if (!master || !bot) return;
    if (spec > 2) spec = Planner::InferSpec(bot);
    if (spec > 2) return;

    // Disposable world/AddClass/reserve bodies are elastic Composer capacity. Preparation must be
    // deterministic and bounded: do not call PlayerbotFactory::Randomize(false), which resets a
    // character's whole life history and was the main source of long 25-player preparation stalls.
    // Instead touch only combat-readiness state that Composer owns.
    uint8 provisionLevel = std::max<uint8>(bot->GetLevel(), targetLevel);
    PlayerbotFactory factory(bot, provisionLevel, ITEM_QUALITY_EPIC, 0);

    if (fullRebuild)
    {
        if (bot->isDead()) bot->ResurrectPlayer(1.0f, false);
        bot->CombatStop(true);

        if (bot->GetLevel() < targetLevel)
        {
            bot->GiveLevel(targetLevel);
            bot->InitStatsForLevel(true);
        }

        // Progression/era owns the available talent system. Finalize that state before Composer
        // chooses talents, rebuilds AI strategies, or equips the activity build.
        RaidRosterEra::SyncBotToMaster(master, bot);
        EraTransition::Detect(bot);

        factory.UnbindInstance();
        bot->LearnDefaultSkills();
        factory.InitSkills();
        factory.InitClassSpells();
        factory.InitAvailableSpells();
        factory.InitSpecialSpells();
    }

    // Playerbots / Era Talents use pseudo-spec 3 for Feral Cat PvE. Keep the public Composer spec
    // as Feral (1) and use the requested role only to select Bear (1) versus Cat (3) behavior.
    uint8 buildSpec = spec;
    if (bot->IsClass(CLASS_DRUID) && spec == 1 && role == ROLE_DPS) buildSpec = 3;

    if (!EraTalentBots::FactoryReconcile(bot, buildSpec))
        PlayerbotFactory::InitTalentsBySpecNo(bot, buildSpec, true);

    // Rebuild AI only after the final talents exist so Tank/Heal/DPS strategies match the requested
    // job when PreparedMemberReady() validates the bot.
    if (PlayerbotAI* ai = GET_PLAYERBOT_AI(bot)) ai->ResetStrategies(false);
    factory.InitGlyphs(false);

    if (fullRebuild)
    {
        RaidRosterGear::EquipForSpec(bot, master, spec, minimumItemLevel, targetItemLevel);
        factory.ApplyEnchantAndGemsNew();
        factory.InitAmmo();
        factory.CleanupConsumables();
        factory.InitReagents();
        factory.InitConsumables();
        factory.InitPotions();
        factory.InitFood();
        factory.InitPet();
        factory.InitPetTalents();
        bot->DurabilityRepairAll(false, 1.0f, false);

        if (bot->IsClass(CLASS_DEATH_KNIGHT))
        {
            uint32 quest = bot->GetTeamId(true) == TEAM_ALLIANCE ? 13188 : 13189;
            if (!bot->IsQuestRewarded(quest)) bot->SetRewardedQuest(quest);
        }

        bot->SetHealth(bot->GetMaxHealth());
        if (bot->GetMaxPower(POWER_MANA) > 0)
            bot->SetPower(POWER_MANA, bot->GetMaxPower(POWER_MANA));
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
        case Map::CANNOT_ENTER_UNSPECIFIED_REASON: return "an instance access requirement (level, quest, item or script gate) is not satisfied";
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
        error = "Instance teleport requires the complete reviewed roster to still be grouped.";
        return false;
    }

    // Composer may be operated by a real raid assistant, but instance ownership and Titan Rune
    // authority belong to the actual live group leader. Resolve that player explicitly instead of
    // accidentally treating the assistant who opened Composer as the leader.
    Player* travelLeader = group->GetLeader();
    if (!travelLeader || GET_PLAYERBOT_AI(travelLeader))
    {
        error = "Instance teleport requires the real group leader to be online.";
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
            error = "'" + member.name + "' went offline before instance teleport.";
            return false;
        }
        if (player->GetGroup() != group)
        {
            error = "'" + member.name + "' left the reviewed group before instance teleport.";
            return false;
        }
        if (player->IsBeingTeleported())
        {
            error = "'" + member.name + "' is already being teleported; wait a moment and press Teleport to Instance again.";
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

        std::string eligibilityReason;
        if (!ActivityEligible(player, plan.config, eligibilityReason))
        {
            error = "'" + member.name + "' cannot enter the selected activity: " + eligibilityReason;
            return false;
        }

        Map::EnterState state = sMapMgr->PlayerCannotEnter(mapId, player);
        if (state != Map::CAN_ENTER && state != Map::CANNOT_ENTER_ALREADY_IN_MAP)
        {
            std::string const accessHint = SpecificInstanceAccessHint(player, plan.config);
            error = "'" + member.name + "' cannot enter the selected instance because " +
                (accessHint.empty() ? std::string(EnterStateReason(state)) + "." : accessHint);
            return false;
        }
        travelers.push_back(player);
    }

    // The explicit Composer selection must beat any stale personal setting. Heroic/Normal turns the
    // next-dungeon protocol off; Alpha/Beta/Gamma persists the selected protocol on the actual group
    // leader before entry so TitanRune::ActivateForPlayer reads the same authority as normal play.
    if (plan.config.mode == "dungeon")
        TitanRune::SaveSelectedMode(travelLeader, titanMode);

    auto teleport = [&](Player* player) -> bool
    {
        if (!player) return false;
        if (player->IsInFlight())
        {
            player->GetMotionMaster()->MovementExpired();
            player->CleanupAfterTaxiFlight();
        }
        else
            player->SaveRecallPosition();

        return player->TeleportTo(destination->target_mapId, destination->target_X, destination->target_Y,
            destination->target_Z, destination->target_Orientation);
    };

    // The real leader goes first. Never strand the human outside while the Playerbots disappear
    // into an instance the leader could not enter. Every teleport return value is authoritative.
    if (!teleport(travelLeader))
    {
        error = "'" + travelLeader->GetName() + "' could not enter the selected instance after preflight. "
            "Check the access requirement or retry once the current teleport/state transition has settled.";
        return false;
    }

    for (Player* player : travelers)
    {
        if (player == travelLeader)
            continue;
        if (!teleport(player))
        {
            error = "'" + player->GetName() + "' could not enter the selected instance after the leader. "
                "The roster remains assembled; press Teleport to Instance again to move the missing member.";
            return false;
        }
    }

    detail = std::string("Roster assembled and entering the selected ") +
        (plan.config.mode == "raid" ? "raid." : "dungeon.");
    return true;
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

        // Nothing already in a live group is disposable. Humans and Playerbots are sticky roster
        // anchors; if membership changed after preview, force a new plan instead of silently pruning
        // somebody's companion. This is the multi-user ownership boundary.
        for (Group::MemberSlot const& slot : group->GetMemberSlots())
        {
            if (Selected(plan, slot.guid)) continue;
            if (!IsBotGuid(slot.guid))
            {
                error = "The group gained a real player after the preview. Run Build & Prepare again so every human is locked into the composition.";
                return false;
            }

            std::string name = "Playerbot";
            sCharacterCache->GetCharacterNameByGuid(slot.guid, name);
            error = "Playerbot '" + name +
                "' joined the group after the preview. Group Composer never removes existing party/raid bots automatically; rebuild the roster or kick that bot explicitly.";
            return false;
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
        if (live->GetLevel() > plan.config.maxBotLevel)
        {
            error = "Selected bot '" + member.name + "' is level " + std::to_string(unsigned(live->GetLevel())) +
                ", above the anti-boost peer cap of " + std::to_string(unsigned(plan.config.maxBotLevel)) +
                ". Run Find Roster again for a level-appropriate replacement.";
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

uint16 PreparedItemLevelFloor(Plan const& plan, Member const& member)
{
    if (!FullProvisionFor(member))
        return plan.config.minimumItemLevel;
    return GearProfileFor(plan.config).minimum;
}

std::string PreparedMemberBlocker(Plan const& plan, Member const& member)
{
    if (BotHasPendingSync(member.guid))
        return "is still waiting for its login/provision callback";

    Player* bot = ObjectAccessor::FindConnectedPlayer(member.guid);
    if (!bot)
        return "is still offline";
    if (!GET_PLAYERBOT_AI(bot))
        return "is online but Playerbot AI is not initialized";
    if (bot->GetLevel() < plan.config.requiredLevel)
        return "is level " + std::to_string(unsigned(bot->GetLevel())) +
            ", below the required level " + std::to_string(unsigned(plan.config.requiredLevel));
    if (bot->GetLevel() > plan.config.maxBotLevel)
        return "is level " + std::to_string(unsigned(bot->GetLevel())) +
            ", above the anti-boost peer cap " + std::to_string(unsigned(plan.config.maxBotLevel));
    if ((member.managed || member.reserve || member.needsPreparation) &&
        bot->GetLevel() < plan.config.botTargetLevel)
        return "is level " + std::to_string(unsigned(bot->GetLevel())) +
            ", below the Composer peer target " + std::to_string(unsigned(plan.config.botTargetLevel));

    // Validate the finalized combat build itself. Playerbot strategy flags can lag a talent reset by
    // one AI tick, which previously stranded correctly-specced healers at 3/4 ready.
    uint8 liveSpec = Planner::InferSpec(bot);
    if (liveSpec == ANY_SPEC)
        return "has no resolved active specialization";
    if (member.spec != ANY_SPEC && liveSpec != member.spec)
        return std::string("resolved to ") + SpecName(member.cls, liveSpec) + " instead of " +
            SpecName(member.cls, member.spec);
    if (!SpecCanFillRole(member.cls, liveSpec, member.role))
        return std::string("final specialization ") + SpecName(member.cls, liveSpec) +
            " cannot fill the requested " + std::string(RoleToken(member.role)) + " role";

    uint16 floor = PreparedItemLevelFloor(plan, member);
    if (floor && bot->GetAverageItemLevel() + 0.001f < floor)
        return "average item level " + std::to_string(uint32(bot->GetAverageItemLevel() + 0.5f)) +
            " is below the preparation floor " + std::to_string(uint32(floor));
    return "";
}

bool PreparedMemberReady(Plan const& plan, Member const& member)
{
    return PreparedMemberBlocker(plan, member).empty();
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
        if (PreparedMemberReady(plan, member)) ++ready;
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
    ComposerGearProfile const activityGear = GearProfileFor(plan.config);
    for (Member const& member : plan.members)
    {
        if (member.human) continue;
        bool ownsPreparation = member.reserve || member.managed || member.needsPreparation;
        if (!ownsPreparation) continue;

        bool const fullProvision = FullProvisionFor(member);
        uint16 const minimumItemLevel = fullProvision ? activityGear.minimum : plan.config.minimumItemLevel;
        uint16 const targetItemLevel = fullProvision ? activityGear.target : 0;

        Player* bot = ObjectAccessor::FindConnectedPlayer(member.guid);
        if (bot)
        {
            if (!(member.guild && member.needsPreparation))
                SyncManagedBot(master, bot, member.role, member.spec, plan.config.botTargetLevel,
                    minimumItemLevel, targetItemLevel, fullProvision);
            EnsureComposerInstanceAccess(master, bot, plan.config);
            continue;
        }

        if (!member.reserve)
            mgr->AddPlayerBot(member.guid, account, true);
        s_pendingSync[member.guid.GetCounter()] = {
            owner, member.role, member.spec, plan.config.botTargetLevel, minimumItemLevel,
            targetItemLevel, fullProvision, 0
        };
    }

    plan.prepareElapsed = 0;
    plan.prepareProgressElapsed = 0;
    plan.prepared = !OwnerHasPendingSync(owner) && PreparedBotCount(plan) == SelectedBotCount(plan);
    plan.preparing = !plan.prepared;
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

bool BeginPreparedAssembly(Player* master, Plan& plan, std::string& error)
{
    if (!master) { error = "Group Composer lost the live owner before assembly."; return false; }
    if (plan.travelPending) { error = "Instance entry is already in progress."; return false; }
    if (plan.assembling) return true;

    uint32 owner = master->GetGUID().GetCounter();
    if (!plan.prepared || plan.preparing || OwnerHasPendingSync(owner))
    {
        error = "Roster preparation has not finished yet.";
        return false;
    }
    if (!ValidateAssemblySnapshot(master, plan, error)) return false;
    if (!Reserve::AcquirePlan(master, plan, error)) return false;

    plan.humanInvitesSent.clear();
    for (Member const& member : plan.members)
    {
        if (member.human || !member.guild || !member.needsPreparation) continue;
        if (Player* bot = ObjectAccessor::FindConnectedPlayer(member.guid))
            SyncManagedBot(master, bot, member.role, member.spec, plan.config.botTargetLevel, 0, 0, false);
    }

    plan.travelPending = false;
    plan.travelElapsed = 0;
    plan.travelAttempts = 0;
    plan.assembled = false;
    plan.assembling = true;
    plan.assembleElapsed = 0;
    plan.assembleProgressElapsed = 0;
    TryAttachMissing(master, plan);
    SendProgress(master, "ASSEMBLING", JoinedPlanMembers(master, plan), uint32(plan.members.size()),
        "Prepared bots are joining your live group...");
    return true;
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
    uint8 level = 1;
    bool online = live != nullptr;
    char const* roleToken = "AUTO";

    if (live)
    {
        name = live->GetName();
        cls = live->getClass();
        level = live->GetLevel();
        roleToken = RoleToken(Planner::InferRole(live));
    }
    else
    {
        CharacterCacheEntry const* cache = sCharacterCache->GetCharacterCacheByGuid(guid);
        if (!cache) return;
        name = cache->Name;
        cls = cache->Class;
        level = cache->Level;

        auto draft = s_drafts.find(master->GetGUID().GetCounter());
        if (draft != s_drafts.end())
        {
            auto overrideItr = draft->second.humanRoles.find(Lower(name));
            if (overrideItr != draft->second.humanRoles.end()) roleToken = RoleToken(overrideItr->second);
        }
    }

    handler->PSendSysMessage("[GC]|ANCHOR|{}|{}|{}|{}|{}|{}|{}", Sanitize(name), ClassToken(cls), roleToken,
        online ? 1 : 0, uint32(subgroup + 1), guid == master->GetGUID() ? 1 : 0, uint32(level));
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
                SyncManagedBot(master, bot, itr->second.role, itr->second.spec, itr->second.targetLevel,
                    itr->second.minimumItemLevel, itr->second.targetItemLevel, itr->second.fullRebuild);
                auto planItr = s_plans.find(itr->second.ownerGuid);
                if (planItr != s_plans.end())
                    EnsureComposerInstanceAccess(master, bot, planItr->second.config);
                itr = s_pendingSync.erase(itr);
            }
            else if (itr->second.elapsed > 12000) itr = s_pendingSync.erase(itr);
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
                    if (master)
                    {
                        SendProgress(master, "READY", readyBots, totalBots,
                            "Prepared roster is ready for review. Press Assemble when you are satisfied.");
                        SendProtocol(master, "STATUS", "Preparation complete. Review the roster, then press Assemble.");
                    }
                }
                else if (plan.prepareElapsed > 15000 && master)
                {
                    std::string failed = "a selected bot";
                    std::string blocker = "did not become ready";
                    for (Member const& member : plan.members)
                    {
                        if (member.human) continue;
                        std::string reason = PreparedMemberBlocker(plan, member);
                        if (!reason.empty())
                        {
                            failed = "'" + member.name + "'";
                            blocker = reason;
                            break;
                        }
                    }

                    std::string detail = "Preparation stalled on " + failed + ": " + blocker + " (" +
                        std::to_string(readyBots) + "/" + std::to_string(totalBots) +
                        " bots ready). Composer stopped instead of waiting or rebuilding the whole roster; press Build & Prepare to select fresh capacity.";
                    plan.preparing = false;
                    plan.prepared = false;
                    Reserve::ReleaseUnjoined(master);
                    ClearPendingSync(ownerLow);
                    SendProgress(master, "ERROR", readyBots, totalBots, detail);
                    SendProtocol(master, "ERROR", detail);
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

                // Teleport is now an explicit player-confirmed action. Perform exactly one delayed
                // attempt after group/difficulty state settles. Repeating Player::TeleportTo here
                // can make module-level access hooks print the same blocker many times (for example
                // Individual Progression's "Progression Level Required" message). A failed attempt
                // leaves the reviewed roster assembled so the player can fix the blocker and click
                // Teleport to Instance again deliberately.
                plan.travelPending = false;
                plan.travelElapsed = 0;
                ++plan.travelAttempts;

                std::string travelDetail, travelError;
                if (TeleportCompletedPlan(master, plan, travelDetail, travelError))
                {
                    SendProgress(master, "DONE", uint32(plan.members.size()), uint32(plan.members.size()), travelDetail);
                    SendProtocol(master, "DONE", travelDetail);
                }
                else
                {
                    SendProtocol(master, "STATUS", travelError);
                    SendProgress(master, "ASSEMBLED", uint32(plan.members.size()), uint32(plan.members.size()),
                        "Group is assembled. Clear the blocker, then press Teleport to Instance to retry.");
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
                    plan.assembled = true;
                    if (ActivityMapId(plan))
                    {
                        SendProgress(master, "ASSEMBLED", uint32(plan.members.size()), uint32(plan.members.size()),
                            "Group assembled. Press Teleport to Instance when everyone is ready.");
                        SendProtocol(master, "STATUS", "Group assembled. Instance travel now requires explicit confirmation.");
                    }
                    else
                    {
                        SendProgress(master, "ASSEMBLED", uint32(plan.members.size()), uint32(plan.members.size()),
                            "Group assembled. Ready for Dungeon Finder.");
                        SendProtocol(master, "STATUS", "Group assembled. Dungeon Finder can choose the destination.");
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
        { "teleport",    HandleTeleport,          SEC_PLAYER, Console::No },
        { "leave",       HandleLeaveInstance,     SEC_PLAYER, Console::No },
        { "disband",     HandleDisband,           SEC_PLAYER, Console::No },
        { "activities",  HandleActivities,        SEC_PLAYER, Console::No },
        { "journey",     HandleJourney,           SEC_PLAYER, Console::No },
        { "queue",       HandleQueue,             SEC_PLAYER, Console::No },
        { "anchors",     HandleAnchors,           SEC_PLAYER, Console::No },
        { "diagnostics", HandleDiagnostics,       SEC_PLAYER, Console::No },
        { "catalogdiag", HandleCatalogDiagnostics,SEC_PLAYER, Console::No },
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

        AdventureEra const liveEra = AdventureCatalog::CurrentRealmEra();
        bool const titan = difficulty == "alpha" || difficulty == "beta" || difficulty == "gamma";
        if (liveEra == AdventureEra::Vanilla && difficulty != "normal")
        { SendError(handler, "Vanilla dungeon mode supports Normal difficulty only."); return true; }
        if (liveEra == AdventureEra::Tbc && titan)
        { SendError(handler, "Titan Rune Alpha/Beta/Gamma are WotLK-only."); return true; }
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
    ApplyBotLevelPolicy(master, config);

    std::string eligibilityReason;
    if (!ActivityEligible(master, config, eligibilityReason))
    {
        SendError(handler, "Selected activity is locked: " + eligibilityReason);
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
    if (stored.prepared)
    {
        SendProgress(master, "READY", readyBots, totalBots,
            "Prepared roster is ready for review. Press Assemble when you are satisfied.");
        handler->SendSysMessage("[GC]|STATUS|Preparation complete. Review the roster, then press Assemble.");
    }
    else
        SendProgress(master, "PREPARING", readyBots, totalBots, "Preparing selected bots for review...");
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
    if (plan.assembled)
    {
        SendProgress(master, "ASSEMBLED", uint32(plan.members.size()), uint32(plan.members.size()),
            ActivityMapId(plan) ? "Group assembled. Press Teleport to Instance when everyone is ready." : "Group assembled. Ready for Dungeon Finder.");
        handler->SendSysMessage("[GC]|STATUS|This reviewed roster is already assembled.");
        return true;
    }
    if (!plan.prepared || plan.preparing || OwnerHasPendingSync(owner))
    {
        handler->SendSysMessage("[GC]|STATUS|Roster preparation is still running. Wait for Ready, then press Assemble.");
        SendProgress(master, "PREPARING", PreparedBotCount(plan), SelectedBotCount(plan),
            "Waiting for selected bots to finish preparation...");
        return true;
    }

    std::string assemblyError;
    if (!BeginPreparedAssembly(master, plan, assemblyError))
    {
        SendError(handler, assemblyError);
        return true;
    }
    handler->SendSysMessage("[GC]|STATUS|Prepared Playerbots are joining server-side; real players accept normally.");
    return true;
}

bool GroupComposerCommand::HandleTeleport(ChatHandler* handler)
{
    Player* master = CommandPlayer(handler);
    if (!master) return true;
    auto itr = s_plans.find(master->GetGUID().GetCounter());
    if (itr == s_plans.end() || !itr->second.valid) { SendError(handler, "Build and assemble a valid roster before teleporting."); return true; }

    Plan& plan = itr->second;
    if (plan.config.mode == "dungeon" && plan.config.activity == "random")
    { SendError(handler, "Random Dungeon has no fixed instance entrance. Use Dungeon Finder after assembly."); return true; }
    if (!ActivityMapId(plan)) { SendError(handler, "The selected activity has no configured instance entrance."); return true; }
    if (plan.travelPending) { handler->SendSysMessage("[GC]|STATUS|Instance teleport is already in progress."); return true; }
    if (plan.assembling || !plan.assembled || !PlanMembershipComplete(master, plan))
    { SendError(handler, "Assemble the complete reviewed group before teleporting it."); return true; }

    std::string validationError;
    if (!ValidateAssemblySnapshot(master, plan, validationError)) { SendError(handler, validationError); return true; }

    ApplyGroupSettings(master, plan);
    plan.travelPending = true;
    plan.travelElapsed = 0;
    plan.travelAttempts = 0;
    SendProgress(master, "TRAVEL", uint32(plan.members.size()), uint32(plan.members.size()),
        "Teleport confirmed. Checking access and entering the selected instance...");
    handler->SendSysMessage("[GC]|STATUS|Teleport confirmed. Validating instance access for the full group.");
    return true;
}

bool GroupComposerCommand::HandleLeaveInstance(ChatHandler* handler)
{
    Player* master = CommandPlayer(handler);
    if (!master) return true;
    uint32 const owner = master->GetGUID().GetCounter();
    auto itr = s_plans.find(owner);
    if (itr == s_plans.end() || !itr->second.valid || !itr->second.assembled)
    {
        SendError(handler, "Leave Instance requires an assembled Composer group.");
        return true;
    }

    Plan& plan = itr->second;
    if (plan.assembling || plan.travelPending)
    {
        SendError(handler, "Wait for the current assembly/travel action to finish first.");
        return true;
    }

    Group* group = master->GetGroup();
    if (!group || !PlanMembershipComplete(master, plan))
    {
        SendError(handler, "The reviewed Composer group is no longer complete. Rebuild the roster before using group travel.");
        return true;
    }

    if (!master->GetInstanceId())
    {
        SendError(handler, "You are not currently inside an instanced dungeon or raid.");
        return true;
    }

    uint32 const instanceMap = master->GetMapId();
    uint32 const instanceId = master->GetInstanceId();
    AreaTriggerTeleport const* exit = sObjectMgr->GetGoBackTrigger(instanceMap);
    if (!exit)
    {
        SendError(handler, "AzerothCore has no canonical exit trigger for this instance.");
        return true;
    }

    std::vector<Player*> travelers;
    for (Member const& member : plan.members)
    {
        Player* player = ObjectAccessor::FindConnectedPlayer(member.guid);
        if (!player || player->GetGroup() != group) continue;
        if (player->GetMapId() != instanceMap || player->GetInstanceId() != instanceId) continue;
        if (player->IsInCombat())
        {
            SendError(handler, "'" + member.name + "' is in combat. The full in-instance group must be out of combat before leaving.");
            return true;
        }
        if (player->IsBeingTeleported())
        {
            SendError(handler, "'" + member.name + "' is already being teleported. Wait a moment and retry.");
            return true;
        }
        travelers.push_back(player);
    }

    if (travelers.empty())
    {
        SendError(handler, "No reviewed group members are currently inside your instance copy.");
        return true;
    }

    for (Player* player : travelers)
        if (!player->TeleportTo(exit->target_mapId, exit->target_X, exit->target_Y, exit->target_Z, exit->target_Orientation))
        {
            SendError(handler, "AzerothCore rejected the instance-exit teleport for one of the reviewed group members.");
            return true;
        }

    std::string detail = "Group left the instance together. The reviewed roster remains assembled and can re-enter later.";
    SendProgress(master, "ASSEMBLED", uint32(plan.members.size()), uint32(plan.members.size()), detail);
    SendProtocol(master, "DONE", detail);
    return true;
}

bool GroupComposerCommand::HandleDisband(ChatHandler* handler)
{
    Player* master = CommandPlayer(handler);
    if (!master) return true;
    uint32 const owner = master->GetGUID().GetCounter();
    auto itr = s_plans.find(owner);
    if (itr == s_plans.end() || !itr->second.valid)
    {
        SendError(handler, "There is no active Composer roster to disband.");
        return true;
    }

    Plan& plan = itr->second;
    if (plan.assembling || plan.travelPending)
    {
        SendError(handler, "Wait for the current assembly/travel action to finish before disbanding.");
        return true;
    }

    Group* group = master->GetGroup();
    if (!group)
    {
        Reserve::ReleaseOwner(owner);
        ClearPendingForOwner(owner);
        s_plans.erase(owner);
        handler->SendSysMessage("[GC]|RESET");
        handler->SendSysMessage("[GC]|DONE|Composer roster cleared; there was no live group to disband.");
        return true;
    }

    if (group->GetLeaderGUID() != master->GetGUID())
    {
        SendError(handler, "Only the real group leader can use Disband Composer Group.");
        return true;
    }
    if (!PlanMembershipComplete(master, plan))
    {
        SendError(handler, "The live group no longer exactly matches the reviewed Composer roster. Disband manually so Composer cannot remove an unreviewed player.");
        return true;
    }

    Reserve::ReleaseOwner(owner);
    ClearPendingForOwner(owner);
    s_plans.erase(owner);
    group->Disband();
    handler->SendSysMessage("[GC]|RESET");
    handler->SendSysMessage("[GC]|DONE|Composer group disbanded. Your configuration is still available for another Build & Prepare.");
    return true;
}

bool GroupComposerCommand::HandleActivities(ChatHandler* handler, std::string mode, std::string difficulty, uint32 size)
{
    Player* master = CommandPlayer(handler);
    if (!master) return true;
    SendActivityEligibility(handler, master, mode, difficulty, size);
    return true;
}

bool GroupComposerCommand::HandleJourney(ChatHandler* handler)
{
    Player* master = CommandPlayer(handler);
    if (!master) return true;
    SendJourney(handler, master);
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

    std::string eligibilityReason;
    if (!ActivityEligible(master, plan.config, eligibilityReason))
    {
        SendError(handler, "Selected dungeon is locked: " + eligibilityReason);
        return true;
    }
    if (plan.assembling || !plan.assembled || !PlanMembershipComplete(master, plan)) { SendError(handler, "Assemble the complete 5-player party before queueing it."); return true; }

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
        // LFGDungeons.dbc 3.3.5a IDs: 258 Classic Normal, 259/260 TBC Normal/Heroic,
        // 261/262 WotLK Normal/Heroic. AzerothCore exposes constants for TBC/WotLK but not
        // Random Classic, so keep the missing stock client ID local and explicit here.
        static constexpr uint32 RANDOM_DUNGEON_NORMAL_CLASSIC = 258u;
        switch (AdventureCatalog::CurrentRealmEra())
        {
            case AdventureEra::Vanilla:
                if (heroic)
                {
                    SendError(handler, "Vanilla Random Dungeon is Normal-only.");
                    return true;
                }
                dungeons.insert(RANDOM_DUNGEON_NORMAL_CLASSIC);
                break;
            case AdventureEra::Tbc:
                dungeons.insert(heroic ? lfg::RANDOM_DUNGEON_HEROIC_TBC : lfg::RANDOM_DUNGEON_NORMAL_TBC);
                break;
            case AdventureEra::Wotlk:
                dungeons.insert(heroic ? lfg::RANDOM_DUNGEON_HEROIC_WOTLK : lfg::RANDOM_DUNGEON_NORMAL_WOTLK);
                break;
        }
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

bool GroupComposerCommand::HandleCatalogDiagnostics(ChatHandler* handler)
{
    if (!CommandPlayer(handler))
        return true;
    SendCatalogDiagnostics(handler);
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
        else if (plan->second.assembled)
            SendProgress(master, "ASSEMBLED", uint32(plan->second.members.size()), uint32(plan->second.members.size()),
                ActivityMapId(plan->second) ? "Group assembled. Press Teleport to Instance when everyone is ready." : "Group assembled. Ready for Dungeon Finder.");
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
