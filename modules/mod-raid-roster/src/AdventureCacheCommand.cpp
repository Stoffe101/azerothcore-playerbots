#include "AdventureCacheCommand.h"
#include "AdventureProgressionStore.h"
#include "RaidRosterConfig.h"
#include "Player.h"
#include "Item.h"
#include "Random.h"
#include "RBAC.h"

using namespace Acore::ChatCommands;

namespace
{
constexpr uint32 ITEM_SUPER_HEALING_POTION = 22829;
constexpr uint32 ITEM_SUPER_MANA_POTION = 22832;
constexpr uint32 COPPER_PER_GOLD = 10000;

bool TryGiveItem(Player* player, uint32 itemId, uint32 count)
{
    ItemPosCountVec dest;
    InventoryResult result = player->CanStoreNewItem(NULL_BAG, NULL_SLOT, dest, itemId, count);
    if (result != EQUIP_ERR_OK)
        return false;

    Item* item = player->StoreNewItem(dest, itemId, true);
    if (!item)
        return false;

    player->SendNewItem(item, count, true, false);
    return true;
}
}

ChatCommandTable AdventureCacheCommand::GetCommands() const
{
    static ChatCommandTable sub =
    {
        { "status", HandleStatus, SEC_PLAYER, Console::No },
        { "open",   HandleOpen,   SEC_PLAYER, Console::No },
    };
    static ChatCommandTable root = { { "cache", sub } };
    return root;
}

bool AdventureCacheCommand::HandleStatus(ChatHandler* handler)
{
    Player* player = handler->GetSession() ? handler->GetSession()->GetPlayer() : nullptr;
    if (!player)
        return false;

    AdventureProgressionStore::State state =
        AdventureProgressionStore::LoadOrCreate(player->GetGUID().GetCounter());

    handler->PSendSysMessage(
        "Adventure caches waiting: {}. Level milestones currently award caches at 65 and 70.",
        state.pendingCaches);
    return true;
}

bool AdventureCacheCommand::HandleOpen(ChatHandler* handler)
{
    Player* player = handler->GetSession() ? handler->GetSession()->GetPlayer() : nullptr;
    if (!player)
        return false;

    if (!g_AdventureProgressionCachesEnable)
    {
        handler->SendSysMessage("Adventure progression caches are disabled.");
        return true;
    }

    uint32 guid = player->GetGUID().GetCounter();
    AdventureProgressionStore::State state = AdventureProgressionStore::LoadOrCreate(guid);
    if (!state.pendingCaches)
    {
        handler->SendSysMessage("You do not have an Adventure Cache waiting.");
        return true;
    }

    // V1 rewards are deliberately combat-focused and profession-free. Gear jackpots are being
    // added through the spec-aware item scorer separately rather than hard-coding class item IDs.
    uint32 healingCount = urand(4, 7);
    uint32 manaCount = urand(4, 7);
    uint32 gold = urand(4, 8);
    uint32 roll = urand(1, 100);
    std::string bonusText;

    if (roll <= 5)
    {
        gold += 20;
        bonusText = " Rare bonus: +20 gold!";
    }
    else if (roll <= 25)
    {
        gold += 5;
        bonusText = " Bonus: +5 gold.";
    }

    // Gold can always be delivered. If a bag is completely full, convert the affected potion
    // bundle into extra gold rather than consuming a cache and silently losing the reward.
    bool healingGiven = TryGiveItem(player, ITEM_SUPER_HEALING_POTION, healingCount);
    bool manaGiven = true;
    bool usesMana = player->getPowerType() == POWER_MANA;
    if (usesMana)
        manaGiven = TryGiveItem(player, ITEM_SUPER_MANA_POTION, manaCount);

    if (!healingGiven)
        gold += 2;
    if (usesMana && !manaGiven)
        gold += 2;

    player->ModifyMoney(static_cast<int32>(gold * COPPER_PER_GOLD));

    if (!AdventureProgressionStore::ConsumePendingCache(guid))
    {
        // This should only be reachable if the queue was changed concurrently. We intentionally
        // do not try to claw rewards back from the player.
        handler->SendSysMessage("Cache reward delivered, but the queue changed while opening it. Check .cache status.");
        return true;
    }

    AdventureProgressionStore::State after = AdventureProgressionStore::LoadOrCreate(guid);
    handler->PSendSysMessage(
        "Adventure Cache opened: {} gold, {} Super Healing Potion(s){}{}. {} cache(s) remain.",
        gold,
        healingGiven ? healingCount : 0,
        usesMana ? Acore::StringFormat(", {} Super Mana Potion(s)", manaGiven ? manaCount : 0) : std::string(),
        bonusText,
        after.pendingCaches);

    return true;
}
