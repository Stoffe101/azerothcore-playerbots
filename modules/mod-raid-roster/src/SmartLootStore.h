#ifndef MOD_RAID_ROSTER_SMART_LOOT_STORE_H
#define MOD_RAID_ROSTER_SMART_LOOT_STORE_H

#include "Define.h"

#include <vector>

struct BadLuckRow
{
    uint32 mapId = 0;
    uint32 bossEntry = 0;
    uint16 dryKills = 0;
};

namespace SmartLootStore
{
    bool PersonalLootEnabled(uint32 guid);
    void SetPersonalLootEnabled(uint32 guid, bool enabled);

    uint16 IncrementDryStreak(uint32 guid, uint32 mapId, uint32 bossEntry);
    void ResetDryStreak(uint32 guid, uint32 mapId, uint32 bossEntry);
    std::vector<BadLuckRow> LoadDryStreaks(uint32 guid);
}

#endif
