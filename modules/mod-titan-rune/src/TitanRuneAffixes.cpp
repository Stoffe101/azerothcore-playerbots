#include "TitanRuneSystem.h"

#include "Creature.h"
#include "Map.h"
#include "ScriptMgr.h"
#include "Unit.h"

#include <algorithm>
#include <chrono>
#include <cmath>
#include <cstdint>
#include <mutex>
#include <vector>

namespace
{
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
    SteadyClock::time_point expiresAt;
};

std::mutex g_affixMutex;
std::vector<BloodPool> g_bloodPools;

void PruneBloodPoolsLocked(SteadyClock::time_point now)
{
    g_bloodPools.erase(std::remove_if(g_bloodPools.begin(), g_bloodPools.end(),
        [now](BloodPool const& pool) { return pool.expiresAt <= now; }), g_bloodPools.end());
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

bool IsStandingInBloodOfTheLoa(Creature const* creature)
{
    if (!CreatureUsesActiveFamily(creature, TitanRuneFamily::Blood))
        return false;

    uint64 const instanceKey = InstanceKey(creature->GetMap());
    float const x = creature->GetPositionX();
    float const y = creature->GetPositionY();
    float const z = creature->GetPositionZ();
    SteadyClock::time_point const now = SteadyClock::now();

    std::lock_guard<std::mutex> lock(g_affixMutex);
    PruneBloodPoolsLocked(now);

    for (BloodPool const& pool : g_bloodPools)
    {
        if (pool.instanceKey != instanceKey)
            continue;

        float const dx = x - pool.x;
        float const dy = y - pool.y;
        float const dz = z - pool.z;
        if ((dx * dx + dy * dy + dz * dz) <= 25.0f) // 5-yard Blood of the Loa radius
            return true;
    }

    return false;
}

void ClearAffixStateForMap(Map const* map)
{
    if (!map || !map->GetInstanceId())
        return;

    uint64 const key = InstanceKey(map);
    std::lock_guard<std::mutex> lock(g_affixMutex);
    g_bloodPools.erase(std::remove_if(g_bloodPools.begin(), g_bloodPools.end(),
        [key](BloodPool const& pool) { return pool.instanceKey == key; }), g_bloodPools.end());
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
        if (!creature || !IsStandingInBloodOfTheLoa(creature) || !creature->IsAlive())
            return;

        // Blood Rune: 100% lifesteal while the enemy is standing in Blood of the Loa.
        uint32 const health = creature->GetHealth();
        uint32 const maxHealth = creature->GetMaxHealth();
        if (health >= maxHealth)
            return;

        uint32 const missing = maxHealth - health;
        uint32 const heal = std::min<uint32>(damage, missing);
        creature->ModifyHealth(int32(heal));
    }

    void OnUnitDeath(Unit* unit, Unit* /*killer*/) override
    {
        Creature* creature = unit ? unit->ToCreature() : nullptr;
        if (!creature)
            return;

        // Every defeated hostile creature in the Blood family leaves Blood of the Loa for 10 sec.
        CreateBloodPool(creature);
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
}

void AddTitanRuneAffixScripts()
{
    new TitanRuneAffixUnitScript();
    new TitanRuneAffixMapScript();
}
