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

extern bool g_AdventureStartStarterKit;
extern uint32 g_AdventureStartStartingGold;
extern bool g_AdventureStartBasicGear;
extern uint32 g_AdventureStartBasicGearItemLevel;
extern bool g_AdventureStartAutoGear;
extern uint32 g_AdventureStartGearMinTalentPoints;
extern uint32 g_AdventureStartGearItemLevel;

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

// Player-facing activity assembly and recovery systems.
extern bool g_GuildDirectorEnable;
extern bool g_GuildDirectorAutoTravel;
extern uint32 g_GuildDirectorReadyTimeoutMs;

extern bool g_EncounterLifecycleEnable;
extern bool g_WipeRecoveryEnable;
extern uint32 g_WipeRecoveryDelayMs;
extern bool g_WipeRecoveryResurrectHumans;
extern bool g_AutoPrepEnable;
extern bool g_AutoPrepRefillConsumables;
extern bool g_AutoPrepWarlockSupport;
extern bool g_AutoPrepSmartPets;

extern bool g_SmartLootEnable;
extern bool g_SmartLootBotNeedUpgrades;
extern bool g_SmartLootBotGreedUseful;
extern bool g_BadLuckProtectionEnable;
extern uint32 g_BadLuckUpgradeWindowSeconds;

extern bool g_AdventureEconomyEnable;
extern uint32 g_AdventureEconomyDungeonBossFirstKillGold;
extern uint32 g_AdventureEconomyRaidBossFirstKillGold;

void RaidRosterLoadConfig();
#endif
