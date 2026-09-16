#include "ScriptMgr.h"
#include "Log.h"
#include "RaidRosterCommand.h"
#include "RaidRosterConfig.h"
#include "GroupComposerCommand.h"

void AddAdventureStartScripts();

class RaidRosterWorld : public WorldScript
{
public:
    RaidRosterWorld() : WorldScript("RaidRosterWorld") { }
    void OnAfterConfigLoad(bool /*reload*/) override { RaidRosterLoadConfig(); }
};

void Addmod_raid_rosterScripts()
{
    LOG_INFO("server.loading", "[RaidRoster] Registering scripts and Group Composer backend.");
    new RaidRosterWorld();
    new RaidRosterCommand();
    AddGroupComposerScripts();
    AddAdventureStartScripts();
}
