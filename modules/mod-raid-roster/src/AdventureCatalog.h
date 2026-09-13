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

struct AdventureActivity
{
    char const* alias;
    char const* name;
    AdventureActivityKind kind;
    uint32 instanceMap;
    uint8 minLevel;
    uint8 minProgression;
    uint8 preferredSize;
    AdventureSupport support;
    char const* supportNote;
};

namespace AdventureCatalog
{
    std::vector<AdventureActivity> const& All();
    AdventureActivity const* Find(std::string const& value);
    bool IsUnlocked(Player* player, AdventureActivity const& activity, std::string& reason);
    char const* SupportLabel(AdventureSupport support);
    char const* SupportIcon(AdventureSupport support);
}

#endif
