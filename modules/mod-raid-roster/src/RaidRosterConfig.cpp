#include "RaidRosterConfig.h"
#include "Config.h"
#include "Log.h"

bool g_RaidRosterEnable = false;

bool g_AdventureStartEnable = true;
uint32 g_AdventureStartLevel = 60;
uint8 g_AdventureStartProgression = 8;
bool g_AdventureStartRevealMap = true;

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

    LOG_INFO("server.loading", "[RaidRoster] Enable={}", g_RaidRosterEnable ? 1 : 0);
    LOG_INFO(
        "server.loading",
        "[AdventureStart] Enable={}, Level={}, Progression={}, RevealMap={}",
        g_AdventureStartEnable ? 1 : 0,
        g_AdventureStartLevel,
        g_AdventureStartProgression,
        g_AdventureStartRevealMap ? 1 : 0);
}
