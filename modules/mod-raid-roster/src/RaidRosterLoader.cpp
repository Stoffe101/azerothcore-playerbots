#include "ScriptMgr.h"
#include "Log.h"
#include "AdventureCacheCommand.h"
#include "AdventureCatchupCommand.h"
#include "AdventureCommand.h"
#include "AdventureControlCommand.h"
#include "AdventureGuideCommand.h"
#include "AutoDungeonClear.h"
#include "EncounterLifecycle.h"
#include "EraPolicy.h"
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
void AddAdventureProgressionHistoryScripts();
void AddAdventureEconomyScripts();

class RaidRosterWorld : public WorldScript
{
public:
    RaidRosterWorld() : WorldScript("RaidRosterWorld") { }

    void OnAfterConfigLoad(bool reload) override
    {
        RaidRosterLoadConfig();

        // Playerbots also reloads its config through WorldScript hooks. Reassert the central era
        // ceiling on the next world update so script registration order cannot leave MaxLevel=80.
        if (reload)
        {
            _pendingEraCapSync = true;
            _eraCapSyncDelayMs = 1000;
        }
    }

    void OnStartup() override
    {
        EraPolicy::SyncRuntimeBotCaps();
    }

    void OnUpdate(uint32 diff) override
    {
        if (!_pendingEraCapSync)
            return;

        if (diff < _eraCapSyncDelayMs)
        {
            _eraCapSyncDelayMs -= diff;
            return;
        }

        _pendingEraCapSync = false;
        _eraCapSyncDelayMs = 0;
        EraPolicy::SyncRuntimeBotCaps();
    }

private:
    bool _pendingEraCapSync = false;
    uint32 _eraCapSyncDelayMs = 0;
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
    AddAdventureProgressionHistoryScripts();
    AddRaidRosterGuildScripts();
    AddGuildGroupDirectorScripts();
    AddEncounterLifecycleScripts();
    AddAutoDungeonClearScripts();
    AddRaidLeaderAutoScripts();
    AddSmartLootScripts();
    AddAdventureEconomyScripts();
}
