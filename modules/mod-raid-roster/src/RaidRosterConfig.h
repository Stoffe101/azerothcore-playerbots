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

// Gold progression for players who prefer questing/dungeons/raids over professions.
// First-kill bounties are intentionally one-time per character/boss/map.
extern bool g_AdventureEconomyEnable;
extern uint32 g_AdventureEconomyDungeonBossFirstKillGold;
extern uint32 g_AdventureEconomyRaidBossFirstKillGold;

void RaidRosterLoadConfig();
#endif
