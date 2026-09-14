#include "TitanRuneSystem.h"

#include "Creature.h"
#include "Map.h"
#include "Player.h"
#include "Random.h"
#include "ScriptMgr.h"
#include "Unit.h"

#include <chrono>
#include <cstdint>
#include <mutex>
#include <unordered_map>

namespace
{
constexpr uint32 SHADOW_WEB_WRAP_SPELL = 71010;
constexpr uint32 SHADOW_PROC_CHANCE = 35;
constexpr uint32 SHADOW_INTERNAL_COOLDOWN_SECONDS = 30;

using SteadyClock = std::chrono::steady_clock;

std::mutex g_shadowMutex;
std::unordered_map<uint64, SteadyClock::time_point> g_shadowNextProc;

bool IsShadowMap(uint32 mapId)
{
    return mapId == 601 || mapId == 619; // Azjol-Nerub / Ahn'kahet: The Old Kingdom
}

uint64 CreatureKey(Creature const* creature)
{
    if (!creature || !creature->GetMap())
        return 0;
    return (uint64(creature->GetMap()->GetInstanceId()) << 32) | uint64(creature->GetGUID().GetCounter());
}

bool IsHadronoxHotfixExcluded(Creature const* creature)
{
    if (!creature || creature->GetMapId() != 601)
        return false;

    // Blizzard's July 11, 2023 Titan Rune hotfix excluded Hadronox-gauntlet minions and
    // Skittering Swarmers from Shadow Rune/web-wrap behavior. These are the stock 3.3.5
    // entries used by those waves. Keeping the exclusion entry-based also prevents a stray
    // gauntlet add from gaining the affix if it is pulled onto the party.
    switch (creature->GetEntry())
    {
        case 28735: // Skittering Swarmer
        case 28736: // Skittering Infector
        case 29117: // Anub'ar Champion (gauntlet wave)
        case 29118: // Anub'ar Crypt Fiend (gauntlet wave)
        case 29119: // Anub'ar Necromancer (gauntlet wave)
            return true;
        default:
            return false;
    }
}

bool UsesShadowProtocol(Creature const* creature)
{
    if (!creature || !creature->IsInWorld() || creature->IsControlledByPlayer() || !creature->IsHostileToPlayers())
        return false;

    Map* map = creature->GetMap();
    if (!map || !IsShadowMap(map->GetId()) || IsHadronoxHotfixExcluded(creature))
        return false;

    TitanRuneMode const mode = TitanRune::GetActiveMode(map);
    return mode == TitanRuneMode::Alpha || mode == TitanRuneMode::Beta || mode == TitanRuneMode::Gamma;
}

bool ConsumeShadowProc(Creature* creature)
{
    if (!creature)
        return false;

    uint64 const key = CreatureKey(creature);
    SteadyClock::time_point const now = SteadyClock::now();

    {
        std::lock_guard<std::mutex> lock(g_shadowMutex);
        auto itr = g_shadowNextProc.find(key);
        if (itr != g_shadowNextProc.end() && now < itr->second)
            return false;
    }

    if (!roll_chance_i(SHADOW_PROC_CHANCE))
        return false;

    std::lock_guard<std::mutex> lock(g_shadowMutex);
    g_shadowNextProc[key] = now + std::chrono::seconds(SHADOW_INTERNAL_COOLDOWN_SECONDS);
    return true;
}

void ClearShadowStateForMap(Map const* map)
{
    if (!map || !map->GetInstanceId())
        return;

    uint32 const instanceId = map->GetInstanceId();
    std::lock_guard<std::mutex> lock(g_shadowMutex);
    for (auto itr = g_shadowNextProc.begin(); itr != g_shadowNextProc.end(); )
    {
        if (uint32(itr->first >> 32) == instanceId)
            itr = g_shadowNextProc.erase(itr);
        else
            ++itr;
    }
}

class TitanRuneShadowUnitScript final : public UnitScript
{
public:
    TitanRuneShadowUnitScript() : UnitScript("TitanRuneShadowUnitScript") { }

    void OnDamage(Unit* attacker, Unit* victim, uint32& damage) override
    {
        if (!attacker || !victim || damage == 0)
            return;

        Creature* creature = attacker->ToCreature();
        Player* player = victim->ToPlayer();
        if (!creature || !player || !player->IsAlive() || !UsesShadowProtocol(creature))
            return;

        // The original WotLK Web Wrap implementation provides exactly the behavior we need:
        // a 10-second stun plus a killable Web Wrap summon that releases its victim when killed.
        // Reusing spell 71010 keeps that interaction client-visible without introducing a
        // Classic-only 3.4.x spell record into a 3.3.5 client.
        if (player->HasAura(SHADOW_WEB_WRAP_SPELL) || !ConsumeShadowProc(creature))
            return;

        creature->CastSpell(player, SHADOW_WEB_WRAP_SPELL, true);
    }
};

class TitanRuneShadowMapScript final : public AllMapScript
{
public:
    TitanRuneShadowMapScript() : AllMapScript("TitanRuneShadowMapScript") { }

    void OnDestroyMap(Map* map) override
    {
        ClearShadowStateForMap(map);
    }
};
}

void AddTitanRuneShadowScripts()
{
    new TitanRuneShadowUnitScript();
    new TitanRuneShadowMapScript();
}
