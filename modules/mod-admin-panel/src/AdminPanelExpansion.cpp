#include "AdminPanelExpansion.h"

#include "IndividualProgression.h"
#include "Log.h"
#include "Player.h"

#include <algorithm>
#include <cctype>
#include <string>

namespace
{
RealmEra g_currentEra = RealmEra::Vanilla;

constexpr uint8 VANILLA_PROGRESSION_LIMIT = PROGRESSION_NAXX40;   // 7: Vanilla complete, TBC still closed.
constexpr uint8 TBC_PROGRESSION_LIMIT = PROGRESSION_TBC_TIER_4;   // 12: Sunwell open, WotLK still closed.

std::string Lower(std::string value)
{
    std::transform(value.begin(), value.end(), value.begin(), [](unsigned char c)
    {
        return static_cast<char>(std::tolower(c));
    });
    return value;
}

void ApplyEraGate(RealmEra era)
{
    switch (era)
    {
        case RealmEra::Vanilla:
            sIndividualProgression->progressionLimit = VANILLA_PROGRESSION_LIMIT;
            sIndividualProgression->BotAccountsMaxLevel = 60;
            break;
        case RealmEra::Tbc:
            sIndividualProgression->progressionLimit = TBC_PROGRESSION_LIMIT;
            sIndividualProgression->BotAccountsMaxLevel = 70;
            break;
        case RealmEra::Wotlk:
            // Zero means no ceiling in mod-individual-progression.
            sIndividualProgression->progressionLimit = 0;
            sIndividualProgression->BotAccountsMaxLevel = 80;
            break;
    }
}
}

namespace AdminPanelExpansion
{
RealmEra CurrentEra()
{
    return g_currentEra;
}

void SetEra(RealmEra era)
{
    g_currentEra = era;
    ApplyEraGate(era);

    LOG_INFO(
        "server.loading",
        "[AdminPanel] Expansion gate applied: current={} progressionLimit={} botLevelCap={}",
        CurrentExpansionName(),
        sIndividualProgression->progressionLimit,
        sIndividualProgression->BotAccountsMaxLevel);
}

bool IsTbcReleased()
{
    return g_currentEra >= RealmEra::Tbc;
}

bool IsWotlkReleased()
{
    return g_currentEra >= RealmEra::Wotlk;
}

uint8 CurrentLevelCap()
{
    switch (g_currentEra)
    {
        case RealmEra::Vanilla: return 60;
        case RealmEra::Tbc: return 70;
        case RealmEra::Wotlk: return 80;
    }
    return 60;
}

uint8 CurrentProgressionLimit()
{
    switch (g_currentEra)
    {
        case RealmEra::Vanilla: return VANILLA_PROGRESSION_LIMIT;
        case RealmEra::Tbc: return TBC_PROGRESSION_LIMIT;
        case RealmEra::Wotlk: return PROGRESSION_WOTLK_TIER_5;
    }
    return VANILLA_PROGRESSION_LIMIT;
}

uint8 MinimumProgressionForCurrentEra()
{
    switch (g_currentEra)
    {
        case RealmEra::Vanilla: return PROGRESSION_START;
        case RealmEra::Tbc: return PROGRESSION_PRE_TBC;
        case RealmEra::Wotlk: return PROGRESSION_TBC_TIER_5;
    }
    return PROGRESSION_START;
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
    switch (g_currentEra)
    {
        case RealmEra::Vanilla: return "VANILLA";
        case RealmEra::Tbc: return "TBC";
        case RealmEra::Wotlk: return "WOTLK";
    }
    return "VANILLA";
}

char const* EraKey(RealmEra era)
{
    switch (era)
    {
        case RealmEra::Vanilla: return "vanilla";
        case RealmEra::Tbc: return "tbc";
        case RealmEra::Wotlk: return "wotlk";
    }
    return "vanilla";
}

bool ParseEra(char const* value, RealmEra& era)
{
    std::string const normalized = Lower(value ? value : "");
    if (normalized == "vanilla" || normalized == "classic" || normalized == "60")
    {
        era = RealmEra::Vanilla;
        return true;
    }
    if (normalized == "tbc" || normalized == "burningcrusade" || normalized == "70")
    {
        era = RealmEra::Tbc;
        return true;
    }
    if (normalized == "wotlk" || normalized == "wrath" || normalized == "80")
    {
        era = RealmEra::Wotlk;
        return true;
    }
    return false;
}
}
