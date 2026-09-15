#include "TitanRuneSystem.h"

#include "Map.h"
#include "Player.h"
#include "ScriptMgr.h"
#include "WorldSession.h"

#include <algorithm>
#include <chrono>
#include <cstdint>
#include <unordered_map>

namespace
{
using Clock = std::chrono::steady_clock;
using TimePoint = Clock::time_point;

constexpr uint8 STACKS_PER_PULSE = 5;
constexpr uint32 STACK_DURATION_SECONDS = 12;

struct PurifiedEnergyState
{
    uint8 stacks = 0;
    TimePoint expires{};
    TimePoint nextPulse{};
};

std::unordered_map<uint32, PurifiedEnergyState> g_purifiedEnergy;

uint32 PlayerKey(Player const* player)
{
    return player ? player->GetGUID().GetCounter() : 0;
}

bool IsHuman(Player const* player)
{
    return player && player->GetSession() && !player->GetSession()->IsBot();
}

bool IsTitanMap(uint32 mapId)
{
    return mapId == 599 || mapId == 602;
}

bool UsesPurifiedEnergy(Player const* player)
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

class TitanRunePurifiedEnergyPlayerScript final : public PlayerScript
{
public:
    TitanRunePurifiedEnergyPlayerScript() : PlayerScript("TitanRunePurifiedEnergyPlayerScript") { }

    void OnPlayerLogin(Player* player) override
    {
        if (player)
            g_purifiedEnergy.erase(PlayerKey(player));
    }

    void OnPlayerLogout(Player* player) override
    {
        if (player)
            g_purifiedEnergy.erase(PlayerKey(player));
    }

    void OnPlayerMapChanged(Player* player) override
    {
        if (player)
            g_purifiedEnergy.erase(PlayerKey(player));
    }

    void OnPlayerUpdate(Player* player, uint32 /*diff*/) override
    {
        if (!IsHuman(player) || !player->IsInWorld())
            return;

        uint32 const key = PlayerKey(player);
        if (!UsesPurifiedEnergy(player))
        {
            g_purifiedEnergy.erase(key);
            return;
        }

        TimePoint const now = Clock::now();
        PurifiedEnergyState& state = g_purifiedEnergy[key];
        if (player->IsInCombat() && now >= state.nextPulse)
        {
            state.stacks = std::min<uint8>(100, uint8(state.stacks + STACKS_PER_PULSE));
            state.expires = now + std::chrono::seconds(STACK_DURATION_SECONDS);
            state.nextPulse = now + std::chrono::seconds(1);
        }
        else if (state.stacks && now >= state.expires)
            state.stacks = 0;
    }
};

class TitanRunePurifiedEnergyUnitScript final : public UnitScript
{
public:
    TitanRunePurifiedEnergyUnitScript() : UnitScript("TitanRunePurifiedEnergyUnitScript") { }

    void OnDamage(Unit* attacker, Unit* victim, uint32& damage) override
    {
        if (!attacker || !victim || !damage || attacker == victim)
            return;

        Player* player = ControllingPlayer(attacker);
        if (!player || !UsesPurifiedEnergy(player))
            return;

        auto itr = g_purifiedEnergy.find(PlayerKey(player));
        if (itr == g_purifiedEnergy.end() || !itr->second.stacks || Clock::now() >= itr->second.expires)
            return;

        damage = uint32(std::min<double>(
            double(damage) * (1.0 + 0.01 * double(itr->second.stacks)), double(0xFFFFFFFFu)));
    }
};
}

void AddTitanRunePurifiedEnergyScripts()
{
    new TitanRunePurifiedEnergyPlayerScript();
    new TitanRunePurifiedEnergyUnitScript();
}
