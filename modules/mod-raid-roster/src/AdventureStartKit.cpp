#include "AdventureStartKit.h"
#include "AdventureProgressionStore.h"
#include "EraPolicy.h"
#include "RaidRosterConfig.h"

#include "AiFactory.h"
#include "Bag.h"
#include "ItemTemplate.h"
#include "Log.h"
#include "ObjectMgr.h"
#include "Player.h"
#include "PlayerbotAI.h"
#include "PlayerbotFactory.h"

#include <algorithm>
#include <map>

namespace
{
constexpr uint32 COPPER_PER_GOLD = 10000u;

// WotLK raid-ready convenience package. Portable Hole is the largest ordinary
// player bag in 3.3.5a (24 slots); keep raid supplies intentionally compact.
constexpr uint32 ITEM_PORTABLE_HOLE          = 51809;
constexpr uint32 ITEM_RUNIC_HEALING_POTION   = 33447;
constexpr uint32 ITEM_RUNIC_MANA_POTION      = 33448;
constexpr uint32 ITEM_INDESTRUCTIBLE_POTION  = 40093;
constexpr uint32 ITEM_POTION_OF_SPEED        = 40211;
constexpr uint32 ITEM_POTION_OF_WILD_MAGIC   = 40212;
constexpr uint32 ITEM_FLASK_FROST_WYRM       = 46376;
constexpr uint32 ITEM_FLASK_ENDLESS_RAGE     = 46377;
constexpr uint32 ITEM_FLASK_STONEBLOOD       = 46379;
constexpr uint32 ITEM_FISH_FEAST             = 43015;

uint32 SpentTalentPoints(Player* player)
{
    uint32 total = 0;
    std::map<uint8, uint32> tabs = AiFactory::GetPlayerSpecTabs(player);
    for (auto const& entry : tabs)
        total += entry.second;
    return total;
}

bool IsTbcRaidReady(AdventureStartProfile profile)
{
    return profile == AdventureStartProfile::TbcRaidReady;
}

bool IsWotlkRaidReady(AdventureStartProfile profile)
{
    return profile == AdventureStartProfile::WotlkRaidReady;
}

bool IsRaidReady(AdventureStartProfile profile)
{
    return IsTbcRaidReady(profile) || IsWotlkRaidReady(profile);
}

AdventureStartProfile StoredProfile(uint8 value)
{
    if (value == static_cast<uint8>(AdventureStartProfile::WotlkRaidReady))
        return AdventureStartProfile::WotlkRaidReady;
    if (value == static_cast<uint8>(AdventureStartProfile::TbcRaidReady))
        return AdventureStartProfile::TbcRaidReady;
    return AdventureStartProfile::TbcAdventure;
}

uint32 StartingGold(AdventureStartProfile profile)
{
    if (IsWotlkRaidReady(profile))
        return g_AdventureStartWotlkRaidReadyStartingGold;
    if (IsTbcRaidReady(profile))
        return g_AdventureStartTbcRaidReadyStartingGold;
    return g_AdventureStartStartingGold;
}

uint32 BasicItemLevel(AdventureStartProfile profile)
{
    if (IsWotlkRaidReady(profile))
        return g_AdventureStartWotlkRaidReadyBasicGearItemLevel;
    if (IsTbcRaidReady(profile))
        return g_AdventureStartTbcRaidReadyBasicGearItemLevel;
    return g_AdventureStartBasicGearItemLevel;
}

uint32 FinalItemLevel(AdventureStartProfile profile)
{
    if (IsWotlkRaidReady(profile))
        return g_AdventureStartWotlkRaidReadyGearItemLevel;
    if (IsTbcRaidReady(profile))
        return g_AdventureStartTbcRaidReadyGearItemLevel;
    return g_AdventureStartGearItemLevel;
}

void EnsureCount(Player* player, uint32 itemId, uint32 wanted)
{
    if (!player || !itemId || !wanted)
        return;
    if (!EraPolicy::IsItemAllowed(itemId))
    {
        LOG_WARN(
            "server.loading",
            "[AdventureStart] Refusing automated starter item {} while live era is {}.",
            itemId,
            EraPolicy::Name(EraPolicy::CurrentRealmEra()));
        return;
    }

    uint32 const have = player->GetItemCount(itemId, false);
    if (have < wanted)
        player->StoreNewItemInBestSlots(itemId, wanted - have);
}

void EnsureWotlkBags(Player* player, PlayerbotFactory& factory)
{
    if (!player)
        return;

    // First fill genuinely empty bag slots with Portable Holes.
    factory.InitBags(false);

    uint32 nonEmptyOldBags = 0;
    uint32 equippedPortableHoles = 0;

    for (uint8 slot = INVENTORY_SLOT_BAG_START; slot < INVENTORY_SLOT_BAG_END; ++slot)
    {
        Item* old = player->GetItemByPos(INVENTORY_SLOT_BAG_0, slot);
        if (!old)
            continue;
        if (old->GetEntry() == ITEM_PORTABLE_HOLE)
        {
            ++equippedPortableHoles;
            continue;
        }

        Bag* bag = old->ToBag();
        if (bag && bag->IsEmpty())
        {
            // Safe replacement: never destroy a bag that still contains the player's items.
            player->DestroyItem(INVENTORY_SLOT_BAG_0, slot, true);
        }
        else
        {
            ++nonEmptyOldBags;
        }
    }

    // Fill slots we just safely emptied.
    factory.InitBags(false);

    equippedPortableHoles = 0;
    for (uint8 slot = INVENTORY_SLOT_BAG_START; slot < INVENTORY_SLOT_BAG_END; ++slot)
        if (Item* bag = player->GetItemByPos(INVENTORY_SLOT_BAG_0, slot))
            if (bag->GetEntry() == ITEM_PORTABLE_HOLE)
                ++equippedPortableHoles;

    // A non-empty smaller bag cannot be safely destroyed or nested. Put one replacement
    // Portable Hole in ordinary inventory for each such bag instead. The player can empty/swap
    // it normally without any risk to existing loot. Avoid making duplicates on repeated boosts.
    uint32 const totalPortableHoles = player->GetItemCount(ITEM_PORTABLE_HOLE, false);
    uint32 const carriedPortableHoles = totalPortableHoles > equippedPortableHoles
        ? totalPortableHoles - equippedPortableHoles
        : 0;
    if (carriedPortableHoles < nonEmptyOldBags)
        player->StoreNewItemInBestSlots(ITEM_PORTABLE_HOLE, nonEmptyOldBags - carriedPortableHoles);
}

void CapAmmoAtFourStacks(Player* player)
{
    if (!player)
        return;

    uint32 const ammoId = player->GetUInt32Value(PLAYER_AMMO_ID);
    if (!ammoId)
        return;

    ItemTemplate const* proto = sObjectMgr->GetItemTemplate(ammoId);
    if (!proto)
        return;

    uint32 const stackSize = std::max<uint32>(1u, proto->GetMaxStackSize());
    uint32 const target = stackSize * 4u;
    uint32 const have = player->GetItemCount(ammoId, false);

    if (have > target)
        player->DestroyItemCount(ammoId, have - target, true);
    else if (have < target)
        player->StoreNewItemInBestSlots(ammoId, target - have);
}

bool IsCasterOrHealer(Player* player)
{
    if (!player)
        return false;

    BotRoles const roles = AiFactory::GetPlayerRoles(player);
    if (roles & BOT_ROLE_HEALER)
        return true;

    uint8 const spec = AiFactory::GetPlayerSpecTab(player);
    switch (player->getClass())
    {
        case CLASS_MAGE:
        case CLASS_WARLOCK:
        case CLASS_PRIEST:
            return true;
        case CLASS_DRUID:
            return spec == 0 || spec == 2; // Balance / Restoration
        case CLASS_SHAMAN:
            return spec == 0 || spec == 2; // Elemental / Restoration
        case CLASS_PALADIN:
            return spec == 0;              // Holy
        default:
            return false;
    }
}

void ProvisionWotlkRaidSupplies(Player* player, PlayerbotFactory& factory)
{
    if (!player)
        return;

    EnsureWotlkBags(player, factory);

    // Let PlayerbotFactory choose the best legal arrow/bullet for the equipped ranged weapon,
    // then trim it to exactly four CURRENT stack sizes instead of filling bags with ammunition.
    factory.InitAmmo();
    CapAmmoAtFourStacks(player);

    // Class reagents plus weapon oils/poisons/stones are useful, compact, and already selected
    // by the factory according to class/spec. Potions/food below are deliberately explicit so
    // the WotLK raid-ready package stays predictable rather than becoming an inventory avalanche.
    factory.InitReagents();
    factory.InitConsumables();

    EnsureCount(player, ITEM_RUNIC_HEALING_POTION, 20);
    if (player->GetMaxPower(POWER_MANA) > 0)
        EnsureCount(player, ITEM_RUNIC_MANA_POTION, 20);

    BotRoles const roles = AiFactory::GetPlayerRoles(player);
    if (roles & BOT_ROLE_TANK)
    {
        EnsureCount(player, ITEM_INDESTRUCTIBLE_POTION, 20);
        EnsureCount(player, ITEM_FLASK_STONEBLOOD, 5);
    }
    else if (IsCasterOrHealer(player))
    {
        EnsureCount(player, ITEM_POTION_OF_WILD_MAGIC, 20);
        EnsureCount(player, ITEM_FLASK_FROST_WYRM, 5);
    }
    else
    {
        EnsureCount(player, ITEM_POTION_OF_SPEED, 20);
        EnsureCount(player, ITEM_FLASK_ENDLESS_RAGE, 5);
    }

    // Fish Feast is the classic all-purpose WotLK raid food: one stack, not a pantry.
    EnsureCount(player, ITEM_FISH_FEAST, 20);
}
}

namespace AdventureStartKit
{
bool GrantInitial(Player* player, AdventureStartProfile profile)
{
    if (!player || !player->IsInWorld() || player->IsBeingTeleportedFar())
        return false;

    uint32 const guid = player->GetGUID().GetCounter();
    AdventureProgressionStore::State state = AdventureProgressionStore::LoadOrCreate(guid);
    if (state.starterInitialized)
        return true;

    if (!g_AdventureStartStarterKit)
    {
        AdventureProgressionStore::MarkStarterInitialized(player, static_cast<uint8>(profile));
        return true;
    }

    if (!EraPolicy::ItemProvenanceReady())
    {
        LOG_ERROR(
            "server.loading",
            "[AdventureStart] Starter kit for {} refused: ERA-07 item provenance unavailable ({}).",
            player->GetName(),
            EraPolicy::ItemProvenanceError());
        return false;
    }

    bool const raidReady = IsRaidReady(profile);
    bool const wotlkRaidReady = IsWotlkRaidReady(profile);
    uint32 const startingGold = StartingGold(profile);
    uint32 const basicIlvl = BasicItemLevel(profile);
    uint32 const finalIlvl = FinalItemLevel(profile);

    // Keep PlayerbotFactory isolated in this translation unit. AdventureStartControl.cpp includes
    // IndividualProgression.h, while PlayerbotFactory -> PlayerbotAI.h defines a conflicting
    // unscoped GENERAL enumerator. Splitting the helpers avoids that compile-time collision.
    PlayerbotFactory factory(player, player->GetLevel());

    player->LearnDefaultSkills();
    factory.InitSkills();
    factory.InitClassSpells();
    factory.InitAvailableSpells();

    if (wotlkRaidReady)
    {
        ProvisionWotlkRaidSupplies(player, factory);
    }
    else
    {
        // Vanilla/TBC profiles keep the existing lightweight factory package.
        factory.InitBags(false);
        factory.InitAmmo();
        factory.InitReagents();
        factory.InitPotions();
        factory.InitFood();
    }

    if (raidReady)
    {
        // Max riding plus a maintained mount bootstrap means the explicit raid-ready shortcuts are
        // actually ready to play rather than requiring a trainer/mount scavenger hunt first.
        if (player->GetSkillValue(SKILL_RIDING) < 300)
            player->SetSkill(SKILL_RIDING, 0, 300, 300);
        factory.InitMounts();

        // Glyphs are a Wrath system. Only the post-release WotLK shortcut receives them.
        if (wotlkRaidReady)
            factory.InitGlyphs(false);
    }
    else if (player->GetSkillValue(SKILL_RIDING) < 150)
    {
        // The level-60 adventure path starts with fast ground riding only. Flying remains part of
        // normal Outland progression.
        player->SetSkill(SKILL_RIDING, 0, 150, 150);
    }

    // Give a playable baseline immediately. For raid-ready modes use secondChance=true so old
    // low-level equipment is replaced directly instead of depending on free bag slots to move it.
    // This was the reason an existing character could reach level 70 yet appear to receive no gear.
    if (g_AdventureStartBasicGear)
    {
        PlayerbotFactory::AutoGear(
            player,
            raidReady ? ITEM_QUALITY_RARE : ITEM_QUALITY_UNCOMMON,
            basicIlvl,
            false,
            raidReady,
            raidReady);
    }

    // A raid-ready button should actually produce raid-ready gear immediately, even before the
    // player has chosen an EraTalents spec. Once enough era talent points are spent, the normal
    // spec-aware pass below runs again and replaces this fallback set for the chosen role.
    if (raidReady && g_AdventureStartAutoGear)
    {
        PlayerbotFactory::AutoGear(
            player,
            ITEM_QUALITY_EPIC,
            finalIlvl,
            false,
            true,
            true);
    }

    uint32 const targetCopper = startingGold * COPPER_PER_GOLD;
    uint32 const currentCopper = player->GetMoney();
    if (currentCopper < targetCopper)
        player->ModifyMoney(static_cast<int32>(targetCopper - currentCopper));

    AdventureProgressionStore::MarkStarterInitialized(player, static_cast<uint8>(profile));

    LOG_INFO(
        "server.loading",
        "[AdventureStart] Starter kit granted to {} (profile={}, gold={}g, bags={}, basicGear={}, basicIlvl={}, immediateRaidIlvl={})",
        player->GetName(),
        AdventureStartControl::ProfileName(profile),
        startingGold,
        wotlkRaidReady ? "24-slot Portable Holes" : "factory",
        g_AdventureStartBasicGear ? 1 : 0,
        basicIlvl,
        raidReady && g_AdventureStartAutoGear ? finalIlvl : 0);
    return true;
}

bool TryGiveSpecStarterGear(Player* player)
{
    if (player && (!player->IsInWorld() || player->IsBeingTeleportedFar()))
        return false;
    if (!player || !g_AdventureStartStarterKit || !g_AdventureStartAutoGear)
        return true;
    if (!EraPolicy::ItemProvenanceReady())
    {
        LOG_ERROR(
            "server.loading",
            "[AdventureStart] Spec-aware starter gear for {} refused: ERA-07 item provenance unavailable ({}).",
            player->GetName(),
            EraPolicy::ItemProvenanceError());
        return false;
    }

    uint32 const guid = player->GetGUID().GetCounter();
    AdventureProgressionStore::State state = AdventureProgressionStore::LoadOrCreate(guid);

    if (state.starterGearGranted)
        return true;
    if (!state.starterInitialized)
        return false;

    uint32 const spent = SpentTalentPoints(player);
    if (spent < g_AdventureStartGearMinTalentPoints)
        return false;

    AdventureStartProfile const profile = StoredProfile(state.starterProfile);
    uint32 const targetIlvl = FinalItemLevel(profile);
    uint8 const specTab = AiFactory::GetPlayerSpecTab(player);

    // Adventure mode gets late-Vanilla raid epics. TBC raid-ready gets a pre-Kara ilvl-115 set.
    // WotLK raid-ready gets ilvl-200 epics, positioning Naxx as the first meaningful Wrath raid.
    // Raid-ready refreshes replace the fallback set directly so a full inventory cannot block it.
    PlayerbotFactory::AutoGear(
        player,
        ITEM_QUALITY_EPIC,
        targetIlvl,
        false,
        IsRaidReady(profile),
        IsRaidReady(profile));

    AdventureProgressionStore::MarkStarterGearGranted(player, specTab);

    LOG_INFO(
        "server.loading",
        "[AdventureStart] Spec-aware epic starter gear granted to {} (profile={}, specTab={}, spentTalents={}, targetIlvl={})",
        player->GetName(),
        AdventureStartControl::ProfileName(profile),
        specTab,
        spent,
        targetIlvl);
    return true;
}
}
