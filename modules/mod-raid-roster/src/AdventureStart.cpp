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

        if (g_AdventureStartLevel > player->GetLevel())
        {
            player->GiveLevel(static_cast<uint8>(g_AdventureStartLevel));
            player->InitTalentForLevel();
            player->SetUInt32Value(PLAYER_XP, 0);
        }

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

        if (g_AdventureStartRevealMap)
            RevealAllMap(player);

        LOG_INFO(
            "server.loading",
            "[AdventureStart] Initialized {} at level {}, progression {}, mapReveal={}",
            player->GetName(),
            player->GetLevel(),
            g_AdventureStartProgression,
            g_AdventureStartRevealMap ? 1 : 0);
    }
};

void AddAdventureStartScripts()
{
    new AdventureStartPlayerScript();
}
