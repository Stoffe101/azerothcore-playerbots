#ifndef MOD_RAID_ROSTER_ADVENTURE_PROGRESSION_STORE_H
#define MOD_RAID_ROSTER_ADVENTURE_PROGRESSION_STORE_H

#include "Define.h"

namespace AdventureProgressionStore
{
struct State
{
    bool starterInitialized = false;
    bool starterGearGranted = false;
    uint8 starterSpecTab = 255;
    uint16 pendingCaches = 0;
    uint8 lastLevelCache = 0;
};

State LoadOrCreate(uint32 playerGuid);
void MarkStarterInitialized(uint32 playerGuid);
void MarkStarterGearGranted(uint32 playerGuid, uint8 specTab);
void AddPendingCache(uint32 playerGuid, uint16 count = 1);
bool ConsumePendingCache(uint32 playerGuid);
void SetLastLevelCache(uint32 playerGuid, uint8 level);
}

#endif
