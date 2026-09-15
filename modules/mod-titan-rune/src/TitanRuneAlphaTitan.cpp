#include "TitanRuneSystem.h"

#include "Creature.h"
#include "Map.h"
#include "Player.h"
#include "ScriptMgr.h"

#include <algorithm>
#include <chrono>
#include <cstdint>
#include <unordered_map>

namespace
{
using Clock = std::chrono::steady_clock;
using TimePoint = Clock::time_point;

struct TitanEnemyState
{
    uint8 stacks = 0;
    TimePoint expires{};
    TimePoint nextPulse{};
};

std::unordered_map<uint64, TitanEnemyState> g_alphaTitanEnemies;

uint64 CreatureKey(Creature const* creature)
{
    if (!creature || !creature->GetMap())
        return 0;
    return (uint64(creature->GetMap()->GetInstanceId()) << 32) | uint64(creature->GetGUID().GetCounter());
}

bool IsTitanMap(uint32 mapId)
{
    return mapId == 599 || mapId == 602; // Halls of Stone / Halls of Lightning
}

bool UsesAlphaTitan(Creature const* creature)
{
    return creature && creature->IsInWorld() && !creature->IsControlledByPlayer() && creature->IsHostileToPlayers() &&
        IsTitanMap(creature->GetMapId()) && TitanRune::GetActiveMode(creature->GetMap()) == TitanRuneMode::Alpha;
}

class TitanRuneAlphaTitanUnitScript final : public UnitScript
{
public:
    TitanRuneAlphaTitanUnitScript() : UnitScript("TitanRuneAlphaTitanUnitScript") { }

    void OnUnitUpdate(Unit* unit, uint32 /*diff*/) override
    {
        Creature* creature = unit ? unit->ToCreature() : nullptr;
        if (!UsesAlphaTitan(creature))
            return;

        TimePoint const now = Clock::now();
        TitanEnemyState& state = g_alphaTitanEnemies[CreatureKey(creature)];
        if (creature->IsInCombat() && now >= state.nextPulse)
        {
            state.stacks = std::min<uint8>(100, uint8(state.stacks + 1));
            state.expires = now + std::chrono::seconds(12);
            state.nextPulse = now + std::chrono::seconds(1);
        }
        else if (state.stacks && now >= state.expires)
            state.stacks = 0;
    }

    void OnDamage(Unit* attacker, Unit* victim, uint32& damage) override
    {
        if (!attacker || !victim || !damage)
            return;

        TimePoint const now = Clock::now();
        if (attacker->ToPlayer())
        {
            Creature* enemy = victim->ToCreature();
            if (enemy && UsesAlphaTitan(enemy))
            {
                auto itr = g_alphaTitanEnemies.find(CreatureKey(enemy));
                if (itr != g_alphaTitanEnemies.end() && itr->second.stacks && now < itr->second.expires)
                    damage = uint32(std::min<double>(double(damage) * (1.0 + 0.02 * itr->second.stacks), double(0xFFFFFFFFu)));
            }
        }

        Creature* enemy = attacker->ToCreature();
        Player* player = victim->ToPlayer();
        if (!enemy || !player || !player->IsAlive() || !UsesAlphaTitan(enemy))
            return;

        auto itr = g_alphaTitanEnemies.find(CreatureKey(enemy));
        if (itr != g_alphaTitanEnemies.end() && itr->second.stacks && now < itr->second.expires)
            damage = uint32(std::min<double>(double(damage) * (1.0 + 0.01 * itr->second.stacks), double(0xFFFFFFFFu)));
    }

    void OnUnitDeath(Unit* unit, Unit* /*killer*/) override
    {
        Creature* creature = unit ? unit->ToCreature() : nullptr;
        if (creature && IsTitanMap(creature->GetMapId()))
            g_alphaTitanEnemies.erase(CreatureKey(creature));
    }
};

class TitanRuneAlphaTitanMapScript final : public AllMapScript
{
public:
    TitanRuneAlphaTitanMapScript() : AllMapScript("TitanRuneAlphaTitanMapScript") { }

    void OnDestroyMap(Map* map) override
    {
        if (!map)
            return;
        uint32 const instanceId = map->GetInstanceId();
        for (auto itr = g_alphaTitanEnemies.begin(); itr != g_alphaTitanEnemies.end(); )
        {
            if (uint32(itr->first >> 32) == instanceId)
                itr = g_alphaTitanEnemies.erase(itr);
            else
                ++itr;
        }
    }
};
}

void AddTitanRuneAlphaTitanScripts()
{
    new TitanRuneAlphaTitanUnitScript();
    new TitanRuneAlphaTitanMapScript();
}
