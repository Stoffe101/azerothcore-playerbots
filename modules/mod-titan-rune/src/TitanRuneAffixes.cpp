#include "TitanRuneSystem.h"

#include "Chat.h"
#include "CommandScript.h"
#include "Creature.h"
#include "GameObject.h"
#include "Map.h"
#include "Player.h"
#include "ScriptMgr.h"
#include "Unit.h"
#include "WorldSession.h"

#include <algorithm>
#include <chrono>
#include <cmath>
#include <cstdint>
#include <mutex>
#include <unordered_map>
#include <unordered_set>
#include <vector>

using namespace Acore::ChatCommands;

namespace
{
constexpr uint32 MYSTERIOUS_CAULDRON_ENTRY = 900120;
constexpr uint32 CAULDRON_LIFETIME_SECONDS = 24 * 60 * 60;

enum class TitanRuneFamily : uint8
{
    None = 0,
    Frost,
    Shadow,
    Blood,
    Titan,
    Arcane,
    Plague,
    Gladiator,
};

enum class BloodPoolState : uint8
{
    None = 0,
    Clean,
    Poisoned,
};

TitanRuneFamily FamilyForMap(uint32 mapId)
{
    switch (mapId)
    {
        case 574: // Utgarde Keep
        case 575: // Utgarde Pinnacle
            return TitanRuneFamily::Frost;
        case 601: // Azjol-Nerub
        case 619: // Ahn'kahet: The Old Kingdom
            return TitanRuneFamily::Shadow;
        case 600: // Drak'Tharon Keep
        case 604: // Gundrak
            return TitanRuneFamily::Blood;
        case 599: // Halls of Stone
        case 602: // Halls of Lightning
            return TitanRuneFamily::Titan;
        case 576: // The Nexus
        case 578: // The Oculus
        case 608: // The Violet Hold
            return TitanRuneFamily::Arcane;
        case 595: // The Culling of Stratholme
            return TitanRuneFamily::Plague;
        case 650: // Trial of the Champion
            return TitanRuneFamily::Gladiator;
        default:
            return TitanRuneFamily::None;
    }
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

using SteadyClock = std::chrono::steady_clock;

// Blood of the Loa in Wrath Classic is a 5-yard persistent area lasting 10 seconds. We model
// the gameplay server-side so it works with an unmodified 3.3.5 client and does not depend on
// Classic-only spell records that do not exist in the Wrath DBC files.
struct BloodPool
{
    uint64 instanceKey = 0;
    float x = 0.0f;
    float y = 0.0f;
    float z = 0.0f;
    bool poisoned = false;
    SteadyClock::time_point expiresAt;
};

struct BrewState
{
    SteadyClock::time_point expiresAt;
    SteadyClock::time_point nextDamageAt;
};

std::mutex g_affixMutex;
std::vector<BloodPool> g_bloodPools;
std::unordered_map<uint32, BrewState> g_brewStates;
std::unordered_map<uint64, SteadyClock::time_point> g_poisonDamageTicks;
std::unordered_set<uint64> g_bloodEntranceCauldronInstances;
std::unordered_set<uint64> g_bloodBossCauldrons;

void NotifyPlayer(Player* player, std::string const& message)
{
    if (!player || !player->GetSession())
        return;
    ChatHandler(player->GetSession()).PSendSysMessage("[Titan Rune] {}", message);
}

void PruneBloodPoolsLocked(SteadyClock::time_point now)
{
    g_bloodPools.erase(std::remove_if(g_bloodPools.begin(), g_bloodPools.end(),
        [now](BloodPool const& pool) { return pool.expiresAt <= now; }), g_bloodPools.end());
}

void PruneBrewStateLocked(uint32 guid, SteadyClock::time_point now)
{
    auto itr = g_brewStates.find(guid);
    if (itr != g_brewStates.end() && itr->second.expiresAt <= now)
        g_brewStates.erase(itr);
}

bool CreatureUsesActiveFamily(Creature const* creature, TitanRuneFamily family)
{
    if (!creature || !creature->IsInWorld() || creature->IsControlledByPlayer() || !creature->IsHostileToPlayers())
        return false;

    Map* map = creature->GetMap();
    if (!map || FamilyForMap(map->GetId()) != family)
        return false;

    return TitanRune::GetActiveMode(map) != TitanRuneMode::Off;
}

bool IsActiveBloodBetaOrGamma(Map const* map)
{
    if (!map || FamilyForMap(map->GetId()) != TitanRuneFamily::Blood)
        return false;

    TitanRuneMode const mode = TitanRune::GetActiveMode(map);
    return mode == TitanRuneMode::Beta || mode == TitanRuneMode::Gamma;
}

bool WithinBloodPool(float x, float y, float z, BloodPool const& pool)
{
    float const dx = x - pool.x;
    float const dy = y - pool.y;
    float const dz = z - pool.z;
    return (dx * dx + dy * dy + dz * dz) <= 25.0f; // 5-yard radius
}

GameObject* SummonMysteriousCauldron(WorldObject* source, float x, float y, float z, float orientation)
{
    if (!source || !source->IsInWorld())
        return nullptr;

    float const half = orientation * 0.5f;
    return source->SummonGameObject(MYSTERIOUS_CAULDRON_ENTRY, x, y, z, orientation,
        0.0f, 0.0f, std::sin(half), std::cos(half), CAULDRON_LIFETIME_SECONDS);
}

void EnsureEntranceCauldron(Player* player)
{
    if (!player || !player->IsInWorld() || !player->GetSession() || player->GetSession()->IsBot() ||
        !IsActiveBloodBetaOrGamma(player->GetMap()))
        return;

    uint64 const key = InstanceKey(player->GetMap());
    {
        std::lock_guard<std::mutex> lock(g_affixMutex);
        if (!g_bloodEntranceCauldronInstances.insert(key).second)
            return;
    }

    // Spawn at the first real player's actual entrance location instead of hard-coding coordinates.
    // This keeps the feature correct across both Drak'Tharon and Gundrak and across DB revisions.
    float const orientation = player->GetOrientation();
    float const x = player->GetPositionX() + std::cos(orientation) * 2.0f;
    float const y = player->GetPositionY() + std::sin(orientation) * 2.0f;
    if (!SummonMysteriousCauldron(player, x, y, player->GetPositionZ(), orientation))
    {
        std::lock_guard<std::mutex> lock(g_affixMutex);
        g_bloodEntranceCauldronInstances.erase(key);
    }
}

void SpawnBossCauldron(Creature* boss)
{
    if (!boss || !boss->IsDungeonBoss() || !IsActiveBloodBetaOrGamma(boss->GetMap()))
        return;

    uint64 const key = CreatureKey(boss);
    {
        std::lock_guard<std::mutex> lock(g_affixMutex);
        if (!g_bloodBossCauldrons.insert(key).second)
            return;
    }

    if (!SummonMysteriousCauldron(boss, boss->GetPositionX(), boss->GetPositionY(), boss->GetPositionZ(), boss->GetOrientation()))
    {
        std::lock_guard<std::mutex> lock(g_affixMutex);
        g_bloodBossCauldrons.erase(key);
    }
}

void CreateBloodPool(Creature* creature)
{
    if (!CreatureUsesActiveFamily(creature, TitanRuneFamily::Blood))
        return;

    BloodPool pool;
    pool.instanceKey = InstanceKey(creature->GetMap());
    pool.x = creature->GetPositionX();
    pool.y = creature->GetPositionY();
    pool.z = creature->GetPositionZ();
    pool.expiresAt = SteadyClock::now() + std::chrono::seconds(10);

    std::lock_guard<std::mutex> lock(g_affixMutex);
    PruneBloodPoolsLocked(SteadyClock::now());
    g_bloodPools.push_back(pool);
}

BloodPoolState BloodPoolStateAt(Creature const* creature)
{
    if (!CreatureUsesActiveFamily(creature, TitanRuneFamily::Blood))
        return BloodPoolState::None;

    uint64 const instanceKey = InstanceKey(creature->GetMap());
    float const x = creature->GetPositionX();
    float const y = creature->GetPositionY();
    float const z = creature->GetPositionZ();
    SteadyClock::time_point const now = SteadyClock::now();

    std::lock_guard<std::mutex> lock(g_affixMutex);
    PruneBloodPoolsLocked(now);

    bool clean = false;
    for (BloodPool const& pool : g_bloodPools)
    {
        if (pool.instanceKey != instanceKey || !WithinBloodPool(x, y, z, pool))
            continue;
        if (pool.poisoned)
            return BloodPoolState::Poisoned;
        clean = true;
    }

    return clean ? BloodPoolState::Clean : BloodPoolState::None;
}

bool GrantBloodBrew(Player* player)
{
    if (!player || !player->IsInWorld() || !IsActiveBloodBetaOrGamma(player->GetMap()))
        return false;

    SteadyClock::time_point const now = SteadyClock::now();
    std::lock_guard<std::mutex> lock(g_affixMutex);
    g_brewStates[player->GetGUID().GetCounter()] =
        BrewState{now + std::chrono::minutes(5), now + std::chrono::seconds(5)};
    return true;
}

bool HasBloodBrew(Player* player)
{
    if (!player)
        return false;

    uint32 const guid = player->GetGUID().GetCounter();
    SteadyClock::time_point const now = SteadyClock::now();
    std::lock_guard<std::mutex> lock(g_affixMutex);
    PruneBrewStateLocked(guid, now);
    return g_brewStates.find(guid) != g_brewStates.end();
}

void PoisonBloodPoolsTouchedBy(Player* player)
{
    if (!player || !player->IsAlive() || !IsActiveBloodBetaOrGamma(player->GetMap()) || !HasBloodBrew(player))
        return;

    uint64 const instanceKey = InstanceKey(player->GetMap());
    float const x = player->GetPositionX();
    float const y = player->GetPositionY();
    float const z = player->GetPositionZ();
    SteadyClock::time_point const now = SteadyClock::now();

    std::lock_guard<std::mutex> lock(g_affixMutex);
    PruneBloodPoolsLocked(now);
    for (BloodPool& pool : g_bloodPools)
    {
        if (pool.instanceKey == instanceKey && WithinBloodPool(x, y, z, pool))
            pool.poisoned = true;
    }
}

void TickBloodBrew(Player* player)
{
    if (!player || !player->IsAlive())
        return;

    uint32 const guid = player->GetGUID().GetCounter();
    SteadyClock::time_point const now = SteadyClock::now();
    bool dealDamage = false;

    {
        std::lock_guard<std::mutex> lock(g_affixMutex);
        PruneBrewStateLocked(guid, now);
        auto itr = g_brewStates.find(guid);
        if (itr == g_brewStates.end())
            return;

        if (now >= itr->second.nextDamageAt)
        {
            dealDamage = true;
            itr->second.nextDamageAt = now + std::chrono::seconds(5);
        }
    }

    // Witch Doctor's Brew: 5% maximum health Nature-style self-damage every 5 seconds.
    // It is implemented as deterministic server damage because the Classic aura is absent in 3.3.5 DBCs.
    if (dealDamage)
    {
        uint32 const amount = std::max<uint32>(1, uint32(std::ceil(double(player->GetMaxHealth()) * 0.05)));
        if (player->GetHealth() <= amount)
            player->KillSelf(false);
        else
            player->ModifyHealth(-int32(amount));
    }

    PoisonBloodPoolsTouchedBy(player);
}

void TickPoisonedBlood(Creature* creature)
{
    if (!creature || !creature->IsAlive())
        return;

    uint64 const key = CreatureKey(creature);
    BloodPoolState const state = BloodPoolStateAt(creature);
    if (state != BloodPoolState::Poisoned)
    {
        std::lock_guard<std::mutex> lock(g_affixMutex);
        g_poisonDamageTicks.erase(key);
        return;
    }

    SteadyClock::time_point const now = SteadyClock::now();
    bool dealDamage = false;
    {
        std::lock_guard<std::mutex> lock(g_affixMutex);
        auto [itr, inserted] = g_poisonDamageTicks.emplace(key, now);
        if (now >= itr->second)
        {
            dealDamage = true;
            itr->second = now + std::chrono::seconds(1);
        }
    }

    if (!dealDamage)
        return;

    // Poisoned Blood of the Loa damages enemies for 1% maximum health each second and suppresses
    // the normal Blood Rune lifesteal while they remain in the poisoned pool.
    uint32 const amount = std::max<uint32>(1, uint32(std::ceil(double(creature->GetMaxHealth()) * 0.01)));
    if (creature->GetHealth() <= amount)
        creature->KillSelf(false);
    else
        creature->ModifyHealth(-int32(amount));
}

void ClearAffixStateForMap(Map const* map)
{
    if (!map || !map->GetInstanceId())
        return;

    uint64 const key = InstanceKey(map);
    uint32 const instanceId = map->GetInstanceId();
    std::lock_guard<std::mutex> lock(g_affixMutex);
    g_bloodPools.erase(std::remove_if(g_bloodPools.begin(), g_bloodPools.end(),
        [key](BloodPool const& pool) { return pool.instanceKey == key; }), g_bloodPools.end());
    g_bloodEntranceCauldronInstances.erase(key);

    for (auto itr = g_poisonDamageTicks.begin(); itr != g_poisonDamageTicks.end(); )
    {
        if (uint32(itr->first >> 32) == instanceId)
            itr = g_poisonDamageTicks.erase(itr);
        else
            ++itr;
    }

    for (auto itr = g_bloodBossCauldrons.begin(); itr != g_bloodBossCauldrons.end(); )
    {
        if (uint32(*itr >> 32) == instanceId)
            itr = g_bloodBossCauldrons.erase(itr);
        else
            ++itr;
    }
}

class TitanRuneAffixUnitScript final : public UnitScript
{
public:
    TitanRuneAffixUnitScript() : UnitScript("TitanRuneAffixUnitScript") { }

    void OnDamage(Unit* attacker, Unit* /*victim*/, uint32& damage) override
    {
        if (!attacker || damage == 0)
            return;

        Creature* creature = attacker->ToCreature();
        if (!creature || !creature->IsAlive())
            return;

        // Blood Rune: enemies have 100% lifesteal while standing in clean Blood of the Loa.
        // Poisoned Blood explicitly suppresses this healing.
        if (BloodPoolStateAt(creature) != BloodPoolState::Clean)
            return;

        uint32 const health = creature->GetHealth();
        uint32 const maxHealth = creature->GetMaxHealth();
        if (health >= maxHealth)
            return;

        uint32 const missing = maxHealth - health;
        uint32 const heal = std::min<uint32>(damage, missing);
        creature->ModifyHealth(int32(heal));
    }

    void OnUnitUpdate(Unit* unit, uint32 /*diff*/) override
    {
        Creature* creature = unit ? unit->ToCreature() : nullptr;
        if (creature && CreatureUsesActiveFamily(creature, TitanRuneFamily::Blood))
            TickPoisonedBlood(creature);
    }

    void OnUnitDeath(Unit* unit, Unit* /*killer*/) override
    {
        Creature* creature = unit ? unit->ToCreature() : nullptr;
        if (!creature)
            return;

        // Every defeated hostile creature in the Blood family leaves Blood of the Loa for 10 sec.
        CreateBloodPool(creature);

        // Beta/Gamma place another Mysterious Cauldron after every boss.
        SpawnBossCauldron(creature);
    }
};

class TitanRuneAffixPlayerScript final : public PlayerScript
{
public:
    TitanRuneAffixPlayerScript() : PlayerScript("TitanRuneAffixPlayerScript") { }

    void OnPlayerLogin(Player* player) override
    {
        EnsureEntranceCauldron(player);
    }

    void OnPlayerMapChanged(Player* player) override
    {
        EnsureEntranceCauldron(player);
    }

    void OnPlayerUpdate(Player* player, uint32 /*diff*/) override
    {
        // Fallback for hook ordering: if the protocol was activated by another PlayerScript during
        // the same map change, the first update guarantees that the entrance cauldron appears.
        EnsureEntranceCauldron(player);
        TickBloodBrew(player);
    }

    void OnPlayerLogout(Player* player) override
    {
        if (!player)
            return;
        std::lock_guard<std::mutex> lock(g_affixMutex);
        g_brewStates.erase(player->GetGUID().GetCounter());
    }
};

class TitanRuneAffixMapScript final : public AllMapScript
{
public:
    TitanRuneAffixMapScript() : AllMapScript("TitanRuneAffixMapScript") { }

    void OnDestroyMap(Map* map) override
    {
        ClearAffixStateForMap(map);
    }
};

class go_titan_blood_cauldron final : public GameObjectScript
{
public:
    go_titan_blood_cauldron() : GameObjectScript("go_titan_blood_cauldron") { }

    bool OnGossipHello(Player* player, GameObject* /*gameObject*/) override
    {
        if (!GrantBloodBrew(player))
        {
            NotifyPlayer(player, "The Mysterious Cauldron only responds during an active Blood-family Beta/Gamma protocol.");
            return true;
        }

        NotifyPlayer(player,
            "Witch Doctor's Brew refreshed for 5 minutes. It costs 5% maximum health every 5 seconds; step in Blood of the Loa to poison the pool.");
        return true;
    }
};

// GM-only diagnostic fallback. Normal gameplay obtains Brew by clicking a Mysterious Cauldron.
class TitanRuneAffixCommandScript final : public CommandScript
{
public:
    TitanRuneAffixCommandScript() : CommandScript("TitanRuneAffixCommandScript") { }

    ChatCommandTable GetCommands() const override
    {
        static ChatCommandTable root =
        {
            { "bloodbrew", HandleBloodBrew, SEC_GAMEMASTER, Console::No },
        };
        return root;
    }

    static bool HandleBloodBrew(ChatHandler* handler)
    {
        Player* player = handler && handler->GetSession() ? handler->GetSession()->GetPlayer() : nullptr;
        if (!player)
            return true;

        if (!GrantBloodBrew(player))
        {
            handler->SendSysMessage("[Titan Rune] Witch Doctor's Brew is only available inside an active Blood-family Beta/Gamma dungeon.");
            return true;
        }

        handler->SendSysMessage("[Titan Rune] Witch Doctor's Brew active for 5 minutes: 5% max health every 5 sec; step in Blood of the Loa to poison it.");
        return true;
    }
};
}

void AddTitanRuneAffixScripts()
{
    new TitanRuneAffixUnitScript();
    new TitanRuneAffixPlayerScript();
    new TitanRuneAffixMapScript();
    new go_titan_blood_cauldron();
    new TitanRuneAffixCommandScript();
}
