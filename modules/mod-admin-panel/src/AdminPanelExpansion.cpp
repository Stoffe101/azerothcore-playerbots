#include "AdminPanelExpansion.h"

#include "EraPolicy.h"
#include "IndividualProgression.h"
#include "Log.h"
#include "Player.h"

#include <string_view>

namespace AdminPanelExpansion
{
RealmEra CurrentEra()
{
    return EraPolicy::CurrentRealmEra();
}

void SetEra(RealmEra era)
{
    EraPolicy::ApplyRealmEra(era);

    LOG_INFO(
        "server.loading",
        "[AdminPanel] Expansion gate applied through EraPolicy: current={} progressionLimit={} botLevelCap={}",
        CurrentExpansionName(),
        sIndividualProgression->progressionLimit,
        sIndividualProgression->BotAccountsMaxLevel);
}

bool IsTbcReleased()
{
    return EraPolicy::IsEraReleased(RealmEra::Tbc);
}

bool IsWotlkReleased()
{
    return EraPolicy::IsEraReleased(RealmEra::Wotlk);
}

uint8 CurrentLevelCap()
{
    return EraPolicy::RealmLevelCap();
}

uint8 CurrentProgressionLimit()
{
    return EraPolicy::RealmProgressionCeiling();
}

uint8 MinimumProgressionForCurrentEra()
{
    return EraPolicy::RealmMinimumProgression();
}

uint8 PlayerProgression(Player* player)
{
    return player ? sIndividualProgression->GetPlayerProgressionFromQuests(player) : 0;
}

bool SetPlayerProgression(Player* player, uint8 stage)
{
    if (!player || !player->IsInWorld() || stage > CurrentProgressionLimit() || stage == 11)
        return false;

    if (stage == PROGRESSION_START)
    {
        for (uint32 value = PROGRESSION_MOLTEN_CORE; value <= PROGRESSION_WOTLK_TIER_5; ++value)
            if (player->IsQuestRewarded(66000u + value))
                player->RemoveRewardedQuest(66000u + value);
    }
    else
    {
        sIndividualProgression->ForceUpdateProgressionState(player, static_cast<ProgressionState>(stage));
    }

    sIndividualProgression->CheckAdjustments(player);
    sIndividualProgression->checkIPPhasing(player, player->GetAreaId());
    player->SaveToDB(false, false);
    return PlayerProgression(player) == stage;
}

char const* CurrentExpansionName()
{
    return EraPolicy::Token(CurrentEra());
}

char const* EraKey(RealmEra era)
{
    return EraPolicy::Key(era);
}

bool ParseEra(char const* value, RealmEra& era)
{
    return EraPolicy::Parse(value ? std::string_view(value) : std::string_view(), era);
}
}
