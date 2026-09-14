#include "AdventureCacheCommand.h"

#include "AdventureProgressionStore.h"
#include "RaidRosterConfig.h"
#include "AiFactory.h"
#include "Item.h"
#include "ItemTemplate.h"
#include "ObjectMgr.h"
#include "Player.h"
#include "PlayerbotAI.h"
#include "Playerbots.h"
#include "Random.h"
#include "RandomItemMgr.h"
#include "RBAC.h"

#include <array>
#include <limits>
#include <vector>

using namespace Acore::ChatCommands;

namespace
{
constexpr uint32 ITEM_SUPER_HEALING_POTION = 22829;
constexpr uint32 ITEM_SUPER_MANA_POTION = 22832;
constexpr uint32 COPPER_PER_GOLD = 10000;

bool IsRealPlayer(Player* player)
{
    return player && player->GetSession() && !player->GetSession()->IsBot() && GET_PLAYERBOT_AI(player) == nullptr;
}

bool TryGiveItem(Player* player, uint32 itemId, uint32 count)
{
    if (!player || !itemId || !count)
        return false;

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

uint32 CacheGearItemLevelCap(Player* player)
{
    return player && player->GetLevel() >= 70 ? 115u : 100u;
}

bool IsSpecAppropriate(Player* player, ItemTemplate const* proto, uint8 specTab)
{
    if (!player || !proto)
        return false;

    if (proto->Class == ITEM_CLASS_WEAPON)
    {
        return sRandomItemMgr.CanEquipWeapon(proto, player->getClass()) &&
               sRandomItemMgr.ShouldEquipWeaponForSpec(proto, player->getClass(), specTab);
    }

    if (proto->Class == ITEM_CLASS_ARMOR)
    {
        return sRandomItemMgr.CanEquipArmor(proto, player->getClass(), player->GetLevel()) &&
               sRandomItemMgr.ShouldEquipArmorForSpec(proto, player->getClass(), specTab);
    }

    return true;
}

uint32 PickSpecAwareGear(Player* player, uint32 quality)
{
    if (!player)
        return 0;

    std::string const specName = AiFactory::GetPlayerSpecName(player);
    if (specName.empty())
        return 0;

    uint8 const specTab = AiFactory::GetPlayerSpecTab(player);
    uint32 const itemLevelCap = CacheGearItemLevelCap(player);
    constexpr std::array<uint8, 7> slots = {
        EQUIPMENT_SLOT_MAINHAND,
        EQUIPMENT_SLOT_TRINKET1,
        EQUIPMENT_SLOT_TRINKET2,
        EQUIPMENT_SLOT_CHEST,
        EQUIPMENT_SLOT_HEAD,
        EQUIPMENT_SLOT_LEGS,
        EQUIPMENT_SLOT_HANDS,
    };

    uint32 const start = urand(0, 2);
    for (uint32 offset = 0; offset < slots.size(); ++offset)
    {
        uint8 const slot = slots[(start + offset) % slots.size()];
        Item* current = player->GetItemByPos(INVENTORY_SLOT_BAG_0, slot);
        uint32 const currentItemId = current ? current->GetEntry() : 0;

        std::vector<uint32> scored = sRandomItemMgr.GetUpgradeList(
            player, specName, slot, quality, currentItemId, 20);

        std::vector<uint32> eligible;
        eligible.reserve(scored.size());
        for (uint32 itemId : scored)
        {
            ItemTemplate const* proto = sObjectMgr->GetItemTemplate(itemId);
            if (!proto || proto->ItemLevel > itemLevelCap)
                continue;
            if (!IsSpecAppropriate(player, proto, specTab))
                continue;
            eligible.push_back(itemId);
        }

        if (!eligible.empty())
            return eligible[urand(0, static_cast<uint32>(eligible.size() - 1))];
    }

    return 0;
}

bool TryGiveGold(Player* player, uint32 gold)
{
    if (!player || !gold)
        return false;

    uint64 const copper64 = uint64(gold) * COPPER_PER_GOLD;
    if (copper64 > uint64(std::numeric_limits<int32>::max()))
        return false;
    return player->ModifyMoney(static_cast<int32>(copper64));
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
    Player* player = handler && handler->GetSession() ? handler->GetSession()->GetPlayer() : nullptr;
    if (!IsRealPlayer(player))
        return true;

    AdventureProgressionStore::State state = AdventureProgressionStore::LoadOrCreate(player->GetGUID().GetCounter());
    handler->PSendSysMessage(
        "Adventure caches waiting: {}. Natural level milestones award caches at 65 and 70.",
        state.pendingCaches);
    return true;
}

bool AdventureCacheCommand::HandleOpen(ChatHandler* handler)
{
    Player* player = handler && handler->GetSession() ? handler->GetSession()->GetPlayer() : nullptr;
    if (!IsRealPlayer(player))
        return true;

    if (!g_AdventureProgressionCachesEnable)
    {
        handler->SendSysMessage("Adventure progression caches are disabled.");
        return true;
    }

    uint32 const guid = player->GetGUID().GetCounter();
    if (!AdventureProgressionStore::ConsumePendingCache(guid))
    {
        handler->SendSysMessage("You do not have an Adventure Cache waiting.");
        return true;
    }

    uint32 const healingCount = urand(4, 7);
    uint32 const manaCount = urand(4, 7);
    uint32 gold = urand(4, 8);
    uint32 const roll = urand(1, 100);

    uint32 gearItemId = 0;
    bool const epicJackpot = roll <= 3;
    bool const rareGearBonus = roll > 3 && roll <= 15;
    bool const goldBonus = roll > 15 && roll <= 30;

    if (epicJackpot)
    {
        gearItemId = PickSpecAwareGear(player, ITEM_QUALITY_EPIC);
        if (!gearItemId)
            gearItemId = PickSpecAwareGear(player, ITEM_QUALITY_RARE);
    }
    else if (rareGearBonus)
        gearItemId = PickSpecAwareGear(player, ITEM_QUALITY_RARE);
    else if (goldBonus)
        gold += 10;

    bool gearGiven = true;
    if (gearItemId)
    {
        gearGiven = TryGiveItem(player, gearItemId, 1);
        if (!gearGiven)
            gold += epicJackpot ? 40 : 15;
    }
    else if (epicJackpot)
        gold += 30;
    else if (rareGearBonus)
        gold += 10;

    bool const healingGiven = TryGiveItem(player, ITEM_SUPER_HEALING_POTION, healingCount);
    bool const usesMana = player->getPowerType() == POWER_MANA;
    bool manaGiven = true;
    if (usesMana)
        manaGiven = TryGiveItem(player, ITEM_SUPER_MANA_POTION, manaCount);

    if (!healingGiven)
        gold += 2;
    if (usesMana && !manaGiven)
        gold += 2;

    bool const goldGiven = TryGiveGold(player, gold);
    player->SaveToDB(false, false);

    AdventureProgressionStore::State after = AdventureProgressionStore::LoadOrCreate(guid);
    if (usesMana)
    {
        handler->PSendSysMessage(
            "Adventure Cache opened: {} gold, {} Super Healing Potion(s), {} Super Mana Potion(s). {} cache(s) remain.",
            goldGiven ? gold : 0,
            healingGiven ? healingCount : 0,
            manaGiven ? manaCount : 0,
            after.pendingCaches);
    }
    else
    {
        handler->PSendSysMessage(
            "Adventure Cache opened: {} gold and {} Super Healing Potion(s). {} cache(s) remain.",
            goldGiven ? gold : 0,
            healingGiven ? healingCount : 0,
            after.pendingCaches);
    }

    if (!goldGiven)
        handler->SendSysMessage("The gold part of the cache could not be added because your character is at the money cap.");

    if (gearItemId && gearGiven)
    {
        ItemTemplate const* proto = sObjectMgr->GetItemTemplate(gearItemId);
        handler->PSendSysMessage(
            epicJackpot ? "EPIC CACHE JACKPOT: {}!" : "Rare cache gear bonus: {}!",
            proto ? proto->Name1 : "spec-appropriate gear");
    }
    else if (gearItemId && !gearGiven)
        handler->SendSysMessage("Your bags were full for the gear reward, so the jackpot was converted to extra gold.");
    else if (epicJackpot)
        handler->SendSysMessage("EPIC CACHE JACKPOT: no progression-safe epic upgrade was available, so you received +30 gold instead.");
    else if (rareGearBonus)
        handler->SendSysMessage("Rare cache roll: no progression-safe gear upgrade was available, so you received +10 gold instead.");
    else if (goldBonus)
        handler->SendSysMessage("Cache bonus: +10 gold.");

    if (!healingGiven || (usesMana && !manaGiven))
        handler->SendSysMessage("Your bags were full, so the missing potion bundle was converted to extra gold.");

    return true;
}
