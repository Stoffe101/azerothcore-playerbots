#include "PBAIGuildServices.h"

#include "AuctionHouseMgr.h"
#include "AsyncCallbackProcessor.h"
#include "Bag.h"
#include "Chat.h"
#include "DatabaseEnv.h"
#include "EraPolicy.h"
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
#include "ScriptMgr.h"
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
#include <unordered_set>
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
AsyncCallbackProcessor<TransactionCallback> g_transactionCallbacks;
std::unordered_set<uint32> g_pendingGuildTransactions;

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

bool HasPendingTransaction(uint32 guildId)
{
    return g_pendingGuildTransactions.contains(guildId);
}

void CommitGuildTransaction(CharacterDatabaseTransaction transaction, uint32 guildId)
{
    g_pendingGuildTransactions.insert(guildId);
    g_transactionCallbacks.AddCallback(CharacterDatabase.AsyncCommitTransaction(transaction)).AfterComplete(
        [guildId](bool success)
        {
            g_pendingGuildTransactions.erase(guildId);
            if (!success)
                LOG_ERROR("server.loading", "[AIGuildEconomy] Character DB transaction failed for guild {}.", guildId);
        });
}

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

bool CheckAutomatedItemPolicy(Player* player, uint32 itemId, char const* action)
{
    if (!EraPolicy::ItemProvenanceReady())
    {
        Reply(player, std::string("[AI Guild] ") + action +
            " is temporarily unavailable because item chronology is not ready. No item, stock, or money was changed.");
        return false;
    }
    if (!EraPolicy::IsItemAllowed(itemId))
    {
        Reply(player, std::string("[AI Guild] ") + action +
            " refused: that item is unavailable in the current realm era. No item, stock, or money was changed.");
        return false;
    }
    return true;
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

void AppendBankCredit(CharacterDatabaseTransaction const& trans, uint32 guildId, uint64 copper, bool earned)
{
    if (!trans || !guildId || !copper)
        return;

    trans->Append(
        "INSERT IGNORE INTO mod_ai_guild_economy (guild_id) VALUES ({})",
        guildId);
    trans->Append(
        "UPDATE mod_ai_guild_economy SET money_copper = money_copper + {}, "
        "earned_copper = earned_copper + {}, updated_at = CURRENT_TIMESTAMP WHERE guild_id = {}",
        copper,
        earned ? copper : 0,
        guildId);
}

void AppendBankDebit(CharacterDatabaseTransaction const& trans, uint32 guildId, uint64 copper)
{
    if (!trans || !guildId || !copper)
        return;

    // Every service caller holds g_serviceMutex and verifies the current balance before appending
    // this statement. Keeping the debit in the same CharacterDatabase transaction as the AH sale
    // removes the old crash window where treasury money could be committed before the auction mail.
    trans->Append(
        "UPDATE mod_ai_guild_economy SET money_copper = money_copper - {}, "
        "spent_copper = spent_copper + {}, updated_at = CURRENT_TIMESTAMP "
        "WHERE guild_id = {} AND money_copper >= {}",
        copper, copper, guildId, copper);
}

uint32 StockCount(uint32 guildId, uint32 itemId)
{
    QueryResult result = CharacterDatabase.Query(
        "SELECT item_count FROM mod_ai_guild_stock WHERE guild_id = {} AND item_id = {}",
        guildId, itemId);
    return result ? result->Fetch()[0].Get<uint32>() : 0;
}

void AppendStockCredit(CharacterDatabaseTransaction const& trans, uint32 guildId, uint32 itemId, uint32 count)
{
    if (!trans || !guildId || !itemId || !count)
        return;

    trans->Append(
        "INSERT INTO mod_ai_guild_stock (guild_id, item_id, item_count) VALUES ({}, {}, {}) "
        "ON DUPLICATE KEY UPDATE item_count = item_count + VALUES(item_count), updated_at = CURRENT_TIMESTAMP",
        guildId, itemId, count);
}

void AppendStockDebit(CharacterDatabaseTransaction const& trans, uint32 guildId, uint32 itemId, uint32 count)
{
    if (!trans || !guildId || !itemId || !count)
        return;

    trans->Append(
        "UPDATE mod_ai_guild_stock SET item_count = item_count - {}, updated_at = CURRENT_TIMESTAMP "
        "WHERE guild_id = {} AND item_id = {} AND item_count >= {}",
        count, guildId, itemId, count);
    trans->Append(
        "DELETE FROM mod_ai_guild_stock WHERE guild_id = {} AND item_id = {} AND item_count = 0",
        guildId, itemId);
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

bool AppendItemMail(CharacterDatabaseTransaction const& trans, uint32 senderGuid, uint32 targetGuid,
                    ItemTemplate const* proto, uint32 count, std::string const& subject, std::string const& body)
{
    if (!trans || !proto || !targetGuid || !count)
        return false;
    if (!EraPolicy::ItemProvenanceReady() || !EraPolicy::IsItemAllowed(proto->ItemId))
        return false;

    count = ClampServiceCount(proto, count);
    if (!count)
        return false;

    MailDraft draft(subject, body);
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

void AppendRequestStatus(CharacterDatabaseTransaction const& trans, uint64 requestId, char const* status)
{
    if (!trans || !requestId || !status)
        return;

    trans->Append(
        "UPDATE mod_ai_guild_request SET status = '{}', fulfilled_at = CASE WHEN '{}' = 'fulfilled' "
        "THEN CURRENT_TIMESTAMP ELSE fulfilled_at END WHERE request_id = {}",
        status, status, requestId);
}

void SetRequestStatus(uint64 requestId, char const* status)
{
    CharacterDatabase.DirectExecute(
        "UPDATE mod_ai_guild_request SET status = '{}', fulfilled_at = CASE WHEN '{}' = 'fulfilled' "
        "THEN CURRENT_TIMESTAMP ELSE fulfilled_at END WHERE request_id = {}",
        status, status, requestId);
}

bool DeliverStockMail(uint32 guildId, uint32 senderGuid, uint32 targetGuid, ItemTemplate const* proto,
                      uint32 count, std::string const& subject, std::string const& body, uint64 requestId = 0)
{
    if (!guildId || !proto || !count || !EraPolicy::ItemProvenanceReady() ||
        !EraPolicy::IsItemAllowed(proto->ItemId) || StockCount(guildId, proto->ItemId) < count)
        return false;

    CharacterDatabaseTransaction trans = CharacterDatabase.BeginTransaction();
    AppendStockDebit(trans, guildId, proto->ItemId, count);
    if (!AppendItemMail(trans, senderGuid, targetGuid, proto, count, subject, body))
        return false;
    if (requestId)
        AppendRequestStatus(trans, requestId, "fulfilled");
    CommitGuildTransaction(trans, guildId);
    return true;
}

uint32 CharacterAccountId(uint32 guid)
{
    QueryResult result = CharacterDatabase.Query("SELECT account FROM characters WHERE guid={} LIMIT 1", guid);
    return result ? result->Fetch()[0].Get<uint32>() : 0;
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
        case 1:
        case 3:
        case 4:
        case 7:
        case 11:
            return AuctionHouseId::Alliance;
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

    uint32 const targetAccount = CharacterAccountId(targetGuid);
    AuctionEntry* best = nullptr;
    for (auto const& [auctionId, auction] : house->GetAuctions())
    {
        (void)auctionId;
        if (!auction || auction->item_template != itemId || auction->itemCount != count || !auction->buyout)
            continue;
        if (auction->owner.GetCounter() == targetGuid || auction->bidder)
            continue;
        if (targetAccount && CharacterAccountId(auction->owner.GetCounter()) == targetAccount)
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
    if (!EraPolicy::ItemProvenanceReady() || !EraPolicy::IsItemAllowed(request.itemId))
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

    CharacterDatabaseTransaction trans = CharacterDatabase.BeginTransaction();
    AppendBankDebit(trans, request.guildId, price);

    auction->bidder = ObjectGuid::Create<HighGuid::Player>(request.targetGuid);
    auction->bid = auction->buyout;

    sAuctionMgr->SendAuctionSalePendingMail(auction, trans);
    sAuctionMgr->SendAuctionSuccessfulMail(auction, trans);
    sAuctionMgr->SendAuctionWonMail(auction, trans);
    sScriptMgr->OnAuctionSuccessful(house, auction);
    auction->DeleteFromDB(trans);
    AppendRequestStatus(trans, request.id, "fulfilled");
    CommitGuildTransaction(trans, request.guildId);

    sAuctionMgr->RemoveAItem(auction->item_guid);
    house->RemoveAuction(auction);

    LOG_INFO("server.loading", "[AIGuildEconomy] Guild {} bought real AH item {} x{} for {} copper for character {}.",
        request.guildId, request.itemId, request.itemCount, price, request.targetGuid);
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

    if (StockCount(request.guildId, request.itemId) >= count)
    {
        if (!DeliverStockMail(request.guildId, request.requesterGuid, request.targetGuid, proto, count,
                              "AI Guild Service", "Your guild request was fulfilled from conserved guild stock.",
                              request.id))
            return false;
        return true;
    }

    if (request.type == "buy")
        return BuyRealAuction(request);

    return false;
}

uint32 ProcessQueued(uint32 guildId, uint32 limit = 20)
{
    if (HasPendingTransaction(guildId))
        return 0;

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
        {
            ++processed;
            if (HasPendingTransaction(guildId))
                break;
        }
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

bool IsConservableStockItem(Item* item)
{
    // Stock stores entry/count only. It cannot preserve bindings, random properties or wrapping.
    return IsTradablePhysicalItem(item) && IsEconomySurplus(item->GetTemplate()) &&
        !item->IsSoulBound() && !item->IsWrapped() && !item->GetItemRandomPropertyId();
}

bool MoveWholeStackToStock(Player* bot, Item* item)
{
    if (!bot || !item || !bot->GetGuildId() || !IsConservableStockItem(item))
        return false;

    uint32 const guildId = bot->GetGuildId();
    uint32 const entry = item->GetEntry();
    uint32 const count = item->GetCount();
    uint8 const bag = item->GetBagSlot();
    uint8 const slot = item->GetSlot();
    if (!entry || !count)
        return false;
    if (!EraPolicy::ItemProvenanceReady() || !EraPolicy::IsItemAllowed(entry))
        return false;

    bot->DestroyItem(bag, slot, true);
    CharacterDatabaseTransaction trans = CharacterDatabase.BeginTransaction();
    bot->SaveInventoryAndGoldToDB(trans);
    AppendStockCredit(trans, guildId, entry, count);
    CommitGuildTransaction(trans, guildId);

    LOG_INFO("server.loading", "[AIGuildEconomy] {} contributed real item {} x{} to guild {} stock.",
        bot->GetName(), entry, count, guildId);
    return true;
}

bool RequestExists(uint32 guildId, uint32 itemId)
{
    return bool(CharacterDatabase.Query(
        "SELECT 1 FROM mod_ai_guild_request WHERE guild_id={} AND item_id={} AND status='queued' LIMIT 1",
        guildId, itemId));
}

bool IsCraftSpellAllowed(uint32 spellId, SpellInfo const* info, uint32 requestedItemId)
{
    EraPolicy::CraftOutputResolution const outputs = EraPolicy::ResolveCraftOutputs(info);
    if (!outputs.resolved || !outputs.allowed || !EraPolicy::IsAutomatedCraftSpellAllowed(spellId))
        return false;

    bool createsRequestedItem = requestedItemId == 0;
    for (uint32 resultItemId : outputs.itemIds)
    {
        if (resultItemId == requestedItemId)
            createsRequestedItem = true;
    }

    return createsRequestedItem;
}

bool FindCraftSpell(Player* bot, uint32 itemId, uint32& spellId)
{
    if (!bot || !itemId || !EraPolicy::ItemProvenanceReady() || !EraPolicy::IsItemAllowed(itemId))
        return false;

    for (PlayerSpellMap::const_iterator itr = bot->GetSpellMap().begin(); itr != bot->GetSpellMap().end(); ++itr)
    {
        if (!itr->second || itr->second->State == PLAYERSPELL_REMOVED || !itr->second->Active)
            continue;

        SpellInfo const* info = sSpellMgr->GetSpellInfo(itr->first);
        if (!IsCraftSpellAllowed(itr->first, info, itemId))
            continue;

        spellId = itr->first;
        return true;
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

    AuctionHouseEntry const* entry = AuctionHouseMgr::GetAuctionHouseEntryFromFactionTemplate(bot->GetFaction());
    if (!entry)
        return nullptr;
    houseId = static_cast<AuctionHouseId>(entry->houseId);
    return entry;
}
}

void UpdateAsyncTransactions()
{
    std::lock_guard<std::mutex> lock(g_serviceMutex);
    g_transactionCallbacks.ProcessReadyCallbacks();
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
    if (HasPendingTransaction(bot->GetGuildId()))
        return false;

    QueryResult requests = CharacterDatabase.Query(
        "SELECT item_id FROM mod_ai_guild_request WHERE guild_id={} AND status='queued' "
        "GROUP BY item_id ORDER BY MIN(request_id) ASC LIMIT 20",
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
    if (!EraPolicy::ItemProvenanceReady())
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
        if (!EraPolicy::IsItemAllowed(itemId))
            continue;
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

bool TryCraftAllowedFromBot(Player* bot)
{
    if (!bot || !bot->GetGuildId() || bot->IsInCombat() || !EraPolicy::ItemProvenanceReady())
        return false;

    PlayerbotAI* ai = GET_PLAYERBOT_AI(bot);
    if (!ai)
        return false;

    for (PlayerSpellMap::const_iterator itr = bot->GetSpellMap().begin(); itr != bot->GetSpellMap().end(); ++itr)
    {
        if (!itr->second || itr->second->State == PLAYERSPELL_REMOVED || !itr->second->Active)
            continue;

        SpellInfo const* info = sSpellMgr->GetSpellInfo(itr->first);
        if (!IsCraftSpellAllowed(itr->first, info, 0))
            continue;
        if (!ai->CanCastSpell(itr->first, bot, true))
            continue;
        if (!ai->CastSpell(itr->first, bot))
            continue;

        LOG_INFO("server.loading", "[AIGuildEconomy] {} started provenance-approved autonomous recipe {}.",
            bot->GetName(), itr->first);
        return true;
    }
    return false;
}

bool ContributeSurplusFromBot(Player* bot)
{
    if (!bot || !bot->GetGuildId() || bot->IsInCombat())
        return false;
    if (!EraPolicy::ItemProvenanceReady())
        return false;

    std::lock_guard<std::mutex> lock(g_serviceMutex);
    if (HasPendingTransaction(bot->GetGuildId()))
        return false;

    for (Item* item : BagItems(bot))
    {
        if (!IsTradablePhysicalItem(item) || !IsEconomySurplus(item->GetTemplate()))
            continue;
        if (!EraPolicy::IsItemAllowed(item->GetEntry()))
            continue;
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
    if (!EraPolicy::ItemProvenanceReady())
        return false;

    std::lock_guard<std::mutex> lock(g_serviceMutex);
    if (HasPendingTransaction(bot->GetGuildId()))
        return false;

    Item* candidate = nullptr;
    for (Item* item : BagItems(bot))
    {
        if (!IsTradablePhysicalItem(item) || !IsEconomySurplus(item->GetTemplate()))
            continue;
        if (!EraPolicy::IsItemAllowed(item->GetEntry()))
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
    CommitGuildTransaction(trans, bot->GetGuildId());

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

    if (command != "!services" && HasPendingTransaction(guildId))
    {
        Reply(player, "[AI Guild] The previous guild transaction is still saving. Please try again in a moment.");
        return true;
    }

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

        uint64 const projectedBalance = BankBalance(guildId) + copper;
        CharacterDatabaseTransaction trans = CharacterDatabase.BeginTransaction();
        player->SaveGoldToDB(trans);
        AppendBankCredit(trans, guildId, copper, true);
        CommitGuildTransaction(trans, guildId);

        Reply(player, "[AI Guild] Donated " + std::to_string(gold) + "g. Treasury is now " +
            MoneyText(projectedBalance) + ". Queued requests will process on the next service pass.");
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

    if ((command == "!deposit" || command == "!withdraw" || command == "!mail" || command == "!buy" ||
         command == "!craft") &&
        !CheckAutomatedItemPolicy(player, itemId, "Item service"))
        return true;

    if (command == "!deposit")
    {
        if (!IsServiceSafe(proto))
        {
            Reply(player, "[AI Guild] The guild stock refuses BoP, conjured, quest/key or above-epic items.");
            return true;
        }
        std::vector<Item*> const inventory = BagItems(player);
        uint32 available = 0;
        for (Item* item : inventory)
            if (item->GetEntry() == itemId && IsConservableStockItem(item))
                available += item->GetCount();
        if (available < count)
        {
            Reply(player, "[AI Guild] Stock accepts only unbound, plain materials, consumables, gems and recipes from your bags.");
            return true;
        }

        uint32 const projectedStock = StockCount(guildId, itemId) + count;
        uint32 remaining = count;
        for (Item* item : inventory)
        {
            if (!remaining)
                break;
            if (item->GetEntry() == itemId && IsConservableStockItem(item))
                player->DestroyItemCount(item, remaining, true);
        }
        CharacterDatabaseTransaction trans = CharacterDatabase.BeginTransaction();
        player->SaveInventoryAndGoldToDB(trans);
        AppendStockCredit(trans, guildId, itemId, count);
        CommitGuildTransaction(trans, guildId);

        Reply(player, "[AI Guild] Deposited " + std::to_string(count) + "x " + proto->Name1 +
            ". Stock now has " + std::to_string(projectedStock) +
            ". Queued requests will process on the next service pass.");
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

        if (!DeliverStockMail(guildId, player->GetGUID().GetCounter(), targetGuid, proto, count,
                              "Guild Stock Delivery", "Requested from the persistent AI guild stock."))
        {
            Reply(player, "[AI Guild] The conserved stock does not have enough of that item, or delivery could not be created.");
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
