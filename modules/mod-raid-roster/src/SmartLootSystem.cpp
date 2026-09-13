#include "SmartLootSystem.h"

#include "AiFactory.h"
#include "Chat.h"
#include "Creature.h"
#include "Group.h"
#include "Item.h"
#include "ItemTemplate.h"
#include "KillRewarder.h"
#include "LootMgr.h"
#include "Map.h"
#include "ObjectMgr.h"
#include "Player.h"
#include "Playerbots.h"
#include "RaidRosterConfig.h"
#include "RandomItemMgr.h"
#include "RandomPlayerbotMgr.h"
#include "RBAC.h"
#include "ScriptMgr.h"
#include "SmartLootStore.h"
#include "StatsWeightCalculator.h"
#include "WorldSession.h"

#include <algorithm>
#include <chrono>
#include <mutex>
#include <unordered_map>
#include <vector>

using namespace Acore::ChatCommands;

namespace
{
struct RecentBoss
{
    uint32 mapId = 0;
    uint32 bossEntry = 0;
    ObjectGuid bossGuid;
    std::chrono::steady_clock::time_point when;
};

std::mutex g_recentMutex;
std::unordered_map<uint32, RecentBoss> g_recentBoss;

bool IsPlayerbot(Player* player)
{
    return !player || sRandomPlayerbotMgr.IsRandomBot(player)
        || sRandomPlayerbotMgr.IsAddclassBot(player)
        || sPlayerbotsMgr.GetPlayerbotAI(player) != nullptr;
}

std::vector<uint8> CandidateSlots(ItemTemplate const* proto)
{
    if (!proto)
        return {};

    switch (proto->InventoryType)
    {
        case INVTYPE_HEAD: return {EQUIPMENT_SLOT_HEAD};
        case INVTYPE_NECK: return {EQUIPMENT_SLOT_NECK};
        case INVTYPE_SHOULDERS: return {EQUIPMENT_SLOT_SHOULDERS};
        case INVTYPE_CHEST:
        case INVTYPE_ROBE: return {EQUIPMENT_SLOT_CHEST};
        case INVTYPE_WAIST: return {EQUIPMENT_SLOT_WAIST};
        case INVTYPE_LEGS: return {EQUIPMENT_SLOT_LEGS};
        case INVTYPE_FEET: return {EQUIPMENT_SLOT_FEET};
        case INVTYPE_WRISTS: return {EQUIPMENT_SLOT_WRISTS};
        case INVTYPE_HANDS: return {EQUIPMENT_SLOT_HANDS};
        case INVTYPE_FINGER: return {EQUIPMENT_SLOT_FINGER1, EQUIPMENT_SLOT_FINGER2};
        case INVTYPE_TRINKET: return {EQUIPMENT_SLOT_TRINKET1, EQUIPMENT_SLOT_TRINKET2};
        case INVTYPE_CLOAK: return {EQUIPMENT_SLOT_BACK};
        case INVTYPE_WEAPON: return {EQUIPMENT_SLOT_MAINHAND, EQUIPMENT_SLOT_OFFHAND};
        case INVTYPE_2HWEAPON:
        case INVTYPE_WEAPONMAINHAND: return {EQUIPMENT_SLOT_MAINHAND};
        case INVTYPE_WEAPONOFFHAND:
        case INVTYPE_SHIELD:
        case INVTYPE_HOLDABLE: return {EQUIPMENT_SLOT_OFFHAND};
        case INVTYPE_RANGED:
        case INVTYPE_THROWN:
        case INVTYPE_RANGEDRIGHT:
        case INVTYPE_RELIC: return {EQUIPMENT_SLOT_RANGED};
        default: return {};
    }
}

bool SpecCanUse(Player* player, ItemTemplate const* proto)
{
    if (!player || !proto)
        return false;

    uint8 const specTab = AiFactory::GetPlayerSpecTab(player);
    if (proto->Class == ITEM_CLASS_WEAPON)
        return sRandomItemMgr.CanEquipWeapon(proto, player->getClass())
            && sRandomItemMgr.ShouldEquipWeaponForSpec(proto, player->getClass(), specTab);

    if (proto->Class == ITEM_CLASS_ARMOR)
        return sRandomItemMgr.CanEquipArmor(proto, player->getClass(), player->GetLevel())
            && sRandomItemMgr.ShouldEquipArmorForSpec(proto, player->getClass(), specTab);

    // TBC/WotLK armor tokens are represented as epic misc/junk and use AllowableClass.
    if (proto->Class == ITEM_CLASS_MISC && proto->SubClass == ITEM_SUBCLASS_JUNK && proto->Quality == ITEM_QUALITY_EPIC)
    {
        uint32 const classMask = 1u << (player->getClass() - 1);
        return (proto->AllowableClass & classMask) != 0;
    }

    return false;
}

bool IsMeaningfulUpgrade(Player* player, Item* item)
{
    if (!player || !item)
        return false;

    ItemTemplate const* proto = item->GetTemplate();
    if (!proto || !SpecCanUse(player, proto))
        return false;

    if (proto->Class == ITEM_CLASS_MISC && proto->SubClass == ITEM_SUBCLASS_JUNK && proto->Quality == ITEM_QUALITY_EPIC)
        return true;

    std::vector<uint8> const slots = CandidateSlots(proto);
    if (slots.empty())
        return false;

    StatsWeightCalculator calc(player);
    calc.SetPvpSpec(false);
    float bestImprovement = -1000000.0f;

    for (uint8 slot : slots)
    {
        float const newScore = calc.CalculateItem(item->GetEntry(), 0, slot);
        if (newScore <= 0.0f)
            continue;

        Item* equipped = player->GetItemByPos(INVENTORY_SLOT_BAG_0, slot);
        if (!equipped)
            return true;

        float const oldScore = calc.CalculateItem(equipped->GetEntry(), 0, slot);
        float const threshold = oldScore <= 0.0f ? oldScore : oldScore * 1.03f;
        bestImprovement = std::max(bestImprovement, newScore - threshold);
    }

    return bestImprovement > 0.0f;
}

void RecordBoss(Player* player, Creature* boss)
{
    if (!g_BadLuckProtectionEnable || !player || !boss || IsPlayerbot(player))
        return;

    Map* map = boss->GetMap();
    if (!map || !(map->IsDungeon() || map->IsRaid()))
        return;

    uint32 const guid = player->GetGUID().GetCounter();
    uint16 const streak = SmartLootStore::IncrementDryStreak(guid, map->GetId(), boss->GetEntry());

    {
        std::lock_guard<std::mutex> lock(g_recentMutex);
        g_recentBoss[guid] = {map->GetId(), boss->GetEntry(), boss->GetGUID(), std::chrono::steady_clock::now()};
    }

    if (streak >= 3 && player->GetSession())
    {
        ChatHandler(player->GetSession()).PSendSysMessage(
            "Bad-luck protection: {} dry credited kill(s) on {}. This streak is being tracked for protected loot.",
            uint32(streak), boss->GetName());
    }
}

void MaybeResetRecentBoss(Player* player, Item* item, ObjectGuid lootSourceGuid)
{
    if (!g_BadLuckProtectionEnable || !player || !item || IsPlayerbot(player) || lootSourceGuid.IsEmpty())
        return;

    RecentBoss recent;
    {
        std::lock_guard<std::mutex> lock(g_recentMutex);
        auto itr = g_recentBoss.find(player->GetGUID().GetCounter());
        if (itr == g_recentBoss.end())
            return;
        recent = itr->second;
    }

    auto const age = std::chrono::duration_cast<std::chrono::seconds>(
        std::chrono::steady_clock::now() - recent.when).count();
    if (age < 0 || static_cast<uint32>(age) > g_BadLuckUpgradeWindowSeconds || player->GetMapId() != recent.mapId)
        return;

    // Require the loot object's source GUID to be the exact defeated boss. Trash, chests and
    // unrelated containers on the same map must never erase a boss dry streak.
    if (lootSourceGuid != recent.bossGuid)
        return;

    if (!IsMeaningfulUpgrade(player, item))
        return;

    SmartLootStore::ResetDryStreak(player->GetGUID().GetCounter(), recent.mapId, recent.bossEntry);
    {
        std::lock_guard<std::mutex> lock(g_recentMutex);
        g_recentBoss.erase(player->GetGUID().GetCounter());
    }

    if (player->GetSession())
    {
        ChatHandler(player->GetSession()).PSendSysMessage(
            "Bad-luck protection: {} counted as a meaningful main-spec win from that boss; its dry streak was reset.",
            item->GetTemplate() ? item->GetTemplate()->Name1 : "your item");
    }
}

class SmartLootPlayerScript : public PlayerScript
{
public:
    SmartLootPlayerScript() : PlayerScript("SmartLootPlayerScript") { }

    void OnPlayerRewardKillRewarder(Player* player, KillRewarder* rewarder, bool /*isDungeon*/, float& /*rate*/) override
    {
        if (!g_BadLuckProtectionEnable || !player || !rewarder || IsPlayerbot(player))
            return;

        Unit* victim = rewarder->GetVictim();
        Creature* boss = victim ? victim->ToCreature() : nullptr;
        if (!boss || !boss->IsDungeonBoss())
            return;

        // KillRewarder passes isDungeon=false for an ungrouped killer even when that character is
        // physically inside an instance. The boss/map are the authoritative signal, so using the
        // hook boolean would silently skip solo/cleanup kills. RecordBoss validates the actual map.
        RecordBoss(player, boss);
    }

    void OnPlayerGroupRollRewardItem(Player* player, Item* item, uint32 /*count*/, RollVote /*voteType*/, Roll* roll) override
    {
        ObjectGuid sourceGuid;
        if (roll)
            if (Loot* loot = roll->getLoot())
                sourceGuid = loot->sourceWorldObjectGUID;
        MaybeResetRecentBoss(player, item, sourceGuid);
    }

    void OnPlayerLootItem(Player* player, Item* item, uint32 /*count*/, ObjectGuid lootguid) override
    {
        MaybeResetRecentBoss(player, item, lootguid);
    }

    void OnPlayerLogout(Player* player) override
    {
        if (!player)
            return;
        std::lock_guard<std::mutex> lock(g_recentMutex);
        g_recentBoss.erase(player->GetGUID().GetCounter());
    }
};

class SmartLootCommand : public CommandScript
{
public:
    SmartLootCommand() : CommandScript("SmartLootCommand") { }

    ChatCommandTable GetCommands() const override
    {
        static ChatCommandTable personal = {
            { "status", HandlePersonalStatus, SEC_PLAYER, Console::No },
        };
        static ChatCommandTable sub = {
            { "status", HandleStatus, SEC_PLAYER, Console::No },
            { "personal", personal },
        };
        static ChatCommandTable root = { { "lootmode", sub } };
        return root;
    }

    static bool HandleStatus(ChatHandler* handler)
    {
        Player* player = handler && handler->GetSession() ? handler->GetSession()->GetPlayer() : nullptr;
        if (!player)
            return false;

        handler->PSendSysMessage(
            "Smart Loot: {}. Bot upgrades Need={}, useful non-upgrades Greed={}.",
            g_SmartLootEnable ? "enabled" : "disabled",
            g_SmartLootBotNeedUpgrades ? "yes" : "no",
            g_SmartLootBotGreedUseful ? "yes" : "no");

        std::vector<BadLuckRow> rows = SmartLootStore::LoadDryStreaks(player->GetGUID().GetCounter());
        if (rows.empty())
        {
            handler->SendSysMessage("Bad-luck protection: no active dry boss streaks.");
            return true;
        }

        handler->SendSysMessage("Bad-luck protection streaks:");
        for (BadLuckRow const& row : rows)
        {
            CreatureTemplate const* creature = sObjectMgr->GetCreatureTemplate(row.bossEntry);
            handler->PSendSysMessage(
                "  {} (map {}, entry {}): {} dry kill(s)",
                creature ? creature->Name : "Unknown boss",
                row.mapId,
                row.bossEntry,
                uint32(row.dryKills));
        }
        return true;
    }

    static bool HandlePersonalStatus(ChatHandler* handler)
    {
        Player* player = handler && handler->GetSession() ? handler->GetSession()->GetPlayer() : nullptr;
        if (!player)
            return false;

        bool const requested = SmartLootStore::PersonalLootEnabled(player->GetGUID().GetCounter());
        handler->PSendSysMessage(
            "Personal Loot preference: {}. The replacement-loot engine is not enabled yet, so normal group loot remains authoritative.",
            requested ? "requested" : "off");
        return true;
    }
};
}

void AddSmartLootScripts()
{
    new SmartLootPlayerScript();
    new SmartLootCommand();
}
