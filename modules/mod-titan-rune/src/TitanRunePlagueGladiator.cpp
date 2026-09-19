#include "TitanRuneSystem.h"

#include "Chat.h"
#include "Creature.h"
#include "Map.h"
#include "Player.h"
#include "Random.h"
#include "ScriptMgr.h"
#include "ScriptedGossip.h"
#include "SpellAuras.h"
#include "TemporarySummon.h"
#include "WorldSession.h"

#include <algorithm>
#include <chrono>
#include <cstdint>
#include <string>
#include <unordered_map>
#include <unordered_set>

namespace
{
using Clock = std::chrono::steady_clock;
using TimePoint = Clock::time_point;

constexpr uint32 FAMILY_PROC_CHANCE = 35;
constexpr uint32 FAMILY_PROC_COOLDOWN_SECONDS = 30;
constexpr uint32 PLAGUE_INFECTION_SPELL = 43958;
constexpr uint32 ZOMBIE_FORM_SPELL = 43869;
constexpr uint32 ZOMBIE_HORROR_ENTRY = 900122;
constexpr uint32 HOLY_GRENADE_CACHE_ENTRY = 900123;
constexpr uint32 BANANA_TRIP_SPELL = 5211;
constexpr uint32 FROST_TRAP_SPELL = 13810;

struct HolyState
{
    TimePoint expires{};
};

struct FireTrapState
{
    uint8 ticksLeft = 0;
    TimePoint nextTick{};
};

struct RoseState
{
    uint8 stacks = 0;
    float appliedHaste = 0.0f;
    TimePoint expires{};
};

std::unordered_map<uint64, TimePoint> g_familyCooldowns;
std::unordered_map<uint32, TimePoint> g_plagueInfections;
std::unordered_map<uint32, HolyState> g_holyImbuement;
std::unordered_map<uint32, FireTrapState> g_fireTraps;
std::unordered_map<uint32, RoseState> g_roses;
std::unordered_set<uint64> g_plagueCaches;
std::unordered_map<uint64, uint8> g_grenadeCharges;

uint32 PlayerKey(Player const* player)
{
    return player ? player->GetGUID().GetCounter() : 0;
}

uint64 InstanceKey(Map const* map)
{
    if (!map)
        return 0;
    return (uint64(map->GetId()) << 32) | uint64(map->GetInstanceId());
}

uint64 CreatureKey(Creature const* creature)
{
    if (!creature || !creature->GetMap())
        return 0;
    return (uint64(creature->GetMap()->GetInstanceId()) << 32) | uint64(creature->GetGUID().GetCounter());
}

bool IsHuman(Player const* player)
{
    return player && player->GetSession() && !player->GetSession()->IsBot();
}

bool IsPlagueMap(uint32 mapId)
{
    return mapId == 595;
}

bool IsGladiatorMap(uint32 mapId)
{
    return mapId == 650;
}

void Notify(Player* player, char const* text)
{
    if (IsHuman(player))
        ChatHandler(player->GetSession()).PSendSysMessage("[Titan Rune] {}", text);
}

bool UsesActiveProtocol(Creature const* creature)
{
    return creature && creature->IsInWorld() && !creature->IsControlledByPlayer() && creature->IsHostileToPlayers() &&
        TitanRune::GetActiveMode(creature->GetMap()) != TitanRuneMode::Off;
}

bool ConsumeFamilyProc(Creature* creature)
{
    if (!creature)
        return false;

    uint64 const key = CreatureKey(creature);
    TimePoint const now = Clock::now();
    auto itr = g_familyCooldowns.find(key);
    if (itr != g_familyCooldowns.end() && now < itr->second)
        return false;
    if (!roll_chance_i(FAMILY_PROC_CHANCE))
        return false;
    g_familyCooldowns[key] = now + std::chrono::seconds(FAMILY_PROC_COOLDOWN_SECONDS);
    return true;
}

void ApplyHaste(Player* player, float percent, bool apply)
{
    if (!player || percent <= 0.0f)
        return;
    player->ApplyAttackTimePercentMod(BASE_ATTACK, percent, apply);
    player->ApplyAttackTimePercentMod(OFF_ATTACK, percent, apply);
    player->ApplyAttackTimePercentMod(RANGED_ATTACK, percent, apply);
    player->ApplyCastTimePercentMod(percent, apply);
}

void GrantHolyImbuement(Player* source, TimePoint now)
{
    if (!source || !source->GetMap())
        return;

    Map::PlayerList const& players = source->GetMap()->GetPlayers();
    for (Map::PlayerList::const_iterator itr = players.begin(); itr != players.end(); ++itr)
    {
        Player* player = itr->GetSource();
        if (!IsHuman(player) || !player->IsAlive() || source->GetDistance(player) > 30.0f)
            continue;
        g_holyImbuement[PlayerKey(player)].expires = now + std::chrono::seconds(20);
        Notify(player, "Holy Imbuement: +20% damage and healing for 20 seconds.");
    }
}

void GrantRose(Player* player, TimePoint now)
{
    if (!player)
        return;

    RoseState& state = g_roses[PlayerKey(player)];
    if (state.appliedHaste > 0.0f)
        ApplyHaste(player, state.appliedHaste, false);
    state.stacks = std::min<uint8>(10, uint8(state.stacks + 1));
    state.appliedHaste = 2.0f * float(state.stacks);
    ApplyHaste(player, state.appliedHaste, true);
    state.expires = now + std::chrono::seconds(20);
    Notify(player, "The crowd throws a rose: +2% damage and haste per stack for 20 seconds.");
}

void SpawnPlagueCache(Player* player)
{
    if (!IsHuman(player) || !player->IsInWorld() || !IsPlagueMap(player->GetMapId()))
        return;

    TitanRuneMode const mode = TitanRune::GetActiveMode(player->GetMap());
    if (mode != TitanRuneMode::Beta && mode != TitanRuneMode::Gamma)
        return;

    uint64 const key = InstanceKey(player->GetMap());
    if (!g_plagueCaches.insert(key).second)
        return;
    g_grenadeCharges[key] = 5;

    TempSummon* cache = player->SummonCreature(HOLY_GRENADE_CACHE_ENTRY,
        player->GetPositionX() + 2.0f, player->GetPositionY(), player->GetPositionZ(), player->GetOrientation(),
        TEMPSUMMON_TIMED_OR_DEAD_DESPAWN, 6 * HOUR * IN_MILLISECONDS);
    if (!cache)
    {
        g_plagueCaches.erase(key);
        g_grenadeCharges.erase(key);
        return;
    }

    TempSummon* horror = player->SummonCreature(ZOMBIE_HORROR_ENTRY,
        player->GetPositionX() + 10.0f, player->GetPositionY(), player->GetPositionZ(), player->GetOrientation(),
        TEMPSUMMON_TIMED_OR_DEAD_DESPAWN, 30 * MINUTE * IN_MILLISECONDS);
    if (horror)
        horror->SetInCombatWithZone();
    Notify(player, "Holy Hand Grenade Cache ready: five charges can instantly destroy nearby Zombie Horrors.");
}

void ClearPlayer(Player* player)
{
    if (!player)
        return;
    uint32 const key = PlayerKey(player);

    auto rose = g_roses.find(key);
    if (rose != g_roses.end() && rose->second.appliedHaste > 0.0f)
        ApplyHaste(player, rose->second.appliedHaste, false);

    player->RemoveAurasDueToSpell(PLAGUE_INFECTION_SPELL);
    player->RemoveAurasDueToSpell(ZOMBIE_FORM_SPELL);
    g_plagueInfections.erase(key);
    g_holyImbuement.erase(key);
    g_fireTraps.erase(key);
    g_roses.erase(key);
}

class TitanRunePlagueGladiatorPlayerScript final : public PlayerScript
{
public:
    TitanRunePlagueGladiatorPlayerScript() : PlayerScript("TitanRunePlagueGladiatorPlayerScript") { }

    void OnPlayerLogin(Player* player) override { SpawnPlagueCache(player); }

    void OnPlayerMapChanged(Player* player) override
    {
        ClearPlayer(player);
        SpawnPlagueCache(player);
    }

    void OnPlayerLogout(Player* player) override { ClearPlayer(player); }

    void OnPlayerUpdate(Player* player, uint32 /*diff*/) override
    {
        if (!player || !player->IsInWorld())
            return;

        SpawnPlagueCache(player);
        uint32 const key = PlayerKey(player);
        TimePoint const now = Clock::now();

        auto infection = g_plagueInfections.find(key);
        if (infection != g_plagueInfections.end())
        {
            if (!player->HasAura(PLAGUE_INFECTION_SPELL))
                g_plagueInfections.erase(infection);
            else if (now >= infection->second)
            {
                player->RemoveAurasDueToSpell(PLAGUE_INFECTION_SPELL);
                player->CastSpell(player, ZOMBIE_FORM_SPELL, true);
                g_plagueInfections.erase(infection);
                Notify(player, "The Zombie Plague completed. You have transformed into a zombie until you leave the dungeon or die.");
            }
        }

        auto holy = g_holyImbuement.find(key);
        if (holy != g_holyImbuement.end() && now >= holy->second.expires)
            g_holyImbuement.erase(holy);

        auto fire = g_fireTraps.find(key);
        if (fire != g_fireTraps.end() && fire->second.ticksLeft && now >= fire->second.nextTick)
        {
            uint32 const amount = std::max<uint32>(1, player->GetMaxHealth() / 20);
            fire->second.nextTick = now + std::chrono::seconds(1);
            --fire->second.ticksLeft;
            if (amount >= player->GetHealth())
                player->KillSelf(false);
            else
                player->ModifyHealth(-int32(amount));
            if (!fire->second.ticksLeft)
                g_fireTraps.erase(fire);
        }

        auto rose = g_roses.find(key);
        if (rose != g_roses.end() && now >= rose->second.expires)
        {
            if (rose->second.appliedHaste > 0.0f)
                ApplyHaste(player, rose->second.appliedHaste, false);
            g_roses.erase(rose);
        }
    }
};

class TitanRunePlagueGladiatorUnitScript final : public UnitScript
{
public:
    TitanRunePlagueGladiatorUnitScript() : UnitScript("TitanRunePlagueGladiatorUnitScript") { }

    void OnHeal(Unit* healer, Unit* /*receiver*/, uint32& gain) override
    {
        Player* player = healer ? healer->ToPlayer() : nullptr;
        if (!player || !gain)
            return;

        auto holy = g_holyImbuement.find(PlayerKey(player));
        if (holy != g_holyImbuement.end() && Clock::now() < holy->second.expires)
            gain = uint32(std::min<double>(double(gain) * 1.20, double(0xFFFFFFFFu)));
    }

    void OnDamage(Unit* attacker, Unit* victim, uint32& damage) override
    {
        if (!attacker || !victim || !damage)
            return;

        TimePoint const now = Clock::now();
        if (Player* player = attacker->ToPlayer())
        {
            uint32 const key = PlayerKey(player);
            auto holy = g_holyImbuement.find(key);
            if (holy != g_holyImbuement.end() && now < holy->second.expires)
                damage = uint32(std::min<double>(double(damage) * 1.20, double(0xFFFFFFFFu)));

            auto rose = g_roses.find(key);
            if (rose != g_roses.end() && now < rose->second.expires)
                damage = uint32(std::min<double>(double(damage) * (1.0 + 0.02 * rose->second.stacks), double(0xFFFFFFFFu)));
        }

        Creature* creature = attacker->ToCreature();
        Player* player = victim->ToPlayer();
        if (!creature || !player || !player->IsAlive() || !UsesActiveProtocol(creature))
            return;

        TitanRuneMode const mode = TitanRune::GetActiveMode(creature->GetMap());
        if (IsPlagueMap(creature->GetMapId()) && ConsumeFamilyProc(creature))
        {
            if (Aura* aura = creature->AddAura(PLAGUE_INFECTION_SPELL, player))
            {
                aura->SetMaxDuration(60 * IN_MILLISECONDS);
                aura->SetDuration(60 * IN_MILLISECONDS);
                g_plagueInfections[PlayerKey(player)] = now + std::chrono::seconds(60);
                Notify(player, "Zombie Plague: cleanse the disease within one minute.");
            }
        }
        else if (IsGladiatorMap(creature->GetMapId()) &&
            (mode == TitanRuneMode::Beta || mode == TitanRuneMode::Gamma) && ConsumeFamilyProc(creature))
        {
            switch (urand(0, 4))
            {
                case 0:
                    creature->CastSpell(player, BANANA_TRIP_SPELL, true);
                    Notify(player, "The Trial crowd throws a banana. You trip!");
                    break;
                case 1:
                    creature->CastSpell(player, FROST_TRAP_SPELL, true);
                    Notify(player, "The Trial crowd drops a frost trap.");
                    break;
                case 2:
                    g_fireTraps[PlayerKey(player)] = {4, now + std::chrono::seconds(1)};
                    Notify(player, "The Trial crowd drops a fire trap.");
                    break;
                case 3:
                    player->ModifyHealth(int32(player->GetMaxHealth() / 4));
                    if (player->GetMaxPower(POWER_MANA) > 0)
                        player->ModifyPower(POWER_MANA, int32(player->GetMaxPower(POWER_MANA) / 4));
                    Notify(player, "The Trial crowd throws a helpful chest, restoring health and mana.");
                    break;
                default:
                    GrantRose(player, now);
                    break;
            }
        }
    }

    void OnUnitDeath(Unit* unit, Unit* /*killer*/) override
    {
        Creature* creature = unit ? unit->ToCreature() : nullptr;
        if (!creature || !creature->GetMap())
            return;

        TitanRuneMode const mode = TitanRune::GetActiveMode(creature->GetMap());
        if (IsPlagueMap(creature->GetMapId()) && creature->IsDungeonBoss() &&
            (mode == TitanRuneMode::Beta || mode == TitanRuneMode::Gamma))
        {
            TempSummon* horror = creature->SummonCreature(ZOMBIE_HORROR_ENTRY,
                creature->GetPositionX() + 3.0f, creature->GetPositionY(), creature->GetPositionZ(), creature->GetOrientation(),
                TEMPSUMMON_TIMED_OR_DEAD_DESPAWN, 30 * MINUTE * IN_MILLISECONDS);
            if (horror)
                horror->SetInCombatWithZone();
        }
    }
};

class TitanRunePlagueGladiatorMapScript final : public AllMapScript
{
public:
    TitanRunePlagueGladiatorMapScript() : AllMapScript("TitanRunePlagueGladiatorMapScript") { }

    void OnDestroyMap(Map* map) override
    {
        if (!map)
            return;
        uint64 const instanceKey = InstanceKey(map);
        uint32 const instanceId = map->GetInstanceId();
        g_plagueCaches.erase(instanceKey);
        g_grenadeCharges.erase(instanceKey);
        for (auto itr = g_familyCooldowns.begin(); itr != g_familyCooldowns.end(); )
            itr = uint32(itr->first >> 32) == instanceId ? g_familyCooldowns.erase(itr) : ++itr;
    }
};

class npc_titan_holy_grenade_cache_v2 final : public CreatureScript
{
public:
    npc_titan_holy_grenade_cache_v2() : CreatureScript("npc_titan_holy_grenade_cache") { }

    bool OnGossipHello(Player* player, Creature* creature) override
    {
        ClearGossipMenuFor(player);
        uint8 const charges = player && player->GetMap() ? g_grenadeCharges[InstanceKey(player->GetMap())] : 0;
        AddGossipItemFor(player, GOSSIP_ICON_CHAT,
            std::string("Holy Hand Grenades remaining: ") + std::to_string(charges), GOSSIP_SENDER_MAIN, 100);
        if (charges)
            AddGossipItemFor(player, GOSSIP_ICON_CHAT,
                "Throw a Holy Hand Grenade at the nearest Zombie Horror", GOSSIP_SENDER_MAIN, 101);
        SendGossipMenuFor(player, player->GetGossipTextId(creature), creature->GetGUID());
        return true;
    }

    bool OnGossipSelect(Player* player, Creature* creature, uint32 /*sender*/, uint32 action) override
    {
        if (!player || action != 101 || !player->GetMap())
            return OnGossipHello(player, creature);

        uint64 const key = InstanceKey(player->GetMap());
        uint8& charges = g_grenadeCharges[key];
        if (!charges)
            return OnGossipHello(player, creature);

        Creature* horror = player->FindNearestCreature(ZOMBIE_HORROR_ENTRY, 100.0f, true);
        if (!horror)
        {
            Notify(player, "No living Zombie Horror is close enough for the grenade.");
            return OnGossipHello(player, creature);
        }

        --charges;
        horror->KillSelf(false);
        GrantHolyImbuement(player, Clock::now());
        Notify(player, "Holy Hand Grenade detonated. The Zombie Horror is destroyed.");
        return OnGossipHello(player, creature);
    }
};
}

void AddTitanRunePlagueGladiatorScripts()
{
    new TitanRunePlagueGladiatorPlayerScript();
    new TitanRunePlagueGladiatorUnitScript();
    new TitanRunePlagueGladiatorMapScript();
    new npc_titan_holy_grenade_cache_v2();
}
