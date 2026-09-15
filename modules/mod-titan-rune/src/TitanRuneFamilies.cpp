#include "TitanRuneSystem.h"

#include "Chat.h"
#include "Creature.h"
#include "CreatureAI.h"
#include "Group.h"
#include "Map.h"
#include "Player.h"
#include "Random.h"
#include "ScriptMgr.h"
#include "ScriptedGossip.h"
#include "SpellAuras.h"
#include "TemporarySummon.h"
#include "Unit.h"
#include "UpdateFields.h"
#include "WorldSession.h"

#include <algorithm>
#include <chrono>
#include <cmath>
#include <cstdint>
#include <unordered_map>
#include <unordered_set>
#include <vector>

namespace
{
using Clock = std::chrono::steady_clock;
using TimePoint = Clock::time_point;

constexpr uint32 FAMILY_PROC_CHANCE = 35;
constexpr uint32 FAMILY_PROC_COOLDOWN_SECONDS = 30;
constexpr uint32 MIRROR_IMAGE_ENTRY = 31216;
constexpr uint32 ARCANE_MISSILE_BOLT_SPELL = 42845;
constexpr uint32 HOLY_NOVA_SPELL = 48078;
constexpr uint32 PLAGUE_INFECTION_SPELL = 43958;
constexpr uint32 ZOMBIE_FORM_SPELL = 43869;
constexpr uint32 ZOMBIE_HORROR_ENTRY = 900122;
constexpr uint32 HOLY_GRENADE_CACHE_ENTRY = 900123;
constexpr uint32 BANANA_TRIP_SPELL = 5211;
constexpr uint32 FROST_TRAP_SPELL = 13810;

enum class MirrorRole : uint8
{
    Arcane = 0,
    Melee = 1,
    Healer = 2,
};

struct IcyPatch
{
    uint64 instanceKey = 0;
    float x = 0.0f;
    float y = 0.0f;
    float z = 0.0f;
    TimePoint expires{};
};

struct FrostState
{
    TimePoint trailExpires{};
    TimePoint nextTrailSample{};
    uint8 samplesLeft = 0;
    TimePoint fireExpires{};
    TimePoint nextFireTick{};
    uint8 fireStacks = 0;
};

struct TimedCrit
{
    bool applied = false;
    TimePoint expires{};
};

struct TempoState
{
    uint8 stacks = 0;
    float appliedHaste = 0.0f;
    float baseRunRate = 1.0f;
    bool movementApplied = false;
    TimePoint expires{};
};

struct MirrorState
{
    MirrorRole role = MirrorRole::Arcane;
    TimePoint nextAction{};
};

struct HolyState
{
    TimePoint expires{};
};

struct TitanPlayerState
{
    uint8 stacks = 0;
    TimePoint expires{};
    TimePoint nextPulse{};
    TimePoint nextManaPulse{};
    TimePoint nextHodirSave{};
    bool keepers = false;
    float baseRunRate = 1.0f;
};

struct TitanEnemyState
{
    uint8 stacks = 0;
    TimePoint expires{};
    TimePoint nextPulse{};
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
std::vector<IcyPatch> g_icyPatches;
std::unordered_map<uint32, FrostState> g_frostStates;
std::unordered_map<uint32, TimedCrit> g_blisteringFury;
std::unordered_map<uint32, TempoState> g_arcaneTempo;
std::unordered_map<uint64, MirrorState> g_mirrorStates;
std::unordered_map<uint32, TimePoint> g_plagueInfections;
std::unordered_map<uint32, HolyState> g_holyImbuement;
std::unordered_map<uint32, TitanPlayerState> g_titanPlayers;
std::unordered_map<uint64, TitanEnemyState> g_titanEnemies;
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

bool IsFrostMap(uint32 mapId)     { return mapId == 574 || mapId == 575; }
bool IsArcaneMap(uint32 mapId)    { return mapId == 576 || mapId == 578 || mapId == 608; }
bool IsPlagueMap(uint32 mapId)    { return mapId == 595; }
bool IsTitanMap(uint32 mapId)     { return mapId == 599 || mapId == 602; }
bool IsGladiatorMap(uint32 mapId) { return mapId == 650; }

void Notify(Player* player, char const* text)
{
    if (!IsHuman(player))
        return;
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

void ApplyCrit(Player* player, float amount, bool apply)
{
    if (!player)
        return;
    player->ApplyModSignedFloatValue(PLAYER_CRIT_PERCENTAGE, amount, apply);
    player->ApplyModSignedFloatValue(PLAYER_RANGED_CRIT_PERCENTAGE, amount, apply);
    player->ApplyModSignedFloatValue(PLAYER_OFFHAND_CRIT_PERCENTAGE, amount, apply);
    for (uint16 i = 0; i < MAX_SPELL_SCHOOL; ++i)
        player->ApplyModSignedFloatValue(PLAYER_SPELL_CRIT_PERCENTAGE1 + i, amount, apply);
}

Player* RandomHumanPlayer(Map* map, Player* fallback)
{
    if (!map)
        return fallback;
    std::vector<Player*> candidates;
    Map::PlayerList const& players = map->GetPlayers();
    for (Map::PlayerList::const_iterator itr = players.begin(); itr != players.end(); ++itr)
    {
        Player* player = itr->GetSource();
        if (IsHuman(player) && player->IsAlive())
            candidates.push_back(player);
    }
    if (candidates.empty())
        return fallback;
    return candidates[urand(0, uint32(candidates.size() - 1))];
}

void AddIcyPatch(Player* player, TimePoint now)
{
    if (!player || !player->GetMap())
        return;
    g_icyPatches.push_back({InstanceKey(player->GetMap()), player->GetPositionX(), player->GetPositionY(),
        player->GetPositionZ(), now + std::chrono::seconds(15)});
}

bool PlayerTouchesIce(Player* player, TimePoint now)
{
    if (!player || !player->GetMap())
        return false;
    uint64 const instance = InstanceKey(player->GetMap());
    bool touching = false;
    for (auto itr = g_icyPatches.begin(); itr != g_icyPatches.end(); )
    {
        if (now >= itr->expires)
        {
            itr = g_icyPatches.erase(itr);
            continue;
        }
        if (itr->instanceKey == instance)
        {
            float const dx = player->GetPositionX() - itr->x;
            float const dy = player->GetPositionY() - itr->y;
            float const dz = player->GetPositionZ() - itr->z;
            if ((dx * dx + dy * dy + dz * dz) <= 9.0f)
                touching = true;
        }
        ++itr;
    }
    return touching;
}

void StartFrostMechanic(Player* player, TitanRuneMode mode)
{
    if (!player)
        return;
    TimePoint const now = Clock::now();
    FrostState& state = g_frostStates[PlayerKey(player)];
    state.trailExpires = now + std::chrono::seconds(6);
    state.nextTrailSample = now;
    state.samplesLeft = 6;
    AddIcyPatch(player, now);

    if (mode == TitanRuneMode::Beta || mode == TitanRuneMode::Gamma)
    {
        state.fireStacks = std::min<uint8>(5, uint8(state.fireStacks + 1));
        state.fireExpires = now + std::chrono::seconds(10);
        state.nextFireTick = now + std::chrono::seconds(1);
        Notify(player, "Glaciate + Fire Blast: keep moving, then cross an icy trail to quench the fire.");
    }
    else
        Notify(player, "Glaciate: keep moving to lay the icy trail away from the group.");
}

void GrantBlisteringFury(Player* player, TimePoint now)
{
    if (!player)
        return;
    TimedCrit& state = g_blisteringFury[PlayerKey(player)];
    if (!state.applied)
    {
        ApplyCrit(player, 50.0f, true);
        state.applied = true;
    }
    state.expires = now + std::chrono::seconds(20);
    Notify(player, "Blistering Fury: Fire Blast quenched, +50% critical strike chance for 20 seconds.");
}

void GrantArcaneTempo(Map* map, TimePoint now)
{
    if (!map)
        return;
    Map::PlayerList const& players = map->GetPlayers();
    for (Map::PlayerList::const_iterator itr = players.begin(); itr != players.end(); ++itr)
    {
        Player* player = itr->GetSource();
        if (!IsHuman(player) || !player->IsAlive())
            continue;
        TempoState& state = g_arcaneTempo[PlayerKey(player)];
        if (state.appliedHaste > 0.0f)
            ApplyHaste(player, state.appliedHaste, false);
        if (!state.movementApplied)
        {
            state.baseRunRate = player->GetSpeedRate(MOVE_RUN);
            state.movementApplied = true;
        }
        state.stacks = std::min<uint8>(6, uint8(state.stacks + 1));
        state.appliedHaste = 5.0f * float(state.stacks);
        ApplyHaste(player, state.appliedHaste, true);
        player->SetSpeed(MOVE_RUN, state.baseRunRate * (1.0f + 0.05f * float(state.stacks)), true);
        state.expires = now + std::chrono::seconds(30);
        Notify(player, "Arcane Tempo gained from a Mirror Image: +5% haste and movement per stack, up to 30%.");
    }
}

TempSummon* SpawnArcaneMirror(Creature* source, Player* initialTarget, MirrorRole role, float offset, TimePoint now)
{
    if (!source)
        return nullptr;

    TempSummon* image = source->SummonCreature(MIRROR_IMAGE_ENTRY,
        source->GetPositionX() + offset, source->GetPositionY(), source->GetPositionZ(), source->GetOrientation(),
        TEMPSUMMON_TIMED_OR_DEAD_DESPAWN, 60 * IN_MILLISECONDS);
    if (!image)
        return nullptr;

    image->SetFaction(source->GetFaction());
    image->SetLevel(source->GetLevel());
    image->SetMaxHealth(1);
    image->SetHealth(1);
    g_mirrorStates[CreatureKey(image)] = {role, now};

    if (initialTarget && image->AI())
        image->AI()->AttackStart(initialTarget);
    return image;
}

void SpawnArcaneMirrors(Creature* source, Player* initialTarget, TitanRuneMode mode, TimePoint now)
{
    if (!source)
        return;

    if (mode == TitanRuneMode::Alpha)
    {
        SpawnArcaneMirror(source, initialTarget, MirrorRole::Arcane, 1.5f, now);
        SpawnArcaneMirror(source, initialTarget, MirrorRole::Arcane, -1.5f, now);
        return;
    }

    // Defense Protocol Beta and Gamma use the later three-image version: one Arcane caster,
    // one melee fixate and one Holy Nova healer. Gamma retains Beta's dungeon-family mechanic.
    SpawnArcaneMirror(source, initialTarget, MirrorRole::Arcane, 1.5f, now);
    SpawnArcaneMirror(source, initialTarget, MirrorRole::Melee, -1.5f, now);
    SpawnArcaneMirror(source, initialTarget, MirrorRole::Healer, 0.0f, now);
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

void ApplyKeeperAid(Player* player, TitanPlayerState& state, TimePoint now)
{
    if (!player || state.keepers)
        return;
    state.keepers = true;
    state.baseRunRate = player->GetSpeedRate(MOVE_RUN);
    player->SetSpeed(MOVE_RUN, state.baseRunRate * 1.20f, true);
    state.nextManaPulse = now + std::chrono::seconds(5);
    state.nextHodirSave = now;
    Notify(player, "Purified Titan Energy reached 100 stacks. The four Keepers are assisting you.");
}

void RemoveKeeperAid(Player* player, TitanPlayerState& state)
{
    if (!player || !state.keepers)
        return;
    player->SetSpeed(MOVE_RUN, state.baseRunRate, true);
    state.keepers = false;
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
        TEMPSUMMON_TIMED_OR_DEAD_DESPAWN, 6 * 60 * 60 * IN_MILLISECONDS);
    if (!cache)
    {
        g_plagueCaches.erase(key);
        g_grenadeCharges.erase(key);
        return;
    }

    TempSummon* horror = player->SummonCreature(ZOMBIE_HORROR_ENTRY,
        player->GetPositionX() + 10.0f, player->GetPositionY(), player->GetPositionZ(), player->GetOrientation(),
        TEMPSUMMON_TIMED_OR_DEAD_DESPAWN, 30 * 60 * IN_MILLISECONDS);
    if (horror)
        horror->SetInCombatWithZone();
    Notify(player, "Holy Hand Grenade Cache ready: five charges can instantly destroy nearby Zombie Horrors.");
}

void ClearPlayerModifiers(Player* player)
{
    if (!player)
        return;
    uint32 const key = PlayerKey(player);

    auto crit = g_blisteringFury.find(key);
    if (crit != g_blisteringFury.end() && crit->second.applied)
        ApplyCrit(player, 50.0f, false);

    auto tempo = g_arcaneTempo.find(key);
    if (tempo != g_arcaneTempo.end())
    {
        if (tempo->second.appliedHaste > 0.0f)
            ApplyHaste(player, tempo->second.appliedHaste, false);
        if (tempo->second.movementApplied)
            player->SetSpeed(MOVE_RUN, tempo->second.baseRunRate, true);
    }

    auto rose = g_roses.find(key);
    if (rose != g_roses.end() && rose->second.appliedHaste > 0.0f)
        ApplyHaste(player, rose->second.appliedHaste, false);

    auto titan = g_titanPlayers.find(key);
    if (titan != g_titanPlayers.end())
        RemoveKeeperAid(player, titan->second);

    player->RemoveAurasDueToSpell(PLAGUE_INFECTION_SPELL);
    player->RemoveAurasDueToSpell(ZOMBIE_FORM_SPELL);
    g_frostStates.erase(key);
    g_blisteringFury.erase(key);
    g_arcaneTempo.erase(key);
    g_plagueInfections.erase(key);
    g_holyImbuement.erase(key);
    g_titanPlayers.erase(key);
    g_fireTraps.erase(key);
    g_roses.erase(key);
}

class TitanRuneFamiliesPlayerScript final : public PlayerScript
{
public:
    TitanRuneFamiliesPlayerScript() : PlayerScript("TitanRuneFamiliesPlayerScript") { }

    void OnPlayerLogin(Player* player) override
    {
        SpawnPlagueCache(player);
    }

    void OnPlayerMapChanged(Player* player) override
    {
        ClearPlayerModifiers(player);
        SpawnPlagueCache(player);
    }

    void OnPlayerLogout(Player* player) override
    {
        ClearPlayerModifiers(player);
    }

    void OnPlayerUpdate(Player* player, uint32 /*diff*/) override
    {
        if (!player || !player->IsInWorld())
            return;

        SpawnPlagueCache(player);
        uint32 const key = PlayerKey(player);
        TimePoint const now = Clock::now();

        auto frost = g_frostStates.find(key);
        if (frost != g_frostStates.end())
        {
            FrostState& state = frost->second;
            if (state.samplesLeft && now < state.trailExpires && now >= state.nextTrailSample)
            {
                AddIcyPatch(player, now);
                state.nextTrailSample = now + std::chrono::seconds(1);
                --state.samplesLeft;
            }

            if (state.fireStacks)
            {
                if (PlayerTouchesIce(player, now))
                {
                    state.fireStacks = 0;
                    GrantBlisteringFury(player, now);
                }
                else if (now >= state.fireExpires)
                    state.fireStacks = 0;
                else if (now >= state.nextFireTick)
                {
                    // Blizzard's July 6, 2023 live hotfix reduced Beta Fire Blast from 10% to
                    // 6% maximum health per second. Gamma inherits the Beta Frost-family mechanic.
                    uint32 const amount = std::max<uint32>(1, uint32((uint64(player->GetMaxHealth()) * 6u * state.fireStacks) / 100u));
                    state.nextFireTick = now + std::chrono::seconds(1);
                    if (amount >= player->GetHealth())
                        player->KillSelf(false);
                    else
                        player->ModifyHealth(-int32(amount));
                }
            }
            if (!state.samplesLeft && !state.fireStacks && now >= state.trailExpires)
                g_frostStates.erase(frost);
        }

        auto fury = g_blisteringFury.find(key);
        if (fury != g_blisteringFury.end() && fury->second.applied && now >= fury->second.expires)
        {
            ApplyCrit(player, 50.0f, false);
            g_blisteringFury.erase(fury);
        }

        auto tempo = g_arcaneTempo.find(key);
        if (tempo != g_arcaneTempo.end() && now >= tempo->second.expires)
        {
            if (tempo->second.appliedHaste > 0.0f)
                ApplyHaste(player, tempo->second.appliedHaste, false);
            if (tempo->second.movementApplied)
                player->SetSpeed(MOVE_RUN, tempo->second.baseRunRate, true);
            g_arcaneTempo.erase(tempo);
        }

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

        Map* map = player->GetMap();
        TitanRuneMode const mode = TitanRune::GetActiveMode(map);
        if (map && IsTitanMap(map->GetId()) && (mode == TitanRuneMode::Beta || mode == TitanRuneMode::Gamma))
        {
            TitanPlayerState& state = g_titanPlayers[key];
            if (player->IsInCombat() && now >= state.nextPulse)
            {
                state.stacks = std::min<uint8>(100, uint8(state.stacks + 5));
                state.expires = now + std::chrono::seconds(12);
                state.nextPulse = now + std::chrono::seconds(1);
                if (state.stacks >= 100)
                    ApplyKeeperAid(player, state, now);
            }
            if (state.stacks && now >= state.expires)
            {
                state.stacks = 0;
                RemoveKeeperAid(player, state);
            }
            if (state.keepers && now >= state.nextManaPulse)
            {
                if (player->GetMaxPower(POWER_MANA) > 0)
                    player->ModifyPower(POWER_MANA, int32(player->GetMaxPower(POWER_MANA) * 15 / 100));
                state.nextManaPulse = now + std::chrono::seconds(5);
            }
        }
    }
};

class TitanRuneFamiliesUnitScript final : public UnitScript
{
public:
    TitanRuneFamiliesUnitScript() : UnitScript("TitanRuneFamiliesUnitScript") { }

    void OnUnitUpdate(Unit* unit, uint32 /*diff*/) override
    {
        Creature* creature = unit ? unit->ToCreature() : nullptr;
        if (!creature)
            return;

        if (creature->GetEntry() == MIRROR_IMAGE_ENTRY)
        {
            auto mirror = g_mirrorStates.find(CreatureKey(creature));
            if (mirror == g_mirrorStates.end())
                return;

            TimePoint const now = Clock::now();
            if (now < mirror->second.nextAction)
                return;

            Player* target = RandomHumanPlayer(creature->GetMap(), nullptr);
            switch (mirror->second.role)
            {
                case MirrorRole::Arcane:
                    if (target)
                        creature->CastSpell(target, ARCANE_MISSILE_BOLT_SPELL, true);
                    mirror->second.nextAction = now + std::chrono::seconds(1);
                    break;
                case MirrorRole::Melee:
                    if (target && creature->AI())
                        creature->AI()->AttackStart(target);
                    mirror->second.nextAction = now + std::chrono::seconds(3);
                    break;
                case MirrorRole::Healer:
                    creature->CastSpell(creature, HOLY_NOVA_SPELL, true);
                    mirror->second.nextAction = now + std::chrono::seconds(2);
                    break;
            }
            return;
        }

        if (!UsesActiveProtocol(creature) || !IsTitanMap(creature->GetMapId()) ||
            TitanRune::GetActiveMode(creature->GetMap()) != TitanRuneMode::Alpha)
            return;

        uint64 const key = CreatureKey(creature);
        TimePoint const now = Clock::now();
        TitanEnemyState& state = g_titanEnemies[key];
        if (creature->IsInCombat() && now >= state.nextPulse)
        {
            state.stacks = std::min<uint8>(100, uint8(state.stacks + 1));
            state.expires = now + std::chrono::seconds(12);
            state.nextPulse = now + std::chrono::seconds(1);
        }
        if (state.stacks && now >= state.expires)
            state.stacks = 0;
    }

    void OnHeal(Unit* healer, Unit* receiver, uint32& gain) override
    {
        if (!healer || !receiver || !gain)
            return;
        TimePoint const now = Clock::now();
        if (Player* player = healer->ToPlayer())
        {
            auto holy = g_holyImbuement.find(PlayerKey(player));
            if (holy != g_holyImbuement.end() && now < holy->second.expires)
                gain = uint32(std::min<double>(double(gain) * 1.20, double(0xFFFFFFFFu)));
        }
        if (Player* player = receiver->ToPlayer())
        {
            auto titan = g_titanPlayers.find(PlayerKey(player));
            if (titan != g_titanPlayers.end() && titan->second.keepers)
                gain = uint32(std::min<double>(double(gain) * 1.20, double(0xFFFFFFFFu)));
        }
    }

    void OnDamage(Unit* attacker, Unit* victim, uint32& damage) override
    {
        if (!attacker || !victim || damage == 0)
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

            auto titan = g_titanPlayers.find(key);
            if (titan != g_titanPlayers.end() && titan->second.stacks && now < titan->second.expires)
            {
                damage = uint32(std::min<double>(double(damage) * (1.0 + 0.01 * titan->second.stacks), double(0xFFFFFFFFu)));
                if (titan->second.keepers)
                    damage = uint32(std::min<double>(double(damage) * 1.40, double(0xFFFFFFFFu)));
            }

            Creature* enemy = victim->ToCreature();
            if (enemy && IsTitanMap(enemy->GetMapId()) && TitanRune::GetActiveMode(enemy->GetMap()) == TitanRuneMode::Alpha)
            {
                auto state = g_titanEnemies.find(CreatureKey(enemy));
                if (state != g_titanEnemies.end() && state->second.stacks && now < state->second.expires)
                    damage = uint32(std::min<double>(double(damage) * (1.0 + 0.02 * state->second.stacks), double(0xFFFFFFFFu)));
            }
        }

        Creature* creature = attacker->ToCreature();
        Player* player = victim->ToPlayer();
        if (!creature || !player || !player->IsAlive() || !UsesActiveProtocol(creature))
            return;

        TitanRuneMode const mode = TitanRune::GetActiveMode(creature->GetMap());
        uint32 const mapId = creature->GetMapId();

        if (IsTitanMap(mapId) && mode == TitanRuneMode::Alpha)
        {
            auto state = g_titanEnemies.find(CreatureKey(creature));
            if (state != g_titanEnemies.end() && state->second.stacks && now < state->second.expires)
                damage = uint32(std::min<double>(double(damage) * (1.0 + 0.01 * state->second.stacks), double(0xFFFFFFFFu)));
        }

        if (IsTitanMap(mapId) && (mode == TitanRuneMode::Beta || mode == TitanRuneMode::Gamma))
        {
            auto state = g_titanPlayers.find(PlayerKey(player));
            if (state != g_titanPlayers.end() && state->second.keepers)
            {
                damage = uint32(double(damage) * 0.80);
                if (damage >= player->GetHealth() && now >= state->second.nextHodirSave)
                {
                    damage = player->GetHealth() > 1 ? player->GetHealth() - 1 : 0;
                    state->second.nextHodirSave = now + std::chrono::seconds(25);
                    Notify(player, "Hodir's Protective Gaze prevents a fatal blow.");
                }
            }
        }

        if (IsFrostMap(mapId) && player->GetDistance(creature) <= 6.0f && ConsumeFamilyProc(creature))
        {
            StartFrostMechanic(RandomHumanPlayer(creature->GetMap(), player), mode);
        }
        else if (IsArcaneMap(mapId) && ConsumeFamilyProc(creature))
        {
            SpawnArcaneMirrors(creature, player, mode, now);
        }
        else if (IsPlagueMap(mapId) && ConsumeFamilyProc(creature))
        {
            if (Aura* aura = creature->AddAura(PLAGUE_INFECTION_SPELL, player))
            {
                aura->SetMaxDuration(60 * IN_MILLISECONDS);
                aura->SetDuration(60 * IN_MILLISECONDS);
                g_plagueInfections[PlayerKey(player)] = now + std::chrono::seconds(60);
                Notify(player, "Zombie Plague: cleanse the disease within one minute.");
            }
        }
        else if (IsGladiatorMap(mapId) && (mode == TitanRuneMode::Beta || mode == TitanRuneMode::Gamma) && ConsumeFamilyProc(creature))
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

        TimePoint const now = Clock::now();
        if (creature->GetEntry() == MIRROR_IMAGE_ENTRY && IsArcaneMap(creature->GetMapId()))
        {
            g_mirrorStates.erase(CreatureKey(creature));
            TitanRuneMode const mode = TitanRune::GetActiveMode(creature->GetMap());
            if (mode == TitanRuneMode::Beta || mode == TitanRuneMode::Gamma)
                GrantArcaneTempo(creature->GetMap(), now);
            return;
        }

        TitanRuneMode const mode = TitanRune::GetActiveMode(creature->GetMap());
        if (IsPlagueMap(creature->GetMapId()) && creature->IsDungeonBoss() &&
            (mode == TitanRuneMode::Beta || mode == TitanRuneMode::Gamma))
        {
            TempSummon* horror = creature->SummonCreature(ZOMBIE_HORROR_ENTRY,
                creature->GetPositionX() + 3.0f, creature->GetPositionY(), creature->GetPositionZ(), creature->GetOrientation(),
                TEMPSUMMON_TIMED_OR_DEAD_DESPAWN, 30 * 60 * IN_MILLISECONDS);
            if (horror)
                horror->SetInCombatWithZone();
        }
    }
};

class TitanRuneFamiliesMapScript final : public AllMapScript
{
public:
    TitanRuneFamiliesMapScript() : AllMapScript("TitanRuneFamiliesMapScript") { }

    void OnDestroyMap(Map* map) override
    {
        if (!map)
            return;
        uint64 const instanceKey = InstanceKey(map);
        uint32 const instanceId = map->GetInstanceId();
        g_plagueCaches.erase(instanceKey);
        g_grenadeCharges.erase(instanceKey);
        g_icyPatches.erase(std::remove_if(g_icyPatches.begin(), g_icyPatches.end(),
            [instanceKey](IcyPatch const& patch) { return patch.instanceKey == instanceKey; }), g_icyPatches.end());

        for (auto itr = g_familyCooldowns.begin(); itr != g_familyCooldowns.end(); )
        {
            if (uint32(itr->first >> 32) == instanceId)
                itr = g_familyCooldowns.erase(itr);
            else
                ++itr;
        }
        for (auto itr = g_mirrorStates.begin(); itr != g_mirrorStates.end(); )
        {
            if (uint32(itr->first >> 32) == instanceId)
                itr = g_mirrorStates.erase(itr);
            else
                ++itr;
        }
        for (auto itr = g_titanEnemies.begin(); itr != g_titanEnemies.end(); )
        {
            if (uint32(itr->first >> 32) == instanceId)
                itr = g_titanEnemies.erase(itr);
            else
                ++itr;
        }
    }
};

class npc_titan_holy_grenade_cache final : public CreatureScript
{
public:
    npc_titan_holy_grenade_cache() : CreatureScript("npc_titan_holy_grenade_cache") { }

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

void AddTitanRuneFamilyScripts()
{
    new TitanRuneFamiliesPlayerScript();
    new TitanRuneFamiliesUnitScript();
    new TitanRuneFamiliesMapScript();
    new npc_titan_holy_grenade_cache();
}
