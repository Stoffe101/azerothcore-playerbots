#include "TitanRuneSystem.h"

#include "Creature.h"
#include "DatabaseEnv.h"
#include "Field.h"
#include "GameObject.h"
#include "Group.h"
#include "ItemTemplate.h"
#include "Log.h"
#include "LootMgr.h"
#include "Map.h"
#include "ObjectMgr.h"
#include "Player.h"
#include "Random.h"
#include "ScriptMgr.h"

#include <algorithm>
#include <array>
#include <cctype>
#include <string>
#include <unordered_map>
#include <vector>

namespace
{
enum LootPool : uint8
{
    POOL_NONE = 0,
    POOL_ALPHA_GEAR = 1,
    POOL_ALPHA_TOKEN = 2,
    POOL_BETA_GEAR = 3,
    POOL_BETA_TOKEN = 4,
    POOL_MAX = 5
};

using SourcePools = std::array<std::vector<uint32>, POOL_MAX>;
std::unordered_map<std::string, SourcePools> g_protocolLoot;

std::string NormalizeName(std::string value)
{
    std::transform(value.begin(), value.end(), value.begin(), [](unsigned char c)
    {
        return static_cast<char>(std::tolower(c));
    });
    return value;
}

bool IsFrozenHalls(uint32 mapId)
{
    return mapId == 632 || mapId == 658 || mapId == 668;
}

void LoadProtocolLoot()
{
    g_protocolLoot.clear();

    QueryResult result = WorldDatabase.Query(
        "SELECT source_name, pool, item_entry FROM mod_titan_rune_boss_loot ORDER BY source_name, pool, item_entry");
    if (!result)
    {
        LOG_WARN("server.loading", "[TitanRune] No protocol boss-loot rows loaded; Alpha/Beta raid-loot injection is disabled.");
        return;
    }

    uint32 loaded = 0;
    do
    {
        Field* fields = result->Fetch();
        std::string source = NormalizeName(fields[0].Get<std::string>());
        uint8 pool = fields[1].Get<uint8>();
        uint32 itemEntry = fields[2].Get<uint32>();
        if (source.empty() || pool <= POOL_NONE || pool >= POOL_MAX)
            continue;
        if (!sObjectMgr->GetItemTemplate(itemEntry))
        {
            LOG_WARN("server.loading", "[TitanRune] Boss-loot row for '{}' references missing item {}.", source, itemEntry);
            continue;
        }

        g_protocolLoot[source][pool].push_back(itemEntry);
        ++loaded;
    } while (result->NextRow());

    LOG_INFO("server.loading", "[TitanRune] Loaded {} resolved Alpha/Beta boss-loot entries for {} encounter sources.",
        loaded, g_protocolLoot.size());
}

std::string SourceName(Player* lootOwner, Loot* loot)
{
    if (!lootOwner || !loot || !lootOwner->GetMap())
        return {};

    if (loot->sourceGameObject && loot->sourceGameObject->GetGOInfo())
        return NormalizeName(loot->sourceGameObject->GetGOInfo()->name);

    ObjectGuid guid = loot->sourceWorldObjectGUID;
    if (!guid)
        return {};

    if (guid.IsCreatureOrVehicle())
    {
        if (Creature* creature = lootOwner->GetMap()->GetCreature(guid))
            return NormalizeName(creature->GetName());
    }
    else if (guid.IsGameObject())
    {
        if (GameObject* gameObject = lootOwner->GetMap()->GetGameObject(guid))
            if (gameObject->GetGOInfo())
                return NormalizeName(gameObject->GetGOInfo()->name);
    }

    return {};
}

bool IsBaselineEquipment(LootItem const& item)
{
    ItemTemplate const* proto = sObjectMgr->GetItemTemplate(item.itemid);
    if (!proto)
        return false;

    // Defense Protocol Beta/Gamma replace the dungeon's ordinary equippable Heroic drops while
    // preserving quest items, currencies, mounts, consumables and other non-equipment rewards.
    return proto->InventoryType != INVTYPE_NON_EQUIP &&
        (proto->Class == ITEM_CLASS_WEAPON || proto->Class == ITEM_CLASS_ARMOR);
}

bool VisibleToAnyEligibleLooter(LootItem const& item, Player* lootOwner, ObjectGuid sourceGuid)
{
    if (!lootOwner)
        return false;

    if (Group* group = lootOwner->GetGroup())
    {
        for (GroupReference* ref = group->GetFirstMember(); ref; ref = ref->next())
        {
            Player* member = ref->GetSource();
            if (member && item.AllowedForPlayer(member, sourceGuid))
                return true;
        }
        return false;
    }

    return item.AllowedForPlayer(lootOwner, sourceGuid);
}

void RebuildImmediateLootAccounting(Loot* loot, Player* lootOwner)
{
    if (!loot)
        return;

    loot->unlootedCount = 0;
    for (uint32 i = 0; i < loot->items.size(); ++i)
    {
        LootItem& item = loot->items[i];
        item.itemIndex = i;

        ItemTemplate const* proto = sObjectMgr->GetItemTemplate(item.itemid);
        if (!proto || item.is_looted || item.freeforall || !item.conditions.empty() ||
            proto->HasFlag(ITEM_FLAG_MULTI_DROP))
            continue;

        if (VisibleToAnyEligibleLooter(item, lootOwner, loot->sourceWorldObjectGUID))
            ++loot->unlootedCount;
    }
}

void ReplaceBaselineHeroicEquipment(Loot* loot, Player* lootOwner)
{
    if (!loot)
        return;

    loot->items.erase(std::remove_if(loot->items.begin(), loot->items.end(), [](LootItem const& item)
    {
        return IsBaselineEquipment(item);
    }), loot->items.end());

    RebuildImmediateLootAccounting(loot, lootOwner);
}

bool HasItem(Loot const* loot, uint32 itemEntry)
{
    if (!loot)
        return false;
    return std::any_of(loot->items.begin(), loot->items.end(), [itemEntry](LootItem const& item)
    {
        return item.itemid == itemEntry && !item.is_looted;
    });
}

void AddRandomFromPool(Loot* loot, std::vector<uint32> const& pool, uint16 lootMode, char const* label)
{
    if (!loot || pool.empty())
        return;

    std::vector<uint32> candidates;
    candidates.reserve(pool.size());
    for (uint32 itemEntry : pool)
        if (!HasItem(loot, itemEntry))
            candidates.push_back(itemEntry);

    if (candidates.empty())
        return;

    if (loot->items.size() >= MAX_NR_LOOT_ITEMS)
    {
        LOG_WARN("server.loading", "[TitanRune] Loot window is full; could not add {} protocol reward.", label);
        return;
    }

    uint32 itemEntry = candidates[urand(0, uint32(candidates.size() - 1))];
    LootStoreItem protocolItem(itemEntry, 0, 100.0f, false, lootMode ? lootMode : LOOT_MODE_DEFAULT, 0, 1, 1);
    loot->AddItem(protocolItem);
}

class TitanRuneLootWorldScript final : public WorldScript
{
public:
    TitanRuneLootWorldScript() : WorldScript("TitanRuneLootWorldScript") { }

    void OnStartup() override
    {
        LoadProtocolLoot();
    }
};

class TitanRuneLootGlobalScript final : public GlobalScript
{
public:
    TitanRuneLootGlobalScript() : GlobalScript("TitanRuneLootGlobalScript") { }

    void OnAfterLootTemplateProcess(Loot* loot, LootTemplate const* /*tab*/, LootStore const& /*store*/,
        Player* lootOwner, bool /*personal*/, bool /*noEmptyError*/, uint16 lootMode) override
    {
        if (!loot || !lootOwner || !lootOwner->IsInWorld())
            return;

        Map* map = lootOwner->GetMap();
        TitanRuneMode mode = TitanRune::GetActiveMode(map);
        if (mode == TitanRuneMode::Off || !map || IsFrozenHalls(map->GetId()))
            return;

        std::string source = SourceName(lootOwner, loot);
        if (source.empty())
            return;

        auto itr = g_protocolLoot.find(source);
        if (itr == g_protocolLoot.end())
            return;

        SourcePools const& pools = itr->second;

        // Alpha keeps normal Heroic loot and adds one Naxx/Sarth/Malygos-era reward, with a Tier 7
        // token on mapped final bosses. Beta and Gamma retain those Alpha additions, replace the
        // ordinary Heroic equipment with Ulduar-10-era gear, and add a Tier 8 token on mapped
        // final bosses. Currency rewards are handled by the death/reward scripts.
        if ((mode == TitanRuneMode::Beta || mode == TitanRuneMode::Gamma) && !pools[POOL_BETA_GEAR].empty())
            ReplaceBaselineHeroicEquipment(loot, lootOwner);

        AddRandomFromPool(loot, pools[POOL_ALPHA_GEAR], lootMode, "Alpha gear");
        AddRandomFromPool(loot, pools[POOL_ALPHA_TOKEN], lootMode, "Alpha token");

        if (mode == TitanRuneMode::Beta || mode == TitanRuneMode::Gamma)
        {
            AddRandomFromPool(loot, pools[POOL_BETA_GEAR], lootMode, "Beta gear");
            AddRandomFromPool(loot, pools[POOL_BETA_TOKEN], lootMode, "Beta token");
        }
    }
};
}

void AddTitanRuneLootScripts()
{
    new TitanRuneLootWorldScript();
    new TitanRuneLootGlobalScript();
}
