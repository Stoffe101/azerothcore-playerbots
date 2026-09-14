#include "AdventureProgressionStore.h"
#include "RaidRosterConfig.h"

#include "Config.h"
#include "Log.h"
#include "Player.h"
#include "ScriptMgr.h"
#include "WorldSession.h"

bool g_AdventureProgressionCachesEnable = true;

namespace
{
bool IsRealPlayer(Player* player)
{
    return player && player->GetSession() && !player->GetSession()->IsBot();
}

class AdventureProgressionConfigScript final : public WorldScript
{
public:
    AdventureProgressionConfigScript() : WorldScript("AdventureProgressionConfigScript") { }

    void OnAfterConfigLoad(bool /*reload*/) override
    {
        g_AdventureProgressionCachesEnable =
            sConfigMgr->GetOption<bool>("AdventureProgression.Caches.Enable", true);
        LOG_INFO("server.loading", "[AdventureProgression] Caches.Enable={}",
            g_AdventureProgressionCachesEnable ? 1 : 0);
    }
};

class AdventureProgressionRewardScript final : public PlayerScript
{
public:
    AdventureProgressionRewardScript() : PlayerScript("AdventureProgressionRewardScript") { }

    void OnPlayerLevelChanged(Player* player, uint8 oldLevel) override
    {
        if (!g_AdventureProgressionCachesEnable || !IsRealPlayer(player))
            return;

        uint8 const newLevel = player->GetLevel();
        if (newLevel <= oldLevel)
            return;

        // Normal XP progression advances one level at a time. Deliberate GM/starter/catch-up boosts
        // can jump many levels and must not manufacture all skipped milestone rewards.
        if (newLevel > uint8(oldLevel + 1))
            return;

        uint8 milestone = 0;
        if (newLevel == 65)
            milestone = 65;
        else if (newLevel == 70)
            milestone = 70;
        else
            return;

        uint32 const guid = player->GetGUID().GetCounter();
        AdventureProgressionStore::State state = AdventureProgressionStore::LoadOrCreate(guid);

        // Starter initialization proves this is part of the custom adventure lifecycle rather than
        // a character being boosted through the level range before its profile is established.
        if (!state.starterInitialized || state.lastLevelCache >= milestone)
            return;

        AdventureProgressionStore::AddPendingCache(guid, 1);
        AdventureProgressionStore::SetLastLevelCache(guid, milestone);

        LOG_INFO(
            "server.loading",
            "[AdventureProgression] {} earned an Adventure Cache at natural level milestone {}",
            player->GetName(), milestone);
    }
};
}

void AddAdventureProgressionRewardScripts()
{
    new AdventureProgressionConfigScript();
    new AdventureProgressionRewardScript();
}
