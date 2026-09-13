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

uint32 g_AdventureStartTbcRaidReadyLevel = 70;
uint8 g_AdventureStartTbcRaidReadyProgression = 8;
uint32 g_AdventureStartTbcRaidReadyStartingGold = 500;
uint32 g_AdventureStartTbcRaidReadyBasicGearItemLevel = 110;
uint32 g_AdventureStartTbcRaidReadyGearItemLevel = 115;
bool g_AdventureStartTbcRaidReadyTeleport = true;
uint32 g_AdventureStartTbcRaidReadyTeleportMap = 530;
float g_AdventureStartTbcRaidReadyTeleportX = -1838.16f;
float g_AdventureStartTbcRaidReadyTeleportY = 5301.79f;
float g_AdventureStartTbcRaidReadyTeleportZ = -12.43f;
float g_AdventureStartTbcRaidReadyTeleportO = 5.95f;

uint32 g_AdventureStartWotlkRaidReadyLevel = 80;
uint8 g_AdventureStartWotlkRaidReadyProgression = 13;
uint32 g_AdventureStartWotlkRaidReadyStartingGold = 1000;
uint32 g_AdventureStartWotlkRaidReadyBasicGearItemLevel = 187;
uint32 g_AdventureStartWotlkRaidReadyGearItemLevel = 200;
bool g_AdventureStartWotlkRaidReadyTeleport = true;
uint32 g_AdventureStartWotlkRaidReadyTeleportMap = 571;
float g_AdventureStartWotlkRaidReadyTeleportX = 5807.75f;
float g_AdventureStartWotlkRaidReadyTeleportY = 588.27f;
float g_AdventureStartWotlkRaidReadyTeleportZ = 660.94f;
float g_AdventureStartWotlkRaidReadyTeleportO = 1.64f;

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
        sConfigMgr->GetOption<uint32>("AdventureStart.DefaultProfile", 0), 0, 2));

    g_AdventureStartLevel = ClampU32(sConfigMgr->GetOption<uint32>("AdventureStart.Level", 60), 1, 70);
    g_AdventureStartProgression = static_cast<uint8>(ClampU32(
        sConfigMgr->GetOption<uint32>("AdventureStart.Progression", 8), 0, 12));

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

    g_AdventureStartTbcRaidReadyLevel = ClampU32(
        sConfigMgr->GetOption<uint32>("AdventureStart.TbcRaidReady.Level", 70), 60, 70);
    g_AdventureStartTbcRaidReadyProgression = static_cast<uint8>(ClampU32(
        sConfigMgr->GetOption<uint32>("AdventureStart.TbcRaidReady.Progression", 8), 8, 12));
    g_AdventureStartTbcRaidReadyStartingGold = ClampU32(
        sConfigMgr->GetOption<uint32>("AdventureStart.TbcRaidReady.StartingGold", 500), 0, 10000);
    g_AdventureStartTbcRaidReadyBasicGearItemLevel = ClampU32(
        sConfigMgr->GetOption<uint32>("AdventureStart.TbcRaidReady.BasicGearItemLevel", 110), 1, 300);
    g_AdventureStartTbcRaidReadyGearItemLevel = ClampU32(
        sConfigMgr->GetOption<uint32>("AdventureStart.TbcRaidReady.GearItemLevel", 115), 1, 300);
    g_AdventureStartTbcRaidReadyTeleport = sConfigMgr->GetOption<bool>("AdventureStart.TbcRaidReady.Teleport.Enable", true);
    g_AdventureStartTbcRaidReadyTeleportMap = sConfigMgr->GetOption<uint32>("AdventureStart.TbcRaidReady.Teleport.Map", 530);
    g_AdventureStartTbcRaidReadyTeleportX = sConfigMgr->GetOption<float>("AdventureStart.TbcRaidReady.Teleport.X", -1838.16f);
    g_AdventureStartTbcRaidReadyTeleportY = sConfigMgr->GetOption<float>("AdventureStart.TbcRaidReady.Teleport.Y", 5301.79f);
    g_AdventureStartTbcRaidReadyTeleportZ = sConfigMgr->GetOption<float>("AdventureStart.TbcRaidReady.Teleport.Z", -12.43f);
    g_AdventureStartTbcRaidReadyTeleportO = sConfigMgr->GetOption<float>("AdventureStart.TbcRaidReady.Teleport.O", 5.95f);

    g_AdventureStartWotlkRaidReadyLevel = ClampU32(
        sConfigMgr->GetOption<uint32>("AdventureStart.WotlkRaidReady.Level", 80), 70, 80);
    g_AdventureStartWotlkRaidReadyProgression = static_cast<uint8>(ClampU32(
        sConfigMgr->GetOption<uint32>("AdventureStart.WotlkRaidReady.Progression", 13), 13, 18));
    g_AdventureStartWotlkRaidReadyStartingGold = ClampU32(
        sConfigMgr->GetOption<uint32>("AdventureStart.WotlkRaidReady.StartingGold", 1000), 0, 10000);
    g_AdventureStartWotlkRaidReadyBasicGearItemLevel = ClampU32(
        sConfigMgr->GetOption<uint32>("AdventureStart.WotlkRaidReady.BasicGearItemLevel", 187), 1, 300);
    g_AdventureStartWotlkRaidReadyGearItemLevel = ClampU32(
        sConfigMgr->GetOption<uint32>("AdventureStart.WotlkRaidReady.GearItemLevel", 200), 1, 300);
    g_AdventureStartWotlkRaidReadyTeleport = sConfigMgr->GetOption<bool>("AdventureStart.WotlkRaidReady.Teleport.Enable", true);
    g_AdventureStartWotlkRaidReadyTeleportMap = sConfigMgr->GetOption<uint32>("AdventureStart.WotlkRaidReady.Teleport.Map", 571);
    g_AdventureStartWotlkRaidReadyTeleportX = sConfigMgr->GetOption<float>("AdventureStart.WotlkRaidReady.Teleport.X", 5807.75f);
    g_AdventureStartWotlkRaidReadyTeleportY = sConfigMgr->GetOption<float>("AdventureStart.WotlkRaidReady.Teleport.Y", 588.27f);
    g_AdventureStartWotlkRaidReadyTeleportZ = sConfigMgr->GetOption<float>("AdventureStart.WotlkRaidReady.Teleport.Z", 660.94f);
    g_AdventureStartWotlkRaidReadyTeleportO = sConfigMgr->GetOption<float>("AdventureStart.WotlkRaidReady.Teleport.O", 1.64f);

    LOG_INFO("server.loading", "[RaidRoster] Enable={}", g_RaidRosterEnable ? 1 : 0);
    LOG_INFO(
        "server.loading",
        "[AdventureStart] Enable={}, DefaultProfile={}, TBC(level={}, stage={}, gold={}g, vanillaRaid@{}), TbcRaidReady(level={}, stage={}, gold={}g, basic@{}, final@{}), WotlkRaidReady(level={}, stage={}, gold={}g, basic@{}, final@{})",
        g_AdventureStartEnable ? 1 : 0,
        g_AdventureStartDefaultProfile,
        g_AdventureStartLevel,
        g_AdventureStartProgression,
        g_AdventureStartStartingGold,
        g_AdventureStartGearItemLevel,
        g_AdventureStartTbcRaidReadyLevel,
        g_AdventureStartTbcRaidReadyProgression,
        g_AdventureStartTbcRaidReadyStartingGold,
        g_AdventureStartTbcRaidReadyBasicGearItemLevel,
        g_AdventureStartTbcRaidReadyGearItemLevel,
        g_AdventureStartWotlkRaidReadyLevel,
        g_AdventureStartWotlkRaidReadyProgression,
        g_AdventureStartWotlkRaidReadyStartingGold,
        g_AdventureStartWotlkRaidReadyBasicGearItemLevel,
        g_AdventureStartWotlkRaidReadyGearItemLevel);
}
