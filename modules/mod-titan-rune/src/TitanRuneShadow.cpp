#include "TitanRuneSystem.h"

#include "Creature.h"
#include "Map.h"
#include "Player.h"
#include "Random.h"
#include "ScriptMgr.h"
#include "Spell.h"
#include "SpellInfo.h"
#include "Unit.h"

#include <algorithm>
#include <chrono>
#include <cstdint>
#include <mutex>
#include <unordered_map>
#include <vector>

namespace
{
constexpr uint32 SHADOW_WEB_WRAP_SPELL = 71010;
constexpr uint32 SHADOW_PROC_CHANCE = 35;
constexpr uint32 SHADOW_INTERNAL_COOLDOWN_SECONDS = 30;
constexpr uint32 SHADOW_IMBUEMENT_CAST_WINDOW_SECONDS = 5;
constexpr uint32 SHADOW_IMBUEMENT_AOE_WINDOW_MS = 500;

using SteadyClock = std::chrono::steady_clock;
using TimePoint = SteadyClock::time_point;

struct ImbuedCast
{
    uint32 spellId = 0;
    TimePoint expires{};
    TimePoint effectWindowExpires{};
    bool activated = false;
};

struct ShadowPlayerState
{
    uint8 charges = 0;
    bool wrapped = false;
    TimePoint nextCharge{};
    std::vector<ImbuedCast> casts;
};

std::mutex g_shadowMutex;
std::unordered_map<uint64, TimePoint> g_shadowNextProc;
std::unordered_map<uint32, ShadowPlayerState> g_shadowPlayers;

bool IsShadowMap(uint32 mapId)
{
    return mapId == 601 || mapId == 619; // Azjol-Nerub / Ahn'kahet: The Old Kingdom
}

bool UsesShadowImbuement(Player const* player)
{
    if (!player || !player->IsInWorld() || !player->GetMap() || !IsShadowMap(player->GetMapId()))
        return false;

    TitanRuneMode const mode = TitanRune::GetActiveMode(player->GetMap());
    return mode == TitanRuneMode::Beta || mode == TitanRuneMode::Gamma;
}

uint32 PlayerKey(Player const* player)
{
    return player ? player->GetGUID().GetCounter() : 0;
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
    TimePoint const now = SteadyClock::now();

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

void PruneImbuedCasts(ShadowPlayerState& state, TimePoint now)
{
    state.casts.erase(std::remove_if(state.casts.begin(), state.casts.end(),
        [now](ImbuedCast const& cast)
        {
            return cast.activated ? now >= cast.effectWindowExpires : now >= cast.expires;
        }), state.casts.end());
}

void TrackImbuedCast(Player* player, Spell* spell)
{
    if (!player || !spell || !UsesShadowImbuement(player) || spell->IsTriggered())
        return;

    SpellInfo const* spellInfo = spell->GetSpellInfo();
    if (!spellInfo || spellInfo->IsPassive())
        return;

    TimePoint const now = SteadyClock::now();
    std::lock_guard<std::mutex> lock(g_shadowMutex);
    auto itr = g_shadowPlayers.find(PlayerKey(player));
    if (itr == g_shadowPlayers.end() || !itr->second.charges)
        return;

    ShadowPlayerState& state = itr->second;
    PruneImbuedCasts(state, now);
    state.casts.push_back({spellInfo->Id, now + std::chrono::seconds(SHADOW_IMBUEMENT_CAST_WINDOW_SECONDS), {}, false});
}

bool ConsumeImbuementForEffect(Player* player, uint32 spellId)
{
    if (!player || !spellId || !UsesShadowImbuement(player))
        return false;

    TimePoint const now = SteadyClock::now();
    std::lock_guard<std::mutex> lock(g_shadowMutex);
    auto stateItr = g_shadowPlayers.find(PlayerKey(player));
    if (stateItr == g_shadowPlayers.end())
        return false;

    ShadowPlayerState& state = stateItr->second;
    PruneImbuedCasts(state, now);

    // Once a cast has spent one charge, every target hit by that same cast during the short
    // effect window receives the duplicated effect. This is what prevents an AoE ability from
    // consuming one Shadow Imbuement charge per target, matching Blizzard's June 2023 fix.
    for (ImbuedCast& cast : state.casts)
        if (cast.activated && cast.spellId == spellId && now < cast.effectWindowExpires)
            return true;

    if (!state.charges)
        return false;

    for (ImbuedCast& cast : state.casts)
    {
        if (cast.activated || cast.spellId != spellId || now >= cast.expires)
            continue;

        --state.charges;
        cast.activated = true;
        cast.effectWindowExpires = now + std::chrono::milliseconds(SHADOW_IMBUEMENT_AOE_WINDOW_MS);
        return true;
    }

    return false;
}

void ClearShadowPlayerState(Player const* player)
{
    if (!player)
        return;
    std::lock_guard<std::mutex> lock(g_shadowMutex);
    g_shadowPlayers.erase(PlayerKey(player));
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

class TitanRuneShadowPlayerScript final : public PlayerScript
{
public:
    TitanRuneShadowPlayerScript() : PlayerScript("TitanRuneShadowPlayerScript") { }

    void OnPlayerMapChanged(Player* player) override
    {
        ClearShadowPlayerState(player);
    }

    void OnPlayerLogout(Player* player) override
    {
        ClearShadowPlayerState(player);
    }

    void OnPlayerSpellCast(Player* player, Spell* spell, bool /*skipCheck*/) override
    {
        TrackImbuedCast(player, spell);
    }

    void OnPlayerUpdate(Player* player, uint32 /*diff*/) override
    {
        if (!player)
            return;

        if (!player->IsAlive() || !UsesShadowImbuement(player))
        {
            ClearShadowPlayerState(player);
            return;
        }

        uint32 const key = PlayerKey(player);
        TimePoint const now = SteadyClock::now();
        bool const wrapped = player->HasAura(SHADOW_WEB_WRAP_SPELL);

        std::lock_guard<std::mutex> lock(g_shadowMutex);
        ShadowPlayerState& state = g_shadowPlayers[key];
        PruneImbuedCasts(state, now);

        if (!wrapped)
        {
            state.wrapped = false;
            state.nextCharge = {};
            return;
        }

        if (!state.wrapped)
        {
            state.wrapped = true;
            state.nextCharge = now + std::chrono::seconds(1);
        }

        // Beta/Gamma Shadow Rune grants one stacking Shadow Imbuement charge for every full
        // second spent Web Wrapped. Charges persist after the wrap and are consumed by later
        // damaging/healing abilities.
        while (now >= state.nextCharge)
        {
            if (state.charges < 250)
                ++state.charges;
            state.nextCharge += std::chrono::seconds(1);
        }
    }
};

class TitanRuneShadowUnitScript final : public UnitScript
{
public:
    TitanRuneShadowUnitScript() : UnitScript("TitanRuneShadowUnitScript") { }

    void ModifySpellDamageTaken(Unit* /*target*/, Unit* attacker, int32& damage, SpellInfo const* spellInfo) override
    {
        Player* player = attacker ? attacker->ToPlayer() : nullptr;
        if (!player || !spellInfo || damage <= 0 || !ConsumeImbuementForEffect(player, spellInfo->Id))
            return;

        damage = int32(std::min<double>(double(damage) * 2.50, double(0x7FFFFFFF)));
    }

    void ModifyHealReceived(Unit* /*target*/, Unit* healer, uint32& heal, SpellInfo const* spellInfo) override
    {
        Player* player = healer ? healer->ToPlayer() : nullptr;
        if (!player || !spellInfo || !heal || !ConsumeImbuementForEffect(player, spellInfo->Id))
            return;

        heal = uint32(std::min<double>(double(heal) * 2.50, double(0xFFFFFFFFu)));
    }

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
    new TitanRuneShadowPlayerScript();
    new TitanRuneShadowUnitScript();
    new TitanRuneShadowMapScript();
}
