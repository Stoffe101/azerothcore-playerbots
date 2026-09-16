#include "ScriptMgr.h"
#include "Log.h"
#include "AdventureCacheCommand.h"
#include "AdventureCatchupCommand.h"
#include "AdventureCommand.h"
#include "AdventureControlCommand.h"
#include "AdventureGuideCommand.h"
#include "AutoDungeonClear.h"
#include "EncounterLifecycle.h"
#include "GroupComposerCommand.h"
#include "GroupComposerTitanRune.h"
#include "GuildGroupDirector.h"
#include "RaidLeaderAuto.h"
#include "RaidLeaderCommand.h"
#include "RaidRosterCommand.h"
#include "RaidRosterConfig.h"
#include "RaidRosterGuild.h"
#include "SmartLootSystem.h"

void AddAdventureStartScripts();
void AddAdventureControlPlayerScripts();
void AddAdventureProgressionRewardScripts();
void AddAdventureEconomyScripts();

class RaidRosterWorld : public WorldScript
{
public:
    RaidRosterWorld() : WorldScript("RaidRosterWorld") { }
    void OnAfterConfigLoad(bool /*reload*/) override { RaidRosterLoadConfig(); }
};

void Addmod_raid_rosterScripts()
{
    LOG_INFO("server.loading", "[RaidRoster] Registering complete adventure stack and Group Composer backend.");
    new RaidRosterWorld();
    new RaidRosterCommand();
    new AdventureCommand();
    new AdventureControlCommand();
    new AdventureCatchupCommand();
    new AdventureCacheCommand();
    new AdventureGuideCommand();
    new RaidLeaderCommand();
    AddGroupComposerScripts();
    AddGroupComposerTitanRuneScripts();
    AddAdventureStartScripts();
    AddAdventureControlPlayerScripts();
    AddAdventureProgressionRewardScripts();
    AddRaidRosterGuildScripts();
    AddGuildGroupDirectorScripts();
    AddEncounterLifecycleScripts();
    AddAutoDungeonClearScripts();
    AddRaidLeaderAutoScripts();
    AddSmartLootScripts();
    AddAdventureEconomyScripts();
}
