#include "TitanRuneSystem.h"

#include "Chat.h"
#include "Creature.h"
#include "CreatureAI.h"
#include "Map.h"
#include "Player.h"
#include "Random.h"
#include "ScriptMgr.h"
#include "Spell.h"
#include "TemporarySummon.h"
#include "UpdateFields.h"
#include "WorldSession.h"

#include <algorithm>
#include <chrono>
#include <cstdint>
#include <cstring>
#include <string>
#include <unordered_map>
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
constexpr uint32 MAGE_LORD_UROM_ENTRY = 27655;

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

std::unordered_map<uint64, TimePoint> g_familyCooldowns;
std::vector<IcyPatch> g_icyPatches;
std::unordered_map<uint32, FrostState> g_frostStates;
std::unordered_map<uint32, TimedCrit> g_blisteringFury;
std::unordered_map<uint32, TempoState> g_arcaneTempo;
std::unordered_map<uint64, MirrorState> g_mirrorStates;

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

bool IsFrostMap(uint32 mapId)
{
    return mapId == 574 || mapId == 575;
}

bool IsArcaneMap(uint32 mapId)
{
    return mapId == 576 || mapId == 578 || mapId == 608;
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

bool IsEmpoweredArcaneExplosion(Creature* creature)
{
    if (!creature || creature->GetEntry() != MAGE_LORD_UROM_ENTRY)
        return false;

    Spell* current = creature->GetCurrentSpell(CURRENT_GENERIC_SPELL);
    if (!current || !current->GetSpellInfo())
        return false;

    char const* name = current->GetSpellInfo()->SpellName[0];
    return name && std::strcmp(name, "Empowered Arcane Explosion") == 0;
}

bool IsArcaneProcExcluded(Creature* creature)
{
    if (!creature)
        return true;

    // Blizzard's July 18, 2023 hotfix explicitly excluded Azure Ring Captains and Urom's
    // Empowered Arcane Explosion from producing protocol Mirror Images. Using the stock template
    // name for the Captain avoids hardcoding an unverified custom/database entry number.
    if (creature->GetMapId() == 578 && creature->GetName() == "Azure Ring Captain")
        return true;
    return IsEmpoweredArcaneExplosion(creature);
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

TempSummon* SpawnMirror(Creature* source, Player* initialTarget, MirrorRole role, float offset, TimePoint now)
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

void SpawnMirrors(Creature* source, Player* initialTarget, TitanRuneMode mode, TimePoint now)
{
    if (mode == TitanRuneMode::Alpha)
    {
        SpawnMirror(source, initialTarget, MirrorRole::Arcane, 1.5f, now);
        SpawnMirror(source, initialTarget, MirrorRole::Arcane, -1.5f, now);
        return;
    }

    SpawnMirror(source, initialTarget, MirrorRole::Arcane, 1.5f, now);
    SpawnMirror(source, initialTarget, MirrorRole::Melee, -1.5f, now);
    SpawnMirror(source, initialTarget, MirrorRole::Healer, 0.0f, now);
}

void ClearPlayer(Player* player)
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

    g_frostStates.erase(key);
    g_blisteringFury.erase(key);
    g_arcaneTempo.erase(key);
}

class TitanRuneFrostArcanePlayerScript final : public PlayerScript
{
public:
    TitanRuneFrostArcanePlayerScript() : PlayerScript("TitanRuneFrostArcanePlayerScript") { }

    void OnPlayerMapChanged(Player* player) override { ClearPlayer(player); }
    void OnPlayerLogout(Player* player) override { ClearPlayer(player); }

    void OnPlayerUpdate(Player* player, uint32 /*diff*/) override
    {
        if (!player || !player->IsInWorld())
            return;

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
                    uint32 const amount = std::max<uint32>(1,
                        uint32((uint64(player->GetMaxHealth()) * 6u * state.fireStacks) / 100u));
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
    }
};

class TitanRuneFrostArcaneUnitScript final : public UnitScript
{
public:
    TitanRuneFrostArcaneUnitScript() : UnitScript("TitanRuneFrostArcaneUnitScript") { }

    void OnUnitUpdate(Unit* unit, uint32 /*diff*/) override
    {
        Creature* image = unit ? unit->ToCreature() : nullptr;
        if (!image || image->GetEntry() != MIRROR_IMAGE_ENTRY)
            return;

        auto itr = g_mirrorStates.find(CreatureKey(image));
        if (itr == g_mirrorStates.end())
            return;

        TimePoint const now = Clock::now();
        if (now < itr->second.nextAction)
            return;

        Player* target = RandomHumanPlayer(image->GetMap(), nullptr);
        switch (itr->second.role)
        {
            case MirrorRole::Arcane:
                if (target)
                    image->CastSpell(target, ARCANE_MISSILE_BOLT_SPELL, true);
                itr->second.nextAction = now + std::chrono::seconds(1);
                break;
            case MirrorRole::Melee:
                if (target && image->AI())
                    image->AI()->AttackStart(target);
                itr->second.nextAction = now + std::chrono::seconds(3);
                break;
            case MirrorRole::Healer:
                image->CastSpell(image, HOLY_NOVA_SPELL, true);
                itr->second.nextAction = now + std::chrono::seconds(2);
                break;
        }
    }

    void OnDamage(Unit* attacker, Unit* victim, uint32& damage) override
    {
        if (!attacker || !victim || !damage)
            return;

        Creature* creature = attacker->ToCreature();
        Player* player = victim->ToPlayer();
        if (!creature || !player || !player->IsAlive() || !UsesActiveProtocol(creature))
            return;

        TitanRuneMode const mode = TitanRune::GetActiveMode(creature->GetMap());
        if (IsFrostMap(creature->GetMapId()) && player->GetDistance(creature) <= 6.0f && ConsumeFamilyProc(creature))
            StartFrostMechanic(RandomHumanPlayer(creature->GetMap(), player), mode);
        else if (IsArcaneMap(creature->GetMapId()) && !IsArcaneProcExcluded(creature) && ConsumeFamilyProc(creature))
            SpawnMirrors(creature, player, mode, Clock::now());
    }

    void OnUnitDeath(Unit* unit, Unit* /*killer*/) override
    {
        Creature* creature = unit ? unit->ToCreature() : nullptr;
        if (!creature || !creature->GetMap() || creature->GetEntry() != MIRROR_IMAGE_ENTRY || !IsArcaneMap(creature->GetMapId()))
            return;

        g_mirrorStates.erase(CreatureKey(creature));
        TitanRuneMode const mode = TitanRune::GetActiveMode(creature->GetMap());
        if (mode == TitanRuneMode::Beta || mode == TitanRuneMode::Gamma)
            GrantArcaneTempo(creature->GetMap(), Clock::now());
    }
};

class TitanRuneFrostArcaneMapScript final : public AllMapScript
{
public:
    TitanRuneFrostArcaneMapScript() : AllMapScript("TitanRuneFrostArcaneMapScript") { }

    void OnDestroyMap(Map* map) override
    {
        if (!map)
            return;
        uint64 const instanceKey = InstanceKey(map);
        uint32 const instanceId = map->GetInstanceId();
        g_icyPatches.erase(std::remove_if(g_icyPatches.begin(), g_icyPatches.end(),
            [instanceKey](IcyPatch const& patch) { return patch.instanceKey == instanceKey; }), g_icyPatches.end());

        for (auto itr = g_familyCooldowns.begin(); itr != g_familyCooldowns.end(); )
            itr = uint32(itr->first >> 32) == instanceId ? g_familyCooldowns.erase(itr) : ++itr;
        for (auto itr = g_mirrorStates.begin(); itr != g_mirrorStates.end(); )
            itr = uint32(itr->first >> 32) == instanceId ? g_mirrorStates.erase(itr) : ++itr;
    }
};
}

void AddTitanRuneFrostArcaneScripts()
{
    new TitanRuneFrostArcanePlayerScript();
    new TitanRuneFrostArcaneUnitScript();
    new TitanRuneFrostArcaneMapScript();
}
