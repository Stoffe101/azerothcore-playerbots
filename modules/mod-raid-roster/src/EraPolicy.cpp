#include "EraPolicy.h"

#include "Config.h"
#include "DBCStores.h"
#include "ItemTemplate.h"
#include "ObjectMgr.h"
#include "IndividualProgression.h"
#include "Log.h"
#include "PlayerbotAIConfig.h"
#include "RandomBotLevelMgr.h"
#include "SharedDefines.h"
#include "SpellInfo.h"
#include "SpellMgr.h"

#include <algorithm>
#include <cctype>
#include <limits>
#include <sstream>
#include <string>
#include <unordered_map>
#include <unordered_set>
#include <vector>

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

std::string Trim(std::string value)
{
    auto const notSpace = [](unsigned char c) { return !std::isspace(c); };
    value.erase(value.begin(), std::find_if(value.begin(), value.end(), notSpace));
    value.erase(std::find_if(value.rbegin(), value.rend(), notSpace).base(), value.end());
    return value;
}

bool ParseUint32(std::string const& value, uint32& out)
{
    try
    {
        size_t used = 0;
        unsigned long parsed = std::stoul(value, &used, 10);
        if (used != value.size() || parsed > std::numeric_limits<uint32>::max())
            return false;
        out = static_cast<uint32>(parsed);
        return true;
    }
    catch (...)
    {
        return false;
    }
}

bool ParseHex64(std::string const& value, uint64& out)
{
    try
    {
        size_t used = 0;
        unsigned long long parsed = std::stoull(value, &used, 16);
        if (used != value.size())
            return false;
        out = static_cast<uint64>(parsed);
        return true;
    }
    catch (...)
    {
        return false;
    }
}

bool ParseItemIdList(std::string const& value, std::unordered_set<uint32>& out, std::string& error)
{
    std::stringstream stream(value);
    std::string token;
    while (std::getline(stream, token, ','))
    {
        token = Trim(token);
        if (token.empty())
            continue;

        size_t const dash = token.find('-');
        if (dash == std::string::npos)
        {
            uint32 itemId = 0;
            if (!ParseUint32(token, itemId))
            {
                error = "invalid item id token '" + token + "'";
                return false;
            }
            out.insert(itemId);
            continue;
        }

        if (token.find('-', dash + 1) != std::string::npos)
        {
            error = "invalid item id range '" + token + "'";
            return false;
        }

        uint32 first = 0;
        uint32 last = 0;
        if (!ParseUint32(Trim(token.substr(0, dash)), first) ||
            !ParseUint32(Trim(token.substr(dash + 1)), last) ||
            last < first)
        {
            error = "invalid item id range '" + token + "'";
            return false;
        }

        for (uint64 itemId = first; itemId <= uint64(last); ++itemId)
            out.insert(static_cast<uint32>(itemId));
    }
    return true;
}

uint64 FingerprintItemIds(std::vector<uint32> ids)
{
    std::sort(ids.begin(), ids.end());
    ids.erase(std::unique(ids.begin(), ids.end()), ids.end());

    uint64 hash = 14695981039346656037ULL;
    constexpr uint64 prime = 1099511628211ULL;
    for (uint32 itemId : ids)
    {
        for (uint8 shift = 0; shift < 32; shift += 8)
        {
            hash ^= uint8((itemId >> shift) & 0xFFu);
            hash *= prime;
        }
    }
    return hash;
}

struct ItemProvenanceCache
{
    bool enabled = false;
    bool ready = false;
    std::string sourceSet;
    std::string error;
    uint32 worldItemCount = 0;
    uint32 unknownCount = 0;
    uint64 worldFingerprint = 0;
    std::unordered_set<uint32> disabledVanilla;
    std::unordered_set<uint32> disabledTbc;
    std::unordered_set<uint32> disabledWotlk;
};

ItemProvenanceCache BuildItemProvenanceCache()
{
    ItemProvenanceCache cache;

    std::vector<uint32> liveItemIds;
    liveItemIds.reserve(sObjectMgr->GetItemTemplateStore()->size());
    for (auto const& [itemId, item] : *sObjectMgr->GetItemTemplateStore())
    {
        (void)item;
        liveItemIds.push_back(itemId);
    }
    cache.worldItemCount = uint32(liveItemIds.size());
    cache.worldFingerprint = FingerprintItemIds(liveItemIds);

    cache.enabled = sConfigMgr->GetOption<bool>("EraPolicy.ItemProvenance.Enable", false);
    if (!cache.enabled)
    {
        cache.error = "central item provenance is disabled";
        return cache;
    }

    cache.sourceSet = sConfigMgr->GetOption<std::string>("EraPolicy.ItemProvenance.SourceSet", "");
    uint32 const configuredCount =
        sConfigMgr->GetOption<uint32>("EraPolicy.ItemProvenance.WorldItemCount", 0);
    std::string const configuredFingerprintText =
        sConfigMgr->GetOption<std::string>("EraPolicy.ItemProvenance.WorldItemFingerprint", "");
    cache.unknownCount =
        sConfigMgr->GetOption<uint32>("EraPolicy.ItemProvenance.UnknownCount", 0);
    uint32 const configuredVanillaBlocked =
        sConfigMgr->GetOption<uint32>("EraPolicy.ItemProvenance.DisabledVanillaCount", 0);
    uint32 const configuredTbcBlocked =
        sConfigMgr->GetOption<uint32>("EraPolicy.ItemProvenance.DisabledTbcCount", 0);
    uint32 const configuredWotlkBlocked =
        sConfigMgr->GetOption<uint32>("EraPolicy.ItemProvenance.DisabledWotlkCount", 0);

    uint64 configuredFingerprint = 0;
    if (cache.sourceSet.empty() || configuredCount == 0 || configuredFingerprintText.empty() ||
        !ParseHex64(configuredFingerprintText, configuredFingerprint))
    {
        cache.error = "central item provenance metadata is incomplete";
        return cache;
    }

    if (!ParseItemIdList(
            sConfigMgr->GetOption<std::string>("EraPolicy.ItemProvenance.DisabledVanillaItemIDs", ""),
            cache.disabledVanilla,
            cache.error) ||
        !ParseItemIdList(
            sConfigMgr->GetOption<std::string>("EraPolicy.ItemProvenance.DisabledTbcItemIDs", ""),
            cache.disabledTbc,
            cache.error) ||
        !ParseItemIdList(
            sConfigMgr->GetOption<std::string>("EraPolicy.ItemProvenance.DisabledWotlkItemIDs", ""),
            cache.disabledWotlk,
            cache.error))
    {
        return cache;
    }

    if (configuredCount != cache.worldItemCount || configuredFingerprint != cache.worldFingerprint)
    {
        std::ostringstream detail;
        detail << "live item_template drift (configured count/fingerprint=" << configuredCount << "/"
               << configuredFingerprintText << ", live=" << cache.worldItemCount << "/";
        detail << std::hex << cache.worldFingerprint << ")";
        cache.error = detail.str();
        return cache;
    }

    if (configuredVanillaBlocked != cache.disabledVanilla.size() ||
        configuredTbcBlocked != cache.disabledTbc.size() ||
        configuredWotlkBlocked != cache.disabledWotlk.size() ||
        cache.unknownCount != cache.disabledWotlk.size())
    {
        cache.error = "central item provenance blocklist counts do not match generated metadata";
        return cache;
    }

    for (uint32 itemId : cache.disabledTbc)
    {
        if (!cache.disabledVanilla.count(itemId))
        {
            cache.error = "TBC blocklist is not a subset of the Vanilla blocklist";
            return cache;
        }
    }
    for (uint32 itemId : cache.disabledWotlk)
    {
        if (!cache.disabledTbc.count(itemId))
        {
            cache.error = "WotLK/UNKNOWN blocklist is not a subset of the TBC blocklist";
            return cache;
        }
    }

    for (uint32 itemId : cache.disabledVanilla)
    {
        if (!sObjectMgr->GetItemTemplate(itemId))
        {
            cache.error = "central item provenance references an item missing from live item_template";
            return cache;
        }
    }

    cache.ready = true;
    LOG_INFO(
        "server.loading",
        "[EraPolicy] Item provenance ready: source={} liveItems={} vanillaBlocked={} tbcBlocked={} "
        "wotlkUnknownBlocked={} unknown={}.",
        cache.sourceSet,
        cache.worldItemCount,
        uint32(cache.disabledVanilla.size()),
        uint32(cache.disabledTbc.size()),
        uint32(cache.disabledWotlk.size()),
        cache.unknownCount);
    return cache;
}

ItemProvenanceCache const& GetItemProvenanceCache()
{
    // Generated config is applied before worldserver startup by setup/update. A restart is the
    // reload boundary, which keeps every item consumer on the same immutable provenance snapshot.
    static ItemProvenanceCache const cache = BuildItemProvenanceCache();
    return cache;
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

bool ItemProvenanceReady()
{
    return GetItemProvenanceCache().ready;
}

char const* ItemProvenanceSourceSet()
{
    return GetItemProvenanceCache().sourceSet.c_str();
}

char const* ItemProvenanceError()
{
    return GetItemProvenanceCache().error.c_str();
}

uint32 ItemProvenanceWorldItemCount()
{
    return GetItemProvenanceCache().worldItemCount;
}

uint32 ItemProvenanceUnknownCount()
{
    return GetItemProvenanceCache().unknownCount;
}

uint32 ItemProvenanceBlockedCount(Era era)
{
    ItemProvenanceCache const& cache = GetItemProvenanceCache();
    switch (era)
    {
        case Era::Vanilla: return uint32(cache.disabledVanilla.size());
        case Era::Tbc: return uint32(cache.disabledTbc.size());
        case Era::Wotlk: return uint32(cache.disabledWotlk.size());
    }
    return 0;
}

uint64 ItemProvenanceWorldFingerprint()
{
    return GetItemProvenanceCache().worldFingerprint;
}

bool TryItemEra(uint32 itemId, Era& era)
{
    ItemProvenanceCache const& cache = GetItemProvenanceCache();
    if (!cache.ready || !sObjectMgr->GetItemTemplate(itemId))
        return false;

    // The generated lists are nested:
    // Vanilla blocks TBC+WotLK+UNKNOWN, TBC blocks WotLK+UNKNOWN, WotLK blocks UNKNOWN.
    if (cache.disabledWotlk.count(itemId))
        return false;
    if (cache.disabledTbc.count(itemId))
    {
        era = Era::Wotlk;
        return true;
    }
    if (cache.disabledVanilla.count(itemId))
    {
        era = Era::Tbc;
        return true;
    }

    era = Era::Vanilla;
    return true;
}

bool IsItemAllowed(uint32 itemId)
{
    Era itemEra;
    return TryItemEra(itemId, itemEra) && IsEraReleased(itemEra);
}

CraftOutputResolution ResolveCraftOutputs(SpellInfo const* spellInfo)
{
    CraftOutputResolution result;
    result.provenanceReady = ItemProvenanceReady();
    if (!spellInfo || !result.provenanceReady)
        return result;

    bool createsItem = false;
    for (uint8 effect = 0; effect < MAX_SPELL_EFFECTS; ++effect)
    {
        auto const& spellEffect = spellInfo->Effects[effect];
        if (spellEffect.Effect == SPELL_EFFECT_CREATE_RANDOM_ITEM)
            return result;
        if (spellEffect.Effect != SPELL_EFFECT_CREATE_ITEM &&
            spellEffect.Effect != SPELL_EFFECT_CREATE_ITEM_2)
            continue;

        createsItem = true;
        if (spellEffect.Effect == SPELL_EFFECT_CREATE_ITEM_2 && spellInfo->IsLootCrafting())
        {
            // EffectCreateItem2 calls AutoStoreLoot(spellId, LootTemplates_Spell). The loaded
            // LootTemplate keeps grouped entries and recursive references private, with no
            // public enumeration API. A fresh SQL read cannot prove the loaded runtime set.
            // Keep this result unresolved before any automated cast can consume reagents.
            return result;
        }

        if (!spellEffect.ItemType)
            return result;
        result.itemIds.push_back(spellEffect.ItemType);
    }

    result.resolved = createsItem;
    result.allowed = result.resolved &&
        std::all_of(result.itemIds.begin(), result.itemIds.end(), [](uint32 itemId)
        {
            return IsItemAllowed(itemId);
        });
    return result;
}

bool IsAutomatedCraftSpellAllowed(uint32 spellId)
{
    CraftOutputResolution const outputs = ResolveCraftOutputs(sSpellMgr->GetSpellInfo(spellId));
    if (!outputs.resolved || !outputs.allowed)
        return false;

    static std::unordered_map<uint32, std::vector<uint32>> const recipeItemsBySpell = []
    {
        std::unordered_map<uint32, std::vector<uint32>> result;
        for (auto const& [itemEntry, proto] : *sObjectMgr->GetItemTemplateStore())
        {
            if (proto.Class != ITEM_CLASS_RECIPE)
                continue;
            for (uint8 slot = 0; slot < MAX_ITEM_PROTO_SPELLS; ++slot)
                if (proto.Spells[slot].SpellId > 0 &&
                    proto.Spells[slot].SpellTrigger == ITEM_SPELLTRIGGER_LEARN_SPELL_ID)
                    result[uint32(proto.Spells[slot].SpellId)].push_back(itemEntry);
        }
        return result;
    }();

    auto itr = recipeItemsBySpell.find(spellId);
    return itr == recipeItemsBySpell.end() ||
        std::any_of(itr->second.begin(), itr->second.end(), [](uint32 itemEntry)
        {
            return IsItemAllowed(itemEntry);
        });
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
