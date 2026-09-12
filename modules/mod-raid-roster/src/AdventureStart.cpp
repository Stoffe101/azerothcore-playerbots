#include "ScriptMgr.h"
#include "Player.h"
#include "Log.h"
#include "IndividualProgression.h"
#include "Playerbots.h"
#include "RandomPlayerbotMgr.h"
#include "RaidRosterConfig.h"

namespace
{
bool IsPlayerbot(Player* player)
{
    if (!player)
        return true;

    return sRandomPlayerbotMgr.IsRandomBot(player)
        || sRandomPlayerbotMgr.IsAddclassBot(player)
        || sPlayerbotsMgr.GetPlayerbotAI(player) != nullptr;
}

void RevealAllMap(Player* player)
{
    for (uint8 i = 0; i < PLAYER_EXPLORED_ZONES_SIZE; ++i)
        player->SetFlag(PLAYER_EXPLORED_ZONES_1 + i, 0xFFFFFFFF);
}

uint8 ApplyAdventureProgression(Player* player)
{
    if (!player || !player->IsInWorld())
        return 0;

    uint8 current = sIndividualProgression->GetPlayerProgressionFromQuests(player);
    if (!g_AdventureStartProgression || !sIndividualProgression->enabled)
        return current;

    if (current < g_AdventureStartProgression)
    {
        // Use IP's normal forward-only API. Unlike ForceUpdateProgressionState(), this respects
        // whether IP is enabled and any configured server progression limit.
        sIndividualProgression->UpdateProgressionState(
            player,
            static_cast<ProgressionState>(g_AdventureStartProgression));
        current = sIndividualProgression->GetPlayerProgressionFromQuests(player);
    }

    // Individual Progression's OnPlayerLogin runs before AzerothCore's OnPlayerFirstLogin hook.
    // It therefore already applied adjustments while a brand-new character still looked like
    // progression 0. Reapply the derived state immediately after changing the hidden progression
    // quests instead of waiting for a later equip/resurrect/zone-change event.
    sIndividualProgression->CheckAdjustments(player);
    sIndividualProgression->checkIPPhasing(player, player->GetAreaId());
    return current;
}
}

class AdventureStartPlayerScript : public PlayerScript
{
public:
    AdventureStartPlayerScript() : PlayerScript("AdventureStartPlayerScript") { }

    void OnPlayerFirstLogin(Player* player) override
    {
        if (!g_AdventureStartEnable || !player || IsPlayerbot(player))
            return;

        if (g_AdventureStartLevel > player->GetLevel())
        {
            player->GiveLevel(static_cast<uint8>(g_AdventureStartLevel));
            player->InitTalentForLevel();
            player->SetUInt32Value(PLAYER_XP, 0);
        }

        uint8 const appliedProgression = ApplyAdventureProgression(player);

        if (g_AdventureStartRevealMap)
            RevealAllMap(player);

        if (sIndividualProgression->enabled && g_AdventureStartProgression > 0 && appliedProgression < g_AdventureStartProgression)
        {
            LOG_WARN(
                "server.loading",
                "[AdventureStart] {} requested progression {} but IP applied only {} (check IndividualProgression.ProgressionLimit/config)",
                player->GetName(),
                g_AdventureStartProgression,
                appliedProgression);
        }

        LOG_INFO(
            "server.loading",
            "[AdventureStart] Initialized {} at level {}, progression {}, mapReveal={}",
            player->GetName(),
            player->GetLevel(),
            appliedProgression,
            g_AdventureStartRevealMap ? 1 : 0);
    }
};

void AddAdventureStartScripts()
{
    new AdventureStartPlayerScript();
}
