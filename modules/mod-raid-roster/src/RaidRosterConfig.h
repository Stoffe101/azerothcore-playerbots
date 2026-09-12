#ifndef MOD_RAID_ROSTER_CONFIG_H
#define MOD_RAID_ROSTER_CONFIG_H

#include "Define.h"

extern bool g_RaidRosterEnable;

extern bool g_AdventureStartEnable;
extern uint32 g_AdventureStartLevel;
extern uint8 g_AdventureStartProgression;
extern bool g_AdventureStartRevealMap;

extern bool g_GuildDirectorEnable;
extern bool g_GuildDirectorAutoTravel;
extern uint32 g_GuildDirectorReadyTimeoutMs;

// Smart guild loot. Fair mode lets bots Need genuine upgrades, Greed useful non-upgrades, and
// Pass unusable items by enabling the behaviour already implemented by Playerbots.
extern bool g_SmartLootEnable;
extern bool g_SmartLootBotNeedUpgrades;
extern bool g_SmartLootBotGreedUseful;
extern bool g_BadLuckProtectionEnable;
extern uint32 g_BadLuckUpgradeWindowSeconds;

void RaidRosterLoadConfig();
#endif
