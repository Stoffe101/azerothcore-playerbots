#include "TitanRuneSystem.h"

#include "Chat.h"
#include "DatabaseEnv.h"
#include "Field.h"
#include "ItemTemplate.h"
#include "ObjectMgr.h"
#include "Player.h"
#include "ScriptMgr.h"
#include "WorldSession.h"

#include <cstdint>
#include <string>

namespace
{
void Notify(Player* player, std::string const& message)
{
    if (!player || !player->GetSession() || player->GetSession()->IsBot())
        return;
    ChatHandler(player->GetSession()).PSendSysMessage("[Titan Rune] {}", message);
}

bool DeliverReward(Player* player, uint64 rewardId, uint32 itemEntry, uint32 count, std::string const& reason,
    bool notifyIfBlocked)
{
    if (!player || !count)
        return false;

    ItemTemplate const* item = sObjectMgr->GetItemTemplate(itemEntry);
    if (!item)
    {
        Notify(player, "A pending Titan Rune reward references a missing item template. The reward was kept pending for server repair.");
        return false;
    }

    if (!player->AddItem(itemEntry, count))
    {
        if (notifyIfBlocked)
            Notify(player, std::string("Pending reward blocked by bag/unique-item restrictions: ") + reason +
                ". Make room and it will retry automatically next login, map change, or Titan Rune reward.");
        return false;
    }

    // Persist the inventory before closing the durable ledger row. This intentionally favours a
    // vanishingly rare duplicate after a process crash over permanently losing an earned currency.
    player->SaveToDB(false, false);
    CharacterDatabase.DirectExecute(
        "UPDATE mod_titan_rune_player_rewards SET delivered=1, delivered_at=CURRENT_TIMESTAMP "
        "WHERE id={} AND guid={} AND delivered=0",
        rewardId, player->GetGUID().GetCounter());

    Notify(player, reason + ": +" + std::to_string(count) + " " + item->Name1);
    return true;
}

class TitanRunePendingRewardPlayerScript final : public PlayerScript
{
public:
    TitanRunePendingRewardPlayerScript() : PlayerScript("TitanRunePendingRewardPlayerScript") { }

    void OnPlayerLogin(Player* player) override
    {
        TitanRune::RetryPendingRewards(player, true);
    }

    void OnPlayerMapChanged(Player* player) override
    {
        TitanRune::RetryPendingRewards(player, true);
    }
};
}

namespace TitanRune
{
void QueuePlayerReward(Player* player, uint32 instanceId, uint32 bossEntry, TitanRuneMode mode,
    uint32 itemEntry, uint32 count, char const* reason)
{
    if (!player || !player->GetSession() || player->GetSession()->IsBot() || !count)
        return;

    std::string escapedReason = reason ? reason : "Titan Rune reward";
    CharacterDatabase.EscapeString(escapedReason);

    // The UNIQUE key makes boss reward delivery idempotent even if multiple death hooks observe the
    // same boss. Keep the row after delivery so a recycled callback cannot award the same reward twice.
    CharacterDatabase.DirectExecute(
        "INSERT IGNORE INTO mod_titan_rune_player_rewards "
        "(guid, instance_id, boss_entry, mode, item_entry, item_count, reason, delivered) "
        "VALUES ({}, {}, {}, {}, {}, {}, '{}', 0)",
        player->GetGUID().GetCounter(), instanceId, bossEntry, uint8(mode), itemEntry, count, escapedReason);

    RetryPendingRewards(player, true);
}

uint32 RetryPendingRewards(Player* player, bool notifyIfBlocked)
{
    if (!player || !player->GetSession() || player->GetSession()->IsBot())
        return 0;

    QueryResult result = CharacterDatabase.Query(
        "SELECT id, item_entry, item_count, reason FROM mod_titan_rune_player_rewards "
        "WHERE guid={} AND delivered=0 ORDER BY id LIMIT 50",
        player->GetGUID().GetCounter());
    if (!result)
        return 0;

    uint32 delivered = 0;
    do
    {
        Field* fields = result->Fetch();
        uint64 const id = fields[0].Get<uint64>();
        uint32 const itemEntry = fields[1].Get<uint32>();
        uint32 const itemCount = fields[2].Get<uint32>();
        std::string const rewardReason = fields[3].Get<std::string>();
        if (DeliverReward(player, id, itemEntry, itemCount, rewardReason, notifyIfBlocked))
            ++delivered;
    } while (result->NextRow());

    return delivered;
}
}

void AddTitanRunePendingRewardScripts()
{
    new TitanRunePendingRewardPlayerScript();
}
