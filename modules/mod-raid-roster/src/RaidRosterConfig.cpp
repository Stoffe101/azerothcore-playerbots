#include "RaidRosterConfig.h"
#include "Config.h"
#include "Log.h"

bool g_RaidRosterEnable = false;

bool g_AdventureStartEnable = true;
uint32 g_AdventureStartLevel = 60;
uint8 g_AdventureStartProgression = 8;
bool g_AdventureStartRevealMap = true;
bool g_AdventureStartStarterKit = true;
uint32 g_AdventureStartStartingGold = 50;
bool g_AdventureStartAutoGear = true;
uint32 g_AdventureStartGearMinTalentPoints = 5;
uint32 g_AdventureStartGearItemLevel = 65;
bool g_AdventureProgressionCachesEnable = true;

void RaidRosterLoadConfig()
{
    g_RaidRosterEnable = sConfigMgr->GetOption<bool>("RaidRoster.Enable", false);

    g_AdventureStartEnable = sConfigMgr->GetOption<bool>("AdventureStart.Enable", true);
    g_AdventureStartLevel = sConfigMgr->GetOption<uint32>("AdventureStart.Level", 60);
    if (g_AdventureStartLevel < 1)
        g_AdventureStartLevel = 1;
    else if (g_AdventureStartLevel > 80)
        g_AdventureStartLevel = 80;

    uint32 progression = sConfigMgr->GetOption<uint32>("AdventureStart.Progression", 8);
    if (progression > 18)
        progression = 18;
    g_AdventureStartProgression = static_cast<uint8>(progression);

    g_AdventureStartRevealMap = sConfigMgr->GetOption<bool>("AdventureStart.RevealMap", true);
    g_AdventureStartStarterKit = sConfigMgr->GetOption<bool>("AdventureStart.StarterKit", true);
    g_AdventureStartStartingGold = sConfigMgr->GetOption<uint32>("AdventureStart.StartingGold", 50);
    if (g_AdventureStartStartingGold > 10000)
        g_AdventureStartStartingGold = 10000;

    g_AdventureStartAutoGear = sConfigMgr->GetOption<bool>("AdventureStart.AutoGear", true);
    g_AdventureStartGearMinTalentPoints = sConfigMgr->GetOption<uint32>("AdventureStart.GearMinTalentPoints", 5);
    if (g_AdventureStartGearMinTalentPoints < 1)
        g_AdventureStartGearMinTalentPoints = 1;
    else if (g_AdventureStartGearMinTalentPoints > 51)
        g_AdventureStartGearMinTalentPoints = 51;

    g_AdventureStartGearItemLevel = sConfigMgr->GetOption<uint32>("AdventureStart.GearItemLevel", 65);
    if (g_AdventureStartGearItemLevel < 55)
        g_AdventureStartGearItemLevel = 55;
    else if (g_AdventureStartGearItemLevel > 90)
        g_AdventureStartGearItemLevel = 90;

    g_AdventureProgressionCachesEnable = sConfigMgr->GetOption<bool>("AdventureProgression.Caches.Enable", true);

    LOG_INFO("server.loading", "[RaidRoster] Enable={}", g_RaidRosterEnable ? 1 : 0);
    LOG_INFO(
        "server.loading",
        "[AdventureStart] Enable={}, Level={}, Progression={}, RevealMap={}, StarterKit={}, StartingGold={}, "
        "AutoGear={}, GearMinTalentPoints={}, GearItemLevel={}, Caches={}",
        g_AdventureStartEnable ? 1 : 0,
        g_AdventureStartLevel,
        g_AdventureStartProgression,
        g_AdventureStartRevealMap ? 1 : 0,
        g_AdventureStartStarterKit ? 1 : 0,
        g_AdventureStartStartingGold,
        g_AdventureStartAutoGear ? 1 : 0,
        g_AdventureStartGearMinTalentPoints,
        g_AdventureStartGearItemLevel,
        g_AdventureProgressionCachesEnable ? 1 : 0);
}
