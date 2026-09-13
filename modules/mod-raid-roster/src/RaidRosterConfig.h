#ifndef MOD_RAID_ROSTER_CONFIG_H
#define MOD_RAID_ROSTER_CONFIG_H

#include "Define.h"

extern bool g_RaidRosterEnable;

// New-player bootstrap for this fork. Kept separate from raid-roster behaviour so it can be
// disabled independently without affecting persistent raid bots.
extern bool g_AdventureStartEnable;
extern uint8 g_AdventureStartDefaultProfile; // 0 = TBC adventure, 1 = WotLK raid-ready
extern uint32 g_AdventureStartLevel;
extern uint8 g_AdventureStartProgression;
extern bool g_AdventureStartRevealMap;
extern bool g_AdventureStartTeleport;
extern uint32 g_AdventureStartTeleportMap;
extern float g_AdventureStartTeleportX;
extern float g_AdventureStartTeleportY;
extern float g_AdventureStartTeleportZ;
extern float g_AdventureStartTeleportO;

// TBC starter package. The first gear set is modest and immediate; the second pass waits for
// talent investment so Playerbots' spec bridge can choose role-appropriate late-Vanilla epics.
extern bool g_AdventureStartStarterKit;
extern uint32 g_AdventureStartStartingGold;
extern bool g_AdventureStartBasicGear;
extern uint32 g_AdventureStartBasicGearItemLevel;
extern bool g_AdventureStartAutoGear;
extern uint32 g_AdventureStartGearMinTalentPoints;
extern uint32 g_AdventureStartGearItemLevel;

// Optional WotLK max-level/raid-ready start profile. It keeps progression at stage 13 so Naxxramas
// is the first raid rather than silently marking the whole expansion complete.
extern uint32 g_AdventureStartRaidReadyLevel;
extern uint8 g_AdventureStartRaidReadyProgression;
extern uint32 g_AdventureStartRaidReadyStartingGold;
extern uint32 g_AdventureStartRaidReadyBasicGearItemLevel;
extern uint32 g_AdventureStartRaidReadyGearItemLevel;
extern bool g_AdventureStartRaidReadyTeleport;
extern uint32 g_AdventureStartRaidReadyTeleportMap;
extern float g_AdventureStartRaidReadyTeleportX;
extern float g_AdventureStartRaidReadyTeleportY;
extern float g_AdventureStartRaidReadyTeleportZ;
extern float g_AdventureStartRaidReadyTeleportO;

void RaidRosterLoadConfig();
#endif
