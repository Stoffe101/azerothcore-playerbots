#!/usr/bin/env python3
"""Apply the ERA-07 PlayerbotFactory item-policy bridge to an assembled AzerothCore tree.

Run this AFTER ordinary wrapper patches and mod-era-talents. Several independent patch
stacks rewrite PlayerbotFactory.cpp, so this integration layer uses strict semantic
markers instead of another fragile unified diff.
"""

from __future__ import annotations

import sys
from pathlib import Path


def replace_once(text: str, old: str, new: str, label: str) -> str:
    count = text.count(old)
    if count != 1:
        raise SystemExit(f"ERROR: {label}: expected exactly one marker, found {count}")
    return text.replace(old, new, 1)


def ensure_replace(text: str, old: str, new: str, applied_token: str, label: str) -> str:
    if applied_token in text:
        return text
    return replace_once(text, old, new, label)


def main() -> int:
    if len(sys.argv) != 2:
        print("usage: apply-playerbot-era-item-policy.py <azerothcore-root>", file=sys.stderr)
        return 2

    core = Path(sys.argv[1]).resolve()
    header = core / "modules/mod-playerbots/src/Bot/Factory/PlayerbotFactory.h"
    source = core / "modules/mod-playerbots/src/Bot/Factory/PlayerbotFactory.cpp"
    craft_source = core / "modules/mod-playerbots/src/Ai/Base/Actions/CastCustomSpellAction.cpp"

    if not header.is_file() or not source.is_file() or not craft_source.is_file():
        raise SystemExit(f"ERROR: Playerbots sources not found under {core}")

    h = header.read_text(encoding="utf-8")
    cpp = source.read_text(encoding="utf-8")
    craft = craft_source.read_text(encoding="utf-8")

    h = ensure_replace(
        h,
        """    static void AutoGear(Player* bot, uint32 itemQuality, uint32 ilvl, bool incremental, bool secondChance = false,
                        bool applyFinishers = true);
""",
        """    static void AutoGear(Player* bot, uint32 itemQuality, uint32 ilvl, bool incremental, bool secondChance = false,
                        bool applyFinishers = true);

    // Optional server integration hooks. Playerbots owns item generation while the caller owns
    // realm chronology; function pointers keep this module independent from any specific era mod.
    using ItemPolicyReadyPredicate = bool (*)();
    using ItemAllowedPredicate = bool (*)(uint32);
    using CraftSpellAllowedPredicate = bool (*)(uint32);
    static void SetItemPolicyPredicates(ItemPolicyReadyPredicate readyPredicate, ItemAllowedPredicate allowedPredicate,
        CraftSpellAllowedPredicate craftSpellAllowedPredicate);
    static bool IsExternalItemPolicyReady();
    static bool IsItemAllowedByExternalPolicy(uint32 itemId);
    static bool IsAutomatedCraftSpellAllowed(uint32 spellId);
""",
        "using ItemPolicyReadyPredicate = bool (*)();",
        "public item-policy API",
    )

    cpp = ensure_replace(
        cpp,
        "std::vector<uint32> PlayerbotFactory::ccBreakTrinketCache;\n",
        """std::vector<uint32> PlayerbotFactory::ccBreakTrinketCache;
static PlayerbotFactory::ItemPolicyReadyPredicate g_itemPolicyReadyPredicate = nullptr;
static PlayerbotFactory::ItemAllowedPredicate g_itemAllowedPredicate = nullptr;
static PlayerbotFactory::CraftSpellAllowedPredicate g_craftSpellAllowedPredicate = nullptr;
""",
        "g_itemPolicyReadyPredicate = nullptr;",
        "item-policy callback storage",
    )

    cpp = ensure_replace(
        cpp,
        """void PlayerbotFactory::InitEquipment(bool incremental, bool second_chance)
{
""",
        """void PlayerbotFactory::InitEquipment(bool incremental, bool second_chance)
{
    // ERA-07: fail closed before second-chance paths can destroy existing equipment.
    if (!IsExternalItemPolicyReady())
        return;

""",
        "ERA-07: fail closed before second-chance",
        "InitEquipment readiness guard",
    )

    cpp = ensure_replace(
        cpp,
        """                uint32 itemId = oEntry->ItemId[j];

                // skip hearthstone
""",
        """                uint32 itemId = oEntry->ItemId[j];

                if (!IsItemAllowedByExternalPolicy(itemId))
                    continue;

                // skip hearthstone
""",
        "uint32 itemId = oEntry->ItemId[j];\n\n                if (!IsItemAllowedByExternalPolicy(itemId))",
        "start outfit item guard",
    )

    cpp = ensure_replace(
        cpp,
        """        for (uint32 itemId : ccBreakTrinketCache)
        {
            ItemTemplate const* proto = sObjectMgr->GetItemTemplate(itemId);
""",
        """        for (uint32 itemId : ccBreakTrinketCache)
        {
            if (!IsItemAllowedByExternalPolicy(itemId))
                continue;

            ItemTemplate const* proto = sObjectMgr->GetItemTemplate(itemId);
""",
        "for (uint32 itemId : ccBreakTrinketCache)\n        {\n            if (!IsItemAllowedByExternalPolicy(itemId))",
        "PvP trinket item guard",
    )

    cpp = ensure_replace(
        cpp,
        """                    for (uint32 itemId : sRandomItemMgr.GetEquipmentNew(requiredLevel, inventoryType))
                    {
                        uint32 skipProb = 25;
""",
        """                    for (uint32 itemId : sRandomItemMgr.GetEquipmentNew(requiredLevel, inventoryType))
                    {
                        if (!IsItemAllowedByExternalPolicy(itemId))
                            continue;

                        uint32 skipProb = 25;
""",
        "for (uint32 itemId : sRandomItemMgr.GetEquipmentNew(requiredLevel, inventoryType))\n                    {\n                        if (!IsItemAllowedByExternalPolicy(itemId))",
        "AutoGear candidate item guard",
    )

    cpp = ensure_replace(
        cpp,
        """inline Item* StoreNewItemInInventorySlot(Player* player, uint32 newItemId, uint32 count)
{
    ItemPosCountVec vDest;
""",
        """inline Item* StoreNewItemInInventorySlot(Player* player, uint32 newItemId, uint32 count)
{
    if (!PlayerbotFactory::IsItemAllowedByExternalPolicy(newItemId))
        return nullptr;

    ItemPosCountVec vDest;
""",
        "PlayerbotFactory::IsItemAllowedByExternalPolicy(newItemId)",
        "inventory creation item guard",
    )

    cpp = ensure_replace(
        cpp,
        """void PlayerbotFactory::InitBags(bool destroyOld)
{
""",
        """void PlayerbotFactory::InitBags(bool destroyOld)
{
    if (!IsExternalItemPolicyReady())
        return;

""",
        "void PlayerbotFactory::InitBags(bool destroyOld)\n{\n    if (!IsExternalItemPolicyReady())",
        "bag readiness guard",
    )

    cpp = ensure_replace(
        cpp,
        """        Item* old_bag = bot->GetItemByPos(INVENTORY_SLOT_BAG_0, slot);
""",
        """        if (!IsItemAllowedByExternalPolicy(newItemId))
            continue;

        Item* old_bag = bot->GetItemByPos(INVENTORY_SLOT_BAG_0, slot);
""",
        "if (!IsItemAllowedByExternalPolicy(newItemId))\n            continue;\n\n        Item* old_bag",
        "bag item guard",
    )

    cpp = ensure_replace(
        cpp,
        """    uint32 entry = sRandomItemMgr.GetAmmo(level, subClass);
    if (!entry)
        return;
""",
        """    uint32 entry = sRandomItemMgr.GetAmmo(level, subClass);
    if (!entry || !IsItemAllowedByExternalPolicy(entry))
        return;
""",
        "!entry || !IsItemAllowedByExternalPolicy(entry)",
        "ammo item guard",
    )

    cpp = ensure_replace(
        cpp,
        """        uint32 itemId = sRandomItemMgr.GetRandomPotion(level, effect);
        if (!itemId)
""",
        """        uint32 itemId = sRandomItemMgr.GetRandomPotion(level, effect);
        if (!itemId || !IsItemAllowedByExternalPolicy(itemId))
""",
        "!itemId || !IsItemAllowedByExternalPolicy(itemId)",
        "potion item guard",
    )

    cpp = ensure_replace(
        cpp,
        """        if (proto->Area || proto->Map || proto->RequiredCityRank || proto->RequiredHonorRank)
            continue;

""",
        """        if (proto->Area || proto->Map || proto->RequiredCityRank || proto->RequiredHonorRank)
            continue;

        if (!IsItemAllowedByExternalPolicy(itemId))
            continue;

""",
        "proto->RequiredHonorRank)\n            continue;\n\n        if (!IsItemAllowedByExternalPolicy(itemId))",
        "food item guard",
    )

    cpp = ensure_replace(
        cpp,
        """    for (uint32 const& enchantGem : enchantGemIdCache)
    {
        ItemTemplate const* gemTemplate = sObjectMgr->GetItemTemplate(enchantGem);
""",
        """    for (uint32 const& enchantGem : enchantGemIdCache)
    {
        if (!IsItemAllowedByExternalPolicy(enchantGem))
            continue;

        ItemTemplate const* gemTemplate = sObjectMgr->GetItemTemplate(enchantGem);
""",
        "if (!IsItemAllowedByExternalPolicy(enchantGem))",
        "gem item guard",
    )

    cpp = ensure_replace(
        cpp,
        """Item* PlayerbotFactory::StoreItem(uint32 itemId, uint32 count)
{
    //ItemTemplate const* proto = sObjectMgr->GetItemTemplate(itemId); //not used, line marked for removal.
""",
        """Item* PlayerbotFactory::StoreItem(uint32 itemId, uint32 count)
{
    if (!IsItemAllowedByExternalPolicy(itemId))
        return nullptr;

    //ItemTemplate const* proto = sObjectMgr->GetItemTemplate(itemId); //not used, line marked for removal.
""",
        "Item* PlayerbotFactory::StoreItem(uint32 itemId, uint32 count)\n{\n    if (!IsItemAllowedByExternalPolicy(itemId))",
        "generic StoreItem guard",
    )

    cpp = ensure_replace(
        cpp,
        """void PlayerbotFactory::AutoGear(Player* bot, uint32 itemQuality, uint32 ilvl, bool incremental, bool secondChance,
                                bool applyFinishers)
{
""",
        """void PlayerbotFactory::SetItemPolicyPredicates(
    ItemPolicyReadyPredicate readyPredicate, ItemAllowedPredicate allowedPredicate,
    CraftSpellAllowedPredicate craftSpellAllowedPredicate)
{
    g_itemPolicyReadyPredicate = readyPredicate;
    g_itemAllowedPredicate = allowedPredicate;
    g_craftSpellAllowedPredicate = craftSpellAllowedPredicate;
}

bool PlayerbotFactory::IsExternalItemPolicyReady()
{
    return !g_itemPolicyReadyPredicate || g_itemPolicyReadyPredicate();
}

bool PlayerbotFactory::IsItemAllowedByExternalPolicy(uint32 itemId)
{
    return (!g_itemPolicyReadyPredicate || g_itemPolicyReadyPredicate()) &&
           (!g_itemAllowedPredicate || g_itemAllowedPredicate(itemId));
}

bool PlayerbotFactory::IsAutomatedCraftSpellAllowed(uint32 spellId)
{
    return g_craftSpellAllowedPredicate && g_craftSpellAllowedPredicate(spellId);
}

void PlayerbotFactory::AutoGear(Player* bot, uint32 itemQuality, uint32 ilvl, bool incremental, bool secondChance,
                                bool applyFinishers)
{
    if (!IsExternalItemPolicyReady())
        return;

""",
        "void PlayerbotFactory::SetItemPolicyPredicates(",
        "AutoGear callback implementation",
    )

    h = ensure_replace(
        h,
        "    static void SetItemPolicyPredicates(ItemPolicyReadyPredicate readyPredicate, ItemAllowedPredicate allowedPredicate);\n",
        """    using CraftSpellAllowedPredicate = bool (*)(uint32);
    static void SetItemPolicyPredicates(ItemPolicyReadyPredicate readyPredicate, ItemAllowedPredicate allowedPredicate,
        CraftSpellAllowedPredicate craftSpellAllowedPredicate);
    static bool IsAutomatedCraftSpellAllowed(uint32 spellId);
""",
        "using CraftSpellAllowedPredicate = bool (*)(uint32);",
        "existing factory craft callback API",
    )
    cpp = ensure_replace(
        cpp,
        "static PlayerbotFactory::ItemAllowedPredicate g_itemAllowedPredicate = nullptr;\n",
        """static PlayerbotFactory::ItemAllowedPredicate g_itemAllowedPredicate = nullptr;
static PlayerbotFactory::CraftSpellAllowedPredicate g_craftSpellAllowedPredicate = nullptr;
""",
        "g_craftSpellAllowedPredicate = nullptr;",
        "existing factory craft callback storage",
    )
    cpp = ensure_replace(
        cpp,
        """void PlayerbotFactory::SetItemPolicyPredicates(
    ItemPolicyReadyPredicate readyPredicate, ItemAllowedPredicate allowedPredicate)
{
    g_itemPolicyReadyPredicate = readyPredicate;
    g_itemAllowedPredicate = allowedPredicate;
}
""",
        """void PlayerbotFactory::SetItemPolicyPredicates(
    ItemPolicyReadyPredicate readyPredicate, ItemAllowedPredicate allowedPredicate,
    CraftSpellAllowedPredicate craftSpellAllowedPredicate)
{
    g_itemPolicyReadyPredicate = readyPredicate;
    g_itemAllowedPredicate = allowedPredicate;
    g_craftSpellAllowedPredicate = craftSpellAllowedPredicate;
}
""",
        "g_craftSpellAllowedPredicate = craftSpellAllowedPredicate;",
        "existing factory craft callback registration",
    )
    cpp = ensure_replace(
        cpp,
        """void PlayerbotFactory::AutoGear(Player* bot, uint32 itemQuality, uint32 ilvl, bool incremental, bool secondChance,
                                bool applyFinishers)
{
""",
        """bool PlayerbotFactory::IsAutomatedCraftSpellAllowed(uint32 spellId)
{
    return g_craftSpellAllowedPredicate && g_craftSpellAllowedPredicate(spellId);
}

void PlayerbotFactory::AutoGear(Player* bot, uint32 itemQuality, uint32 ilvl, bool incremental, bool secondChance,
                                bool applyFinishers)
{
""",
        "bool PlayerbotFactory::IsAutomatedCraftSpellAllowed(uint32 spellId)",
        "existing factory craft callback implementation",
    )

    craft = ensure_replace(
        craft,
        '#include "Playerbots.h"\n',
        '#include "Playerbots.h"\n#include "PlayerbotFactory.h"\n',
        '#include "PlayerbotFactory.h"',
        "craft action item-policy include",
    )
    craft = ensure_replace(
        craft,
        """bool CastRandomSpellAction::AcceptSpell(SpellInfo const* spellInfo)
{
    bool isTradeSkill = spellInfo->Effects[EFFECT_0].Effect == SPELL_EFFECT_CREATE_ITEM &&
""",
        """bool CastRandomSpellAction::AcceptSpell(SpellInfo const* spellInfo)
{
    for (uint8 effect = 0; effect < MAX_SPELL_EFFECTS; ++effect)
    {
        auto const kind = spellInfo->Effects[effect].Effect;
        if ((kind == SPELL_EFFECT_CREATE_ITEM || kind == SPELL_EFFECT_CREATE_ITEM_2 ||
             kind == SPELL_EFFECT_CREATE_RANDOM_ITEM) &&
            !PlayerbotFactory::IsAutomatedCraftSpellAllowed(spellInfo->Id))
            return false;
    }

    bool isTradeSkill = spellInfo->Effects[EFFECT_0].Effect == SPELL_EFFECT_CREATE_ITEM &&
""",
        "kind == SPELL_EFFECT_CREATE_ITEM_2",
        "generic random spell item-creation guard",
    )
    craft = ensure_replace(
        craft,
        """    return spellInfo->Effects[EFFECT_0].Effect == SPELL_EFFECT_CREATE_ITEM && spellInfo->ReagentCount[EFFECT_0] > 0 &&
           spellInfo->SchoolMask == 0;
""",
        """    return spellInfo->Effects[EFFECT_0].Effect == SPELL_EFFECT_CREATE_ITEM && spellInfo->ReagentCount[EFFECT_0] > 0 &&
           spellInfo->SchoolMask == 0 && PlayerbotFactory::IsAutomatedCraftSpellAllowed(spellInfo->Id);
""",
        "PlayerbotFactory::IsAutomatedCraftSpellAllowed(spellInfo->Id)",
        "autonomous craft action guard",
    )

    required_header = (
        "using ItemPolicyReadyPredicate = bool (*)();",
        "SetItemPolicyPredicates",
        "IsExternalItemPolicyReady",
        "IsItemAllowedByExternalPolicy",
    )
    required_source = (
        "g_itemPolicyReadyPredicate = nullptr;",
        "ERA-07: fail closed before second-chance",
        "PlayerbotFactory::IsItemAllowedByExternalPolicy(newItemId)",
        "!entry || !IsItemAllowedByExternalPolicy(entry)",
        "!itemId || !IsItemAllowedByExternalPolicy(itemId)",
        "if (!IsItemAllowedByExternalPolicy(enchantGem))",
        "void PlayerbotFactory::SetItemPolicyPredicates(",
    )
    for token in required_header:
        if token not in h:
            raise SystemExit(f"ERROR: transformed PlayerbotFactory.h missing token: {token}")
    for token in required_source:
        if token not in cpp:
            raise SystemExit(f"ERROR: transformed PlayerbotFactory.cpp missing token: {token}")

    header.write_text(h, encoding="utf-8")
    source.write_text(cpp, encoding="utf-8")
    craft_source.write_text(craft, encoding="utf-8")
    print("Applied ERA-07 PlayerbotFactory item-policy bridge after complete patch stack")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
