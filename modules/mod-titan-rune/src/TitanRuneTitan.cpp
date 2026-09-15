#include "TitanRuneSystem.h"

#include "Chat.h"
#include "Creature.h"
#include "CreatureAI.h"
#include "Map.h"
#include "Player.h"
#include "ScriptMgr.h"
#include "ScriptedCreature.h"
#include "Spell.h"
#include "TemporarySummon.h"
#include "WorldSession.h"

#include <algorithm>
#include <chrono>
#include <cmath>
#include <cstdint>
#include <string>
#include <unordered_map>

namespace
{
using Clock = std::chrono::steady_clock;
using TimePoint = Clock::time_point;

constexpr uint32 IMMORTAL_CRUSHER_ENTRY = 900124;
constexpr uint32 INSANE_SPELL = 63120; // Stock 3.3.5 Yogg-Saron mind-control aura.
constexpr uint32 MAX_SANITY = 100;
constexpr uint32 SANITY_DRAIN = 2;
constexpr uint32 SANITY_DRAIN_SECONDS = 2;
constexpr uint32 SANITY_RESTORE = 20;
constexpr uint32 SANITY_RESTORE_SECONDS = 5;
constexpr uint32 KEEPER_PULSE_STACKS = 5;
constexpr uint32 KEEPER_STACK_SECONDS = 12;
constexpr uint32 CRUSHER_MAX_PER_INSTANCE = 4;
constexpr float CRUSHER_PROGRESS_DISTANCE = 120.0f;
constexpr float CRUSHER_SANITY_RANGE = 40.0f;
constexpr float CRUSHER_SPAWN_DISTANCE = 12.0f;

struct TitanPlayerRuntime
{
    uint8 stacks = 0;
    bool keepers = false;
    uint8 sanity = MAX_SANITY;
    bool sanityStarted = false;
    bool insane = false;
    TimePoint expires{};
    TimePoint nextStackPulse{};
    TimePoint nextSanityDrain{};
    TimePoint nextSanityRestore{};
    TimePoint lastAbility{};
    TimePoint stillSince{};
    float lastX = 0.0f;
    float lastY = 0.0f;
    float lastZ = 0.0f;
    bool havePosition = false;
};

struct TitanInstanceRuntime
{
    uint32 anchorPlayer = 0;
    uint8 crushersSpawned = 0;
    float travelSinceSpawn = 0.0f;
    float lastX = 0.0f;
    float lastY = 0.0f;
    float lastZ = 0.0f;
    bool havePosition = false;
};

struct CrusherRuntime
{
    bool meleeBroken = false;
};

std::unordered_map<uint32, TitanPlayerRuntime> g_titanPlayers;
std::unordered_map<uint64, TitanInstanceRuntime> g_titanInstances;
std::unordered_map<uint64, CrusherRuntime> g_crushers;

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

bool IsTitanMap(uint32 mapId)
{
    return mapId == 599 || mapId == 602; // Halls of Stone / Halls of Lightning
}

bool UsesPurifiedTitanRune(Player const* player)
{
    if (!player || !player->GetMap() || !IsTitanMap(player->GetMapId()))
        return false;
    TitanRuneMode const mode = TitanRune::GetActiveMode(player->GetMap());
    return mode == TitanRuneMode::Beta || mode == TitanRuneMode::Gamma;
}

void Notify(Player* player, std::string const& text)
{
    if (!IsHuman(player))
        return;
    ChatHandler(player->GetSession()).PSendSysMessage("[Titan Rune] {}", text);
}

bool HasKeeperAid(Player const* player)
{
    if (!player)
        return false;
    auto itr = g_titanPlayers.find(PlayerKey(player));
    return itr != g_titanPlayers.end() && itr->second.keepers;
}

void RefreshMaxHealth(Player* player)
{
    if (!player)
        return;
    uint32 const oldMax = std::max<uint32>(1, player->GetMaxHealth());
    uint32 const oldHealth = player->GetHealth();
    player->UpdateMaxHealth();
    uint32 const newMax = std::max<uint32>(1, player->GetMaxHealth());
    if (player->IsAlive())
    {
        uint64 scaledHealth = uint64(oldHealth) * uint64(newMax) / uint64(oldMax);
        player->SetHealth(uint32(std::min<uint64>(scaledHealth, newMax)));
    }
}

void SetKeeperAid(Player* player, TitanPlayerRuntime& state, bool enabled)
{
    if (!player || state.keepers == enabled)
        return;

    state.keepers = enabled;
    RefreshMaxHealth(player);
    if (enabled)
    {
        state.sanity = MAX_SANITY;
        state.sanityStarted = false;
        state.insane = false;
        state.nextSanityRestore = Clock::now() + std::chrono::seconds(SANITY_RESTORE_SECONDS);
        Notify(player,
            "Purified Titan Energy reached 100 stacks. Hodir, Thorim, Freya and Mimiron are assisting you: "
            "+40% damage, -20% damage taken, +20% healing received, +20% maximum health, +20% movement speed and Keeper utilities.");
    }
    else
        Notify(player, "Purified Titan Energy expired. Keeper assistance has faded.");
}

void ReportSanity(Player* player, TitanPlayerRuntime const& state)
{
    if (!player || !state.sanityStarted)
        return;
    Notify(player, "Sanity: " + std::to_string(uint32(state.sanity)) + "/100");
}

Creature* NearestCrusher(Player* player)
{
    return player ? player->FindNearestCreature(IMMORTAL_CRUSHER_ENTRY, CRUSHER_SANITY_RANGE, true) : nullptr;
}

TempSummon* SpawnCrusher(Player* player)
{
    if (!player || !player->GetMap())
        return nullptr;

    float const orientation = player->GetOrientation();
    float const x = player->GetPositionX() + std::cos(orientation) * CRUSHER_SPAWN_DISTANCE;
    float const y = player->GetPositionY() + std::sin(orientation) * CRUSHER_SPAWN_DISTANCE;
    float const z = player->GetPositionZ();

    TempSummon* crusher = player->SummonCreature(IMMORTAL_CRUSHER_ENTRY, x, y, z, orientation,
        TEMPSUMMON_TIMED_OR_DEAD_DESPAWN, 6 * HOUR * IN_MILLISECONDS);
    if (!crusher)
        return nullptr;

    g_crushers[CreatureKey(crusher)] = {};
    Notify(player,
        "An Immortal Crusher Tentacle emerges. A melee hit breaks its 99% damage suppression; "
        "at 100 Purified Titan Energy stacks, Thorim can finish it below 5% health.");
    return crusher;
}

void UpdateCrusherSpawns(Player* player)
{
    if (!IsHuman(player) || !UsesPurifiedTitanRune(player))
        return;

    uint64 const key = InstanceKey(player->GetMap());
    TitanInstanceRuntime& state = g_titanInstances[key];
    uint32 const playerKey = PlayerKey(player);
    if (!state.anchorPlayer)
        state.anchorPlayer = playerKey;
    if (state.anchorPlayer != playerKey)
        return;

    if (!state.crushersSpawned)
    {
        if (SpawnCrusher(player))
            ++state.crushersSpawned;
        state.lastX = player->GetPositionX();
        state.lastY = player->GetPositionY();
        state.lastZ = player->GetPositionZ();
        state.havePosition = true;
        return;
    }

    if (!state.havePosition)
    {
        state.lastX = player->GetPositionX();
        state.lastY = player->GetPositionY();
        state.lastZ = player->GetPositionZ();
        state.havePosition = true;
        return;
    }

    float const dx = player->GetPositionX() - state.lastX;
    float const dy = player->GetPositionY() - state.lastY;
    float const dz = player->GetPositionZ() - state.lastZ;
    float const step = std::sqrt(dx * dx + dy * dy + dz * dz);
    state.lastX = player->GetPositionX();
    state.lastY = player->GetPositionY();
    state.lastZ = player->GetPositionZ();

    // Ignore teleports/large corrections. We only want ordinary dungeon traversal to seed Crushers.
    if (step <= 40.0f)
        state.travelSinceSpawn += step;

    if (state.crushersSpawned < CRUSHER_MAX_PER_INSTANCE && state.travelSinceSpawn >= CRUSHER_PROGRESS_DISTANCE)
    {
        if (SpawnCrusher(player))
        {
            ++state.crushersSpawned;
            state.travelSinceSpawn = 0.0f;
        }
    }
}

void UpdateMovementSilence(Player* player, TitanPlayerRuntime& state, TimePoint now)
{
    if (!player)
        return;

    if (!state.havePosition)
    {
        state.lastX = player->GetPositionX();
        state.lastY = player->GetPositionY();
        state.lastZ = player->GetPositionZ();
        state.havePosition = true;
        state.stillSince = now;
        return;
    }

    float const dx = player->GetPositionX() - state.lastX;
    float const dy = player->GetPositionY() - state.lastY;
    float const dz = player->GetPositionZ() - state.lastZ;
    if ((dx * dx + dy * dy + dz * dz) > 0.25f)
        state.stillSince = now;

    state.lastX = player->GetPositionX();
    state.lastY = player->GetPositionY();
    state.lastZ = player->GetPositionZ();
}

class TitanRuneTitanPlayerScript final : public PlayerScript
{
public:
    TitanRuneTitanPlayerScript() : PlayerScript("TitanRuneTitanPlayerScript") { }

    void OnPlayerLogin(Player* player) override
    {
        if (player)
            g_titanPlayers.erase(PlayerKey(player));
    }

    void OnPlayerLogout(Player* player) override
    {
        if (player)
            g_titanPlayers.erase(PlayerKey(player));
    }

    void OnPlayerMapChanged(Player* player) override
    {
        if (player)
            g_titanPlayers.erase(PlayerKey(player));
    }

    void OnPlayerSpellCast(Player* player, Spell* /*spell*/, bool /*skipCheck*/) override
    {
        if (!player || !UsesPurifiedTitanRune(player))
            return;
        g_titanPlayers[PlayerKey(player)].lastAbility = Clock::now();
    }

    void OnPlayerAfterUpdateMaxHealth(Player* player, float& value) override
    {
        if (player && HasKeeperAid(player))
            value *= 1.20f;
    }

    void OnPlayerUpdate(Player* player, uint32 /*diff*/) override
    {
        if (!IsHuman(player) || !player->IsInWorld())
            return;

        if (!UsesPurifiedTitanRune(player))
        {
            auto existing = g_titanPlayers.find(PlayerKey(player));
            if (existing != g_titanPlayers.end())
            {
                if (existing->second.keepers)
                    SetKeeperAid(player, existing->second, false);
                g_titanPlayers.erase(existing);
            }
            return;
        }

        UpdateCrusherSpawns(player);

        uint32 const key = PlayerKey(player);
        TimePoint const now = Clock::now();
        TitanPlayerRuntime& state = g_titanPlayers[key];
        UpdateMovementSilence(player, state, now);

        if (player->IsInCombat() && now >= state.nextStackPulse)
        {
            state.stacks = std::min<uint8>(100, uint8(state.stacks + KEEPER_PULSE_STACKS));
            state.expires = now + std::chrono::seconds(KEEPER_STACK_SECONDS);
            state.nextStackPulse = now + std::chrono::seconds(1);
            if (state.stacks >= 100)
                SetKeeperAid(player, state, true);
        }
        else if (state.stacks && now >= state.expires)
        {
            state.stacks = 0;
            SetKeeperAid(player, state, false);
        }

        Creature* crusher = NearestCrusher(player);
        if (crusher)
        {
            if (!state.sanityStarted)
            {
                state.sanityStarted = true;
                state.sanity = MAX_SANITY;
                state.nextSanityDrain = now + std::chrono::seconds(SANITY_DRAIN_SECONDS);
                state.nextSanityRestore = now + std::chrono::seconds(SANITY_RESTORE_SECONDS);
                Notify(player, "Sanity: 100/100. Immortal Crusher Tentacles will slowly drain it while nearby.");
            }

            if (!state.insane && now >= state.nextSanityDrain)
            {
                uint8 const before = state.sanity;
                state.sanity = uint8(before > SANITY_DRAIN ? before - SANITY_DRAIN : 0);
                state.nextSanityDrain = now + std::chrono::seconds(SANITY_DRAIN_SECONDS);
                if (state.sanity == 0)
                {
                    state.insane = true;
                    crusher->CastSpell(player, INSANE_SPELL, true);
                    Notify(player, "Your Sanity reached 0. The Old God's influence takes control of your mind!");
                }
                else if (state.sanity == 80 || state.sanity == 60 || state.sanity == 40 || state.sanity == 20 || state.sanity <= 10)
                    ReportSanity(player, state);
            }
        }

        if (state.keepers && state.sanityStarted && !state.insane && state.sanity < MAX_SANITY && now >= state.nextSanityRestore)
        {
            bool const noAbility = state.lastAbility.time_since_epoch().count() == 0 ||
                now - state.lastAbility >= std::chrono::seconds(SANITY_RESTORE_SECONDS);
            bool const standingStill = state.stillSince.time_since_epoch().count() != 0 &&
                now - state.stillSince >= std::chrono::seconds(SANITY_RESTORE_SECONDS);
            if (noAbility && standingStill)
            {
                state.sanity = std::min<uint8>(MAX_SANITY, uint8(state.sanity + SANITY_RESTORE));
                ReportSanity(player, state);
            }
            state.nextSanityRestore = now + std::chrono::seconds(SANITY_RESTORE_SECONDS);
        }
    }
};

class TitanRuneTitanUnitScript final : public UnitScript
{
public:
    TitanRuneTitanUnitScript() : UnitScript("TitanRuneTitanUnitScript") { }

    void ModifyMeleeDamage(Unit* target, Unit* attacker, uint32& /*damage*/) override
    {
        Creature* crusher = target ? target->ToCreature() : nullptr;
        Player* player = attacker ? attacker->GetCharmerOrOwnerPlayerOrPlayerItself() : nullptr;
        if (!crusher || crusher->GetEntry() != IMMORTAL_CRUSHER_ENTRY || !player)
            return;

        CrusherRuntime& state = g_crushers[CreatureKey(crusher)];
        if (!state.meleeBroken)
        {
            state.meleeBroken = true;
            Notify(player, "Diminish Power broken by a melee hit. The Immortal Crusher now takes normal damage.");
        }
    }

    void OnDamage(Unit* attacker, Unit* victim, uint32& damage) override
    {
        if (!attacker || !victim || !damage)
            return;

        Creature* crusher = victim->ToCreature();
        Player* player = attacker->GetCharmerOrOwnerPlayerOrPlayerItself();
        if (!crusher || crusher->GetEntry() != IMMORTAL_CRUSHER_ENTRY || !player)
            return;

        CrusherRuntime& state = g_crushers[CreatureKey(crusher)];
        if (!state.meleeBroken)
            damage = std::max<uint32>(1, damage / 100); // 99% suppression until a melee hit interrupts it.
    }

    void OnUnitUpdate(Unit* unit, uint32 /*diff*/) override
    {
        Creature* crusher = unit ? unit->ToCreature() : nullptr;
        if (!crusher || crusher->GetEntry() != IMMORTAL_CRUSHER_ENTRY || !crusher->IsAlive() || !crusher->GetMap())
            return;

        if (!IsTitanMap(crusher->GetMapId()))
            return;
        TitanRuneMode const mode = TitanRune::GetActiveMode(crusher->GetMap());
        if (mode != TitanRuneMode::Beta && mode != TitanRuneMode::Gamma)
            return;

        if (crusher->GetHealth() > std::max<uint32>(1, crusher->GetMaxHealth() / 20))
            return;

        Map::PlayerList const& players = crusher->GetMap()->GetPlayers();
        for (Map::PlayerList::const_iterator itr = players.begin(); itr != players.end(); ++itr)
        {
            Player* player = itr->GetSource();
            if (!IsHuman(player) || !player->IsAlive() || !HasKeeperAid(player))
                continue;
            crusher->KillSelf(false);
            Notify(player, "Titanic Storm destroys the weakened Immortal Crusher Tentacle.");
            break;
        }
    }

    void OnUnitDeath(Unit* unit, Unit* /*killer*/) override
    {
        Creature* crusher = unit ? unit->ToCreature() : nullptr;
        if (crusher && crusher->GetEntry() == IMMORTAL_CRUSHER_ENTRY)
            g_crushers.erase(CreatureKey(crusher));
    }
};

class TitanRuneTitanMapScript final : public AllMapScript
{
public:
    TitanRuneTitanMapScript() : AllMapScript("TitanRuneTitanMapScript") { }

    void OnDestroyMap(Map* map) override
    {
        if (!map)
            return;

        uint64 const instanceKey = InstanceKey(map);
        uint32 const instanceId = map->GetInstanceId();
        g_titanInstances.erase(instanceKey);
        for (auto itr = g_crushers.begin(); itr != g_crushers.end(); )
        {
            if (uint32(itr->first >> 32) == instanceId)
                itr = g_crushers.erase(itr);
            else
                ++itr;
        }
    }
};

struct npc_titan_immortal_crusherAI final : public ScriptedAI
{
    explicit npc_titan_immortal_crusherAI(Creature* creature) : ScriptedAI(creature) { }

    void Reset() override
    {
        me->SetReactState(REACT_AGGRESSIVE);
    }

    void UpdateAI(uint32 /*diff*/) override
    {
        if (!UpdateVictim())
        {
            if (Player* target = me->SelectNearestPlayer(25.0f))
                AttackStart(target);
            return;
        }
        DoMeleeAttackIfReady();
    }
};
}

void AddTitanRuneTitanScripts()
{
    new TitanRuneTitanPlayerScript();
    new TitanRuneTitanUnitScript();
    new TitanRuneTitanMapScript();
    RegisterCreatureAI(npc_titan_immortal_crusherAI);
}
