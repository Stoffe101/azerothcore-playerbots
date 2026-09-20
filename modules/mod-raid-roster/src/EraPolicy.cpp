#include "EraPolicy.h"

#include "IndividualProgression.h"

#include <algorithm>
#include <cctype>
#include <string>

namespace
{
std::string Normalize(std::string_view value)
{
    std::string normalized(value);
    normalized.erase(std::remove_if(normalized.begin(), normalized.end(), [](unsigned char c)
    {
        return std::isspace(c) || c == '-' || c == '_';
    }), normalized.end());
    std::transform(normalized.begin(), normalized.end(), normalized.begin(), [](unsigned char c)
    {
        return static_cast<char>(std::tolower(c));
    });
    return normalized;
}
}

namespace EraPolicy
{
Era CurrentRealmEra()
{
    uint8 const limit = sIndividualProgression->progressionLimit;
    if (limit == 0 || limit >= PROGRESSION_TBC_TIER_5)
        return Era::Wotlk;
    if (limit >= PROGRESSION_PRE_TBC)
        return Era::Tbc;
    return Era::Vanilla;
}

void ApplyRealmEra(Era era)
{
    // mod-individual-progression uses 0 as "no ceiling", which is the WotLK state on this realm.
    sIndividualProgression->progressionLimit = era == Era::Wotlk ? 0 : ProgressionCeiling(era);
    sIndividualProgression->BotAccountsMaxLevel = LevelCap(era);
}

Era EraForLevel(uint8 level)
{
    if (level > 70)
        return Era::Wotlk;
    if (level > 60)
        return Era::Tbc;
    return Era::Vanilla;
}

Era EraForProgression(uint8 progression)
{
    if (progression >= PROGRESSION_TBC_TIER_5)
        return Era::Wotlk;
    if (progression >= PROGRESSION_PRE_TBC)
        return Era::Tbc;
    return Era::Vanilla;
}

uint8 LevelCap(Era era)
{
    switch (era)
    {
        case Era::Vanilla: return 60;
        case Era::Tbc: return 70;
        case Era::Wotlk: return 80;
    }
    return 60;
}

uint8 RealmLevelCap()
{
    return LevelCap(CurrentRealmEra());
}

bool IsLevelAllowed(uint8 level)
{
    return level <= RealmLevelCap();
}

uint8 ProgressionCeiling(Era era)
{
    switch (era)
    {
        case Era::Vanilla: return PROGRESSION_NAXX40;
        case Era::Tbc: return PROGRESSION_TBC_TIER_4;
        case Era::Wotlk: return PROGRESSION_WOTLK_TIER_5;
    }
    return PROGRESSION_NAXX40;
}

uint8 RealmProgressionCeiling()
{
    return ProgressionCeiling(CurrentRealmEra());
}

uint8 MinimumProgression(Era era)
{
    switch (era)
    {
        case Era::Vanilla: return PROGRESSION_START;
        case Era::Tbc: return PROGRESSION_PRE_TBC;
        case Era::Wotlk: return PROGRESSION_TBC_TIER_5;
    }
    return PROGRESSION_START;
}

uint8 RealmMinimumProgression()
{
    return MinimumProgression(CurrentRealmEra());
}

bool IsProgressionAllowed(uint8 progression)
{
    return progression <= RealmProgressionCeiling();
}

bool IsEraReleased(Era era)
{
    return static_cast<uint8>(era) <= static_cast<uint8>(CurrentRealmEra());
}

char const* Name(Era era)
{
    switch (era)
    {
        case Era::Vanilla: return "Vanilla";
        case Era::Tbc: return "TBC";
        case Era::Wotlk: return "WotLK";
    }
    return "Vanilla";
}

char const* Token(Era era)
{
    switch (era)
    {
        case Era::Vanilla: return "VANILLA";
        case Era::Tbc: return "TBC";
        case Era::Wotlk: return "WOTLK";
    }
    return "VANILLA";
}

char const* Key(Era era)
{
    switch (era)
    {
        case Era::Vanilla: return "vanilla";
        case Era::Tbc: return "tbc";
        case Era::Wotlk: return "wotlk";
    }
    return "vanilla";
}

bool Parse(std::string_view value, Era& era)
{
    std::string const normalized = Normalize(value);
    if (normalized == "vanilla" || normalized == "classic" || normalized == "60")
    {
        era = Era::Vanilla;
        return true;
    }
    if (normalized == "tbc" || normalized == "burningcrusade" || normalized == "70")
    {
        era = Era::Tbc;
        return true;
    }
    if (normalized == "wotlk" || normalized == "wrath" || normalized == "80")
    {
        era = Era::Wotlk;
        return true;
    }
    return false;
}
}
