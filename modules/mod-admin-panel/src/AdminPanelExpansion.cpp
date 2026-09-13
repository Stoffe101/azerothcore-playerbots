#include "AdminPanelExpansion.h"

#include "IndividualProgression.h"
#include "Log.h"
#include "Player.h"

namespace
{
bool g_wotlkReleased = false;
constexpr uint8 TBC_PROGRESSION_LIMIT = PROGRESSION_TBC_TIER_4; // 12: Sunwell open, WotLK still locked
}

namespace AdminPanelExpansion
{
bool IsWotlkReleased()
{
    return g_wotlkReleased;
}

void SetWotlkReleased(bool released)
{
    g_wotlkReleased = released;

    // Individual Progression already drives the effective player level bands:
    // < stage 8 => 60, stage 8-12 => 70, stage 13+ => 80. Keep its hard ceiling at stage 12
    // while TBC is the live expansion, then remove the ceiling when WotLK is deliberately released.
    sIndividualProgression->progressionLimit = released ? 0 : TBC_PROGRESSION_LIMIT;

    // Keep random/playerbot accounts from naturally levelling past the live expansion as well.
    sIndividualProgression->BotAccountsMaxLevel = released ? 80 : 70;

    LOG_INFO(
        "server.loading",
        "[AdminPanel] Expansion gate applied: current={} progressionLimit={} botLevelCap={}",
        released ? "WotLK" : "TBC",
        sIndividualProgression->progressionLimit,
        sIndividualProgression->BotAccountsMaxLevel);
}

uint8 CurrentLevelCap()
{
    return g_wotlkReleased ? 80 : 70;
}

uint8 CurrentProgressionLimit()
{
    return g_wotlkReleased ? 18 : TBC_PROGRESSION_LIMIT;
}

uint8 PlayerProgression(Player* player)
{
    return player ? sIndividualProgression->GetPlayerProgressionFromQuests(player) : 0;
}

bool SetPlayerProgression(Player* player, uint8 stage)
{
    if (!player || !player->IsInWorld())
        return false;

    // This control center starts in TBC, so never use it to rewind into Vanilla. While WotLK is
    // locked, stage 12 is a hard ceiling; once released, the full IP range becomes available.
    if (stage < PROGRESSION_PRE_TBC || stage > CurrentProgressionLimit())
        return false;

    sIndividualProgression->ForceUpdateProgressionState(player, static_cast<ProgressionState>(stage));
    sIndividualProgression->checkIPPhasing(player, player->GetAreaId());
    player->SaveToDB(false, false);
    return PlayerProgression(player) == stage;
}

char const* CurrentExpansionName()
{
    return g_wotlkReleased ? "WOTLK" : "TBC";
}
}
