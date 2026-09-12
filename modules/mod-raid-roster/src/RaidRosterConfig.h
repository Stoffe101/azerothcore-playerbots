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

// Natural guild-chat group director. Uses the persistent roster rather than creating a second
// population of disposable dungeon bots.
extern bool g_GuildDirectorEnable;
extern bool g_GuildDirectorAutoTravel;
extern uint32 g_GuildDirectorReadyTimeoutMs;

void RaidRosterLoadConfig();
#endif
