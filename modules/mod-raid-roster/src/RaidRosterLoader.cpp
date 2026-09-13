#include "ScriptMgr.h"
#include "Log.h"
#include "AdventureCommand.h"
#include "AdventureGuideCommand.h"
#include "EncounterLifecycle.h"
#include "GuildGroupDirector.h"
#include "RaidLeaderCommand.h"
#include "RaidRosterCommand.h"
#include "RaidRosterConfig.h"
#include "SmartLootSystem.h"

void AddAdventureStartScripts();
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
    new AdventureGuideCommand();
    new RaidLeaderCommand();
    AddAdventureStartScripts();
    AddGuildGroupDirectorScripts();
    AddEncounterLifecycleScripts();
    AddSmartLootScripts();
    AddAdventureEconomyScripts();
}
