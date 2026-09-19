#ifndef MOD_RAID_ROSTER_ADVENTURE_CATALOG_H
#define MOD_RAID_ROSTER_ADVENTURE_CATALOG_H

#include "Define.h"

#include <string>
#include <vector>

class Player;

enum class AdventureActivityKind : uint8
{
    Dungeon = 0,
    Raid = 1,
};

enum class AdventureSupport : uint8
{
    Ready = 0,
    Playable = 1,
    NotReady = 2,
};

enum class AdventureEra : uint8
{
    Vanilla = 0,
    Tbc = 1,
    Wotlk = 2,
};

struct AdventureActivity
{
    // alias is the short Adventure Guide command name. composerId is the stable Group Composer ID.
    char const* alias;
    char const* composerId;
    char const* name;
    AdventureActivityKind kind;
    AdventureEra era;
    uint32 instanceMap;
    uint8 minLevel;
    uint8 minProgression;
    uint8 preferredSize;
    AdventureSupport support;
    char const* supportNote;
    uint32 finalBossEntry; // 0 for dungeons/non-clear-tracked activities.
};

namespace AdventureCatalog
{
    std::vector<AdventureActivity> const& All();
    AdventureActivity const* Find(std::string const& value);
    AdventureActivity const* FindComposer(std::string const& value);

    AdventureEra CurrentRealmEra();
    char const* EraName(AdventureEra era);
    uint8 EraLevelCap(AdventureEra era);
    bool IsEraReleased(AdventureEra era);

    bool IsUnlocked(Player* player, AdventureActivity const& activity, std::string& reason);
    std::string ProgressionRequirementText(uint8 requiredProgression);
    char const* SupportLabel(AdventureSupport support);
    char const* SupportIcon(AdventureSupport support);
}

#endif
