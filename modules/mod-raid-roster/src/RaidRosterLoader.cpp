#include "ScriptMgr.h"
#include "Log.h"
#include "AdventureCatchupCommand.h"
#include "AdventureCommand.h"
#include "AdventureControlCommand.h"
#include "AdventureGuideCommand.h"
#include "AutoDungeonClear.h"
#include "EncounterLifecycle.h"
#include "GuildGroupDirector.h"
#include "RaidLeaderAuto.h"
#include "RaidLeaderCommand.h"
#include "RaidRosterCommand.h"
#include "RaidRosterConfig.h"
#include "RaidRosterGuild.h"
#include "SmartLootSystem.h"

void AddAdventureStartScripts();
void AddAdventureControlPlayerScripts();
void AddAdventureEconomyScripts();

class RaidRosterWorld : public WorldScript
{
public:
    RaidRosterWorld() : WorldScript("RaidRosterWorld") { }
    void OnAfterConfigLoad(bool /*reload*/) override { RaidRosterLoadConfig(); }
};

void Addmod_raid_rosterScripts()
{
    LOG_INFO("server.loading", "[RaidRoster] Registering complete adventure stack.");
    new RaidRosterWorld();
    new RaidRosterCommand();
    new AdventureCommand();
    new AdventureControlCommand();
    new AdventureCatchupCommand();
    new AdventureGuideCommand();
    new RaidLeaderCommand();
    AddAdventureStartScripts();
    AddAdventureControlPlayerScripts();
    AddRaidRosterGuildScripts();
    AddGuildGroupDirectorScripts();
    AddEncounterLifecycleScripts();
    AddAutoDungeonClearScripts();
    AddRaidLeaderAutoScripts();
    AddSmartLootScripts();
    AddAdventureEconomyScripts();
}
