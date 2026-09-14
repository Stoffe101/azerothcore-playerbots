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

// This table is intentionally conservative. "Ready" means the content is allowed to appear in
// the normal Finder. Playable/WIP content remains visible to compatibility/roadmap tooling but is
// not offered as a one-click normal activity until this fork has actually validated it.
std::vector<AdventureActivity> const Activities = {
    // TBC dungeons.
    {"ramparts",       "Hellfire Ramparts",          AdventureActivityKind::Dungeon, 543, 60,  8,  5, AdventureSupport::Ready, "Normal Playerbots dungeon play."},
    {"bloodfurnace",   "The Blood Furnace",          AdventureActivityKind::Dungeon, 542, 60,  8,  5, AdventureSupport::Ready, "Normal Playerbots dungeon play."},
    {"shatteredhalls", "The Shattered Halls",        AdventureActivityKind::Dungeon, 540, 65,  8,  5, AdventureSupport::Ready, "Normal Playerbots dungeon play."},
    {"slavepens",      "The Slave Pens",             AdventureActivityKind::Dungeon, 547, 60,  8,  5, AdventureSupport::Ready, "Normal Playerbots dungeon play."},
    {"underbog",       "The Underbog",               AdventureActivityKind::Dungeon, 546, 61,  8,  5, AdventureSupport::Ready, "Normal Playerbots dungeon play."},
    {"steamvault",     "The Steamvault",             AdventureActivityKind::Dungeon, 545, 65,  8,  5, AdventureSupport::Ready, "Normal Playerbots dungeon play."},
    {"manatombs",      "Mana-Tombs",                 AdventureActivityKind::Dungeon, 557, 62,  8,  5, AdventureSupport::Ready, "Normal Playerbots dungeon play."},
    {"auchenai",       "Auchenai Crypts",            AdventureActivityKind::Dungeon, 558, 63,  8,  5, AdventureSupport::Ready, "Playerbots has an Auchindoun strategy."},
    {"sethekk",        "Sethekk Halls",              AdventureActivityKind::Dungeon, 556, 65,  8,  5, AdventureSupport::Ready, "Playerbots has a Sethekk strategy."},
    {"shadowlab",      "Shadow Labyrinth",           AdventureActivityKind::Dungeon, 555, 67,  8,  5, AdventureSupport::Ready, "Normal Playerbots dungeon play."},
    {"oldhillsbrad",   "Old Hillsbrad Foothills",    AdventureActivityKind::Dungeon, 560, 66,  8,  5, AdventureSupport::Ready, "Normal Playerbots dungeon play."},
    {"blackmorass",    "The Black Morass",           AdventureActivityKind::Dungeon, 269, 68,  8,  5, AdventureSupport::Ready, "Normal Playerbots dungeon play."},
    {"mechanar",       "The Mechanar",               AdventureActivityKind::Dungeon, 554, 68,  8,  5, AdventureSupport::Ready, "Normal Playerbots dungeon play."},
    {"botanica",       "The Botanica",               AdventureActivityKind::Dungeon, 553, 68,  8,  5, AdventureSupport::Ready, "Normal Playerbots dungeon play."},
    {"arcatraz",       "The Arcatraz",               AdventureActivityKind::Dungeon, 552, 68,  8,  5, AdventureSupport::Ready, "Normal Playerbots dungeon play."},
    {"magisters",      "Magisters' Terrace",         AdventureActivityKind::Dungeon, 585, 70, 12,  5, AdventureSupport::Ready, "Late-TBC dungeon; progression gated."},

    // WotLK dungeons with documented Playerbots strategy coverage.
    {"utgardekeep",    "Utgarde Keep",               AdventureActivityKind::Dungeon, 574, 68, 13,  5, AdventureSupport::Ready, "Documented Playerbots strategy."},
    {"nexus",          "The Nexus",                  AdventureActivityKind::Dungeon, 576, 68, 13,  5, AdventureSupport::Ready, "Documented Playerbots strategy."},
    {"azjol",          "Azjol-Nerub",                AdventureActivityKind::Dungeon, 601, 68, 13,  5, AdventureSupport::Ready, "Documented Playerbots strategy."},
    {"ahnkahet",       "Ahn'kahet: The Old Kingdom", AdventureActivityKind::Dungeon, 619, 68, 13,  5, AdventureSupport::Ready, "Documented Playerbots strategy."},
    {"draktharon",     "Drak'Tharon Keep",           AdventureActivityKind::Dungeon, 600, 72, 13,  5, AdventureSupport::Ready, "Documented Playerbots strategy."},
    {"violethold",     "The Violet Hold",            AdventureActivityKind::Dungeon, 608, 73, 13,  5, AdventureSupport::Ready, "Documented Playerbots strategy."},
    {"gundrak",        "Gundrak",                    AdventureActivityKind::Dungeon, 604, 74, 13,  5, AdventureSupport::Ready, "Documented Playerbots strategy."},
    {"hallsofstone",   "Halls of Stone",             AdventureActivityKind::Dungeon, 599, 75, 13,  5, AdventureSupport::Ready, "Documented Playerbots strategy."},
    {"hallsoflightning","Halls of Lightning",        AdventureActivityKind::Dungeon, 602, 77, 13,  5, AdventureSupport::Ready, "Documented Playerbots strategy."},
    {"oculus",         "The Oculus",                 AdventureActivityKind::Dungeon, 578, 77, 13,  5, AdventureSupport::Ready, "Documented Playerbots strategy."},
    {"utgardepinnacle","Utgarde Pinnacle",           AdventureActivityKind::Dungeon, 575, 77, 13,  5, AdventureSupport::Ready, "Documented Playerbots strategy."},
    {"culling",        "The Culling of Stratholme",  AdventureActivityKind::Dungeon, 595, 78, 13,  5, AdventureSupport::Ready, "Documented Playerbots strategy."},
    {"trial",          "Trial of the Champion",      AdventureActivityKind::Dungeon, 650, 80, 13,  5, AdventureSupport::Ready, "Documented Playerbots strategy."},
    {"forgeofsouls",   "The Forge of Souls",         AdventureActivityKind::Dungeon, 632, 80, 16,  5, AdventureSupport::Ready, "Documented Playerbots strategy."},
    {"pitofsaron",     "Pit of Saron",               AdventureActivityKind::Dungeon, 658, 80, 16,  5, AdventureSupport::Ready, "Documented Playerbots strategy."},
    {"hallsofreflection","Halls of Reflection",      AdventureActivityKind::Dungeon, 668, 80, 16,  5, AdventureSupport::Playable, "Travel is supported; keep out of the normal Finder until this fork validates the escape/wave flow."},

    // TBC raids. Current upstream completion guidance marks these as completable except Sunwell.
    {"karazhan",       "Karazhan",                    AdventureActivityKind::Raid, 532, 70,  8, 10, AdventureSupport::Ready, "Completable; Chess remains a manual/solo exception."},
    {"gruul",          "Gruul's Lair",                AdventureActivityKind::Raid, 565, 70,  8, 25, AdventureSupport::Ready, "Completable with implemented strategies."},
    {"magtheridon",    "Magtheridon's Lair",         AdventureActivityKind::Raid, 544, 70,  8, 25, AdventureSupport::Ready, "Completable with implemented strategies."},
    {"ssc",            "Serpentshrine Cavern",       AdventureActivityKind::Raid, 548, 70,  9, 25, AdventureSupport::Ready, "Completable with implemented strategies."},
    {"tempestkeep",    "Tempest Keep",               AdventureActivityKind::Raid, 550, 70,  9, 25, AdventureSupport::Ready, "Completable with implemented strategies."},
    {"hyjal",          "Hyjal Summit",               AdventureActivityKind::Raid, 534, 70, 10, 25, AdventureSupport::Ready, "Completable with implemented strategies."},
    {"blacktemple",    "Black Temple",               AdventureActivityKind::Raid, 564, 70, 10, 25, AdventureSupport::Ready, "Completable with implemented strategies."},
    {"zulaman",        "Zul'Aman",                   AdventureActivityKind::Raid, 568, 70, 12, 10, AdventureSupport::Ready, "Completable with implemented strategies; actual ZA progression requirement is configurable."},
    {"sunwell",        "Sunwell Plateau",            AdventureActivityKind::Raid, 580, 70, 12, 25, AdventureSupport::Playable, "Upstream remains WIP. This fork has inherited Sunwell patches but will not call it Guild Ready until runtime-tested."},

    // WotLK raids. Only upstream-completable normal-mode content is Finder Ready.
    {"naxxramas",      "Naxxramas",                   AdventureActivityKind::Raid, 533, 80, 13, 10, AdventureSupport::Ready, "Completable; most encounters have strategies."},
    {"obsidiansanctum","The Obsidian Sanctum",       AdventureActivityKind::Raid, 615, 80, 13, 10, AdventureSupport::Ready, "Completable up to two drakes; Vesperon-first caveat applies."},
    {"eyeofeternity",  "The Eye of Eternity",        AdventureActivityKind::Raid, 616, 80, 13, 10, AdventureSupport::Ready, "Completable with Malygos strategy."},
    {"onyxia",         "Onyxia's Lair",              AdventureActivityKind::Raid, 249, 80, 13, 10, AdventureSupport::Ready, "Completable with Onyxia strategy."},
    {"vault",          "Vault of Archavon",          AdventureActivityKind::Raid, 624, 80, 13, 10, AdventureSupport::Playable, "WIP; only partial strategy coverage."},
    {"ulduar",         "Ulduar",                     AdventureActivityKind::Raid, 603, 80, 14, 10, AdventureSupport::Playable, "WIP; broad strategy coverage but not yet a normal Finder activity."},
    {"toc",            "Trial of the Crusader",      AdventureActivityKind::Raid, 649, 80, 15, 10, AdventureSupport::NotReady, "WIP and needs strategies."},
    {"icc",            "Icecrown Citadel",           AdventureActivityKind::Raid, 631, 80, 16, 10, AdventureSupport::Ready, "Normal mode completable with implemented strategies."},
    {"rubysanctum",    "Ruby Sanctum",               AdventureActivityKind::Raid, 724, 80, 17, 10, AdventureSupport::Playable, "WIP; keep out of the normal Finder until validated."},
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
        if (wanted == Normalize(activity.alias) || wanted == Normalize(activity.name))
            return &activity;
    }
    return nullptr;
}

bool IsUnlocked(Player* player, AdventureActivity const& activity, std::string& reason)
{
    if (!player)
    {
        reason = "No player is available.";
        return false;
    }

    if (player->GetLevel() < activity.minLevel)
    {
        reason = std::string(activity.name) + " requires level " + std::to_string(activity.minLevel) + ".";
        return false;
    }

    uint8 requiredProgression = activity.minProgression;
    if (std::string(activity.alias) == "zulaman")
        requiredProgression = sIndividualProgression->RequiredZulAmanProgression;

    uint8 progression = sIndividualProgression->GetPlayerProgressionFromQuests(player);
    if (progression < requiredProgression)
    {
        reason = std::string(activity.name) + " is locked by your current progression tier.";
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
