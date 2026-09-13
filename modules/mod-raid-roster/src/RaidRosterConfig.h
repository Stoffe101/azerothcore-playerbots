#ifndef MOD_RAID_ROSTER_CONFIG_H
#define MOD_RAID_ROSTER_CONFIG_H

#include "Define.h"

extern bool g_RaidRosterEnable;

// New-player bootstrap for this fork. Kept separate from raid-roster behaviour so it can be
// disabled independently without affecting persistent raid bots.
extern bool g_AdventureStartEnable;
extern uint32 g_AdventureStartLevel;
extern uint8 g_AdventureStartProgression;
extern bool g_AdventureStartRevealMap;
extern bool g_AdventureStartTeleport;
extern uint32 g_AdventureStartTeleportMap;
extern float g_AdventureStartTeleportX;
extern float g_AdventureStartTeleportY;
extern float g_AdventureStartTeleportZ;
extern float g_AdventureStartTeleportO;

void RaidRosterLoadConfig();
#endif
