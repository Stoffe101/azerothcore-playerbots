#ifndef MOD_TITAN_RUNE_INTERNAL_H
#define MOD_TITAN_RUNE_INTERNAL_H

#include "TitanRune.h"

#include <cstddef>
#include <cstdint>
#include <mutex>
#include <string>
#include <unordered_map>
#include <vector>

class Creature;
class Map;
class Player;
class Unit;

namespace TitanRuneInternal
{
    struct InstanceKey
    {
        uint32 mapId = 0;
        uint32 instanceId = 0;
        bool operator==(InstanceKey const& rhs) const { return mapId == rhs.mapId && instanceId == rhs.instanceId; }
    };

    struct InstanceKeyHash
    {
        std::size_t operator()(InstanceKey const& k) const noexcept
        {
            return (static_cast<std::size_t>(k.mapId) << 32) ^ static_cast<std::size_t>(k.instanceId);
        }
    };

    struct CreatureState
    {
        bool scaled = false;
        uint32 nextProc = 0;
        uint32 nextPulse = 0;
        uint8 titanStacks = 0;
        bool tentacleVulnerable = false;
    };

    struct FrostPatch
    {
        float x = 0.f, y = 0.f, z = 0.f;
        uint32 expires = 0;
    };

    struct BloodPool
    {
        float x = 0.f, y = 0.f, z = 0.f;
        uint32 expires = 0;
        bool poisoned = false;
    };

    struct InstanceState
    {
        TitanRune::Protocol protocol = TitanRune::Protocol::None;
        TitanRune::Family family = TitanRune::Family::None;
        std::unordered_map<uint64, CreatureState> creatures;
        std::vector<FrostPatch> frost;
        std::vector<BloodPool> blood;
        uint32 nextGlobalSpawn = 0;
        uint32 activatedAt = 0;
    };

    struct PlayerState
    {
        TitanRune::GammaBuff gammaBuff = TitanRune::GammaBuff::None;
        uint8 mirrorStacks = 0;
        uint32 mirrorExpires = 0;
        uint8 confessorStacks = 0;
        uint32 confessorClearAt = 0;
        uint32 rallyExpires = 0;
        uint32 shatterExpires = 0;
        uint64 shatterTarget = 0;
        uint32 brewExpires = 0;
        uint32 nextBrewTick = 0;
        uint32 fireBlastExpires = 0;
        uint32 nextFireTick = 0;
        uint32 blisteringExpires = 0;
        uint32 plagueExpires = 0;
        uint32 plagueAura = 0;
        uint8 purifiedStacks = 0;
        uint32 nextPurifiedPulse = 0;
    };

    extern std::unordered_map<InstanceKey, InstanceState, InstanceKeyHash> g_instances;
    extern std::unordered_map<uint64, PlayerState> g_players;
    extern std::mutex g_lock;

    constexpr uint32 SPELL_WEB_WRAP = 52086;
    constexpr uint32 SPELL_FROST_SLOW = 45524;
    constexpr uint32 SPELL_PLAGUE_MARK = 55095;
    constexpr uint32 ALPHA_EMBLEM = 45624;

    InstanceKey Key(Map const* map);
    InstanceKey Key(Unit const* unit);
    bool IsCustomCreature(uint32 entry);
    bool IsFinalBoss(uint32 entry);
    bool IsGammaBoss(uint32 entry);
    float HealthBonus(TitanRune::Protocol protocol, TitanRune::Family family);
    float DamageBonus(TitanRune::Protocol protocol, TitanRune::Family family);
    bool AddItem(Player* player, uint32 itemId, uint32 count);
    void Message(Player* player, std::string const& text);
    void MessageMap(Map* map, std::string const& text);
    Player* RandomAlivePlayer(Map* map);
    Creature* SummonHelper(Creature* source, uint32 entry, Player* near, uint32 despawnMs);
    bool Near(float x, float y, float z, Unit const* unit, float radius);
    void GrantMirrorStack(Map* map);
    void RewardPlayers(Creature* boss, TitanRune::Protocol protocol);
}

#endif
