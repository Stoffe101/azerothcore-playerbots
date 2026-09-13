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
}

class AdventureStartPlayerScript : public PlayerScript
{
public:
    AdventureStartPlayerScript() : PlayerScript("AdventureStartPlayerScript") { }

    void OnPlayerFirstLogin(Player* player) override
    {
        if (!g_AdventureStartEnable || !player || IsPlayerbot(player))
            return;

        // Death Knights are a WotLK-only class on this progression setup and have their own
        // stage-13 bootstrap. Never pull a fresh DK backwards into the TBC start flow.
        if (player->getClass() == CLASS_DEATH_KNIGHT)
        {
            LOG_INFO("server.loading", "[AdventureStart] Skipping Death Knight {}", player->GetName());
            return;
        }

        bool levelChanged = false;
        if (g_AdventureStartLevel > player->GetLevel())
        {
            player->GiveLevel(static_cast<uint8>(g_AdventureStartLevel));
            player->SetUInt32Value(PLAYER_XP, 0);
            levelChanged = true;
        }

        // Match the verified faction-leader expansion flow: only force the IP state here.
        // mod-era-talents detects the era crossing and performs its existing talent wipe,
        // tree switch, spell reconcile, glyph handling and addon sync on the normal poll.
        if (g_AdventureStartProgression > 0 && player->IsInWorld())
        {
            uint8 current = sIndividualProgression->GetPlayerProgressionFromQuests(player);
            if (current < g_AdventureStartProgression)
            {
                sIndividualProgression->ForceUpdateProgressionState(
                    player,
                    static_cast<ProgressionState>(g_AdventureStartProgression));
            }
        }

        // Recalculate native talent points only after the level/progression bootstrap. Era talents
        // use their own point accounting, but keeping the core state correct avoids stale UI/state.
        if (levelChanged)
            player->InitTalentForLevel();

        if (g_AdventureStartRevealMap)
            RevealAllMap(player);

        if (g_AdventureStartTeleport && player->IsInWorld())
        {
            player->TeleportTo(
                g_AdventureStartTeleportMap,
                g_AdventureStartTeleportX,
                g_AdventureStartTeleportY,
                g_AdventureStartTeleportZ,
                g_AdventureStartTeleportO);
        }

        LOG_INFO(
            "server.loading",
            "[AdventureStart] Initialized {} at level {}, progression {}, mapReveal={}, teleport={} map={} xyz=({:.2f},{:.2f},{:.2f}) o={:.2f}",
            player->GetName(),
            player->GetLevel(),
            g_AdventureStartProgression,
            g_AdventureStartRevealMap ? 1 : 0,
            g_AdventureStartTeleport ? 1 : 0,
            g_AdventureStartTeleportMap,
            g_AdventureStartTeleportX,
            g_AdventureStartTeleportY,
            g_AdventureStartTeleportZ,
            g_AdventureStartTeleportO);
    }
};

void AddAdventureStartScripts()
{
    new AdventureStartPlayerScript();
}
