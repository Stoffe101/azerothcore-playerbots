#ifndef MOD_RAID_ROSTER_CONFIG_H
#define MOD_RAID_ROSTER_CONFIG_H

#include "Define.h"

extern bool g_RaidRosterEnable;

// New-player bootstrap for this fork. Kept separate from raid-roster behaviour so it can be
// disabled independently without affecting persistent raid bots.
extern bool g_AdventureStartEnable;
extern uint8 g_AdventureStartDefaultProfile; // 0 = TBC adventure, 1 = TBC raid-ready, 2 = WotLK raid-ready
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

// TBC max-level/raid-ready profile. It remains at stage 8 so Karazhan/Gruul/Mag are still the
// first progression raids; this is a convenience gear/level shortcut, not a progression skip.
extern uint32 g_AdventureStartTbcRaidReadyLevel;
extern uint8 g_AdventureStartTbcRaidReadyProgression;
extern uint32 g_AdventureStartTbcRaidReadyStartingGold;
extern uint32 g_AdventureStartTbcRaidReadyBasicGearItemLevel;
extern uint32 g_AdventureStartTbcRaidReadyGearItemLevel;
extern bool g_AdventureStartTbcRaidReadyTeleport;
extern uint32 g_AdventureStartTbcRaidReadyTeleportMap;
extern float g_AdventureStartTbcRaidReadyTeleportX;
extern float g_AdventureStartTbcRaidReadyTeleportY;
extern float g_AdventureStartTbcRaidReadyTeleportZ;
extern float g_AdventureStartTbcRaidReadyTeleportO;

// WotLK max-level/raid-ready profile. This is only exposed by the Admin Panel after WotLK has
// actually been released. Stage 13 opens Northrend/Naxx without skipping the Wrath raid ladder.
extern uint32 g_AdventureStartWotlkRaidReadyLevel;
extern uint8 g_AdventureStartWotlkRaidReadyProgression;
extern uint32 g_AdventureStartWotlkRaidReadyStartingGold;
extern uint32 g_AdventureStartWotlkRaidReadyBasicGearItemLevel;
extern uint32 g_AdventureStartWotlkRaidReadyGearItemLevel;
extern bool g_AdventureStartWotlkRaidReadyTeleport;
extern uint32 g_AdventureStartWotlkRaidReadyTeleportMap;
extern float g_AdventureStartWotlkRaidReadyTeleportX;
extern float g_AdventureStartWotlkRaidReadyTeleportY;
extern float g_AdventureStartWotlkRaidReadyTeleportZ;
extern float g_AdventureStartWotlkRaidReadyTeleportO;

void RaidRosterLoadConfig();
#endif
