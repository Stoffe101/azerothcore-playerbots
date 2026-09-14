#include "TitanRuneSystem.h"

#include "Chat.h"
#include "CommandScript.h"
#include "Creature.h"
#include "DatabaseEnv.h"
#include "Field.h"
#include "Group.h"
#include "ItemTemplate.h"
#include "Log.h"
#include "Map.h"
#include "MapMgr.h"
#include "ObjectAccessor.h"
#include "ObjectMgr.h"
#include "Player.h"
#include "RBAC.h"
#include "ScriptMgr.h"
#include "ScriptedGossip.h"
#include "WorldSession.h"

#include <algorithm>
#include <array>
#include <cmath>
#include <cstdint>
#include <mutex>
#include <string>
#include <unordered_map>
#include <vector>

using namespace Acore::ChatCommands;

namespace
{
constexpr uint32 DALARAN_MAP = 571;
constexpr float VENDOR_Z = 660.94f;
constexpr uint8 VENDOR_SIDEREAL = 1;
constexpr uint8 VENDOR_SCOURGESTONE = 2;
constexpr uint32 PAGE_SIZE = 10;

struct VendorItem
{
    uint32 itemEntry = 0;
    uint32 cost = 0;
};

struct ScaledCreature
{
    uint32 baseMaxHealth = 0;
    uint32 targetMaxHealth = 0;
    TitanRuneMode mode = TitanRuneMode::Off;
};

std::mutex g_stateMutex;
std::unordered_map<uint64, TitanRuneMode> g_instanceModes;
std::unordered_map<uint64, ScaledCreature> g_scaledCreatures;
std::array<std::vector<VendorItem>, 3> g_vendorItems;

uint64 InstanceKey(Map const* map)
{
    if (!map)
        return 0;
    return (uint64(map->GetId()) << 32) | uint64(map->GetInstanceId());
}

uint64 CreatureScaleKey(Creature const* creature)
{
    if (!creature || !creature->GetMap())
        return 0;
    return (uint64(creature->GetMap()->GetInstanceId()) << 32) | uint64(creature->GetGUID().GetCounter());
}

bool IsShadowMap(uint32 mapId)
{
    return mapId == 601 || mapId == 619; // Azjol-Nerub / Ahn'kahet
}

bool IsBloodMap(uint32 mapId)
{
    return mapId == 600 || mapId == 604; // Drak'Tharon / Gundrak
}

bool IsTitanMap(uint32 mapId)
{
    return mapId == 599 || mapId == 602; // Halls of Stone / Halls of Lightning
}

bool IsFrozenHalls(uint32 mapId)
{
    return mapId == 632 || mapId == 658 || mapId == 668; // FoS / PoS / HoR
}

float HealthMultiplier(uint32 mapId, TitanRuneMode mode)
{
    // In Classic Phase 4, the Frozen Halls are intentionally normal Heroic difficulty while
    // participating in the Gamma reward track. Never apply protocol stat scaling there.
    if (mode == TitanRuneMode::Gamma && IsFrozenHalls(mapId))
        return 1.0f;

    switch (mode)
    {
        // Final post-hotfix Alpha tuning. Halls of Stone/Lightning use the special Titan family.
        case TitanRuneMode::Alpha: return IsTitanMap(mapId) ? 2.18f : 1.50f;
        case TitanRuneMode::Beta:
            if (IsTitanMap(mapId))  return 6.80f;
            if (IsBloodMap(mapId))  return 2.80f;
            if (IsShadowMap(mapId)) return 2.50f;
            return 2.20f;
        case TitanRuneMode::Gamma:
            if (IsTitanMap(mapId))  return 9.80f;
            if (IsBloodMap(mapId))  return 4.05f;
            if (IsShadowMap(mapId)) return 3.60f;
            return 3.15f;
        default:
            return 1.0f;
    }
}

float DamageMultiplier(uint32 mapId, TitanRuneMode mode)
{
    if (mode == TitanRuneMode::Gamma && IsFrozenHalls(mapId))
        return 1.0f;

    switch (mode)
    {
        case TitanRuneMode::Alpha: return IsTitanMap(mapId) ? 1.05f : 1.17f;
        case TitanRuneMode::Beta:  return 1.40f;
        case TitanRuneMode::Gamma: return 1.70f;
        default: return 1.0f;
    }
}

uint32 FinalBossEntry(uint32 mapId)
{
    switch (mapId)
    {
        case 574: return 23954; // Ingvar the Plunderer
        case 575: return 26861; // King Ymiron
        case 576: return 26723; // Keristrasza
        case 578: return 27656; // Ley-Guardian Eregos
        case 595: return 26533; // Mal'Ganis
        case 599: return 27978; // Sjonnir the Ironshaper
        case 600: return 26632; // The Prophet Tharon'ja
        case 601: return 29120; // Anub'arak
        case 602: return 28923; // Loken
        case 604: return 29306; // Gal'darah
        case 608: return 31134; // Cyanigosa
        case 619: return 29311; // Herald Volazj
        case 650: return 35451; // The Black Knight
        default: return 0;
    }
}

bool IsEligibleHeroicMap(Map const* map)
{
    return map && map->IsDungeon() && map->GetDifficulty() == DUNGEON_DIFFICULTY_HEROIC;
}

void Notify(Player* player, std::string const& message)
{
    if (!player || !player->GetSession())
        return;
    ChatHandler handler(player->GetSession());
    handler.PSendSysMessage("[Titan Rune] {}", message);
}

void BroadcastMode(Map* map, TitanRuneMode mode)
{
    if (!map)
        return;

    std::string message;
    if (mode == TitanRuneMode::Gamma && IsFrozenHalls(map->GetId()))
        message = "Defense Protocol Gamma reward track active. Frozen Halls remain normal Heroic difficulty; no Titan Rune stat scaling or affix is applied.";
    else
        message = std::string("Defense Protocol ") + TitanRune::ModeName(mode) +
            " active. Protocol health/damage tuning is applied to hostile dungeon enemies; Beta/Gamma currency rewards are enabled.";

    Map::PlayerList const& players = map->GetPlayers();
    for (Map::PlayerList::const_iterator itr = players.begin(); itr != players.end(); ++itr)
    {
        Player* player = itr->GetSource();
        if (!player || !player->GetSession() || player->GetSession()->IsBot())
            continue;
        Notify(player, message);
    }
}

void LoadVendorItems()
{
    for (auto& items : g_vendorItems)
        items.clear();

    QueryResult result = WorldDatabase.Query(
        "SELECT vendor, item_entry, cost FROM mod_titan_rune_vendor_items ORDER BY vendor, sort_order, item_entry");
    if (!result)
    {
        LOG_WARN("server.loading", "[TitanRune] No vendor catalog rows loaded.");
        return;
    }

    do
    {
        Field* fields = result->Fetch();
        uint8 vendor = fields[0].Get<uint8>();
        if (vendor >= g_vendorItems.size())
            continue;
        uint32 entry = fields[1].Get<uint32>();
        if (!sObjectMgr->GetItemTemplate(entry))
            continue;
        g_vendorItems[vendor].push_back({entry, fields[2].Get<uint32>()});
    } while (result->NextRow());

    LOG_INFO("server.loading", "[TitanRune] Loaded {} Sidereal and {} Scourgestone vendor rewards.",
        g_vendorItems[VENDOR_SIDEREAL].size(), g_vendorItems[VENDOR_SCOURGESTONE].size());
}

bool SpawnPersistentNpc(uint32 entry, float x, float y, float z, float o)
{
    QueryResult existing = WorldDatabase.Query(
        "SELECT spawn_guid FROM mod_titan_rune_vendor_spawns WHERE entry = {} LIMIT 1", entry);
    if (existing)
        return true;

    if (!sObjectMgr->GetCreatureTemplate(entry))
    {
        LOG_ERROR("server.loading", "[TitanRune] Cannot spawn entry {}: creature_template is missing.", entry);
        return false;
    }

    Map* map = sMapMgr->CreateBaseMap(DALARAN_MAP);
    if (!map)
        return false;

    Creature* creature = new Creature();
    if (!creature->Create(map->GenerateLowGuid<HighGuid::Unit>(), map, 1, entry, 0, x, y, z, o))
    {
        delete creature;
        return false;
    }

    creature->SaveToDB(DALARAN_MAP, uint8(1 << map->GetSpawnMode()), 1);
    ObjectGuid::LowType spawnId = creature->GetSpawnId();
    creature->CleanupsBeforeDelete();
    delete creature;

    creature = new Creature();
    if (!creature->LoadCreatureFromDB(spawnId, map, true, true))
    {
        delete creature;
        return false;
    }

    sObjectMgr->AddCreatureToGrid(spawnId, sObjectMgr->GetCreatureData(spawnId));
    WorldDatabase.DirectExecute(
        "REPLACE INTO mod_titan_rune_vendor_spawns (entry, spawn_guid) VALUES ({}, {})", entry, uint32(spawnId));
    LOG_INFO("server.loading", "[TitanRune] Spawned Dalaran NPC entry={} spawn={}", entry, uint32(spawnId));
    return true;
}

void EnsureDalaranNpcs()
{
    SpawnPersistentNpc(TitanRune::COORDINATOR_ENTRY,          5808.0f, 590.5f, VENDOR_Z, 4.70f);
    SpawnPersistentNpc(TitanRune::SIDEREAL_VENDOR_ENTRY,      5811.0f, 590.5f, VENDOR_Z, 4.70f);
    SpawnPersistentNpc(TitanRune::SCOURGESTONE_VENDOR_ENTRY,  5814.0f, 590.5f, VENDOR_Z, 4.70f);
}

uint32 CurrencyForVendor(uint8 vendor)
{
    return vendor == VENDOR_SIDEREAL ? TitanRune::SIDEREAL_ESSENCE_ITEM : TitanRune::SCOURGESTONE_ITEM;
}

char const* CurrencyName(uint8 vendor)
{
    return vendor == VENDOR_SIDEREAL ? "Sidereal Essence" : "Defiler's Scourgestone";
}

void ShowVendorPage(Player* player, Creature* creature, uint8 vendor, uint32 page)
{
    if (!player || !creature || vendor >= g_vendorItems.size())
        return;

    ClearGossipMenuFor(player);
    std::vector<VendorItem> const& items = g_vendorItems[vendor];
    uint32 currency = CurrencyForVendor(vendor);
    uint32 balance = player->GetItemCount(currency, false);

    std::string header = std::string("You have ") + std::to_string(balance) + " " + CurrencyName(vendor) + ".";
    AddGossipItemFor(player, GOSSIP_ICON_CHAT, header, GOSSIP_SENDER_MAIN, 90000);

    uint32 begin = page * PAGE_SIZE;
    if (begin >= items.size() && page > 0)
    {
        page = 0;
        begin = 0;
    }
    uint32 end = std::min<uint32>(begin + PAGE_SIZE, items.size());
    for (uint32 i = begin; i < end; ++i)
    {
        ItemTemplate const* proto = sObjectMgr->GetItemTemplate(items[i].itemEntry);
        if (!proto)
            continue;
        std::string label = std::to_string(items[i].cost) + " " + CurrencyName(vendor) + " - " + proto->Name1;
        AddGossipItemFor(player, GOSSIP_ICON_VENDOR, label, GOSSIP_SENDER_MAIN, 10000 + uint32(vendor) * 1000 + i);
    }

    if (page > 0)
        AddGossipItemFor(player, GOSSIP_ICON_CHAT, "< Previous page", GOSSIP_SENDER_MAIN,
            20000 + uint32(vendor) * 1000 + (page - 1));
    if (end < items.size())
        AddGossipItemFor(player, GOSSIP_ICON_CHAT, "Next page >", GOSSIP_SENDER_MAIN,
            20000 + uint32(vendor) * 1000 + (page + 1));

    if (vendor == VENDOR_SCOURGESTONE && player->GetItemCount(TitanRune::SCOURGESTONE_ITEM, false) > 0)
        AddGossipItemFor(player, GOSSIP_ICON_MONEY_BAG, "Exchange 1 Scourgestone for 1 Sidereal Essence",
            GOSSIP_SENDER_MAIN, 30001);

    SendGossipMenuFor(player, player->GetGossipTextId(creature), creature->GetGUID());
}

bool BuyVendorItem(Player* player, uint8 vendor, uint32 index)
{
    if (!player || vendor >= g_vendorItems.size() || index >= g_vendorItems[vendor].size())
        return false;

    VendorItem const& offer = g_vendorItems[vendor][index];
    uint32 currency = CurrencyForVendor(vendor);
    if (player->GetItemCount(currency, false) < offer.cost)
    {
        Notify(player, std::string("You need ") + std::to_string(offer.cost) + " " + CurrencyName(vendor) + ".");
        return false;
    }

    if (!player->AddItem(offer.itemEntry, 1))
    {
        Notify(player, "The item could not be placed in your inventory. Make bag space and check unique-item restrictions.");
        return false;
    }

    player->DestroyItemCount(currency, offer.cost, true);
    ItemTemplate const* proto = sObjectMgr->GetItemTemplate(offer.itemEntry);
    Notify(player, std::string("Purchased ") + (proto ? proto->Name1 : "item") + ".");
    player->SaveToDB(false, false);
    return true;
}

bool RewardAlreadyGranted(uint32 instanceId, uint32 bossEntry, TitanRuneMode mode)
{
    QueryResult result = CharacterDatabase.Query(
        "SELECT 1 FROM mod_titan_rune_boss_rewards WHERE instance_id={} AND boss_entry={} AND mode={} LIMIT 1",
        instanceId, bossEntry, uint8(mode));
    return bool(result);
}

void MarkRewardGranted(uint32 instanceId, uint32 bossEntry, TitanRuneMode mode)
{
    CharacterDatabase.DirectExecute(
        "INSERT IGNORE INTO mod_titan_rune_boss_rewards (instance_id, boss_entry, mode) VALUES ({}, {}, {})",
        instanceId, bossEntry, uint8(mode));
}

void GrantCurrencyToHumans(Map* map, uint32 itemEntry, uint32 count, char const* reason)
{
    if (!map || !count)
        return;

    Map::PlayerList const& players = map->GetPlayers();
    for (Map::PlayerList::const_iterator itr = players.begin(); itr != players.end(); ++itr)
    {
        Player* player = itr->GetSource();
        if (!player || !player->GetSession() || player->GetSession()->IsBot())
            continue;
        if (player->AddItem(itemEntry, count))
        {
            ItemTemplate const* proto = sObjectMgr->GetItemTemplate(itemEntry);
            Notify(player, std::string(reason) + ": +" + std::to_string(count) + " " +
                (proto ? proto->Name1 : "Titan Rune currency"));
        }
        else
            Notify(player, "Titan Rune reward could not fit in your bags. Clear space before the next boss.");
    }
}

class TitanRuneWorldScript final : public WorldScript
{
public:
    TitanRuneWorldScript() : WorldScript("TitanRuneWorldScript") { }

    void OnStartup() override
    {
        LoadVendorItems();
        EnsureDalaranNpcs();
        LOG_INFO("server.loading", "[TitanRune] Defense Protocol Alpha/Beta/Gamma ready.");
    }
};

class TitanRunePlayerScript final : public PlayerScript
{
public:
    TitanRunePlayerScript() : PlayerScript("TitanRunePlayerScript") { }

    void OnPlayerLogin(Player* player) override
    {
        TitanRune::ActivateForPlayer(player);
    }

    void OnPlayerMapChanged(Player* player) override
    {
        TitanRune::ActivateForPlayer(player);
    }
};

class TitanRuneMapScript final : public AllMapScript
{
public:
    TitanRuneMapScript() : AllMapScript("TitanRuneMapScript") { }

    void OnDestroyMap(Map* map) override
    {
        if (!map || !map->GetInstanceId())
            return;

        uint64 const instanceKey = InstanceKey(map);
        uint32 const instanceId = map->GetInstanceId();
        std::lock_guard<std::mutex> lock(g_stateMutex);
        g_instanceModes.erase(instanceKey);

        for (auto itr = g_scaledCreatures.begin(); itr != g_scaledCreatures.end(); )
        {
            if (uint32(itr->first >> 32) == instanceId)
                itr = g_scaledCreatures.erase(itr);
            else
                ++itr;
        }
    }
};

class TitanRuneCreatureScript final : public AllCreatureScript
{
public:
    TitanRuneCreatureScript() : AllCreatureScript("TitanRuneCreatureScript") { }

    void OnAllCreatureUpdate(Creature* creature, uint32 /*diff*/) override
    {
        if (!creature || !creature->IsInWorld() || creature->IsControlledByPlayer() || !creature->IsHostileToPlayers())
            return;

        Map* map = creature->GetMap();
        TitanRuneMode mode = TitanRune::GetActiveMode(map);
        if (mode == TitanRuneMode::Off)
            return;

        float const multiplier = HealthMultiplier(map->GetId(), mode);
        if (multiplier == 1.0f)
            return;

        uint64 const key = CreatureScaleKey(creature);
        ScaledCreature state;
        bool inserted = false;
        {
            std::lock_guard<std::mutex> lock(g_stateMutex);
            auto itr = g_scaledCreatures.find(key);
            if (itr == g_scaledCreatures.end())
            {
                uint32 const baseMax = creature->GetMaxHealth();
                if (!baseMax)
                    return;
                uint64 const scaled64 = uint64(std::llround(double(baseMax) * multiplier));
                uint32 const targetMax = uint32(std::min<uint64>(scaled64, 0xFFFFFFFFull));
                state = {baseMax, targetMax, mode};
                g_scaledCreatures.emplace(key, state);
                inserted = true;
            }
            else
                state = itr->second;
        }

        if (inserted)
        {
            uint32 const oldMax = creature->GetMaxHealth();
            uint32 const oldHealth = creature->GetHealth();
            creature->SetMaxHealth(state.targetMaxHealth);
            if (oldHealth >= oldMax)
                creature->SetHealth(state.targetMaxHealth);
            else
                creature->SetHealth(std::max<uint32>(1, uint32((uint64(oldHealth) * state.targetMaxHealth) /
                    std::max<uint32>(1, oldMax))));
            return;
        }

        // Core respawns can restore stock max health on the same creature object. Reapply outside
        // combat without multiplying an already-scaled max-health value a second time.
        if (!creature->IsInCombat() && creature->GetMaxHealth() != state.targetMaxHealth &&
            creature->GetMaxHealth() <= uint32(double(state.baseMaxHealth) * 1.10))
        {
            creature->SetMaxHealth(state.targetMaxHealth);
            creature->SetFullHealth();
        }
    }
};

class TitanRuneDamageScript final : public UnitScript
{
public:
    TitanRuneDamageScript() : UnitScript("TitanRuneDamageScript") { }

    static TitanRuneMode AttackerMode(Unit* attacker)
    {
        if (!attacker || !attacker->IsCreature() || attacker->IsControlledByPlayer() || !attacker->IsHostileToPlayers())
            return TitanRuneMode::Off;
        return TitanRune::GetActiveMode(attacker->GetMap());
    }

    static float AttackerDamageMultiplier(Unit* attacker, TitanRuneMode mode)
    {
        return attacker && attacker->GetMap() ? DamageMultiplier(attacker->GetMapId(), mode) : 1.0f;
    }

    void ModifyMeleeDamage(Unit* /*target*/, Unit* attacker, uint32& damage) override
    {
        TitanRuneMode const mode = AttackerMode(attacker);
        if (mode != TitanRuneMode::Off)
            damage = uint32(std::min<double>(double(damage) * AttackerDamageMultiplier(attacker, mode), double(0xFFFFFFFFu)));
    }

    void ModifySpellDamageTaken(Unit* /*target*/, Unit* attacker, int32& damage, SpellInfo const* /*spellInfo*/) override
    {
        if (damage <= 0)
            return;
        TitanRuneMode const mode = AttackerMode(attacker);
        if (mode != TitanRuneMode::Off)
            damage = int32(std::min<double>(double(damage) * AttackerDamageMultiplier(attacker, mode), double(0x7FFFFFFF)));
    }

    void ModifyPeriodicDamageAurasTick(Unit* /*target*/, Unit* attacker, uint32& damage, SpellInfo const* /*spellInfo*/) override
    {
        TitanRuneMode const mode = AttackerMode(attacker);
        if (mode != TitanRuneMode::Off)
            damage = uint32(std::min<double>(double(damage) * AttackerDamageMultiplier(attacker, mode), double(0xFFFFFFFFu)));
    }

    void OnUnitDeath(Unit* unit, Unit* /*killer*/) override
    {
        Creature* boss = unit ? unit->ToCreature() : nullptr;
        if (!boss || !boss->IsDungeonBoss())
            return;

        Map* map = boss->GetMap();
        TitanRuneMode const mode = TitanRune::GetActiveMode(map);
        if (mode == TitanRuneMode::Off || !map)
            return;

        uint32 const instanceId = map->GetInstanceId();
        uint32 const bossEntry = boss->GetEntry();
        if (RewardAlreadyGranted(instanceId, bossEntry, mode))
            return;
        MarkRewardGranted(instanceId, bossEntry, mode);

        if (mode == TitanRuneMode::Gamma)
            GrantCurrencyToHumans(map, TitanRune::SCOURGESTONE_ITEM, 1, "Gamma boss defeated");

        if (mode == TitanRuneMode::Beta && bossEntry == FinalBossEntry(map->GetId()))
            GrantCurrencyToHumans(map, TitanRune::SIDEREAL_ESSENCE_ITEM, 1, "Beta dungeon completed");
    }
};

class npc_titan_rune_coordinator final : public CreatureScript
{
public:
    npc_titan_rune_coordinator() : CreatureScript("npc_titan_rune_coordinator") { }

    bool OnGossipHello(Player* player, Creature* creature) override
    {
        ClearGossipMenuFor(player);
        TitanRuneMode current = TitanRune::LoadSelectedMode(player);
        AddGossipItemFor(player, GOSSIP_ICON_CHAT,
            std::string("Current next-dungeon protocol: ") + TitanRune::ModeName(current), GOSSIP_SENDER_MAIN, 90000);
        AddGossipItemFor(player, GOSSIP_ICON_CHAT, "Normal Heroic (disable Titan Rune)", GOSSIP_SENDER_MAIN, 100);
        AddGossipItemFor(player, GOSSIP_ICON_CHAT,
            "Defense Protocol Alpha (final tuning; Titan-family dungeons scale differently)", GOSSIP_SENDER_MAIN, 101);
        AddGossipItemFor(player, GOSSIP_ICON_CHAT,
            "Defense Protocol Beta (+40% damage; health varies by rune family)", GOSSIP_SENDER_MAIN, 102);
        AddGossipItemFor(player, GOSSIP_ICON_CHAT,
            "Defense Protocol Gamma (+70% damage; family health; Frozen Halls reward-only)", GOSSIP_SENDER_MAIN, 103);
        SendGossipMenuFor(player, player->GetGossipTextId(creature), creature->GetGUID());
        return true;
    }

    bool OnGossipSelect(Player* player, Creature* creature, uint32 /*sender*/, uint32 action) override
    {
        if (action >= 100 && action <= 103)
        {
            TitanRuneMode mode = static_cast<TitanRuneMode>(action - 100);
            TitanRune::SaveSelectedMode(player, mode);
            Notify(player, std::string("Next eligible WotLK heroic set to ") + TitanRune::ModeName(mode) +
                ". The group leader's selection controls the instance.");
        }
        return OnGossipHello(player, creature);
    }
};

class npc_titan_sidereal_vendor final : public CreatureScript
{
public:
    npc_titan_sidereal_vendor() : CreatureScript("npc_titan_sidereal_vendor") { }

    bool OnGossipHello(Player* player, Creature* creature) override
    {
        ShowVendorPage(player, creature, VENDOR_SIDEREAL, 0);
        return true;
    }

    bool OnGossipSelect(Player* player, Creature* creature, uint32 /*sender*/, uint32 action) override
    {
        if (action >= 11000 && action < 12000)
            BuyVendorItem(player, VENDOR_SIDEREAL, action - 11000);
        else if (action >= 21000 && action < 22000)
            return (ShowVendorPage(player, creature, VENDOR_SIDEREAL, action - 21000), true);
        ShowVendorPage(player, creature, VENDOR_SIDEREAL, 0);
        return true;
    }
};

class npc_titan_scourgestone_vendor final : public CreatureScript
{
public:
    npc_titan_scourgestone_vendor() : CreatureScript("npc_titan_scourgestone_vendor") { }

    bool OnGossipHello(Player* player, Creature* creature) override
    {
        ShowVendorPage(player, creature, VENDOR_SCOURGESTONE, 0);
        return true;
    }

    bool OnGossipSelect(Player* player, Creature* creature, uint32 /*sender*/, uint32 action) override
    {
        if (action >= 12000 && action < 13000)
            BuyVendorItem(player, VENDOR_SCOURGESTONE, action - 12000);
        else if (action >= 22000 && action < 23000)
            return (ShowVendorPage(player, creature, VENDOR_SCOURGESTONE, action - 22000), true);
        else if (action == 30001)
        {
            if (player->GetItemCount(TitanRune::SCOURGESTONE_ITEM, false) >= 1 && player->AddItem(TitanRune::SIDEREAL_ESSENCE_ITEM, 1))
            {
                player->DestroyItemCount(TitanRune::SCOURGESTONE_ITEM, 1, true);
                Notify(player, "Exchanged 1 Defiler's Scourgestone for 1 Sidereal Essence.");
            }
            else
                Notify(player, "You need a Scourgestone and one free bag slot for the exchange.");
        }
        ShowVendorPage(player, creature, VENDOR_SCOURGESTONE, 0);
        return true;
    }
};

class TitanRuneCommandScript final : public CommandScript
{
public:
    TitanRuneCommandScript() : CommandScript("TitanRuneCommandScript") { }

    ChatCommandTable GetCommands() const override
    {
        static ChatCommandTable sub =
        {
            { "status", HandleStatus, SEC_PLAYER, Console::No },
            { "off",    HandleOff,    SEC_PLAYER, Console::No },
            { "alpha",  HandleAlpha,  SEC_PLAYER, Console::No },
            { "beta",   HandleBeta,   SEC_PLAYER, Console::No },
            { "gamma",  HandleGamma,  SEC_PLAYER, Console::No },
        };
        static ChatCommandTable root = { { "titan", sub } };
        return root;
    }

    static Player* GetPlayer(ChatHandler* handler)
    {
        return handler && handler->GetSession() ? handler->GetSession()->GetPlayer() : nullptr;
    }

    static bool Set(ChatHandler* handler, TitanRuneMode mode)
    {
        Player* player = GetPlayer(handler);
        if (!player)
            return true;
        TitanRune::SaveSelectedMode(player, mode);
        handler->PSendSysMessage("[Titan Rune] Next eligible heroic: {}. Group leader selection wins.", TitanRune::ModeName(mode));
        return true;
    }

    static bool HandleStatus(ChatHandler* handler)
    {
        Player* player = GetPlayer(handler);
        if (!player)
            return true;
        handler->PSendSysMessage("[Titan Rune] selected={} active={} map={} instance={}",
            TitanRune::ModeName(TitanRune::LoadSelectedMode(player)),
            TitanRune::ModeName(TitanRune::GetActiveMode(player->GetMap())),
            player->GetMapId(), player->GetInstanceId());
        return true;
    }
    static bool HandleOff(ChatHandler* handler)   { return Set(handler, TitanRuneMode::Off); }
    static bool HandleAlpha(ChatHandler* handler) { return Set(handler, TitanRuneMode::Alpha); }
    static bool HandleBeta(ChatHandler* handler)  { return Set(handler, TitanRuneMode::Beta); }
    static bool HandleGamma(ChatHandler* handler) { return Set(handler, TitanRuneMode::Gamma); }
};
}

namespace TitanRune
{
char const* ModeName(TitanRuneMode mode)
{
    switch (mode)
    {
        case TitanRuneMode::Alpha: return "Alpha";
        case TitanRuneMode::Beta: return "Beta";
        case TitanRuneMode::Gamma: return "Gamma";
        default: return "Off";
    }
}

TitanRuneMode LoadSelectedMode(Player* player)
{
    if (!player)
        return TitanRuneMode::Off;
    QueryResult result = CharacterDatabase.Query(
        "SELECT mode FROM mod_titan_rune_selection WHERE guid={} LIMIT 1", player->GetGUID().GetCounter());
    if (!result)
        return TitanRuneMode::Off;
    uint8 raw = result->Fetch()[0].Get<uint8>();
    if (raw > uint8(TitanRuneMode::Gamma))
        return TitanRuneMode::Off;
    return static_cast<TitanRuneMode>(raw);
}

void SaveSelectedMode(Player* player, TitanRuneMode mode)
{
    if (!player)
        return;
    CharacterDatabase.DirectExecute(
        "REPLACE INTO mod_titan_rune_selection (guid, mode) VALUES ({}, {})",
        player->GetGUID().GetCounter(), uint8(mode));
}

TitanRuneMode GetActiveMode(Map const* map)
{
    if (!IsEligibleHeroicMap(map))
        return TitanRuneMode::Off;
    std::lock_guard<std::mutex> lock(g_stateMutex);
    auto itr = g_instanceModes.find(InstanceKey(map));
    return itr == g_instanceModes.end() ? TitanRuneMode::Off : itr->second;
}

bool IsSupportedDungeon(uint32 mapId, TitanRuneMode mode)
{
    switch (mapId)
    {
        case 574: // Utgarde Keep
        case 575: // Utgarde Pinnacle
        case 576: // Nexus
        case 578: // Oculus
        case 595: // Culling of Stratholme
        case 599: // Halls of Stone
        case 600: // Drak'Tharon Keep
        case 601: // Azjol-Nerub
        case 602: // Halls of Lightning
        case 604: // Gundrak
        case 608: // Violet Hold
        case 619: // Ahn'kahet
            return mode != TitanRuneMode::Off;
        case 650: // Trial of the Champion was added to Beta/Gamma, not Alpha
            return mode == TitanRuneMode::Beta || mode == TitanRuneMode::Gamma;
        case 632: // Forge of Souls: Gamma rewards, normal Heroic difficulty
        case 658: // Pit of Saron: Gamma rewards, normal Heroic difficulty
        case 668: // Halls of Reflection: Gamma rewards, normal Heroic difficulty
            return mode == TitanRuneMode::Gamma;
        default:
            return false;
    }
}

void ActivateForPlayer(Player* player)
{
    if (!player || !player->IsInWorld())
        return;
    Map* map = player->GetMap();
    if (!IsEligibleHeroicMap(map))
        return;

    uint64 const key = InstanceKey(map);
    {
        std::lock_guard<std::mutex> lock(g_stateMutex);
        if (g_instanceModes.find(key) != g_instanceModes.end())
            return;
    }

    // Frozen Halls shipped in the Gamma phase with Scourgestone rewards active by default while
    // preserving ordinary Heroic health, damage and mechanics. Treat that as an instance property,
    // not as a mutation of anyone's persisted next-dungeon selection.
    TitanRuneMode selected = IsFrozenHalls(map->GetId()) ? TitanRuneMode::Gamma : TitanRuneMode::Off;
    bool hasRealLeader = false;

    if (!IsFrozenHalls(map->GetId()))
    {
        if (Group* group = player->GetGroup())
        {
            if (Player* leader = ObjectAccessor::FindPlayer(group->GetLeaderGUID()))
            {
                if (leader->GetSession() && !leader->GetSession()->IsBot())
                {
                    hasRealLeader = true;
                    selected = LoadSelectedMode(leader);
                }
            }
        }

        // A real group leader is authoritative even when their explicit selection is Off. Only
        // groups without a real online leader fall back to the entering human's personal setting.
        if (!hasRealLeader)
            selected = LoadSelectedMode(player);
    }

    if (selected == TitanRuneMode::Off)
        return;
    if (!IsSupportedDungeon(map->GetId(), selected))
    {
        Notify(player, std::string("Defense Protocol ") + ModeName(selected) + " is not available in this dungeon.");
        return;
    }

    bool activated = false;
    {
        std::lock_guard<std::mutex> lock(g_stateMutex);
        activated = g_instanceModes.emplace(key, selected).second;
    }
    if (!activated)
        return;

    BroadcastMode(map, selected);
    LOG_INFO("server.loading", "[TitanRune] Activated {} on map={} instance={} by {}{}",
        ModeName(selected), map->GetId(), map->GetInstanceId(), player->GetName(),
        selected == TitanRuneMode::Gamma && IsFrozenHalls(map->GetId()) ? " (reward-only Frozen Halls)" : "");
}
}

void AddTitanRuneScripts()
{
    new TitanRuneWorldScript();
    new TitanRunePlayerScript();
    new TitanRuneMapScript();
    new TitanRuneCreatureScript();
    new TitanRuneDamageScript();
    new npc_titan_rune_coordinator();
    new npc_titan_sidereal_vendor();
    new npc_titan_scourgestone_vendor();
    new TitanRuneCommandScript();
}
