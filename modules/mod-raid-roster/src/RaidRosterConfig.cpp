#include "RaidRosterConfig.h"
#include "Config.h"
#include "Log.h"

bool g_RaidRosterEnable = false;

bool g_AdventureStartEnable = true;
uint32 g_AdventureStartLevel = 60;
uint8 g_AdventureStartProgression = 8;
bool g_AdventureStartRevealMap = true;
bool g_AdventureStartTeleport = true;
uint32 g_AdventureStartTeleportMap = 0;
float g_AdventureStartTeleportX = -11894.80f;
float g_AdventureStartTeleportY = -3206.52f;
float g_AdventureStartTeleportZ = -14.62f;
float g_AdventureStartTeleportO = 0.0f;
bool g_AdventureStartStarterKit = true;
uint32 g_AdventureStartStartingGold = 50;
bool g_AdventureStartBasicGear = true;
uint32 g_AdventureStartBasicGearItemLevel = 58;
bool g_AdventureStartAutoGear = true;
uint32 g_AdventureStartGearMinTalentPoints = 5;
uint32 g_AdventureStartGearItemLevel = 65;

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
    g_AdventureStartTeleport = sConfigMgr->GetOption<bool>("AdventureStart.Teleport.Enable", true);
    g_AdventureStartTeleportMap = sConfigMgr->GetOption<uint32>("AdventureStart.Teleport.Map", 0);
    g_AdventureStartTeleportX = sConfigMgr->GetOption<float>("AdventureStart.Teleport.X", -11894.80f);
    g_AdventureStartTeleportY = sConfigMgr->GetOption<float>("AdventureStart.Teleport.Y", -3206.52f);
    g_AdventureStartTeleportZ = sConfigMgr->GetOption<float>("AdventureStart.Teleport.Z", -14.62f);
    g_AdventureStartTeleportO = sConfigMgr->GetOption<float>("AdventureStart.Teleport.O", 0.0f);

    g_AdventureStartStarterKit = sConfigMgr->GetOption<bool>("AdventureStart.StarterKit", true);
    g_AdventureStartStartingGold = sConfigMgr->GetOption<uint32>("AdventureStart.StartingGold", 50);
    if (g_AdventureStartStartingGold > 10000)
        g_AdventureStartStartingGold = 10000;

    g_AdventureStartBasicGear = sConfigMgr->GetOption<bool>("AdventureStart.BasicGear", true);
    g_AdventureStartBasicGearItemLevel = sConfigMgr->GetOption<uint32>("AdventureStart.BasicGearItemLevel", 58);
    if (g_AdventureStartBasicGearItemLevel < 1)
        g_AdventureStartBasicGearItemLevel = 1;
    else if (g_AdventureStartBasicGearItemLevel > 200)
        g_AdventureStartBasicGearItemLevel = 200;

    g_AdventureStartAutoGear = sConfigMgr->GetOption<bool>("AdventureStart.AutoGear", true);
    g_AdventureStartGearMinTalentPoints = sConfigMgr->GetOption<uint32>("AdventureStart.GearMinTalentPoints", 5);
    if (g_AdventureStartGearMinTalentPoints > 61)
        g_AdventureStartGearMinTalentPoints = 61;

    g_AdventureStartGearItemLevel = sConfigMgr->GetOption<uint32>("AdventureStart.GearItemLevel", 65);
    if (g_AdventureStartGearItemLevel < 1)
        g_AdventureStartGearItemLevel = 1;
    else if (g_AdventureStartGearItemLevel > 200)
        g_AdventureStartGearItemLevel = 200;

    LOG_INFO("server.loading", "[RaidRoster] Enable={}", g_RaidRosterEnable ? 1 : 0);
    LOG_INFO(
        "server.loading",
        "[AdventureStart] Enable={}, Level={}, Progression={}, RevealMap={}, Teleport={}, Map={}, XYZ=({:.2f},{:.2f},{:.2f}), O={:.2f}, StarterKit={}, Gold={}g, BasicGear={}@{}, SpecGear={} after {} pts @{}",
        g_AdventureStartEnable ? 1 : 0,
        g_AdventureStartLevel,
        g_AdventureStartProgression,
        g_AdventureStartRevealMap ? 1 : 0,
        g_AdventureStartTeleport ? 1 : 0,
        g_AdventureStartTeleportMap,
        g_AdventureStartTeleportX,
        g_AdventureStartTeleportY,
        g_AdventureStartTeleportZ,
        g_AdventureStartTeleportO,
        g_AdventureStartStarterKit ? 1 : 0,
        g_AdventureStartStartingGold,
        g_AdventureStartBasicGear ? 1 : 0,
        g_AdventureStartBasicGearItemLevel,
        g_AdventureStartAutoGear ? 1 : 0,
        g_AdventureStartGearMinTalentPoints,
        g_AdventureStartGearItemLevel);
}
