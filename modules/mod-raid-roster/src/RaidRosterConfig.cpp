#include "RaidRosterConfig.h"
#include "Config.h"
#include "Log.h"

bool g_RaidRosterEnable = false;

bool g_AdventureStartEnable = true;
uint8 g_AdventureStartDefaultProfile = 0;
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
uint32 g_AdventureStartGearItemLevel = 88;

uint32 g_AdventureStartRaidReadyLevel = 80;
uint8 g_AdventureStartRaidReadyProgression = 13;
uint32 g_AdventureStartRaidReadyStartingGold = 500;
uint32 g_AdventureStartRaidReadyBasicGearItemLevel = 187;
uint32 g_AdventureStartRaidReadyGearItemLevel = 200;
bool g_AdventureStartRaidReadyTeleport = true;
uint32 g_AdventureStartRaidReadyTeleportMap = 571;
float g_AdventureStartRaidReadyTeleportX = 5807.75f;
float g_AdventureStartRaidReadyTeleportY = 588.27f;
float g_AdventureStartRaidReadyTeleportZ = 660.94f;
float g_AdventureStartRaidReadyTeleportO = 1.64f;

namespace
{
uint32 ClampU32(uint32 value, uint32 minValue, uint32 maxValue)
{
    if (value < minValue)
        return minValue;
    if (value > maxValue)
        return maxValue;
    return value;
}
}

void RaidRosterLoadConfig()
{
    g_RaidRosterEnable = sConfigMgr->GetOption<bool>("RaidRoster.Enable", false);

    g_AdventureStartEnable = sConfigMgr->GetOption<bool>("AdventureStart.Enable", true);
    g_AdventureStartDefaultProfile = static_cast<uint8>(ClampU32(
        sConfigMgr->GetOption<uint32>("AdventureStart.DefaultProfile", 0), 0, 1));

    g_AdventureStartLevel = ClampU32(sConfigMgr->GetOption<uint32>("AdventureStart.Level", 60), 1, 80);
    g_AdventureStartProgression = static_cast<uint8>(ClampU32(
        sConfigMgr->GetOption<uint32>("AdventureStart.Progression", 8), 0, 18));

    g_AdventureStartRevealMap = sConfigMgr->GetOption<bool>("AdventureStart.RevealMap", true);
    g_AdventureStartTeleport = sConfigMgr->GetOption<bool>("AdventureStart.Teleport.Enable", true);
    g_AdventureStartTeleportMap = sConfigMgr->GetOption<uint32>("AdventureStart.Teleport.Map", 0);
    g_AdventureStartTeleportX = sConfigMgr->GetOption<float>("AdventureStart.Teleport.X", -11894.80f);
    g_AdventureStartTeleportY = sConfigMgr->GetOption<float>("AdventureStart.Teleport.Y", -3206.52f);
    g_AdventureStartTeleportZ = sConfigMgr->GetOption<float>("AdventureStart.Teleport.Z", -14.62f);
    g_AdventureStartTeleportO = sConfigMgr->GetOption<float>("AdventureStart.Teleport.O", 0.0f);

    g_AdventureStartStarterKit = sConfigMgr->GetOption<bool>("AdventureStart.StarterKit", true);
    g_AdventureStartStartingGold = ClampU32(
        sConfigMgr->GetOption<uint32>("AdventureStart.StartingGold", 50), 0, 10000);

    g_AdventureStartBasicGear = sConfigMgr->GetOption<bool>("AdventureStart.BasicGear", true);
    g_AdventureStartBasicGearItemLevel = ClampU32(
        sConfigMgr->GetOption<uint32>("AdventureStart.BasicGearItemLevel", 58), 1, 300);

    g_AdventureStartAutoGear = sConfigMgr->GetOption<bool>("AdventureStart.AutoGear", true);
    g_AdventureStartGearMinTalentPoints = ClampU32(
        sConfigMgr->GetOption<uint32>("AdventureStart.GearMinTalentPoints", 5), 0, 71);
    g_AdventureStartGearItemLevel = ClampU32(
        sConfigMgr->GetOption<uint32>("AdventureStart.GearItemLevel", 88), 1, 300);

    g_AdventureStartRaidReadyLevel = ClampU32(
        sConfigMgr->GetOption<uint32>("AdventureStart.RaidReady.Level", 80), 1, 80);
    g_AdventureStartRaidReadyProgression = static_cast<uint8>(ClampU32(
        sConfigMgr->GetOption<uint32>("AdventureStart.RaidReady.Progression", 13), 0, 18));
    g_AdventureStartRaidReadyStartingGold = ClampU32(
        sConfigMgr->GetOption<uint32>("AdventureStart.RaidReady.StartingGold", 500), 0, 10000);
    g_AdventureStartRaidReadyBasicGearItemLevel = ClampU32(
        sConfigMgr->GetOption<uint32>("AdventureStart.RaidReady.BasicGearItemLevel", 187), 1, 300);
    g_AdventureStartRaidReadyGearItemLevel = ClampU32(
        sConfigMgr->GetOption<uint32>("AdventureStart.RaidReady.GearItemLevel", 200), 1, 300);
    g_AdventureStartRaidReadyTeleport = sConfigMgr->GetOption<bool>("AdventureStart.RaidReady.Teleport.Enable", true);
    g_AdventureStartRaidReadyTeleportMap = sConfigMgr->GetOption<uint32>("AdventureStart.RaidReady.Teleport.Map", 571);
    g_AdventureStartRaidReadyTeleportX = sConfigMgr->GetOption<float>("AdventureStart.RaidReady.Teleport.X", 5807.75f);
    g_AdventureStartRaidReadyTeleportY = sConfigMgr->GetOption<float>("AdventureStart.RaidReady.Teleport.Y", 588.27f);
    g_AdventureStartRaidReadyTeleportZ = sConfigMgr->GetOption<float>("AdventureStart.RaidReady.Teleport.Z", 660.94f);
    g_AdventureStartRaidReadyTeleportO = sConfigMgr->GetOption<float>("AdventureStart.RaidReady.Teleport.O", 1.64f);

    LOG_INFO("server.loading", "[RaidRoster] Enable={}", g_RaidRosterEnable ? 1 : 0);
    LOG_INFO(
        "server.loading",
        "[AdventureStart] Enable={}, DefaultProfile={}, TBC(level={}, stage={}, gold={}g, basic@{}, epic@{}), RaidReady(level={}, stage={}, gold={}g, basic@{}, epic@{})",
        g_AdventureStartEnable ? 1 : 0,
        g_AdventureStartDefaultProfile,
        g_AdventureStartLevel,
        g_AdventureStartProgression,
        g_AdventureStartStartingGold,
        g_AdventureStartBasicGearItemLevel,
        g_AdventureStartGearItemLevel,
        g_AdventureStartRaidReadyLevel,
        g_AdventureStartRaidReadyProgression,
        g_AdventureStartRaidReadyStartingGold,
        g_AdventureStartRaidReadyBasicGearItemLevel,
        g_AdventureStartRaidReadyGearItemLevel);
}
