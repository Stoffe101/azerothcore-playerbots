#include "TitanRuneSystem.h"

#include "Chat.h"
#include "Creature.h"
#include "Map.h"
#include "Player.h"
#include "Random.h"
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
constexpr uint32 FLASH_FREEZE_SPELL = 64175; // Hodir's save visual/immunity from the original Ulduar encounter.
constexpr uint32 FORTITUDE_OF_FROST_SPELL = 62650;
constexpr uint32 RESILIENCE_OF_NATURE_SPELL = 62670;
constexpr uint32 SPEED_OF_INVENTION_SPELL = 62671;
constexpr uint32 FURY_OF_THE_STORM_SPELL = 62702;
constexpr uint32 DESTABILIZATION_MATRIX_SPELL = 65210;
constexpr uint32 IMMORTAL_CRUSHER_HEALTH = 1981707; // Wrath Classic heroic value.
constexpr uint8 MAX_SANITY = 100;
constexpr uint8 SANITY_DRAIN = 2;
constexpr uint8 SANITY_RESTORE = 20;
constexpr uint32 SANITY_DRAIN_SECONDS = 2;
constexpr uint32 SANITY_RESTORE_SECONDS = 5;
constexpr uint32 MANA_RESTORE_SECONDS = 5;
constexpr uint8 MANA_RESTORE_PERCENT = 15;
constexpr uint8 KEEPER_PULSE_STACKS = 5;
constexpr uint32 KEEPER_STACK_SECONDS = 12;
constexpr uint8 CRUSHER_MAX_PER_INSTANCE = 4;
constexpr float CRUSHER_PROGRESS_DISTANCE = 120.0f;
constexpr float CRUSHER_SANITY_RANGE = 40.0f;
constexpr float CRUSHER_SPAWN_DISTANCE = 12.0f;

struct TitanPlayerRuntime
{
    uint8 stacks = 0;
    bool keepers = false;
    bool hodirSaveAvailable = false;
    uint8 sanity = MAX_SANITY;
    bool sanityStarted = false;
    bool insane = false;
    TimePoint expires{};
    TimePoint nextStackPulse{};
    TimePoint nextSanityDrain{};
    TimePoint nextSanityRestore{};
    TimePoint nextManaRestore{};
    TimePoint lastAbility{};
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
    uint64 instanceKey = 0;
    bool diminishActive = true;
    bool fixedHealthApplied = false;
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

Player* ControllingPlayer(Unit* unit)
{
    if (!unit)
        return nullptr;
    if (Player* player = unit->ToPlayer())
        return player;
    return unit->GetCharmerOrOwnerPlayerOrPlayerItself();
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

bool InstanceHasDiminishPower(Map const* map)
{
    if (!map)
        return false;
    uint64 const key = InstanceKey(map);
    for (auto const& pair : g_crushers)
        if (pair.second.instanceKey == key && pair.second.diminishActive)
            return true;
    return false;
}

void ReducePlayerDamage(Map const* map, uint32& damage)
{
    if (damage && InstanceHasDiminishPower(map))
        damage = std::max<uint32>(1, damage / 100); // Wrath Classic Titan Rune: 99% reduced damage dealt.
}

void RemoveKeeperAuras(Player* player)
{
    if (!player)
        return;
    player->RemoveAurasDueToSpell(FORTITUDE_OF_FROST_SPELL);
    player->RemoveAurasDueToSpell(RESILIENCE_OF_NATURE_SPELL);
    player->RemoveAurasDueToSpell(SPEED_OF_INVENTION_SPELL);
    player->RemoveAurasDueToSpell(FURY_OF_THE_STORM_SPELL);
}

void ApplyKeeperAuras(Player* player)
{
    if (!player)
        return;

    // These four spells are native 3.3.5 Ulduar Keeper auras. Reusing them gives the backport the
    // exact original +10% damage from each Keeper, -20% damage taken, +20% healing received,
    // +20% movement speed and +20% maximum health without inventing client-side DBC records.
    player->AddAura(FORTITUDE_OF_FROST_SPELL, player);
    player->AddAura(RESILIENCE_OF_NATURE_SPELL, player);
    player->AddAura(SPEED_OF_INVENTION_SPELL, player);
    player->AddAura(FURY_OF_THE_STORM_SPELL, player);
}

void SetKeeperAid(Player* player, TitanPlayerRuntime& state, bool enabled)
{
    if (!player || state.keepers == enabled)
        return;

    state.keepers = enabled;
    if (enabled)
    {
        ApplyKeeperAuras(player);
        state.hodirSaveAvailable = true;
        state.sanity = MAX_SANITY;
        state.sanityStarted = false;
        state.insane = false;
        TimePoint const now = Clock::now();
        state.nextSanityRestore = now + std::chrono::seconds(SANITY_RESTORE_SECONDS);
        state.nextManaRestore = now + std::chrono::seconds(MANA_RESTORE_SECONDS);
        Notify(player,
            "Purified Titan Energy reaches 100 stacks. The four Keepers answer: +40% damage, 20% less damage taken, +20% healing received, +20% movement speed and +20% maximum health. Resilience restores mana/Sanity, Hodir can save one fatal blow, and Titanic Storm can finish weakened Crushers.");
    }
    else
    {
        RemoveKeeperAuras(player);
        state.hodirSaveAvailable = false;
    }
}

void ClearPlayerState(Player* player)
{
    if (!player)
        return;
    auto itr = g_titanPlayers.find(PlayerKey(player));
    if (itr == g_titanPlayers.end())
    {
        RemoveKeeperAuras(player);
        return;
    }
    if (itr->second.keepers)
        SetKeeperAid(player, itr->second, false);
    else
        RemoveKeeperAuras(player);
    g_titanPlayers.erase(itr);
}

void ReportSanity(Player* player, TitanPlayerRuntime const& state)
{
    if (player && state.sanityStarted)
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
    TempSummon* crusher = player->SummonCreature(IMMORTAL_CRUSHER_ENTRY, x, y, player->GetPositionZ(), orientation,
        TEMPSUMMON_TIMED_OR_DEAD_DESPAWN, 6 * HOUR * IN_MILLISECONDS);
    if (!crusher)
        return nullptr;

    CrusherRuntime& state = g_crushers[CreatureKey(crusher)];
    state.instanceKey = InstanceKey(player->GetMap());
    crusher->SetInCombatWithZone();
    Notify(player,
        "An Immortal Crusher Tentacle emerges. Its Diminish Power reduces all player damage by 99% until a melee attack interrupts the channel.");
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

    float const x = player->GetPositionX();
    float const y = player->GetPositionY();
    float const z = player->GetPositionZ();
    if (!state.havePosition)
    {
        state.lastX = x;
        state.lastY = y;
        state.lastZ = z;
        state.havePosition = true;
        return;
    }

    float const dx = x - state.lastX;
    float const dy = y - state.lastY;
    float const dz = z - state.lastZ;
    float const step = std::sqrt(dx * dx + dy * dy + dz * dz);
    state.lastX = x;
    state.lastY = y;
    state.lastZ = z;
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

class TitanRuneTitanPlayerScript final : public PlayerScript
{
public:
    TitanRuneTitanPlayerScript() : PlayerScript("TitanRuneTitanPlayerScript") { }

    void OnPlayerLogin(Player* player) override
    {
        if (!player)
            return;
        g_titanPlayers.erase(PlayerKey(player));
        RemoveKeeperAuras(player); // Clean up a persisted aura after an abnormal previous shutdown.
    }

    void OnPlayerLogout(Player* player) override
    {
        ClearPlayerState(player);
    }

    void OnPlayerMapChanged(Player* player) override
    {
        ClearPlayerState(player);
    }

    void OnPlayerSpellCast(Player* player, Spell* /*spell*/, bool /*skipCheck*/) override
    {
        if (player && UsesPurifiedTitanRune(player))
            g_titanPlayers[PlayerKey(player)].lastAbility = Clock::now();
    }

    void OnPlayerUpdate(Player* player, uint32 /*diff*/) override
    {
        if (!IsHuman(player) || !player->IsInWorld())
            return;
        if (!UsesPurifiedTitanRune(player))
        {
            ClearPlayerState(player);
            return;
        }

        UpdateCrusherSpawns(player);
        TimePoint const now = Clock::now();
        TitanPlayerRuntime& state = g_titanPlayers[PlayerKey(player)];

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
                Notify(player, "Sanity: 100/100. Living Immortal Crushers slowly drain it.");
            }
            if (!state.insane && now >= state.nextSanityDrain)
            {
                state.sanity = state.sanity > SANITY_DRAIN ? uint8(state.sanity - SANITY_DRAIN) : 0;
                state.nextSanityDrain = now + std::chrono::seconds(SANITY_DRAIN_SECONDS);
                if (!state.sanity)
                {
                    state.insane = true;
                    crusher->CastSpell(player, INSANE_SPELL, true);
                    Notify(player, "Sanity reached 0. The Old God's influence takes control of your mind!");
                }
                else if (state.sanity == 80 || state.sanity == 60 || state.sanity == 40 || state.sanity == 20 || state.sanity <= 10)
                    ReportSanity(player, state);
            }
        }

        if (!state.keepers)
            return;

        // Defense Protocol Beta/Gamma's Resilience of Nature restores 15% maximum mana every 5 sec.
        if (now >= state.nextManaRestore)
        {
            uint32 const maxMana = player->GetMaxPower(POWER_MANA);
            if (maxMana)
            {
                uint32 const current = player->GetPower(POWER_MANA);
                uint32 const restored = std::max<uint32>(1, uint32(uint64(maxMana) * MANA_RESTORE_PERCENT / 100));
                player->SetPower(POWER_MANA, std::min<uint32>(maxMana, current + restored));
            }
            state.nextManaRestore = now + std::chrono::seconds(MANA_RESTORE_SECONDS);
        }

        // The Classic backport tooltip requires five seconds without a spell/ability. Movement does
        // not cancel this recovery, so do not incorrectly require the player to stand still.
        if (state.sanityStarted && !state.insane && state.sanity < MAX_SANITY && now >= state.nextSanityRestore)
        {
            bool const noAbility = state.lastAbility.time_since_epoch().count() == 0 ||
                now - state.lastAbility >= std::chrono::seconds(SANITY_RESTORE_SECONDS);
            if (noAbility)
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
        Player* player = ControllingPlayer(attacker);
        if (!player || !UsesPurifiedTitanRune(player))
            return;

        Creature* crusher = target ? target->ToCreature() : nullptr;
        if (crusher && crusher->GetEntry() == IMMORTAL_CRUSHER_ENTRY)
        {
            CrusherRuntime& state = g_crushers[CreatureKey(crusher)];
            state.instanceKey = InstanceKey(crusher->GetMap());
            if (state.diminishActive)
            {
                state.diminishActive = false;
                Notify(player, "Melee contact interrupts Diminish Power. Player damage returns to normal unless another Crusher is still channeling.");
            }
        }
    }

    void OnDamage(Unit* attacker, Unit* victim, uint32& damage) override
    {
        if (!damage || !victim)
            return;

        Player* attackingPlayer = ControllingPlayer(attacker);
        if (attackingPlayer && UsesPurifiedTitanRune(attackingPlayer) && attacker != victim)
        {
            // Apply Diminish Power once at the final generic damage hook so melee, direct spells,
            // periodic effects, pets and unusual class abilities cannot be reduced twice or escape it.
            ReducePlayerDamage(attackingPlayer->GetMap(), damage);

            Creature* targetCreature = victim->ToCreature();
            if (targetCreature && targetCreature->GetEntry() == IMMORTAL_CRUSHER_ENTRY &&
                HasKeeperAid(attackingPlayer) && !targetCreature->HasAura(DESTABILIZATION_MATRIX_SPELL) && urand(1, 100) <= 10)
            {
                attackingPlayer->CastSpell(targetCreature, DESTABILIZATION_MATRIX_SPELL, true);
                Notify(attackingPlayer, "Speed of Invention destabilizes the Immortal Crusher's Saronite structure.");
            }
        }

        Creature* crusher = victim->ToCreature();
        if (crusher && crusher->GetEntry() == IMMORTAL_CRUSHER_ENTRY && crusher->IsAlive())
        {
            // Immortal means exactly that until Titanic Storm executes the weakened tentacle.
            if (damage >= crusher->GetHealth())
                damage = crusher->GetHealth() > 1 ? crusher->GetHealth() - 1 : 0;
            return;
        }

        Player* victimPlayer = victim->ToPlayer();
        if (!victimPlayer || !UsesPurifiedTitanRune(victimPlayer) || !HasKeeperAid(victimPlayer) ||
            damage < victimPlayer->GetHealth())
            return;

        auto itr = g_titanPlayers.find(PlayerKey(victimPlayer));
        if (itr == g_titanPlayers.end() || !itr->second.hodirSaveAvailable)
            return;

        // Defense Protocol's Hodir aid is a single safety net for this 100-stack Keeper empowerment.
        // Clamp the lethal hit at 1 HP and use the native Ulduar Flash Freeze for the 10-sec immunity.
        itr->second.hodirSaveAvailable = false;
        damage = victimPlayer->GetHealth() > 1 ? victimPlayer->GetHealth() - 1 : 0;
        victimPlayer->CastSpell(victimPlayer, FLASH_FREEZE_SPELL, true);
        Notify(victimPlayer, "Hodir's Protective Gaze prevents a fatal blow. His save is spent until the Keepers answer again.");
    }

    void OnUnitUpdate(Unit* unit, uint32 /*diff*/) override
    {
        Creature* crusher = unit ? unit->ToCreature() : nullptr;
        if (!crusher || crusher->GetEntry() != IMMORTAL_CRUSHER_ENTRY || !crusher->IsAlive() || !crusher->GetMap())
            return;

        CrusherRuntime& crusherState = g_crushers[CreatureKey(crusher)];
        crusherState.instanceKey = InstanceKey(crusher->GetMap());

        // The custom NPC is excluded conceptually from ordinary protocol mob scaling. Force the
        // known Wrath Classic heroic value once after the core/module scaling pass has seen it.
        if (!crusherState.fixedHealthApplied)
        {
            uint32 const oldMax = std::max<uint32>(1, crusher->GetMaxHealth());
            uint32 const oldHealth = crusher->GetHealth();
            crusher->SetMaxHealth(IMMORTAL_CRUSHER_HEALTH);
            crusher->SetHealth(oldHealth >= oldMax ? IMMORTAL_CRUSHER_HEALTH :
                std::max<uint32>(1, uint32(uint64(oldHealth) * IMMORTAL_CRUSHER_HEALTH / oldMax)));
            crusherState.fixedHealthApplied = true;
        }

        if (crusher->GetHealth() > std::max<uint32>(1, crusher->GetMaxHealth() / 20))
            return;

        Map::PlayerList const& players = crusher->GetMap()->GetPlayers();
        for (Map::PlayerList::const_iterator itr = players.begin(); itr != players.end(); ++itr)
        {
            Player* player = itr->GetSource();
            if (!IsHuman(player) || !player->IsAlive() || !HasKeeperAid(player))
                continue;
            crusherState.diminishActive = false;
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
        uint64 const key = InstanceKey(map);
        g_titanInstances.erase(key);
        for (auto itr = g_crushers.begin(); itr != g_crushers.end(); )
            itr = itr->second.instanceKey == key ? g_crushers.erase(itr) : ++itr;
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
