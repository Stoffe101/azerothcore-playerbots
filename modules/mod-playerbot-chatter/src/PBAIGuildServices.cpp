#include "PBAIGuildServices.h"

#include "AuctionHouseMgr.h"
#include "Bag.h"
#include "Chat.h"
#include "DatabaseEnv.h"
#include "GameTime.h"
#include "Guild.h"
#include "Item.h"
#include "ItemTemplate.h"
#include "Log.h"
#include "Mail.h"
#include "ObjectGuid.h"
#include "ObjectMgr.h"
#include "Player.h"
#include "PlayerbotAI.h"
#include "Playerbots.h"
#include "QueryResult.h"
#include "SharedDefines.h"
#include "SpellInfo.h"
#include "SpellMgr.h"
#include "World.h"
#include "WorldSession.h"

#include <algorithm>
#include <atomic>
#include <cctype>
#include <chrono>
#include <cstdint>
#include <limits>
#include <mutex>
#include <sstream>
#include <string>
#include <vector>

namespace PBAIGuildServices
{
namespace
{
constexpr uint32 COPPER_PER_GOLD = 10000;
constexpr uint32 MAX_SERVICE_STACKS = 12;
constexpr uint32 MAX_DONATION_GOLD = 100000;
std::mutex g_serviceMutex;
std::atomic<uint32> g_requestSequence{0};

struct PendingRequest
{
    uint64 id = 0;
    uint32 guildId = 0;
    uint32 requesterGuid = 0;
    uint32 targetGuid = 0;
    std::string type;
    uint32 itemId = 0;
    uint32 itemCount = 0;
    uint64 quotedCopper = 0;
};

uint64 NextRequestId()
{
    // Do not rely on LAST_INSERT_ID() across pooled DB connections. Generate a durable key on the
    // world process instead: millisecond timestamp + a 16-bit local sequence is ample for this
    // human-driven service surface and remains stable across asynchronous/direct DB helpers.
    uint64 nowMs = static_cast<uint64>(std::chrono::duration_cast<std::chrono::milliseconds>(
        std::chrono::system_clock::now().time_since_epoch()).count());
    uint64 sequence = static_cast<uint64>(g_requestSequence.fetch_add(1, std::memory_order_relaxed) & 0xFFFFu);
    return (nowMs << 16) | sequence;
}

std::string Lower(std::string value)
{
    std::transform(value.begin(), value.end(), value.begin(), [](unsigned char c)
    {
        return static_cast<char>(std::tolower(c));
    });
    return value;
}

bool ParseU32(std::string const& raw, uint32& out)
{
    try
    {
        size_t used = 0;
        unsigned long value = std::stoul(raw, &used);
        if (used != raw.size() || value > 0xFFFFFFFFul)
            return false;
        out = static_cast<uint32>(value);
        return true;
    }
    catch (...)
    {
        return false;
    }
}

void Reply(Player* player, std::string const& text)
{
    if (player && player->GetSession())
        ChatHandler(player->GetSession()).SendSysMessage(text.c_str());
}

void EnsureEconomy(uint32 guildId)
{
    CharacterDatabase.DirectExecute(
        "INSERT IGNORE INTO mod_ai_guild_economy (guild_id) VALUES ({})",
        guildId);
}

uint64 BankBalance(uint32 guildId)
{
    EnsureEconomy(guildId);
    QueryResult result = CharacterDatabase.Query(
        "SELECT money_copper FROM mod_ai_guild_economy WHERE guild_id = {}",
        guildId);
    return result ? result->Fetch()[0].Get<uint64>() : 0;
}

void CreditBank(uint32 guildId, uint64 copper, bool earned)
{
    EnsureEconomy(guildId);
    CharacterDatabase.DirectExecute(
        "UPDATE mod_ai_guild_economy SET money_copper = money_copper + {}, "
        "earned_copper = earned_copper + {}, updated_at = CURRENT_TIMESTAMP WHERE guild_id = {}",
        copper,
        earned ? copper : 0,
        guildId);
}

void RefundBank(uint32 guildId, uint64 copper)
{
    EnsureEconomy(guildId);
    CharacterDatabase.DirectExecute(
        "UPDATE mod_ai_guild_economy SET money_copper = money_copper + {}, "
        "spent_copper = GREATEST(0, spent_copper - {}), updated_at = CURRENT_TIMESTAMP WHERE guild_id = {}",
        copper, copper, guildId);
}

bool DebitBank(uint32 guildId, uint64 copper)
{
    EnsureEconomy(guildId);
    if (!copper || BankBalance(guildId) < copper)
        return false;

    CharacterDatabase.DirectExecute(
        "UPDATE mod_ai_guild_economy SET money_copper = money_copper - {}, "
        "spent_copper = spent_copper + {}, updated_at = CURRENT_TIMESTAMP "
        "WHERE guild_id = {} AND money_copper >= {}",
        copper, copper, guildId, copper);

    return BankBalance(guildId) + copper >= copper;
}

uint32 StockCount(uint32 guildId, uint32 itemId)
{
    QueryResult result = CharacterDatabase.Query(
        "SELECT item_count FROM mod_ai_guild_stock WHERE guild_id = {} AND item_id = {}",
        guildId, itemId);
    return result ? result->Fetch()[0].Get<uint32>() : 0;
}

void AddStock(uint32 guildId, uint32 itemId, uint32 count)
{
    if (!guildId || !itemId || !count)
        return;

    CharacterDatabase.DirectExecute(
        "INSERT INTO mod_ai_guild_stock (guild_id, item_id, item_count) VALUES ({}, {}, {}) "
        "ON DUPLICATE KEY UPDATE item_count = item_count + VALUES(item_count), updated_at = CURRENT_TIMESTAMP",
        guildId, itemId, count);
}

bool RemoveStock(uint32 guildId, uint32 itemId, uint32 count)
{
    if (!count || StockCount(guildId, itemId) < count)
        return false;
    CharacterDatabase.DirectExecute(
        "UPDATE mod_ai_guild_stock SET item_count = item_count - {}, updated_at = CURRENT_TIMESTAMP "
        "WHERE guild_id = {} AND item_id = {} AND item_count >= {}",
        count, guildId, itemId, count);
    CharacterDatabase.DirectExecute(
        "DELETE FROM mod_ai_guild_stock WHERE guild_id = {} AND item_id = {} AND item_count = 0",
        guildId, itemId);
    return true;
}

bool IsServiceSafe(ItemTemplate const* proto)
{
    if (!proto)
        return false;
    if (proto->Bonding == BIND_WHEN_PICKED_UP || proto->Bonding == BIND_QUEST_ITEM)
        return false;
    if (proto->Class == ITEM_CLASS_QUEST || proto->Class == ITEM_CLASS_KEY)
        return false;
    if (proto->HasFlag(ITEM_FLAG_CONJURED))
        return false;
    return proto->Quality <= ITEM_QUALITY_EPIC;
}

bool IsEconomySurplus(ItemTemplate const* proto)
{
    if (!IsServiceSafe(proto))
        return false;

    switch (proto->Class)
    {
        case ITEM_CLASS_CONSUMABLE:
        case ITEM_CLASS_TRADE_GOODS:
        case ITEM_CLASS_GEM:
        case ITEM_CLASS_RECIPE:
            return true;
        default:
            return false;
    }
}

uint32 ClampServiceCount(ItemTemplate const* proto, uint32 count)
{
    if (!proto || !count)
        return 0;
    uint32 const stack = std::max<uint32>(1, proto->GetMaxStackSize());
    return std::min<uint32>(count, stack * MAX_SERVICE_STACKS);
}

bool SendItemMail(uint32 senderGuid, uint32 targetGuid, ItemTemplate const* proto, uint32 count,
                  std::string const& subject, std::string const& body)
{
    if (!proto || !targetGuid || !count)
        return false;

    count = ClampServiceCount(proto, count);
    if (!count)
        return false;

    MailDraft draft(subject, body);
    CharacterDatabaseTransaction trans = CharacterDatabase.BeginTransaction();
    uint32 remaining = count;
    uint32 const maxStack = std::max<uint32>(1, proto->GetMaxStackSize());
    uint32 attachments = 0;

    while (remaining && attachments < MAX_SERVICE_STACKS)
    {
        uint32 const stack = std::min(remaining, maxStack);
        Item* item = Item::CreateItem(proto->ItemId, stack);
        if (!item)
            return false;
        item->SaveToDB(trans);
        draft.AddItem(item);
        remaining -= stack;
        ++attachments;
    }

    if (remaining)
        return false;

    MailSender sender(MAIL_NORMAL, senderGuid, MAIL_STATIONERY_GM);
    draft.SendMailTo(trans, MailReceiver(targetGuid), sender);
    CharacterDatabase.CommitTransaction(trans);
    return true;
}

uint64 CreateRequest(uint32 guildId, uint32 requesterGuid, uint32 targetGuid, std::string type,
                     uint32 itemId, uint32 count, uint64 quote)
{
    uint64 const requestId = NextRequestId();
    CharacterDatabase.EscapeString(type);
    CharacterDatabase.DirectExecute(
        "INSERT INTO mod_ai_guild_request "
        "(request_id, guild_id, requester_guid, target_guid, request_type, item_id, item_count, quoted_copper, status) "
        "VALUES ({}, {}, {}, {}, '{}', {}, {}, {}, 'queued')",
        requestId, guildId, requesterGuid, targetGuid, type, itemId, count, quote);
    return requestId;
}

void SetRequestStatus(uint64 requestId, char const* status)
{
    CharacterDatabase.DirectExecute(
        "UPDATE mod_ai_guild_request SET status = '{}', fulfilled_at = CASE WHEN '{}' = 'fulfilled' "
        "THEN CURRENT_TIMESTAMP ELSE fulfilled_at END WHERE request_id = {}",
        status, status, requestId);
}

AuctionHouseId HouseIdForCharacter(uint32 guid)
{
    if (sWorld->getBoolConfig(CONFIG_ALLOW_TWO_SIDE_INTERACTION_AUCTION))
        return AuctionHouseId::Neutral;

    QueryResult result = CharacterDatabase.Query("SELECT race FROM characters WHERE guid={} LIMIT 1", guid);
    if (!result)
        return AuctionHouseId::Neutral;

    switch (result->Fetch()[0].Get<uint8>())
    {
        // 3.3.5 Alliance races: Human, Dwarf, Night Elf, Gnome, Draenei.
        case 1:
        case 3:
        case 4:
        case 7:
        case 11:
            return AuctionHouseId::Alliance;
        // Horde races: Orc, Undead, Tauren, Troll, Blood Elf.
        case 2:
        case 5:
        case 6:
        case 8:
        case 10:
            return AuctionHouseId::Horde;
        default:
            return AuctionHouseId::Neutral;
    }
}

AuctionEntry* FindExactBuyout(uint32 targetGuid, uint32 itemId, uint32 count)
{
    AuctionHouseObject* house = sAuctionMgr->GetAuctionsMapByHouseId(HouseIdForCharacter(targetGuid));
    if (!house)
        return nullptr;

    AuctionEntry* best = nullptr;
    for (auto const& [auctionId, auction] : house->GetAuctions())
    {
        (void)auctionId;
        if (!auction || auction->item_template != itemId || auction->itemCount != count || !auction->buyout)
            continue;
        if (auction->owner.GetCounter() == targetGuid || auction->bidder)
            continue;
        if (!best || auction->buyout < best->buyout)
            best = auction;
    }
    return best;
}

uint64 RealMarketQuote(uint32 targetGuid, uint32 itemId, uint32 count)
{
    AuctionEntry* auction = FindExactBuyout(targetGuid, itemId, count);
    return auction ? auction->buyout : 0;
}

bool BuyRealAuction(PendingRequest const& request)
{
    if (request.type != "buy" || !request.targetGuid || !request.itemId || !request.itemCount)
        return false;

    AuctionHouseObject* house = sAuctionMgr->GetAuctionsMapByHouseId(HouseIdForCharacter(request.targetGuid));
    AuctionEntry* auction = FindExactBuyout(request.targetGuid, request.itemId, request.itemCount);
    if (!house || !auction || !auction->buyout)
        return false;

    uint64 const price = auction->buyout;
    if (price > MAX_MONEY_AMOUNT || BankBalance(request.guildId) < price)
        return false;

    Item* auctionItem = sAuctionMgr->GetAItem(auction->item_guid);
    if (!auctionItem || auctionItem->GetEntry() != request.itemId || auctionItem->GetCount() != request.itemCount)
        return false;

    if (!DebitBank(request.guildId, price))
        return false;

    CharacterDatabaseTransaction trans = CharacterDatabase.BeginTransaction();
    auction->bidder = ObjectGuid::Create<HighGuid::Player>(request.targetGuid);
    auction->bid = auction->buyout;

    // Use AzerothCore's normal auction mail path. The guild treasury is the payer, but the item is
    // still the seller's real auction item, the seller receives normal sale mail/cut handling, and
    // the requesting character receives the normal won-auction item mail.
    sAuctionMgr->SendAuctionSalePendingMail(auction, trans);
    sAuctionMgr->SendAuctionSuccessfulMail(auction, trans);
    sAuctionMgr->SendAuctionWonMail(auction, trans);
    auction->DeleteFromDB(trans);
    CharacterDatabase.CommitTransaction(trans);

    sAuctionMgr->RemoveAItem(auction->item_guid);
    house->RemoveAuction(auction);

    LOG_INFO("server.loading", "[AIGuildEconomy] Guild {} bought real AH item {} x{} for {} copper for character {}.",
        request.guildId, request.itemId, request.itemCount, price, request.targetGuid);
    SetRequestStatus(request.id, "fulfilled");
    return true;
}

bool FulfillRequest(PendingRequest const& request)
{
    ItemTemplate const* proto = sObjectMgr->GetItemTemplate(request.itemId);
    if (!IsServiceSafe(proto))
    {
        SetRequestStatus(request.id, "rejected");
        return true;
    }

    uint32 count = ClampServiceCount(proto, request.itemCount);
    if (!count)
    {
        SetRequestStatus(request.id, "rejected");
        return true;
    }

    // First choice is always conserved guild stock. Stock only increases when a human/bot gives up
    // a real item stack, so creating the mail attachment here is a storage representation change,
    // not item generation from nothing.
    if (StockCount(request.guildId, request.itemId) >= count)
    {
        if (!RemoveStock(request.guildId, request.itemId, count))
            return false;
        if (!SendItemMail(request.requesterGuid, request.targetGuid, proto, count,
                          "AI Guild Service", "Your guild request was fulfilled from conserved guild stock."))
        {
            AddStock(request.guildId, request.itemId, count);
            return false;
        }
        SetRequestStatus(request.id, "fulfilled");
        return true;
    }

    // Shopping requests may spend the virtual guild treasury, but only by purchasing an existing
    // exact-stack auction. The old synthetic fallback that created arbitrary items from vendor-price
    // estimates is intentionally gone.
    if (request.type == "buy")
        return BuyRealAuction(request);

    // Craft requests remain queued until an actual guild bot with the recipe and reagents crafts the
    // item and contributes the physical result to stock.
    return false;
}

uint32 ProcessQueued(uint32 guildId, uint32 limit = 20)
{
    QueryResult result = CharacterDatabase.Query(
        "SELECT request_id, guild_id, requester_guid, target_guid, request_type, item_id, item_count, quoted_copper "
        "FROM mod_ai_guild_request WHERE guild_id = {} AND status = 'queued' ORDER BY request_id ASC LIMIT {}",
        guildId, limit);
    if (!result)
        return 0;

    uint32 processed = 0;
    do
    {
        Field* f = result->Fetch();
        PendingRequest request;
        request.id = f[0].Get<uint64>();
        request.guildId = f[1].Get<uint32>();
        request.requesterGuid = f[2].Get<uint32>();
        request.targetGuid = f[3].Get<uint32>();
        request.type = f[4].Get<std::string>();
        request.itemId = f[5].Get<uint32>();
        request.itemCount = f[6].Get<uint32>();
        request.quotedCopper = f[7].Get<uint64>();
        if (FulfillRequest(request))
            ++processed;
        // Do not let one unavailable craft/material request block unrelated real-stock or AH work.
    } while (result->NextRow());
    return processed;
}

uint32 FindGuildMemberGuid(uint32 guildId, std::string name)
{
    CharacterDatabase.EscapeString(name);
    QueryResult result = CharacterDatabase.Query(
        "SELECT c.guid FROM characters c INNER JOIN guild_member gm ON gm.guid = c.guid "
        "WHERE gm.guildid = {} AND c.name = '{}' LIMIT 1",
        guildId, name);
    return result ? result->Fetch()[0].Get<uint32>() : 0;
}

std::string MoneyText(uint64 copper)
{
    uint64 const gold = copper / COPPER_PER_GOLD;
    copper %= COPPER_PER_GOLD;
    uint64 const silver = copper / 100;
    uint64 const c = copper % 100;
    std::ostringstream out;
    out << gold << "g " << silver << "s " << c << "c";
    return out.str();
}

void ShowHelp(Player* player)
{
    Reply(player,
        "[AI Guild] Services: !bank, !donate <gold>, !deposit <itemId> [count], !withdraw <itemId> [count], "
        "!mail <itemId> [count] <guildmate>, !buy <itemId> [count], !craft <itemId> [count], !requests. "
        "Buy uses real AH listings; craft waits for a real guild-bot recipe + reagents.");
}

std::vector<Item*> BagItems(Player* player)
{
    std::vector<Item*> items;
    if (!player)
        return items;

    for (uint8 slot = INVENTORY_SLOT_ITEM_START; slot < INVENTORY_SLOT_ITEM_END; ++slot)
        if (Item* item = player->GetItemByPos(INVENTORY_SLOT_BAG_0, slot))
            items.push_back(item);

    for (uint8 bagSlot = INVENTORY_SLOT_BAG_START; bagSlot < INVENTORY_SLOT_BAG_END; ++bagSlot)
    {
        Bag* bag = static_cast<Bag*>(player->GetItemByPos(INVENTORY_SLOT_BAG_0, bagSlot));
        if (!bag)
            continue;
        for (uint32 slot = 0; slot < bag->GetBagSize(); ++slot)
            if (Item* item = bag->GetItemByPos(slot))
                items.push_back(item);
    }
    return items;
}

bool IsTradablePhysicalItem(Item* item)
{
    if (!item || !item->GetTemplate() || !IsServiceSafe(item->GetTemplate()))
        return false;
    if (!item->CanBeTraded() || item->IsNotEmptyBag() || item->GetUInt32Value(ITEM_FIELD_DURATION))
        return false;
    return true;
}

bool MoveWholeStackToStock(Player* bot, Item* item)
{
    if (!bot || !item || !bot->GetGuildId() || !IsTradablePhysicalItem(item))
        return false;

    uint32 const entry = item->GetEntry();
    uint32 const count = item->GetCount();
    uint8 const bag = item->GetBagSlot();
    uint8 const slot = item->GetSlot();
    if (!entry || !count)
        return false;

    bot->DestroyItem(bag, slot, true);
    bot->SaveToDB(false, false);
    AddStock(bot->GetGuildId(), entry, count);
    LOG_INFO("server.loading", "[AIGuildEconomy] {} contributed real item {} x{} to guild {} stock.",
        bot->GetName(), entry, count, bot->GetGuildId());
    return true;
}

bool RequestExists(uint32 guildId, uint32 itemId)
{
    return bool(CharacterDatabase.Query(
        "SELECT 1 FROM mod_ai_guild_request WHERE guild_id={} AND item_id={} AND status='queued' LIMIT 1",
        guildId, itemId));
}

bool FindCraftSpell(Player* bot, uint32 itemId, uint32& spellId)
{
    if (!bot || !itemId)
        return false;

    for (PlayerSpellMap::const_iterator itr = bot->GetSpellMap().begin(); itr != bot->GetSpellMap().end(); ++itr)
    {
        if (!itr->second || itr->second->State == PLAYERSPELL_REMOVED || !itr->second->Active)
            continue;

        SpellInfo const* info = sSpellMgr->GetSpellInfo(itr->first);
        if (!info)
            continue;

        for (uint8 effect = 0; effect < MAX_SPELL_EFFECTS; ++effect)
        {
            if (info->Effects[effect].Effect == SPELL_EFFECT_CREATE_ITEM && info->Effects[effect].ItemType == itemId)
            {
                spellId = itr->first;
                return true;
            }
        }
    }
    return false;
}

AuctionHouseEntry const* AuctionEntryForBot(Player* bot, AuctionHouseId& houseId)
{
    if (!bot)
        return nullptr;

    if (sWorld->getBoolConfig(CONFIG_ALLOW_TWO_SIDE_INTERACTION_AUCTION))
    {
        houseId = AuctionHouseId::Neutral;
        return AuctionHouseMgr::GetAuctionHouseEntryFromHouse(houseId);
    }

    AuctionHouseEntry const* entry = AuctionHouseMgr::GetAuctionHouseEntryFromFactionTemplate(bot->getFaction());
    if (!entry)
        return nullptr;
    houseId = static_cast<AuctionHouseId>(entry->houseId);
    return entry;
}
}

uint32 ProcessQueuedGuild(uint32 guildId)
{
    if (!guildId)
        return 0;
    std::lock_guard<std::mutex> lock(g_serviceMutex);
    return ProcessQueued(guildId);
}

bool SupplyQueuedFromBot(Player* bot)
{
    if (!bot || !bot->GetGuildId() || bot->IsInCombat())
        return false;

    std::lock_guard<std::mutex> lock(g_serviceMutex);
    QueryResult requests = CharacterDatabase.Query(
        "SELECT DISTINCT item_id FROM mod_ai_guild_request WHERE guild_id={} AND status='queued' ORDER BY request_id ASC LIMIT 20",
        bot->GetGuildId());
    if (!requests)
        return false;

    do
    {
        uint32 const itemId = requests->Fetch()[0].Get<uint32>();
        for (Item* item : BagItems(bot))
        {
            if (!item || item->GetEntry() != itemId || !IsTradablePhysicalItem(item))
                continue;
            if (!MoveWholeStackToStock(bot, item))
                continue;
            ProcessQueued(bot->GetGuildId());
            return true;
        }
    } while (requests->NextRow());
    return false;
}

bool TryCraftQueuedFromBot(Player* bot)
{
    if (!bot || !bot->GetGuildId() || bot->IsInCombat())
        return false;

    PlayerbotAI* ai = GET_PLAYERBOT_AI(bot);
    if (!ai)
        return false;

    std::lock_guard<std::mutex> lock(g_serviceMutex);
    QueryResult requests = CharacterDatabase.Query(
        "SELECT item_id FROM mod_ai_guild_request WHERE guild_id={} AND request_type='craft' AND status='queued' "
        "ORDER BY request_id ASC LIMIT 20",
        bot->GetGuildId());
    if (!requests)
        return false;

    do
    {
        uint32 const itemId = requests->Fetch()[0].Get<uint32>();
        uint32 spellId = 0;
        if (!FindCraftSpell(bot, itemId, spellId))
            continue;
        if (!ai->CanCastSpell(spellId, bot, true))
            continue;
        if (!ai->CastSpell(spellId, bot))
            continue;

        LOG_INFO("server.loading", "[AIGuildEconomy] {} started real recipe {} for queued guild item {}.",
            bot->GetName(), spellId, itemId);
        return true;
    } while (requests->NextRow());
    return false;
}

bool ContributeSurplusFromBot(Player* bot)
{
    if (!bot || !bot->GetGuildId() || bot->IsInCombat())
        return false;

    std::lock_guard<std::mutex> lock(g_serviceMutex);
    for (Item* item : BagItems(bot))
    {
        if (!IsTradablePhysicalItem(item) || !IsEconomySurplus(item->GetTemplate()))
            continue;
        // A queued exact request gets first refusal through SupplyQueuedFromBot. Do not divert it
        // to generic stock/AH paths here.
        if (RequestExists(bot->GetGuildId(), item->GetEntry()))
            continue;
        if (item->GetTemplate()->Class != ITEM_CLASS_RECIPE && item->GetCount() < 2)
            continue;
        return MoveWholeStackToStock(bot, item);
    }
    return false;
}

bool ListSurplusOnAuction(Player* bot)
{
    if (!bot || !bot->GetGuildId() || bot->IsInCombat())
        return false;

    std::lock_guard<std::mutex> lock(g_serviceMutex);
    Item* candidate = nullptr;
    for (Item* item : BagItems(bot))
    {
        if (!IsTradablePhysicalItem(item) || !IsEconomySurplus(item->GetTemplate()))
            continue;
        if (RequestExists(bot->GetGuildId(), item->GetEntry()))
            continue;
        if (item->GetTemplate()->Class != ITEM_CLASS_RECIPE && item->GetCount() < 2)
            continue;
        candidate = item;
        break;
    }
    if (!candidate)
        return false;

    ItemTemplate const* proto = candidate->GetTemplate();
    uint32 const count = candidate->GetCount();
    uint64 unitAnchor = std::max<uint64>(uint64(proto->SellPrice) * 4u, uint64(proto->BuyPrice) / 2u);
    if (!unitAnchor)
        return false;

    uint64 const buyout64 = std::min<uint64>(uint64(MAX_MONEY_AMOUNT), unitAnchor * count);
    uint32 const buyout = static_cast<uint32>(buyout64);
    uint32 const startBid = std::max<uint32>(1, uint32((uint64(buyout) * 80u) / 100u));

    AuctionHouseId houseId = AuctionHouseId::Neutral;
    AuctionHouseEntry const* houseEntry = AuctionEntryForBot(bot, houseId);
    AuctionHouseObject* house = sAuctionMgr->GetAuctionsMapByHouseId(houseId);
    if (!houseEntry || !house)
        return false;

    uint32 const auctionTime = MIN_AUCTION_TIME;
    uint32 const deposit = sAuctionMgr->GetAuctionDeposit(houseEntry, auctionTime, candidate, count);
    if (deposit > static_cast<uint32>(std::numeric_limits<int32>::max()) || !bot->HasEnoughMoney(deposit))
        return false;

    AuctionEntry* auction = new AuctionEntry;
    auction->Id = sObjectMgr->GenerateAuctionID();
    auction->houseId = houseId;
    auction->item_guid = candidate->GetGUID();
    auction->item_template = candidate->GetEntry();
    auction->itemCount = count;
    auction->owner = bot->GetGUID();
    auction->startbid = startBid;
    auction->bidder = ObjectGuid::Empty;
    auction->bid = 0;
    auction->buyout = buyout;
    auction->expire_time = GameTime::GetGameTime().count() +
        uint32(double(auctionTime) * sWorld->getRate(RATE_AUCTION_TIME));
    auction->deposit = deposit;
    auction->auctionHouseEntry = houseEntry;

    bot->ModifyMoney(-static_cast<int32>(deposit));
    sAuctionMgr->AddAItem(candidate);
    house->AddAuction(auction);
    bot->MoveItemFromInventory(candidate->GetBagSlot(), candidate->GetSlot(), true);

    CharacterDatabaseTransaction trans = CharacterDatabase.BeginTransaction();
    candidate->DeleteFromInventoryDB(trans);
    candidate->SaveToDB(trans);
    auction->SaveToDB(trans);
    bot->SaveInventoryAndGoldToDB(trans);
    CharacterDatabase.CommitTransaction(trans);

    LOG_INFO("server.loading", "[AIGuildEconomy] {} listed real item {} x{} on AH for {} copper buyout.",
        bot->GetName(), auction->item_template, auction->itemCount, auction->buyout);
    return true;
}

bool HandleGuildMessage(Player* player, Guild* guild, std::string const& message)
{
    if (!player || !guild || player->GetGuildId() != guild->GetId() || message.empty() || message[0] != '!')
        return false;

    std::istringstream input(message);
    std::string command;
    input >> command;
    command = Lower(command);
    if (command != "!services" && command != "!bank" && command != "!donate" &&
        command != "!deposit" && command != "!withdraw" && command != "!mail" &&
        command != "!buy" && command != "!craft" && command != "!requests")
        return false;

    std::lock_guard<std::mutex> lock(g_serviceMutex);
    uint32 const guildId = guild->GetId();
    EnsureEconomy(guildId);

    if (command == "!services")
    {
        ShowHelp(player);
        return true;
    }

    if (command == "!bank")
    {
        QueryResult stock = CharacterDatabase.Query(
            "SELECT COUNT(*), COALESCE(SUM(item_count),0) FROM mod_ai_guild_stock WHERE guild_id = {}",
            guildId);
        uint64 lines = 0, items = 0;
        if (stock)
        {
            lines = stock->Fetch()[0].Get<uint64>();
            items = stock->Fetch()[1].Get<uint64>();
        }
        uint32 const processed = ProcessQueued(guildId);
        Reply(player, "[AI Guild] Treasury: " + MoneyText(BankBalance(guildId)) + ". Conserved stock: " +
            std::to_string(items) + " items across " + std::to_string(lines) + " item types. " +
            std::to_string(processed) + " queued real-stock/AH request(s) processed now.");
        return true;
    }

    if (command == "!donate")
    {
        std::string raw;
        input >> raw;
        uint32 gold = 0;
        if (!ParseU32(raw, gold) || !gold || gold > MAX_DONATION_GOLD)
        {
            Reply(player, "[AI Guild] Usage: !donate <gold>, max 100000g at once.");
            return true;
        }
        uint64 const copper = uint64(gold) * COPPER_PER_GOLD;
        if (player->GetMoney() < copper || copper > uint64(INT32_MAX))
        {
            Reply(player, "[AI Guild] You do not have that much spendable gold in one transaction.");
            return true;
        }
        if (!player->ModifyMoney(-static_cast<int32>(copper)))
        {
            Reply(player, "[AI Guild] Donation failed; your money was not changed.");
            return true;
        }
        CreditBank(guildId, copper, true);
        player->SaveToDB(false, false);
        uint32 const processed = ProcessQueued(guildId);
        Reply(player, "[AI Guild] Donated " + std::to_string(gold) + "g. Treasury is now " +
            MoneyText(BankBalance(guildId)) + ". Processed " + std::to_string(processed) + " queued request(s).");
        return true;
    }

    if (command == "!requests")
    {
        QueryResult requests = CharacterDatabase.Query(
            "SELECT request_id, request_type, item_id, item_count, quoted_copper, status "
            "FROM mod_ai_guild_request WHERE guild_id = {} ORDER BY request_id DESC LIMIT 8",
            guildId);
        if (!requests)
        {
            Reply(player, "[AI Guild] No service requests yet.");
            return true;
        }
        do
        {
            Field* f = requests->Fetch();
            Reply(player, "[AI Guild] #" + std::to_string(f[0].Get<uint64>()) + " " + f[1].Get<std::string>() +
                " item=" + std::to_string(f[2].Get<uint32>()) + " x" + std::to_string(f[3].Get<uint32>()) +
                " market=" + (f[4].Get<uint64>() ? MoneyText(f[4].Get<uint64>()) : std::string("waiting")) +
                " status=" + f[5].Get<std::string>());
        } while (requests->NextRow());
        return true;
    }

    std::string rawItem;
    input >> rawItem;
    if (rawItem.empty())
    {
        ShowHelp(player);
        return true;
    }
    uint32 itemId = 0;
    if (!ParseU32(rawItem, itemId))
    {
        Reply(player, "[AI Guild] Item must be a numeric item ID.");
        return true;
    }
    ItemTemplate const* proto = sObjectMgr->GetItemTemplate(itemId);
    if (!proto)
    {
        Reply(player, "[AI Guild] Unknown item ID.");
        return true;
    }

    uint32 count = 1;
    std::string targetName;
    if (command == "!mail")
    {
        std::string token;
        input >> token;
        if (token.empty())
        {
            Reply(player, "[AI Guild] Usage: !mail <itemId> [count] <guildmate>.");
            return true;
        }

        uint32 parsedCount = 0;
        if (ParseU32(token, parsedCount))
        {
            count = parsedCount;
            input >> targetName;
        }
        else
        {
            targetName = token;
        }

        if (targetName.empty())
        {
            Reply(player, "[AI Guild] Usage: !mail <itemId> [count] <guildmate>.");
            return true;
        }
    }
    else
    {
        std::string rawCount;
        input >> rawCount;
        if (!rawCount.empty() && !ParseU32(rawCount, count))
        {
            Reply(player, "[AI Guild] Count must be a positive number.");
            return true;
        }
    }

    count = ClampServiceCount(proto, count);
    if (!count)
    {
        Reply(player, "[AI Guild] Invalid count.");
        return true;
    }

    if (command == "!deposit")
    {
        if (!IsServiceSafe(proto))
        {
            Reply(player, "[AI Guild] The guild stock refuses BoP, conjured, quest/key or above-epic items.");
            return true;
        }
        if (player->GetItemCount(itemId, false) < count)
        {
            Reply(player, "[AI Guild] You do not have enough of that item.");
            return true;
        }
        player->DestroyItemCount(itemId, count, true, false);
        player->SaveToDB(false, false);
        AddStock(guildId, itemId, count);
        uint32 const processed = ProcessQueued(guildId);
        Reply(player, "[AI Guild] Deposited " + std::to_string(count) + "x " + proto->Name1 +
            ". Stock now has " + std::to_string(StockCount(guildId, itemId)) + ". Processed " +
            std::to_string(processed) + " queued request(s).");
        return true;
    }

    if (command == "!withdraw" || command == "!mail")
    {
        if (!IsServiceSafe(proto))
        {
            Reply(player, "[AI Guild] The guild stock refuses BoP, conjured, quest/key or above-epic items.");
            return true;
        }

        uint32 targetGuid = player->GetGUID().GetCounter();
        if (command == "!mail")
        {
            targetGuid = FindGuildMemberGuid(guildId, targetName);
            if (!targetGuid)
            {
                Reply(player, "[AI Guild] That character is not a member of this guild.");
                return true;
            }
        }
        else
            targetName = player->GetName();

        if (!RemoveStock(guildId, itemId, count))
        {
            Reply(player, "[AI Guild] The conserved stock does not have enough of that item.");
            return true;
        }
        if (!SendItemMail(player->GetGUID().GetCounter(), targetGuid, proto, count,
                          "Guild Stock Delivery", "Requested from the persistent AI guild stock."))
        {
            AddStock(guildId, itemId, count);
            Reply(player, "[AI Guild] Mail creation failed; stock was restored.");
            return true;
        }
        Reply(player, "[AI Guild] Sent " + std::to_string(count) + "x " + proto->Name1 + " to " + targetName + ".");
        return true;
    }

    if (command == "!buy" || command == "!craft")
    {
        if (!IsServiceSafe(proto))
        {
            Reply(player, "[AI Guild] The service refuses BoP, conjured, quest/key or above-epic items.");
            return true;
        }

        bool const craft = command == "!craft";
        uint64 const quote = craft ? 0 : RealMarketQuote(player->GetGUID().GetCounter(), itemId, count);
        uint64 const requestId = CreateRequest(
            guildId,
            player->GetGUID().GetCounter(),
            player->GetGUID().GetCounter(),
            craft ? "craft" : "buy",
            itemId,
            count,
            quote);

        ProcessQueued(guildId);
        QueryResult state = CharacterDatabase.Query(
            "SELECT status FROM mod_ai_guild_request WHERE request_id = {}",
            requestId);
        std::string status = state ? state->Fetch()[0].Get<std::string>() : "queued";

        if (craft)
        {
            Reply(player, "[AI Guild] Craft request #" + std::to_string(requestId) + " for " +
                std::to_string(count) + "x " + proto->Name1 + ". Status: " + status +
                (status == "queued"
                    ? ". A guild bot must actually know the recipe, have the reagents, craft it and contribute the result."
                    : ". Delivery is in the mail."));
        }
        else
        {
            Reply(player, "[AI Guild] Market request #" + std::to_string(requestId) + " for " +
                std::to_string(count) + "x " + proto->Name1 + ". " +
                (quote ? "Current exact-stack AH price: " + MoneyText(quote) + ". " :
                         "No exact-stack AH listing exists yet; the request will wait. ") +
                "Status: " + status + (status == "queued"
                    ? ". Treasury funds are only spent on a real listing; no item will be fabricated."
                    : ". The real auction item is being delivered by mail."));
        }
        return true;
    }

    return true;
}
}
