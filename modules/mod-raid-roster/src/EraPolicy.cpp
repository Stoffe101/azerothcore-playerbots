#include "EraPolicy.h"

#include "DBCStores.h"
#include "IndividualProgression.h"
#include "Log.h"
#include "PlayerbotAIConfig.h"
#include "RandomBotLevelMgr.h"
#include "SharedDefines.h"

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
    SyncRuntimeBotCaps();
}

void SyncRuntimeBotCaps()
{
    uint8 const cap = RealmLevelCap();
    sIndividualProgression->BotAccountsMaxLevel = cap;

    // Playerbots has its own runtime ceiling and a level-bracket manager that snapshots it.
    // Drive both from the live era rather than leaving an 80 cap active on Vanilla/TBC.
    sPlayerbotAIConfig.randomBotMaxLevel = cap;
    RandomBotLevelMgr::instance().LoadConfig();

    LOG_INFO(
        "server.loading",
        "[EraPolicy] Runtime bot caps synchronized: era={} cap={} (IP + Playerbots).",
        Name(CurrentRealmEra()),
        uint32(cap));
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

Era RequiredEraForClass(uint8 classId)
{
    return classId == CLASS_DEATH_KNIGHT ? Era::Wotlk : Era::Vanilla;
}

bool IsClassAllowed(uint8 classId)
{
    switch (classId)
    {
        case CLASS_WARRIOR:
        case CLASS_PALADIN:
        case CLASS_HUNTER:
        case CLASS_ROGUE:
        case CLASS_PRIEST:
        case CLASS_SHAMAN:
        case CLASS_MAGE:
        case CLASS_WARLOCK:
        case CLASS_DRUID:
            return true;
        case CLASS_DEATH_KNIGHT:
            return IsEraReleased(Era::Wotlk);
        default:
            return false;
    }
}

Era RequiredEraForRace(uint8 raceId)
{
    return raceId == RACE_BLOODELF || raceId == RACE_DRAENEI ? Era::Tbc : Era::Vanilla;
}

bool IsRaceAllowed(uint8 raceId)
{
    switch (raceId)
    {
        case RACE_HUMAN:
        case RACE_ORC:
        case RACE_DWARF:
        case RACE_NIGHTELF:
        case RACE_UNDEAD_PLAYER:
        case RACE_TAUREN:
        case RACE_GNOME:
        case RACE_TROLL:
            return true;
        case RACE_BLOODELF:
        case RACE_DRAENEI:
            return IsEraReleased(Era::Tbc);
        default:
            return false;
    }
}

Era RequiredEraForProfession(uint32 skillId)
{
    if (skillId == SKILL_INSCRIPTION)
        return Era::Wotlk;
    if (skillId == SKILL_JEWELCRAFTING)
        return Era::Tbc;
    return Era::Vanilla;
}

bool IsProfessionAllowed(uint32 skillId)
{
    switch (skillId)
    {
        case SKILL_ALCHEMY:
        case SKILL_BLACKSMITHING:
        case SKILL_ENCHANTING:
        case SKILL_ENGINEERING:
        case SKILL_HERBALISM:
        case SKILL_LEATHERWORKING:
        case SKILL_MINING:
        case SKILL_SKINNING:
        case SKILL_TAILORING:
        case SKILL_COOKING:
        case SKILL_FIRST_AID:
        case SKILL_FISHING:
            return true;
        case SKILL_JEWELCRAFTING:
            return IsEraReleased(Era::Tbc);
        case SKILL_INSCRIPTION:
            return IsEraReleased(Era::Wotlk);
        default:
            return false;
    }
}

uint16 ProfessionSkillCap(Era era)
{
    switch (era)
    {
        case Era::Vanilla: return 300;
        case Era::Tbc: return 375;
        case Era::Wotlk: return 450;
    }
    return 300;
}

uint16 RealmProfessionSkillCap()
{
    return ProfessionSkillCap(CurrentRealmEra());
}

bool TryMapEra(uint32 mapId, Era& era)
{
    MapEntry const* map = sMapStore.LookupEntry(mapId);
    if (!map)
        return false;

    uint32 const expansion = map->Expansion();
    era = expansion == 0 ? Era::Vanilla : (expansion == 1 ? Era::Tbc : Era::Wotlk);
    return true;
}

bool IsMapAllowed(uint32 mapId)
{
    Era era;
    return TryMapEra(mapId, era) && IsEraReleased(era);
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
