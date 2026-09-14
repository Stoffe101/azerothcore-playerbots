#include "RaidRosterConfig.h"
#include "Config.h"
#include "Log.h"
#include "PlayerbotAIConfig.h"

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

bool g_GuildDirectorEnable = true;
bool g_GuildDirectorAutoTravel = true;
uint32 g_GuildDirectorReadyTimeoutMs = 30000;

bool g_EncounterLifecycleEnable = true;
bool g_WipeRecoveryEnable = true;
uint32 g_WipeRecoveryDelayMs = 5000;
bool g_WipeRecoveryResurrectHumans = true;
bool g_AutoPrepEnable = true;
bool g_AutoPrepRefillConsumables = true;
bool g_AutoPrepWarlockSupport = true;
bool g_AutoPrepSmartPets = true;

bool g_SmartLootEnable = true;
bool g_SmartLootBotNeedUpgrades = true;
bool g_SmartLootBotGreedUseful = true;
bool g_BadLuckProtectionEnable = true;
uint32 g_BadLuckUpgradeWindowSeconds = 120;

bool g_AdventureEconomyEnable = true;
uint32 g_AdventureEconomyDungeonBossFirstKillGold = 5;
uint32 g_AdventureEconomyRaidBossFirstKillGold = 20;
uint32 g_AdventureEconomyDungeonBossRepeatGold = 1;
uint32 g_AdventureEconomyRaidBossRepeatGold = 3;
uint32 g_AdventureEconomyDailyRepeatCapGold = 30;

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

    g_GuildDirectorEnable = sConfigMgr->GetOption<bool>("GuildDirector.Enable", true);
    g_GuildDirectorAutoTravel = sConfigMgr->GetOption<bool>("GuildDirector.AutoTravel", true);
    g_GuildDirectorReadyTimeoutMs = ClampU32(
        sConfigMgr->GetOption<uint32>("GuildDirector.ReadyTimeoutMs", 30000), 5000, 60000);

    g_EncounterLifecycleEnable = sConfigMgr->GetOption<bool>("EncounterLifecycle.Enable", true);
    g_WipeRecoveryEnable = sConfigMgr->GetOption<bool>("WipeRecovery.Enable", true);
    g_WipeRecoveryDelayMs = ClampU32(
        sConfigMgr->GetOption<uint32>("WipeRecovery.DelayMs", 5000), 2000, 30000);
    g_WipeRecoveryResurrectHumans = sConfigMgr->GetOption<bool>("WipeRecovery.ResurrectHumans", true);
    g_AutoPrepEnable = sConfigMgr->GetOption<bool>("AutoPrep.Enable", true);
    g_AutoPrepRefillConsumables = sConfigMgr->GetOption<bool>("AutoPrep.RefillConsumables", true);
    g_AutoPrepWarlockSupport = sConfigMgr->GetOption<bool>("AutoPrep.WarlockSupport", true);
    g_AutoPrepSmartPets = sConfigMgr->GetOption<bool>("AutoPrep.SmartPets", true);

    g_SmartLootEnable = sConfigMgr->GetOption<bool>("SmartLoot.Enable", true);
    g_SmartLootBotNeedUpgrades = sConfigMgr->GetOption<bool>("SmartLoot.BotNeedUpgrades", true);
    g_SmartLootBotGreedUseful = sConfigMgr->GetOption<bool>("SmartLoot.BotGreedUseful", true);
    g_BadLuckProtectionEnable = sConfigMgr->GetOption<bool>("BadLuckProtection.Enable", true);
    g_BadLuckUpgradeWindowSeconds = ClampU32(
        sConfigMgr->GetOption<uint32>("BadLuckProtection.UpgradeWindowSeconds", 120), 30, 600);

    if (g_SmartLootEnable)
    {
        PlayerbotAIConfig& botConfig = PlayerbotAIConfig::instance();
        botConfig.lootNeedRollLevel = g_SmartLootBotNeedUpgrades ? 2 : 1;
        botConfig.lootGreedRollLevel = g_SmartLootBotGreedUseful;
    }

    g_AdventureEconomyEnable = sConfigMgr->GetOption<bool>("AdventureEconomy.Enable", true);
    g_AdventureEconomyDungeonBossFirstKillGold = ClampU32(
        sConfigMgr->GetOption<uint32>("AdventureEconomy.DungeonBossFirstKillGold", 5), 0, 1000);
    g_AdventureEconomyRaidBossFirstKillGold = ClampU32(
        sConfigMgr->GetOption<uint32>("AdventureEconomy.RaidBossFirstKillGold", 20), 0, 5000);
    g_AdventureEconomyDungeonBossRepeatGold = ClampU32(
        sConfigMgr->GetOption<uint32>("AdventureEconomy.DungeonBossRepeatGold", 1), 0, 100);
    g_AdventureEconomyRaidBossRepeatGold = ClampU32(
        sConfigMgr->GetOption<uint32>("AdventureEconomy.RaidBossRepeatGold", 3), 0, 500);
    g_AdventureEconomyDailyRepeatCapGold = ClampU32(
        sConfigMgr->GetOption<uint32>("AdventureEconomy.DailyRepeatCapGold", 30), 0, 1000);

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
    LOG_INFO("server.loading", "[GuildDirector] Enable={}, AutoTravel={}, ReadyTimeoutMs={}",
        g_GuildDirectorEnable ? 1 : 0, g_GuildDirectorAutoTravel ? 1 : 0, g_GuildDirectorReadyTimeoutMs);
    LOG_INFO("server.loading", "[EncounterLifecycle] Enable={}, WipeRecovery={}, Delay={}ms, ResurrectHumans={}, AutoPrep={}, RefillConsumables={}, WarlockSupport={}, SmartPets={}",
        g_EncounterLifecycleEnable ? 1 : 0, g_WipeRecoveryEnable ? 1 : 0, g_WipeRecoveryDelayMs,
        g_WipeRecoveryResurrectHumans ? 1 : 0, g_AutoPrepEnable ? 1 : 0, g_AutoPrepRefillConsumables ? 1 : 0,
        g_AutoPrepWarlockSupport ? 1 : 0, g_AutoPrepSmartPets ? 1 : 0);
    LOG_INFO("server.loading", "[SmartLoot] Enable={}, BotNeedUpgrades={}, BotGreedUseful={}, BadLuckProtection={}, UpgradeWindow={}s",
        g_SmartLootEnable ? 1 : 0, g_SmartLootBotNeedUpgrades ? 1 : 0,
        g_SmartLootBotGreedUseful ? 1 : 0, g_BadLuckProtectionEnable ? 1 : 0, g_BadLuckUpgradeWindowSeconds);
    LOG_INFO("server.loading", "[AdventureEconomy] Enable={}, firstKill(dungeon={}g, raid={}g), repeat(dungeon={}g, raid={}g, dailyCap={}g)",
        g_AdventureEconomyEnable ? 1 : 0,
        g_AdventureEconomyDungeonBossFirstKillGold,
        g_AdventureEconomyRaidBossFirstKillGold,
        g_AdventureEconomyDungeonBossRepeatGold,
        g_AdventureEconomyRaidBossRepeatGold,
        g_AdventureEconomyDailyRepeatCapGold);
}
