#ifndef MOD_RAID_ROSTER_ADVENTURE_CONTROL_STORE_H
#define MOD_RAID_ROSTER_ADVENTURE_CONTROL_STORE_H

#include "Define.h"

struct AdventureControlRates
{
    uint16 xpPercent = 100;
    uint16 goldPercent = 100;
    uint16 repPercent = 100;
};

namespace AdventureControlStore
{
    AdventureControlRates Load(uint32 guid);
    AdventureControlRates Get(uint32 guid);
    void Save(uint32 guid, AdventureControlRates const& rates);
    void Forget(uint32 guid);
}

#endif
