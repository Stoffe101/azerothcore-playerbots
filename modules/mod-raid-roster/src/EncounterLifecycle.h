#ifndef MOD_RAID_ROSTER_ENCOUNTER_LIFECYCLE_H
#define MOD_RAID_ROSTER_ENCOUNTER_LIFECYCLE_H

#include "Define.h"

class Player;

namespace EncounterLifecycle
{
    void Tick(uint32 diff);
    void PrepareGroup(Player* anchor);
}

void AddEncounterLifecycleScripts();

#endif
