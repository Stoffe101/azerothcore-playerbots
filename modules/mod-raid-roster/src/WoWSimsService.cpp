#include "WoWSimsService.h"

#include "Bag.h"
#include "Chat.h"
#include "Config.h"
#include "DBCStores.h"
#include "EraPolicy.h"
#include "Item.h"
#include "ObjectAccessor.h"
#include "Player.h"
#include "PlayerbotAI.h"
#include "SharedDefines.h"
#include "httplib.h"
#include "nlohmann/json.hpp"

#include <algorithm>
#include <array>
#include <condition_variable>
#include <cstdint>
#include <deque>
#include <mutex>
#include <regex>
#include <sstream>
#include <string>
#include <thread>
#include <unordered_map>
#include <unordered_set>
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

struct AsyncBagJob
{
    uint64 id = 0;
    uint32 playerGuid = 0;
    std::string baseUrl;
    uint32 timeoutSeconds = 300;
    std::string body;
    std::string characterSnapshot;
    std::string bagCandidateSnapshot;
};

struct AsyncBagResult
{
    uint64 id = 0;
    uint32 playerGuid = 0;
    bool success = false;
    std::string response;
    std::string error;
    std::string characterSnapshot;
    std::string bagCandidateSnapshot;
};

std::mutex g_asyncMutex;
std::condition_variable g_asyncCv;
std::deque<AsyncBagJob> g_asyncPending;
std::deque<AsyncBagResult> g_asyncCompleted;
std::unordered_set<uint32> g_asyncActivePlayers;
std::thread g_asyncWorker;
bool g_asyncStopping = false;
uint64 g_asyncNextJobId = 1;

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

json BuildItemState(Item* item)
{
    static constexpr std::array<EnchantmentSlot, 3> socketSlots = {
        SOCK_ENCHANTMENT_SLOT,
        SOCK_ENCHANTMENT_SLOT_2,
        SOCK_ENCHANTMENT_SLOT_3,
    };

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

    return {
        { "id", item->GetEntry() },
        { "enchant", item->GetEnchantmentId(PERM_ENCHANTMENT_SLOT) },
        { "gems", std::move(gems) },
        { "randomPropertyId", item->GetItemRandomPropertyId() },
        { "suffixFactor", item->GetItemSuffixFactor() },
    };
}

json BuildGear(Player* player)
{
    json gear = json::array();
    for (GearSlot const& descriptor : kGearSlots)
    {
        Item* item = player->GetItemByPos(INVENTORY_SLOT_BAG_0, descriptor.slot);
        if (!item)
        {
            gear.push_back(nullptr);
            continue;
        }

        json state = BuildItemState(item);
        state["slot"] = descriptor.name;
        gear.push_back(std::move(state));
    }
    return gear;
}

bool CandidateWouldChangeSecondSlot(Player* player, Item* item, uint8 equipmentSlot)
{
    if (!player || !item || equipmentSlot != EQUIPMENT_SLOT_MAINHAND)
        return false;

    ItemTemplate const* proto = item->GetTemplate();
    if (!proto || proto->InventoryType != INVTYPE_2HWEAPON)
        return false;
    if (!player->GetItemByPos(INVENTORY_SLOT_BAG_0, EQUIPMENT_SLOT_OFFHAND))
        return false;

    return !player->CanTitanGrip() ||
        proto->SubClass == ITEM_SUBCLASS_WEAPON_POLEARM ||
        proto->SubClass == ITEM_SUBCLASS_WEAPON_STAFF ||
        proto->SubClass == ITEM_SUBCLASS_WEAPON_FISHING_POLE;
}

json BuildBagCandidates(Player* player)
{
    json candidates = json::array();
    uint32 scanned = 0;
    uint32 eraBlocked = 0;
    uint32 noEquipSlot = 0;
    uint32 multiSlotBlocked = 0;

    auto inspect = [&](Item* item, uint8 bag, uint8 slot)
    {
        if (!item)
            return;

        ++scanned;
        if (!EraPolicy::IsItemAllowed(item->GetEntry()))
        {
            ++eraBlocked;
            return;
        }

        json slotIndexes = json::array();
        for (std::size_t index = 0; index < kGearSlots.size(); ++index)
        {
            GearSlot const& descriptor = kGearSlots[index];
            uint16 dest = 0;
            if (player->CanEquipItem(descriptor.slot, dest, item, true, false) != EQUIP_ERR_OK)
                continue;
            if (uint8(dest & 0xFF) != descriptor.slot)
                continue;
            if (CandidateWouldChangeSecondSlot(player, item, descriptor.slot))
            {
                ++multiSlotBlocked;
                continue;
            }
            slotIndexes.push_back(index);
        }

        if (slotIndexes.empty())
        {
            ++noEquipSlot;
            return;
        }

        candidates.push_back({
            { "bag", bag },
            { "slot", slot },
            { "item", BuildItemState(item) },
            { "slotIndexes", std::move(slotIndexes) },
        });
    };

    for (uint8 slot = INVENTORY_SLOT_ITEM_START; slot < INVENTORY_SLOT_ITEM_END; ++slot)
        inspect(player->GetItemByPos(INVENTORY_SLOT_BAG_0, slot), INVENTORY_SLOT_BAG_0, slot);

    for (uint8 bagSlot = INVENTORY_SLOT_BAG_START; bagSlot < INVENTORY_SLOT_BAG_END; ++bagSlot)
    {
        Bag* bag = player->GetBagByPos(bagSlot);
        if (!bag)
            continue;
        for (uint8 slot = 0; slot < bag->GetBagSize(); ++slot)
            inspect(bag->GetItemByPos(slot), bagSlot, slot);
    }

    return {
        { "schema", 1 },
        { "era", EraPolicy::Token(EraPolicy::CurrentRealmEra()) },
        { "candidates", std::move(candidates) },
        { "scan", {
            { "items", scanned },
            { "eraBlocked", eraBlocked },
            { "noEquipSlot", noEquipSlot },
            { "multiSlotBlocked", multiSlotBlocked },
        } },
    };
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

std::string ProtocolField(std::string value)
{
    for (char& ch : value)
        if (ch == '|' || ch == '\n' || ch == '\r')
            ch = ' ';
    if (value.size() > 220)
        value.resize(220);
    return value;
}

void AsyncWorkerLoop()
{
    for (;;)
    {
        AsyncBagJob job;
        {
            std::unique_lock<std::mutex> lock(g_asyncMutex);
            g_asyncCv.wait(lock, [] { return g_asyncStopping || !g_asyncPending.empty(); });
            if (g_asyncStopping)
                return;

            job = std::move(g_asyncPending.front());
            g_asyncPending.pop_front();
        }

        AsyncBagResult completed;
        completed.id = job.id;
        completed.playerGuid = job.playerGuid;
        completed.characterSnapshot = std::move(job.characterSnapshot);
        completed.bagCandidateSnapshot = std::move(job.bagCandidateSnapshot);
        completed.success = PostJson(
            job.baseUrl,
            "/v1/snapshot/compare-bags",
            job.body,
            job.timeoutSeconds,
            completed.response,
            completed.error);

        std::lock_guard<std::mutex> lock(g_asyncMutex);
        g_asyncCompleted.push_back(std::move(completed));
    }
}
}

namespace WoWSimsService
{
void StartAsyncWorker()
{
    std::lock_guard<std::mutex> lock(g_asyncMutex);
    if (g_asyncWorker.joinable())
        return;

    g_asyncStopping = false;
    g_asyncWorker = std::thread(AsyncWorkerLoop);
}

void StopAsyncWorker()
{
    std::thread worker;
    {
        std::lock_guard<std::mutex> lock(g_asyncMutex);
        if (!g_asyncWorker.joinable())
            return;

        g_asyncStopping = true;
        g_asyncPending.clear();
        worker = std::move(g_asyncWorker);
    }

    g_asyncCv.notify_all();
    if (worker.joinable())
        worker.join();

    std::lock_guard<std::mutex> lock(g_asyncMutex);
    g_asyncCompleted.clear();
    g_asyncActivePlayers.clear();
    g_asyncStopping = false;
}

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


std::string BuildBagCandidateSnapshot(Player* player)
{
    if (!player)
        return "{}";
    if (!EraPolicy::ItemProvenanceReady())
    {
        return json({
            { "schema", 1 },
            { "era", EraPolicy::Token(EraPolicy::CurrentRealmEra()) },
            { "error", std::string("item provenance unavailable: ") + EraPolicy::ItemProvenanceError() },
            { "candidates", json::array() },
        }).dump();
    }
    return BuildBagCandidates(player).dump();
}


bool BuildBagCandidateManifest(Player* player, std::string& summary, std::string& error)
{
    if (!player)
    {
        error = "player is unavailable";
        return false;
    }
    if (!EraPolicy::ItemProvenanceReady())
    {
        error = std::string("item provenance unavailable: ") + EraPolicy::ItemProvenanceError();
        return false;
    }

    json snapshot;
    json bagCandidates;
    try
    {
        snapshot = json::parse(BuildCharacterSnapshot(player));
        bagCandidates = json::parse(BuildBagCandidateSnapshot(player));
    }
    catch (std::exception const& ex)
    {
        error = std::string("failed to build authoritative bag candidate input: ") + ex.what();
        return false;
    }

    json const body = {
        { "snapshot", std::move(snapshot) },
        { "candidates", bagCandidates.value("candidates", json::array()) },
    };
    std::string const baseUrl =
        sConfigMgr->GetOption<std::string>("RaidRoster.WoWSimsUrl", "http://ac-wowsims:8092");
    uint32 const timeout =
        std::max<uint32>(1, sConfigMgr->GetOption<uint32>("RaidRoster.WoWSimsTimeoutSeconds", 5));

    std::string response;
    if (!PostJson(baseUrl, "/v1/snapshot/bag-candidates", body.dump(), timeout, response, error))
        return false;

    try
    {
        json const parsed = json::parse(response);
        if (parsed.value("status", std::string()) != "BAG_CANDIDATES_BUILT_UNVALIDATED")
        {
            error = parsed.value("error", std::string("service did not build an unvalidated bag candidate manifest"));
            return false;
        }

        json const scan = bagCandidates.value("scan", json::object());
        summary =
            "era=" + parsed.value("era", std::string("UNKNOWN")) +
            ", candidates=" + std::to_string(parsed.value("candidateCount", 0u)) +
            ", swaps=" + std::to_string(parsed.value("swapCount", 0u)) +
            ", no-change=" + std::to_string(parsed.value("skippedCount", 0u)) +
            ", scanned=" + std::to_string(scan.value("items", 0u)) +
            ", era-blocked=" + std::to_string(scan.value("eraBlocked", 0u)) +
            ", multi-slot-blocked=" + std::to_string(scan.value("multiSlotBlocked", 0u)) +
            ", status=BAG_CANDIDATES_BUILT_UNVALIDATED";
        return true;
    }
    catch (std::exception const& ex)
    {
        error = std::string("invalid bag-candidate response: ") + ex.what();
        return false;
    }
}



bool BuildBaselineRequest(Player* player, std::string& summary, std::string& error)
{
    if (!player)
    {
        error = "player is unavailable";
        return false;
    }

    json snapshot;
    try
    {
        snapshot = json::parse(BuildCharacterSnapshot(player));
    }
    catch (std::exception const& ex)
    {
        error = std::string("failed to parse authoritative snapshot: ") + ex.what();
        return false;
    }

    json const body = {
        { "snapshot", std::move(snapshot) },
    };
    std::string const baseUrl =
        sConfigMgr->GetOption<std::string>("RaidRoster.WoWSimsUrl", "http://ac-wowsims:8092");
    uint32 const timeout =
        std::max<uint32>(1, sConfigMgr->GetOption<uint32>("RaidRoster.WoWSimsTimeoutSeconds", 5));

    std::string response;
    if (!PostJson(baseUrl, "/v1/snapshot/request", body.dump(), timeout, response, error))
        return false;

    try
    {
        json const parsed = json::parse(response);
        if (parsed.value("status", std::string()) != "REQUEST_BUILT_UNVALIDATED")
        {
            error = parsed.value("error", std::string("service did not build an unvalidated request"));
            return false;
        }

        json const preset = parsed.value("preset", json::object());
        json const support = parsed.value("support", json::object());
        std::string sha = preset.value("sha256", std::string());
        if (sha.size() > 12)
            sha.resize(12);
        summary =
            "era=" + parsed.value("era", std::string("UNKNOWN")) +
            ", route=" + parsed.value("routeKey", std::string("?")) +
            ", preset=" + preset.value("file", std::string("?")) +
            ", sha=" + (sha.empty() ? std::string("?") : sha) +
            ", support=" + support.value("status", std::string("UNKNOWN")) +
            ", status=REQUEST_BUILT_UNVALIDATED";
        return true;
    }
    catch (std::exception const& ex)
    {
        error = std::string("invalid request-builder response: ") + ex.what();
        return false;
    }
}

bool QueueBagComparison(Player* player, uint64& jobId, std::string& error)
{
    if (!player)
    {
        error = "player is unavailable";
        return false;
    }
    if (!EraPolicy::ItemProvenanceReady())
    {
        error = std::string("item provenance unavailable: ") + EraPolicy::ItemProvenanceError();
        return false;
    }

    json snapshot;
    json bagCandidates;
    try
    {
        snapshot = json::parse(BuildCharacterSnapshot(player));
        bagCandidates = json::parse(BuildBagCandidateSnapshot(player));
    }
    catch (std::exception const& ex)
    {
        error = std::string("failed to capture asynchronous Sim Bags input: ") + ex.what();
        return false;
    }

    json const body = {
        { "snapshot", snapshot },
        { "candidates", bagCandidates.value("candidates", json::array()) },
    };

    AsyncBagJob job;
    job.characterSnapshot = snapshot.dump();
    job.bagCandidateSnapshot = bagCandidates.dump();
    job.playerGuid = player->GetGUID().GetCounter();
    job.baseUrl = sConfigMgr->GetOption<std::string>(
        "RaidRoster.WoWSimsUrl", "http://ac-wowsims:8092");
    job.timeoutSeconds = std::clamp<uint32>(
        sConfigMgr->GetOption<uint32>("RaidRoster.WoWSimsAsyncTimeoutSeconds", 300),
        30,
        1800);
    uint32 const maxQueued = std::clamp<uint32>(
        sConfigMgr->GetOption<uint32>("RaidRoster.WoWSimsMaxQueuedJobs", 4),
        1,
        32);

    StartAsyncWorker();
    {
        std::lock_guard<std::mutex> lock(g_asyncMutex);
        if (g_asyncStopping)
        {
            error = "WoWSims asynchronous worker is stopping";
            return false;
        }
        if (g_asyncActivePlayers.count(job.playerGuid))
        {
            error = "a Sim Bags comparison is already queued or running for this character";
            return false;
        }
        if (g_asyncPending.size() >= maxQueued)
        {
            error = "WoWSims asynchronous queue is full";
            return false;
        }

        job.id = g_asyncNextJobId++;
        jobId = job.id;
        g_asyncActivePlayers.insert(job.playerGuid);
        g_asyncPending.push_back(std::move(job));
    }

    g_asyncCv.notify_one();
    return true;
}

void TickAsyncResults()
{
    std::deque<AsyncBagResult> completed;
    {
        std::lock_guard<std::mutex> lock(g_asyncMutex);
        completed.swap(g_asyncCompleted);
        for (AsyncBagResult const& result : completed)
            g_asyncActivePlayers.erase(result.playerGuid);
    }

    for (AsyncBagResult const& result : completed)
    {
        Player* player = ObjectAccessor::FindConnectedPlayer(
            ObjectGuid::Create<HighGuid::Player>(
                static_cast<ObjectGuid::LowType>(result.playerGuid)));
        if (!player || !player->GetSession())
            continue;

        ChatHandler handler(player->GetSession());
        if (
            BuildCharacterSnapshot(player) != result.characterSnapshot ||
            BuildBagCandidateSnapshot(player) != result.bagCandidateSnapshot)
        {
            handler.PSendSysMessage("[GA]|SIMSTALE|{}", result.id);
            handler.PSendSysMessage(
                "[WoWSims] async Sim Bags job {} was discarded because the character or bags changed while it was running.",
                result.id);
            continue;
        }

        auto sendProtocolError = [&](std::string const& detail)
        {
            handler.PSendSysMessage(
                "[GA]|SIMERROR|{}|{}",
                result.id,
                ProtocolField(detail));
        };

        if (!result.success)
        {
            sendProtocolError(result.error);
            handler.PSendSysMessage(
                "[WoWSims] async Sim Bags job {} failed: {}",
                result.id,
                result.error);
            continue;
        }

        try
        {
            json const parsed = json::parse(result.response);
            if (parsed.value("status", std::string()) != "BAG_COMPARE_COMPLETE_UNVALIDATED")
            {
                sendProtocolError("WoWSims returned an unexpected comparison status");
                handler.PSendSysMessage(
                    "[WoWSims] async Sim Bags job {} returned an unexpected status.",
                    result.id);
                continue;
            }

            json const support = parsed.value("support", json::object());
            std::string const supportStatus =
                ProtocolField(support.value("status", std::string("UNKNOWN")));
            std::string const metric =
                ProtocolField(parsed.value("metric", std::string("?")));
            double const baseline =
                parsed.contains("baseline") && !parsed["baseline"].is_null()
                    ? parsed["baseline"].get<double>()
                    : 0.0;

            std::ostringstream message;
            message << "[WoWSims] async Sim Bags job " << result.id
                    << " complete (UNVALIDATED): metric=" << metric
                    << ", baseline=";
            if (parsed.contains("baseline") && !parsed["baseline"].is_null())
                message << baseline;
            else
                message << "n/a";
            message << ", swaps=" << parsed.value("resultCount", 0u)
                    << ", skipped=" << parsed.value("skippedCount", 0u)
                    << ", support=" << supportStatus;

            json const best = parsed.value("bestUpgrade", json());
            if (best.is_object())
            {
                double const candidate = best.value("candidate", baseline);
                double const deltaPercent =
                    best.contains("deltaPercent") && !best["deltaPercent"].is_null()
                        ? best["deltaPercent"].get<double>()
                        : 0.0;
                uint32 const itemId = best.value("itemId", 0u);
                uint32 const slotIndex = best.value("slotIndex", 0u);

                handler.PSendSysMessage(
                    "[GA]|SIM|{}|{}|{:.6f}|{:.6f}|{:.6f}|{}|{}|{}",
                    result.id,
                    metric,
                    baseline,
                    candidate,
                    deltaPercent,
                    itemId,
                    slotIndex,
                    supportStatus);

                message << ", best=item " << itemId
                        << " -> slot " << slotIndex
                        << ", delta=" << best.value("delta", 0.0)
                        << " (" << deltaPercent << "%)";
            }
            else
            {
                handler.PSendSysMessage(
                    "[GA]|SIMNONE|{}|{}|{:.6f}|{}|{}",
                    result.id,
                    metric,
                    baseline,
                    supportStatus,
                    parsed.value("resultCount", 0u));
                message << ", best=no positive candidate";
            }

            handler.SendSysMessage(message.str());
        }
        catch (std::exception const& ex)
        {
            sendProtocolError(std::string("invalid WoWSims comparison response: ") + ex.what());
            handler.PSendSysMessage(
                "[WoWSims] async Sim Bags job {} returned invalid JSON: {}",
                result.id,
                ex.what());
        }
    }
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
