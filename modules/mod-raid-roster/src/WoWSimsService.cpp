#include "WoWSimsService.h"

#include "Config.h"
#include "DBCStores.h"
#include "EraPolicy.h"
#include "Item.h"
#include "Player.h"
#include "PlayerbotAI.h"
#include "SharedDefines.h"
#include "httplib.h"
#include "nlohmann/json.hpp"

#include <algorithm>
#include <array>
#include <cstdint>
#include <regex>
#include <sstream>
#include <string>
#include <unordered_map>
#include <utility>
#include <vector>

namespace
{
using json = nlohmann::json;

struct GearSlot
{
    uint8 slot;
    char const* name;
};

static constexpr std::array<GearSlot, 17> kGearSlots = {{
    { EQUIPMENT_SLOT_HEAD, "HEAD" },
    { EQUIPMENT_SLOT_NECK, "NECK" },
    { EQUIPMENT_SLOT_SHOULDERS, "SHOULDERS" },
    { EQUIPMENT_SLOT_BACK, "BACK" },
    { EQUIPMENT_SLOT_CHEST, "CHEST" },
    { EQUIPMENT_SLOT_WRISTS, "WRISTS" },
    { EQUIPMENT_SLOT_HANDS, "HANDS" },
    { EQUIPMENT_SLOT_WAIST, "WAIST" },
    { EQUIPMENT_SLOT_LEGS, "LEGS" },
    { EQUIPMENT_SLOT_FEET, "FEET" },
    { EQUIPMENT_SLOT_FINGER1, "FINGER1" },
    { EQUIPMENT_SLOT_FINGER2, "FINGER2" },
    { EQUIPMENT_SLOT_TRINKET1, "TRINKET1" },
    { EQUIPMENT_SLOT_TRINKET2, "TRINKET2" },
    { EQUIPMENT_SLOT_MAINHAND, "MAINHAND" },
    { EQUIPMENT_SLOT_OFFHAND, "OFFHAND" },
    { EQUIPMENT_SLOT_RANGED, "RANGED" },
}};

char const* ClassToken(uint8 classId)
{
    switch (classId)
    {
        case CLASS_WARRIOR: return "WARRIOR";
        case CLASS_PALADIN: return "PALADIN";
        case CLASS_HUNTER: return "HUNTER";
        case CLASS_ROGUE: return "ROGUE";
        case CLASS_PRIEST: return "PRIEST";
        case CLASS_DEATH_KNIGHT: return "DEATHKNIGHT";
        case CLASS_SHAMAN: return "SHAMAN";
        case CLASS_MAGE: return "MAGE";
        case CLASS_WARLOCK: return "WARLOCK";
        case CLASS_DRUID: return "DRUID";
        default: return "UNKNOWN";
    }
}

char const* RaceToken(uint8 raceId)
{
    switch (raceId)
    {
        case RACE_HUMAN: return "HUMAN";
        case RACE_ORC: return "ORC";
        case RACE_DWARF: return "DWARF";
        case RACE_NIGHTELF: return "NIGHTELF";
        case RACE_UNDEAD_PLAYER: return "UNDEAD";
        case RACE_TAUREN: return "TAUREN";
        case RACE_GNOME: return "GNOME";
        case RACE_TROLL: return "TROLL";
        case RACE_BLOODELF: return "BLOODELF";
        case RACE_DRAENEI: return "DRAENEI";
        default: return "UNKNOWN";
    }
}

char const* RoleToken(Player* player)
{
    if (PlayerbotAI::IsTank(player, true))
        return "TANK";
    if (PlayerbotAI::IsHeal(player, true))
        return "HEALER";
    return "DPS";
}

std::string BuildTalentString(Player* player)
{
    if (!player || player->getClass() == 0)
        return "";

    uint32 const classMask = 1u << (player->getClass() - 1);
    std::array<std::vector<TalentEntry const*>, 3> tabs;

    for (uint32 id = 0; id < sTalentStore.GetNumRows(); ++id)
    {
        TalentEntry const* talent = sTalentStore.LookupEntry(id);
        if (!talent)
            continue;

        TalentTabEntry const* tab = sTalentTabStore.LookupEntry(talent->TalentTab);
        if (!tab || tab->tabpage >= tabs.size() || !(tab->ClassMask & classMask))
            continue;

        tabs[tab->tabpage].push_back(talent);
    }

    for (auto& entries : tabs)
        std::sort(entries.begin(), entries.end(), [](TalentEntry const* left, TalentEntry const* right)
        {
            if (left->Row != right->Row)
                return left->Row < right->Row;
            if (left->Col != right->Col)
                return left->Col < right->Col;
            return left->TalentID < right->TalentID;
        });

    std::unordered_map<uint32, uint8> rankByTalent;
    uint8 const activeSpec = player->GetActiveSpec();
    for (auto const& [spellId, state] : player->GetTalentMap())
    {
        if (!state || state->State == PLAYERSPELL_REMOVED || !state->IsInSpec(activeSpec))
            continue;

        TalentEntry const* talent = sTalentStore.LookupEntry(state->talentID);
        if (!talent)
            continue;

        uint8 learnedRank = 0;
        for (uint8 rank = 0; rank < MAX_TALENT_RANK; ++rank)
        {
            if (talent->RankID[rank] == spellId)
            {
                learnedRank = rank + 1;
                break;
            }
        }

        auto found = rankByTalent.find(talent->TalentID);
        if (found == rankByTalent.end() || learnedRank > found->second)
            rankByTalent[talent->TalentID] = learnedRank;
    }

    std::ostringstream out;
    for (uint8 tab = 0; tab < tabs.size(); ++tab)
    {
        if (tab)
            out << '-';

        for (TalentEntry const* talent : tabs[tab])
        {
            uint8 const rank = rankByTalent.count(talent->TalentID) ? rankByTalent[talent->TalentID] : 0;
            out << char('0' + std::min<uint8>(rank, 9));
        }
    }
    return out.str();
}

json BuildGear(Player* player)
{
    json gear = json::array();
    static constexpr std::array<EnchantmentSlot, 3> socketSlots = {
        SOCK_ENCHANTMENT_SLOT,
        SOCK_ENCHANTMENT_SLOT_2,
        SOCK_ENCHANTMENT_SLOT_3,
    };

    for (GearSlot const& descriptor : kGearSlots)
    {
        Item* item = player->GetItemByPos(INVENTORY_SLOT_BAG_0, descriptor.slot);
        if (!item)
        {
            gear.push_back(nullptr);
            continue;
        }

        json gems = json::array();
        for (EnchantmentSlot socket : socketSlots)
        {
            uint32 const enchantId = item->GetEnchantmentId(socket);
            uint32 gemId = 0;
            if (enchantId)
                if (SpellItemEnchantmentEntry const* enchant = sSpellItemEnchantmentStore.LookupEntry(enchantId))
                    gemId = enchant->GemID;
            gems.push_back(gemId);
        }

        gear.push_back({
            { "slot", descriptor.name },
            { "id", item->GetEntry() },
            { "enchant", item->GetEnchantmentId(PERM_ENCHANTMENT_SLOT) },
            { "gems", std::move(gems) },
            { "randomPropertyId", item->GetItemRandomPropertyId() },
            { "suffixFactor", item->GetItemSuffixFactor() },
        });
    }
    return gear;
}

json BuildGlyphs(Player* player)
{
    json glyphs = json::array();
    for (uint8 slot = 0; slot < MAX_GLYPH_SLOT_INDEX; ++slot)
    {
        uint32 const glyphPropertyId = player->GetGlyph(slot);
        if (!glyphPropertyId)
            continue;

        json glyph = {
            { "slot", slot },
            { "glyphPropertyId", glyphPropertyId },
        };
        if (GlyphPropertiesEntry const* property = sGlyphPropertiesStore.LookupEntry(glyphPropertyId))
        {
            glyph["spellId"] = property->SpellId;
            glyph["typeFlags"] = property->TypeFlags;
        }
        glyphs.push_back(std::move(glyph));
    }
    return glyphs;
}

json BuildProfessions(Player* player)
{
    struct Profession
    {
        uint32 skill;
        char const* name;
    };

    static constexpr std::array<Profession, 11> professions = {{
        { SKILL_ALCHEMY, "ALCHEMY" },
        { SKILL_BLACKSMITHING, "BLACKSMITHING" },
        { SKILL_ENCHANTING, "ENCHANTING" },
        { SKILL_ENGINEERING, "ENGINEERING" },
        { SKILL_HERBALISM, "HERBALISM" },
        { SKILL_INSCRIPTION, "INSCRIPTION" },
        { SKILL_JEWELCRAFTING, "JEWELCRAFTING" },
        { SKILL_LEATHERWORKING, "LEATHERWORKING" },
        { SKILL_MINING, "MINING" },
        { SKILL_SKINNING, "SKINNING" },
        { SKILL_TAILORING, "TAILORING" },
    }};

    json out = json::array();
    for (Profession const& profession : professions)
    {
        uint16 const value = player->GetSkillValue(profession.skill);
        if (!value)
            continue;
        out.push_back({
            { "skillId", profession.skill },
            { "name", profession.name },
            { "level", value },
        });
    }
    return out;
}

bool PostJson(std::string const& baseUrl, std::string const& endpoint, std::string const& body,
    uint32 timeoutSeconds, std::string& response, std::string& error)
{
    std::smatch match;
    std::regex const urlPattern(R"(^(https?)://([^:/]+)(?::(\d+))?(/.*)?$)");
    if (!std::regex_match(baseUrl, match, urlPattern))
    {
        error = "invalid RaidRoster.WoWSimsUrl";
        return false;
    }
    if (match[1] == "https")
    {
        error = "HTTPS is not supported by the internal WoWSims client; use the private Docker http URL";
        return false;
    }

    std::string const host = match[2];
    int const port = match[3].matched ? std::stoi(match[3]) : 80;
    std::string basePath = match[4].matched ? std::string(match[4]) : "";
    while (!basePath.empty() && basePath.back() == '/')
        basePath.pop_back();
    std::string const path = basePath + endpoint;

    httplib::Client client(host, port);
    client.set_connection_timeout(2, 0);
    client.set_read_timeout(timeoutSeconds, 0);
    client.set_write_timeout(3, 0);

    auto result = client.Post(path, body, "application/json");
    if (!result)
    {
        error = "no response from " + baseUrl + endpoint;
        return false;
    }
    if (result->status != 200)
    {
        error = "HTTP " + std::to_string(result->status) + " from " + baseUrl + endpoint;
        if (!result->body.empty())
            error += ": " + result->body.substr(0, 300);
        return false;
    }

    response = result->body;
    return true;
}
}

namespace WoWSimsService
{
std::string BuildCharacterSnapshot(Player* player)
{
    if (!player)
        return "{}";

    uint8 treePoints[3] = { 0, 0, 0 };
    player->GetTalentTreePoints(treePoints);

    json snapshot = {
        { "schema", 1 },
        { "era", EraPolicy::Token(EraPolicy::CurrentRealmEra()) },
        { "realmLevelCap", EraPolicy::RealmLevelCap() },
        { "character", {
            { "guid", player->GetGUID().GetCounter() },
            { "name", player->GetName() },
            { "level", player->GetLevel() },
            { "classId", player->getClass() },
            { "class", ClassToken(player->getClass()) },
            { "raceId", player->getRace() },
            { "race", RaceToken(player->getRace()) },
            { "role", RoleToken(player) },
            { "activeSpecSlot", player->GetActiveSpec() },
            { "dominantTree", player->GetMostPointsTalentTree() },
            { "treePoints", { treePoints[0], treePoints[1], treePoints[2] } },
            { "talents", BuildTalentString(player) },
            { "gear", BuildGear(player) },
            { "glyphs", BuildGlyphs(player) },
            { "professions", BuildProfessions(player) },
        } },
    };

    return snapshot.dump();
}

bool ValidateCharacterSnapshot(Player* player, std::string& summary, std::string& error)
{
    if (!player)
    {
        error = "player is unavailable";
        return false;
    }

    std::string const body = BuildCharacterSnapshot(player);
    std::string const baseUrl =
        sConfigMgr->GetOption<std::string>("RaidRoster.WoWSimsUrl", "http://ac-wowsims:8092");
    uint32 const timeout =
        std::max<uint32>(1, sConfigMgr->GetOption<uint32>("RaidRoster.WoWSimsTimeoutSeconds", 5));

    std::string response;
    if (!PostJson(baseUrl, "/v1/snapshot/validate", body, timeout, response, error))
        return false;

    try
    {
        json const parsed = json::parse(response);
        if (!parsed.value("valid", false))
        {
            error = parsed.value("error", std::string("service rejected the character snapshot"));
            return false;
        }

        json const support = parsed.value("support", json::object());
        json const engine = parsed.value("engine", json::object());
        summary =
            "era=" + parsed.value("era", std::string("UNKNOWN")) +
            ", model=" + support.value("modelKey", std::string("unknown")) +
            ", status=" + support.value("status", std::string("UNKNOWN")) +
            ", engine=" + engine.value("repository", std::string("unknown")) +
            "@" + engine.value("commit", std::string("unknown")).substr(0, 8);
        return true;
    }
    catch (std::exception const& ex)
    {
        error = std::string("invalid JSON from WoWSims service: ") + ex.what();
        return false;
    }
}
}
