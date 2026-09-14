#include "PBAIGuildServices.h"

#include "Chat.h"
#include "DatabaseEnv.h"
#include "Guild.h"
#include "Item.h"
#include "ItemTemplate.h"
#include "Mail.h"
#include "ObjectMgr.h"
#include "Player.h"
#include "QueryResult.h"
#include "SharedDefines.h"
#include "WorldSession.h"

#include <algorithm>
#include <atomic>
#include <cctype>
#include <chrono>
#include <cstdint>
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
    if (BankBalance(guildId) < copper)
        return false;

    CharacterDatabase.DirectExecute(
        "UPDATE mod_ai_guild_economy SET money_copper = money_copper - {}, "
        "spent_copper = spent_copper + {}, updated_at = CURRENT_TIMESTAMP "
        "WHERE guild_id = {} AND money_copper >= {}",
        copper, copper, guildId, copper);
    return true;
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
    CharacterDatabase.DirectExecute(
        "INSERT INTO mod_ai_guild_stock (guild_id, item_id, item_count) VALUES ({}, {}, {}) "
        "ON DUPLICATE KEY UPDATE item_count = item_count + VALUES(item_count), updated_at = CURRENT_TIMESTAMP",
        guildId, itemId, count);
}

bool RemoveStock(uint32 guildId, uint32 itemId, uint32 count)
{
    if (StockCount(guildId, itemId) < count)
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
    return proto->Quality <= ITEM_QUALITY_EPIC;
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

uint64 ServicePrice(ItemTemplate const* proto, uint32 count, bool craft)
{
    if (!proto || !count)
        return 0;

    uint64 unit = 0;
    if (craft)
    {
        // A virtual guild crafter charges above vendor-sale value for materials and work, while
        // never undercutting half of a normal vendor purchase price when one exists.
        uint64 const fromSell = uint64(proto->SellPrice) * 4u;
        uint64 const fromBuy = uint64(proto->BuyPrice) / 2u;
        unit = std::max<uint64>(fromSell, fromBuy);
    }
    else
    {
        unit = proto->BuyPrice;
    }

    return unit ? unit * count : 0;
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

    // Prefer actual guild stock. This keeps player deposits useful and avoids spending guild money.
    if (StockCount(request.guildId, request.itemId) >= count)
    {
        if (!RemoveStock(request.guildId, request.itemId, count))
            return false;
        if (!SendItemMail(request.requesterGuid, request.targetGuid, proto, count,
                          "AI Guild Service", "Your guild request was fulfilled from the guild vault."))
        {
            AddStock(request.guildId, request.itemId, count);
            return false;
        }
        SetRequestStatus(request.id, "fulfilled");
        return true;
    }

    if (!request.quotedCopper || BankBalance(request.guildId) < request.quotedCopper)
        return false;
    if (!DebitBank(request.guildId, request.quotedCopper))
        return false;

    std::string body = request.type == "craft"
        ? "A guild crafter completed your request. The guild treasury covered materials and service cost."
        : "The guild shopping service sourced your request. The guild treasury covered the purchase.";

    if (!SendItemMail(request.requesterGuid, request.targetGuid, proto, count,
                      "AI Guild Service", body))
    {
        RefundBank(request.guildId, request.quotedCopper);
        return false;
    }

    SetRequestStatus(request.id, "fulfilled");
    return true;
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
        else
            break; // preserve FIFO when the treasury cannot afford the next request
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
        "!mail <itemId> [count] <guildmate>, !buy <itemId> [count], !craft <itemId> [count], !requests");
}
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
        Reply(player, "[AI Guild] Treasury: " + MoneyText(BankBalance(guildId)) + ". Vault: " +
            std::to_string(items) + " items across " + std::to_string(lines) + " item types. " +
            std::to_string(processed) + " queued request(s) processed now.");
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
                " quote=" + MoneyText(f[4].Get<uint64>()) + " status=" + f[5].Get<std::string>());
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
            Reply(player, "[AI Guild] The guild vault refuses BoP, quest/key or above-epic items.");
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
            ". Vault now has " + std::to_string(StockCount(guildId, itemId)) + ". Processed " +
            std::to_string(processed) + " queued request(s).");
        return true;
    }

    if (command == "!withdraw" || command == "!mail")
    {
        if (!IsServiceSafe(proto))
        {
            Reply(player, "[AI Guild] The guild vault refuses BoP, quest/key or above-epic items.");
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
        {
            targetName = player->GetName();
        }

        if (!RemoveStock(guildId, itemId, count))
        {
            Reply(player, "[AI Guild] The vault does not have enough of that item.");
            return true;
        }
        if (!SendItemMail(player->GetGUID().GetCounter(), targetGuid, proto, count,
                          "Guild Vault Delivery", "Requested from the persistent AI guild vault."))
        {
            AddStock(guildId, itemId, count);
            Reply(player, "[AI Guild] Mail creation failed; vault stock was restored.");
            return true;
        }
        Reply(player, "[AI Guild] Sent " + std::to_string(count) + "x " + proto->Name1 + " to " + targetName + ".");
        return true;
    }

    if (command == "!buy" || command == "!craft")
    {
        if (!IsServiceSafe(proto))
        {
            Reply(player, "[AI Guild] The service refuses BoP, quest/key or above-epic items.");
            return true;
        }

        bool const craft = command == "!craft";
        uint64 const quote = ServicePrice(proto, count, craft);
        if (!quote)
        {
            Reply(player, craft
                ? "[AI Guild] This item has no sane crafting-service price and cannot be synthesized by guild crafters."
                : "[AI Guild] This item has no vendor purchase price, so the shopping service will not fabricate a market listing.");
            return true;
        }

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
        Reply(player, "[AI Guild] Request #" + std::to_string(requestId) + " for " + std::to_string(count) +
            "x " + proto->Name1 + " quoted at " + MoneyText(quote) + ". Status: " + status +
            (status == "queued" ? ". Donate to the treasury or deposit matching stock to unblock it." : ". Delivery is in the mail."));
        return true;
    }

    return true;
}
}
