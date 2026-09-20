#include "AdventureCatalog.h"

#include "IndividualProgression.h"
#include "Player.h"

#include <algorithm>
#include <cctype>

namespace
{
std::string Normalize(std::string value)
{
    value.erase(std::remove_if(value.begin(), value.end(), [](unsigned char c)
    {
        return std::isspace(c) || c == '-' || c == '_' || c == '\'' || c == ':' || c == '/';
    }), value.end());
    std::transform(value.begin(), value.end(), value.begin(), [](unsigned char c)
    {
        return static_cast<char>(std::tolower(c));
    });
    return value;
}

// One server-authoritative activity catalog shared by Adventure Guide and Group Composer.
// "Ready" is intentionally conservative. Playable activities can be shown with a caveat but are
// not promoted as the default recommendation until runtime validation proves them on this fork.
std::vector<AdventureActivity> const Activities = {
    // ---------------------------------------------------------------------
    // VANILLA DUNGEONS
    // ---------------------------------------------------------------------
    {"rfc", "ragefire_chasm", "Ragefire Chasm", AdventureActivityKind::Dungeon, AdventureEra::Vanilla, 389, 13, 0, 5, AdventureSupport::Playable, "Legacy dungeon; runtime validation pending.", 0},
    {"deadmines", "deadmines", "The Deadmines", AdventureActivityKind::Dungeon, AdventureEra::Vanilla, 36, 15, 0, 5, AdventureSupport::Playable, "Legacy dungeon; runtime validation pending.", 0},
    {"wailingcaverns", "wailing_caverns", "Wailing Caverns", AdventureActivityKind::Dungeon, AdventureEra::Vanilla, 43, 15, 0, 5, AdventureSupport::Playable, "Legacy dungeon; runtime validation pending.", 0},
    {"shadowfang", "shadowfang_keep", "Shadowfang Keep", AdventureActivityKind::Dungeon, AdventureEra::Vanilla, 33, 18, 0, 5, AdventureSupport::Playable, "Legacy dungeon; runtime validation pending.", 0},
    {"blackfathom", "blackfathom_deeps", "Blackfathom Deeps", AdventureActivityKind::Dungeon, AdventureEra::Vanilla, 48, 20, 0, 5, AdventureSupport::Playable, "Legacy dungeon; runtime validation pending.", 0},
    {"stockades", "stockades", "The Stockade", AdventureActivityKind::Dungeon, AdventureEra::Vanilla, 34, 22, 0, 5, AdventureSupport::Playable, "Legacy dungeon; runtime validation pending.", 0},
    {"gnomeregan", "gnomeregan", "Gnomeregan", AdventureActivityKind::Dungeon, AdventureEra::Vanilla, 90, 24, 0, 5, AdventureSupport::Playable, "Legacy dungeon; runtime validation pending.", 0},
    {"rfk", "razorfen_kraul", "Razorfen Kraul", AdventureActivityKind::Dungeon, AdventureEra::Vanilla, 47, 25, 0, 5, AdventureSupport::Playable, "Legacy dungeon; runtime validation pending.", 0},
    {"scarlet", "scarlet_monastery", "Scarlet Monastery", AdventureActivityKind::Dungeon, AdventureEra::Vanilla, 189, 30, 0, 5, AdventureSupport::Playable, "Shared Scarlet Monastery instance; wing routing validation pending.", 0},
    {"rfd", "razorfen_downs", "Razorfen Downs", AdventureActivityKind::Dungeon, AdventureEra::Vanilla, 129, 35, 0, 5, AdventureSupport::Playable, "Legacy dungeon; runtime validation pending.", 0},
    {"uldaman", "uldaman", "Uldaman", AdventureActivityKind::Dungeon, AdventureEra::Vanilla, 70, 35, 0, 5, AdventureSupport::Playable, "Legacy dungeon; runtime validation pending.", 0},
    {"zulfarrak", "zul_farrak", "Zul'Farrak", AdventureActivityKind::Dungeon, AdventureEra::Vanilla, 209, 44, 0, 5, AdventureSupport::Playable, "Legacy dungeon; runtime validation pending.", 0},
    {"maraudon", "maraudon", "Maraudon", AdventureActivityKind::Dungeon, AdventureEra::Vanilla, 349, 45, 0, 5, AdventureSupport::Playable, "Legacy dungeon; runtime validation pending.", 0},
    {"sunkentemple", "sunken_temple", "The Sunken Temple", AdventureActivityKind::Dungeon, AdventureEra::Vanilla, 109, 50, 0, 5, AdventureSupport::Playable, "Legacy dungeon; runtime validation pending.", 0},
    {"brd", "blackrock_depths", "Blackrock Depths", AdventureActivityKind::Dungeon, AdventureEra::Vanilla, 230, 52, 0, 5, AdventureSupport::Playable, "Large legacy dungeon; routing validation pending.", 0},
    {"lbrs", "lower_blackrock_spire", "Lower Blackrock Spire", AdventureActivityKind::Dungeon, AdventureEra::Vanilla, 229, 55, 0, 5, AdventureSupport::Playable, "Blackrock Spire routing validation pending.", 0},
    {"diremaul", "dire_maul", "Dire Maul", AdventureActivityKind::Dungeon, AdventureEra::Vanilla, 429, 55, 0, 5, AdventureSupport::Playable, "Multiple wings; routing validation pending.", 0},
    {"scholomance", "scholomance", "Scholomance", AdventureActivityKind::Dungeon, AdventureEra::Vanilla, 289, 58, 0, 5, AdventureSupport::Playable, "Legacy dungeon; runtime validation pending.", 0},
    {"stratholme", "stratholme", "Stratholme", AdventureActivityKind::Dungeon, AdventureEra::Vanilla, 329, 58, 0, 5, AdventureSupport::Playable, "Multiple routes; runtime validation pending.", 0},

    // ---------------------------------------------------------------------
    // VANILLA RAIDS
    // ---------------------------------------------------------------------
    {"moltencore", "molten_core", "Molten Core", AdventureActivityKind::Raid, AdventureEra::Vanilla, 409, 60, 0, 40, AdventureSupport::Ready, "Primary Vanilla opening raid.", 11502},
    {"zulgurub", "zul_gurub", "Zul'Gurub", AdventureActivityKind::Raid, AdventureEra::Vanilla, 309, 60, 3, 20, AdventureSupport::Ready, "20-player catch-up raid.", 14834},
    {"blackwinglair", "blackwing_lair", "Blackwing Lair", AdventureActivityKind::Raid, AdventureEra::Vanilla, 469, 60, 1, 40, AdventureSupport::Ready, "Unlocked by Molten Core progression.", 11583},
    {"aq20", "aq20", "Ruins of Ahn'Qiraj", AdventureActivityKind::Raid, AdventureEra::Vanilla, 509, 60, 5, 20, AdventureSupport::Ready, "Requires the Ahn'Qiraj war progression gate.", 15339},
    {"aq40", "aq40", "Temple of Ahn'Qiraj", AdventureActivityKind::Raid, AdventureEra::Vanilla, 531, 60, 5, 40, AdventureSupport::Ready, "Requires the Ahn'Qiraj war progression gate.", 15727},

    // ---------------------------------------------------------------------
    // THE BURNING CRUSADE DUNGEONS
    // ---------------------------------------------------------------------
    {"ramparts", "hellfire_ramparts", "Hellfire Ramparts", AdventureActivityKind::Dungeon, AdventureEra::Tbc, 543, 60, 8, 5, AdventureSupport::Ready, "Normal Playerbots dungeon play.", 0},
    {"bloodfurnace", "blood_furnace", "The Blood Furnace", AdventureActivityKind::Dungeon, AdventureEra::Tbc, 542, 60, 8, 5, AdventureSupport::Ready, "Normal Playerbots dungeon play.", 0},
    {"shatteredhalls", "shattered_halls", "The Shattered Halls", AdventureActivityKind::Dungeon, AdventureEra::Tbc, 540, 65, 8, 5, AdventureSupport::Ready, "Normal Playerbots dungeon play.", 0},
    {"slavepens", "slave_pens", "The Slave Pens", AdventureActivityKind::Dungeon, AdventureEra::Tbc, 547, 60, 8, 5, AdventureSupport::Ready, "Normal Playerbots dungeon play.", 0},
    {"underbog", "underbog", "The Underbog", AdventureActivityKind::Dungeon, AdventureEra::Tbc, 546, 61, 8, 5, AdventureSupport::Ready, "Normal Playerbots dungeon play.", 0},
    {"steamvault", "steamvault", "The Steamvault", AdventureActivityKind::Dungeon, AdventureEra::Tbc, 545, 65, 8, 5, AdventureSupport::Ready, "Normal Playerbots dungeon play.", 0},
    {"manatombs", "mana_tombs", "Mana-Tombs", AdventureActivityKind::Dungeon, AdventureEra::Tbc, 557, 62, 8, 5, AdventureSupport::Ready, "Normal Playerbots dungeon play.", 0},
    {"auchenai", "auchenai_crypts", "Auchenai Crypts", AdventureActivityKind::Dungeon, AdventureEra::Tbc, 558, 63, 8, 5, AdventureSupport::Ready, "Playerbots has an Auchindoun strategy.", 0},
    {"sethekk", "sethekk_halls", "Sethekk Halls", AdventureActivityKind::Dungeon, AdventureEra::Tbc, 556, 65, 8, 5, AdventureSupport::Ready, "Playerbots has a Sethekk strategy.", 0},
    {"shadowlab", "shadow_labyrinth", "Shadow Labyrinth", AdventureActivityKind::Dungeon, AdventureEra::Tbc, 555, 67, 8, 5, AdventureSupport::Ready, "Normal Playerbots dungeon play.", 0},
    {"oldhillsbrad", "old_hillsbrad", "Old Hillsbrad Foothills", AdventureActivityKind::Dungeon, AdventureEra::Tbc, 560, 66, 8, 5, AdventureSupport::Ready, "Normal Playerbots dungeon play.", 0},
    {"blackmorass", "black_morass", "The Black Morass", AdventureActivityKind::Dungeon, AdventureEra::Tbc, 269, 68, 8, 5, AdventureSupport::Ready, "Normal Playerbots dungeon play.", 0},
    {"mechanar", "mechanar", "The Mechanar", AdventureActivityKind::Dungeon, AdventureEra::Tbc, 554, 68, 8, 5, AdventureSupport::Ready, "Normal Playerbots dungeon play.", 0},
    {"botanica", "botanica", "The Botanica", AdventureActivityKind::Dungeon, AdventureEra::Tbc, 553, 68, 8, 5, AdventureSupport::Ready, "Normal Playerbots dungeon play.", 0},
    {"arcatraz", "arcatraz", "The Arcatraz", AdventureActivityKind::Dungeon, AdventureEra::Tbc, 552, 68, 8, 5, AdventureSupport::Ready, "Normal Playerbots dungeon play.", 0},
    {"magisters", "magisters_terrace", "Magisters' Terrace", AdventureActivityKind::Dungeon, AdventureEra::Tbc, 585, 70, 12, 5, AdventureSupport::Ready, "Late-TBC dungeon; progression gated.", 0},

    // ---------------------------------------------------------------------
    // THE BURNING CRUSADE RAIDS
    // ---------------------------------------------------------------------
    {"karazhan", "karazhan", "Karazhan", AdventureActivityKind::Raid, AdventureEra::Tbc, 532, 70, 8, 10, AdventureSupport::Ready, "Completable; Chess remains a manual/solo exception.", 15690},
    {"gruul", "gruul", "Gruul's Lair", AdventureActivityKind::Raid, AdventureEra::Tbc, 565, 70, 8, 25, AdventureSupport::Ready, "Completable with implemented strategies.", 19044},
    {"magtheridon", "magtheridon", "Magtheridon's Lair", AdventureActivityKind::Raid, AdventureEra::Tbc, 544, 70, 8, 25, AdventureSupport::Ready, "Completable with implemented strategies.", 17257},
    {"ssc", "serpentshrine", "Serpentshrine Cavern", AdventureActivityKind::Raid, AdventureEra::Tbc, 548, 70, 9, 25, AdventureSupport::Ready, "Completable with implemented strategies.", 21212},
    {"tempestkeep", "tempest_keep", "Tempest Keep", AdventureActivityKind::Raid, AdventureEra::Tbc, 550, 70, 9, 25, AdventureSupport::Ready, "Completable with implemented strategies.", 19622},
    {"hyjal", "hyjal", "Hyjal Summit", AdventureActivityKind::Raid, AdventureEra::Tbc, 534, 70, 10, 25, AdventureSupport::Ready, "Completable with implemented strategies.", 17968},
    {"blacktemple", "black_temple", "Black Temple", AdventureActivityKind::Raid, AdventureEra::Tbc, 564, 70, 10, 25, AdventureSupport::Ready, "Completable with implemented strategies.", 22917},
    {"zulaman", "zulaman", "Zul'Aman", AdventureActivityKind::Raid, AdventureEra::Tbc, 568, 70, 12, 10, AdventureSupport::Ready, "Completable with implemented strategies; actual ZA progression requirement is configurable.", 23863},
    {"sunwell", "sunwell", "Sunwell Plateau", AdventureActivityKind::Raid, AdventureEra::Tbc, 580, 70, 12, 25, AdventureSupport::Playable, "Upstream remains WIP; runtime validation required.", 25315},

    // ---------------------------------------------------------------------
    // WRATH OF THE LICH KING DUNGEONS
    // ---------------------------------------------------------------------
    {"utgardekeep", "utgarde_keep", "Utgarde Keep", AdventureActivityKind::Dungeon, AdventureEra::Wotlk, 574, 68, 13, 5, AdventureSupport::Ready, "Documented Playerbots strategy.", 0},
    {"nexus", "nexus", "The Nexus", AdventureActivityKind::Dungeon, AdventureEra::Wotlk, 576, 68, 13, 5, AdventureSupport::Ready, "Documented Playerbots strategy.", 0},
    {"azjol", "azjol_nerub", "Azjol-Nerub", AdventureActivityKind::Dungeon, AdventureEra::Wotlk, 601, 68, 13, 5, AdventureSupport::Ready, "Documented Playerbots strategy.", 0},
    {"ahnkahet", "ahnkahet", "Ahn'kahet: The Old Kingdom", AdventureActivityKind::Dungeon, AdventureEra::Wotlk, 619, 68, 13, 5, AdventureSupport::Ready, "Documented Playerbots strategy.", 0},
    {"draktharon", "drak_tharon", "Drak'Tharon Keep", AdventureActivityKind::Dungeon, AdventureEra::Wotlk, 600, 72, 13, 5, AdventureSupport::Ready, "Documented Playerbots strategy.", 0},
    {"violethold", "violet_hold", "The Violet Hold", AdventureActivityKind::Dungeon, AdventureEra::Wotlk, 608, 73, 13, 5, AdventureSupport::Ready, "Documented Playerbots strategy.", 0},
    {"gundrak", "gundrak", "Gundrak", AdventureActivityKind::Dungeon, AdventureEra::Wotlk, 604, 74, 13, 5, AdventureSupport::Ready, "Documented Playerbots strategy.", 0},
    {"hallsofstone", "halls_of_stone", "Halls of Stone", AdventureActivityKind::Dungeon, AdventureEra::Wotlk, 599, 75, 13, 5, AdventureSupport::Ready, "Documented Playerbots strategy.", 0},
    {"hallsoflightning", "halls_of_lightning", "Halls of Lightning", AdventureActivityKind::Dungeon, AdventureEra::Wotlk, 602, 77, 13, 5, AdventureSupport::Ready, "Documented Playerbots strategy.", 0},
    {"oculus", "oculus", "The Oculus", AdventureActivityKind::Dungeon, AdventureEra::Wotlk, 578, 77, 13, 5, AdventureSupport::Ready, "Documented Playerbots strategy.", 0},
    {"utgardepinnacle", "utgarde_pinnacle", "Utgarde Pinnacle", AdventureActivityKind::Dungeon, AdventureEra::Wotlk, 575, 77, 13, 5, AdventureSupport::Ready, "Documented Playerbots strategy.", 0},
    {"culling", "culling", "The Culling of Stratholme", AdventureActivityKind::Dungeon, AdventureEra::Wotlk, 595, 78, 13, 5, AdventureSupport::Ready, "Documented Playerbots strategy.", 0},
    {"trial", "trial_champion", "Trial of the Champion", AdventureActivityKind::Dungeon, AdventureEra::Wotlk, 650, 80, 15, 5, AdventureSupport::Ready, "Documented Playerbots strategy.", 0},
    {"forgeofsouls", "forge_souls", "The Forge of Souls", AdventureActivityKind::Dungeon, AdventureEra::Wotlk, 632, 80, 16, 5, AdventureSupport::Ready, "Documented Playerbots strategy.", 0},
    {"pitofsaron", "pit_saron", "Pit of Saron", AdventureActivityKind::Dungeon, AdventureEra::Wotlk, 658, 80, 16, 5, AdventureSupport::Ready, "Frozen Halls quest chain required.", 0},
    {"hallsofreflection", "halls_reflection", "Halls of Reflection", AdventureActivityKind::Dungeon, AdventureEra::Wotlk, 668, 80, 16, 5, AdventureSupport::Playable, "Travel supported; escape/wave flow still needs runtime validation.", 0},

    // ---------------------------------------------------------------------
    // WRATH OF THE LICH KING RAIDS
    // ---------------------------------------------------------------------
    {"naxxramas", "naxxramas", "Naxxramas", AdventureActivityKind::Raid, AdventureEra::Wotlk, 533, 80, 13, 10, AdventureSupport::Ready, "Completable; most encounters have strategies.", 15990},
    {"obsidiansanctum", "obsidian_sanctum", "The Obsidian Sanctum", AdventureActivityKind::Raid, AdventureEra::Wotlk, 615, 80, 13, 10, AdventureSupport::Ready, "Completable up to two drakes; Vesperon-first caveat applies.", 28860},
    {"eyeofeternity", "eye_of_eternity", "The Eye of Eternity", AdventureActivityKind::Raid, AdventureEra::Wotlk, 616, 80, 13, 10, AdventureSupport::Ready, "Completable with Malygos strategy.", 28859},
    {"onyxia", "onyxia", "Onyxia's Lair", AdventureActivityKind::Raid, AdventureEra::Wotlk, 249, 80, 13, 10, AdventureSupport::Ready, "WotLK Onyxia encounter.", 10184},
    {"vault", "vault_archavon", "Vault of Archavon", AdventureActivityKind::Raid, AdventureEra::Wotlk, 624, 80, 13, 10, AdventureSupport::Playable, "Partial strategy coverage.", 38433},
    {"ulduar", "ulduar", "Ulduar", AdventureActivityKind::Raid, AdventureEra::Wotlk, 603, 80, 14, 10, AdventureSupport::Playable, "Broad strategy coverage; runtime validation pending.", 33288},
    {"toc", "trial_crusader", "Trial of the Crusader", AdventureActivityKind::Raid, AdventureEra::Wotlk, 649, 80, 15, 10, AdventureSupport::NotReady, "Needs additional encounter strategy coverage.", 34564},
    {"icc", "icecrown", "Icecrown Citadel", AdventureActivityKind::Raid, AdventureEra::Wotlk, 631, 80, 16, 10, AdventureSupport::Ready, "Normal mode completable with implemented strategies.", 36597},
    {"rubysanctum", "ruby_sanctum", "Ruby Sanctum", AdventureActivityKind::Raid, AdventureEra::Wotlk, 724, 80, 17, 10, AdventureSupport::Playable, "Runtime validation pending.", 39863},
};
}

namespace AdventureCatalog
{
std::vector<AdventureActivity> const& All()
{
    return Activities;
}

AdventureActivity const* Find(std::string const& value)
{
    std::string wanted = Normalize(value);
    for (AdventureActivity const& activity : Activities)
    {
        if (wanted == Normalize(activity.alias) || wanted == Normalize(activity.composerId) || wanted == Normalize(activity.name))
            return &activity;
    }
    return nullptr;
}

AdventureActivity const* FindComposer(std::string const& value)
{
    std::string wanted = Normalize(value);
    for (AdventureActivity const& activity : Activities)
        if (wanted == Normalize(activity.composerId))
            return &activity;
    return nullptr;
}

AdventureEra CurrentRealmEra()
{
    return EraPolicy::CurrentRealmEra();
}

char const* EraName(AdventureEra era)
{
    return EraPolicy::Name(era);
}

uint8 EraLevelCap(AdventureEra era)
{
    return EraPolicy::LevelCap(era);
}

bool IsEraReleased(AdventureEra era)
{
    return EraPolicy::IsEraReleased(era);
}

std::string ProgressionRequirementText(uint8 requiredProgression)
{
    switch (requiredProgression)
    {
        case PROGRESSION_START: return "Available from the start of Vanilla.";
        case PROGRESSION_MOLTEN_CORE: return "Defeat Ragnaros in Molten Core.";
        case PROGRESSION_ONYXIA: return "Defeat Onyxia.";
        case PROGRESSION_BLACKWING_LAIR: return "Defeat Nefarian in Blackwing Lair.";
        case PROGRESSION_PRE_AQ: return "Reach the Ahn'Qiraj pre-war progression milestone.";
        case PROGRESSION_AQ_WAR: return "Complete the Ahn'Qiraj war progression gate.";
        case PROGRESSION_AQ: return "Defeat C'Thun in Temple of Ahn'Qiraj.";
        case PROGRESSION_NAXX40: return "Complete the final Vanilla Naxxramas progression milestone.";
        case PROGRESSION_PRE_TBC: return "Complete Vanilla progression and open the Dark Portal.";
        case PROGRESSION_TBC_TIER_1: return "Defeat Prince Malchezaar in Karazhan.";
        case PROGRESSION_TBC_TIER_2: return "Defeat Kael'thas Sunstrider in Tempest Keep.";
        case PROGRESSION_TBC_TIER_4: return "Defeat Illidan Stormrage in Black Temple.";
        case PROGRESSION_TBC_TIER_5: return "Defeat Kil'jaeden in Sunwell Plateau.";
        case PROGRESSION_WOTLK_TIER_1: return "Defeat Kel'Thuzad in Naxxramas.";
        case PROGRESSION_WOTLK_TIER_2: return "Defeat Yogg-Saron in Ulduar.";
        case PROGRESSION_WOTLK_TIER_3: return "Defeat Anub'arak in Trial of the Crusader.";
        case PROGRESSION_WOTLK_TIER_4: return "Defeat The Lich King in Icecrown Citadel.";
        case PROGRESSION_WOTLK_TIER_5: return "Defeat Halion in Ruby Sanctum.";
        default: return "Advance the current expansion progression.";
    }
}

bool IsUnlocked(Player* player, AdventureActivity const& activity, std::string& reason)
{
    if (!player)
    {
        reason = "No player is available.";
        return false;
    }

    if (!IsEraReleased(activity.era))
    {
        reason = std::string(EraName(activity.era)) + " is not released on this realm yet.";
        return false;
    }

    if (player->GetLevel() < activity.minLevel)
    {
        reason = std::string("Requires level ") + std::to_string(activity.minLevel) + ".";
        return false;
    }

    uint8 requiredProgression = activity.minProgression;
    if (std::string(activity.composerId) == "zul_gurub")
        requiredProgression = sIndividualProgression->RequiredZulGurubProgression;
    else if (std::string(activity.composerId) == "zulaman")
        requiredProgression = sIndividualProgression->RequiredZulAmanProgression;

    uint8 const progression = sIndividualProgression->GetPlayerProgressionFromQuests(player);
    if (progression < requiredProgression)
    {
        reason = ProgressionRequirementText(requiredProgression) +
            " Your progression is " + std::to_string(progression) + "; required stage is " +
            std::to_string(requiredProgression) + ".";
        return false;
    }

    reason.clear();
    return true;
}

char const* SupportLabel(AdventureSupport support)
{
    switch (support)
    {
        case AdventureSupport::Ready: return "Guild Ready";
        case AdventureSupport::Playable: return "Playable / experimental";
        case AdventureSupport::NotReady: return "Not Ready";
        default: return "Unknown";
    }
}

char const* SupportIcon(AdventureSupport support)
{
    switch (support)
    {
        case AdventureSupport::Ready: return "[GREEN]";
        case AdventureSupport::Playable: return "[YELLOW]";
        case AdventureSupport::NotReady: return "[RED]";
        default: return "[?]";
    }
}
}
