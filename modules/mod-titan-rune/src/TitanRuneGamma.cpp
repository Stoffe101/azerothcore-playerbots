#include "TitanRuneSystem.h"

#include "Chat.h"
#include "Creature.h"
#include "Group.h"
#include "Item.h"
#include "Map.h"
#include "Player.h"
#include "Random.h"
#include "ScriptMgr.h"
#include "ScriptedGossip.h"
#include "TemporarySummon.h"
#include "Unit.h"
#include "UpdateFields.h"
#include "WorldSession.h"

#include <algorithm>
#include <chrono>
#include <cstdint>
#include <mutex>
#include <unordered_map>
#include <unordered_set>

namespace
{
using Clock = std::chrono::steady_clock;
using TimePoint = Clock::time_point;

constexpr uint32 GAMMA_WARDEN_ALLIANCE_ENTRY = 900120;
constexpr uint32 GAMMA_WARDEN_HORDE_ENTRY = 900121;
constexpr uint32 GAMMA_SIGNET_ALLIANCE_ITEM = 900104;
constexpr uint32 GAMMA_SIGNET_HORDE_ITEM = 900105;
constexpr float SHATTER_PROC_CHANCE = 20.0f;
constexpr float RALLY_PROC_CHANCE = 15.0f;
constexpr float RALLY_HASTE_PERCENT = 20.0f;
constexpr uint32 THORNS_MIN_DAMAGE = 1000;
constexpr uint32 THORNS_MAX_DAMAGE = 1400;
constexpr uint32 SIGNET_COOLDOWN_SECONDS = 120;
constexpr uint32 SIGNET_RETRY_SECONDS = 10;

enum class GammaBuff : uint8
{
    None = 0,
    Shatter = 1,
    Rally = 2,
    Confessor = 3,
    Thorns = 4,
};

struct RallyState
{
    bool applied = false;
    TimePoint expires{};
};

struct ConfessorState
{
    uint8 stacks = 0;
    TimePoint expires{};
    TimePoint lockedUntil{};
};

std::mutex g_gammaMutex;
std::unordered_map<uint32, GammaBuff> g_playerBuffs;
std::unordered_map<uint64, TimePoint> g_shatteredTargets;
std::unordered_map<uint32, RallyState> g_rallyStates;
std::unordered_map<uint32, TimePoint> g_rallyProcCooldowns;
std::unordered_map<uint32, ConfessorState> g_confessorStates;
std::unordered_map<uint32, TimePoint> g_signetCooldowns;
std::unordered_map<uint32, TimePoint> g_signetRetryAt;
std::unordered_set<uint64> g_wardenInstances;

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

uint64 InstanceKey(Map const* map)
{
    if (!map)
        return 0;
    return (uint64(map->GetId()) << 32) | uint64(map->GetInstanceId());
}

bool IsFrozenHalls(uint32 mapId)
{
    return mapId == 632 || mapId == 658 || mapId == 668;
}

bool IsHuman(Player const* player)
{
    return player && player->GetSession() && !player->GetSession()->IsBot();
}

bool IsGammaGameplayMap(Player const* player)
{
    return player && player->GetMap() && TitanRune::GetActiveMode(player->GetMap()) == TitanRuneMode::Gamma &&
        !IsFrozenHalls(player->GetMapId());
}

uint32 WardenEntryFor(Player const* player)
{
    return player && player->GetTeamId() == TEAM_ALLIANCE ? GAMMA_WARDEN_ALLIANCE_ENTRY : GAMMA_WARDEN_HORDE_ENTRY;
}

uint32 SignetEntryFor(Player const* player)
{
    return player && player->GetTeamId() == TEAM_ALLIANCE ? GAMMA_SIGNET_ALLIANCE_ITEM : GAMMA_SIGNET_HORDE_ITEM;
}

void Notify(Player* player, char const* text)
{
    if (!IsHuman(player))
        return;
    ChatHandler(player->GetSession()).PSendSysMessage("[Titan Rune] {}", text);
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

void ClearPlayerState(Player* player)
{
    if (!player)
        return;

    uint32 const key = PlayerKey(player);
    auto rally = g_rallyStates.find(key);
    if (rally != g_rallyStates.end() && rally->second.applied)
        ApplyHaste(player, RALLY_HASTE_PERCENT, false);

    g_playerBuffs.erase(key);
    g_rallyStates.erase(key);
    g_rallyProcCooldowns.erase(key);
    g_confessorStates.erase(key);
    g_signetCooldowns.erase(key);
    g_signetRetryAt.erase(key);
}

bool SummonWarden(Player* player, bool portable)
{
    if (!IsHuman(player) || !player->IsInWorld() || !IsGammaGameplayMap(player))
        return false;

    uint32 const entry = WardenEntryFor(player);
    if (portable)
    {
        if (player->FindNearestCreature(entry, 40.0f, true))
        {
            Notify(player, "Your faction Warden is already nearby.");
            return false;
        }
    }
    else
    {
        uint64 const key = InstanceKey(player->GetMap());
        std::lock_guard<std::mutex> lock(g_gammaMutex);
        if (!g_wardenInstances.insert(key).second)
            return false;
    }

    TempSummon* warden = player->SummonCreature(entry,
        player->GetPositionX() + 2.0f, player->GetPositionY(), player->GetPositionZ(), player->GetOrientation(),
        TEMPSUMMON_TIMED_OR_DEAD_DESPAWN, (portable ? 2 * MINUTE : 6 * HOUR) * IN_MILLISECONDS);
    if (!warden)
    {
        if (!portable)
        {
            std::lock_guard<std::mutex> lock(g_gammaMutex);
            g_wardenInstances.erase(InstanceKey(player->GetMap()));
        }
        return false;
    }

    if (portable)
        Notify(player, "Your Gamma signet summons the faction Warden. You may change your helper buff while the Warden is here.");
    else
        Notify(player, "A faction Titan Rune Warden is available at the entrance with the four Defense Protocol Gamma helper buffs.");
    return true;
}

void EnsureGammaSignet(Player* player)
{
    if (!IsHuman(player) || !IsGammaGameplayMap(player))
        return;

    uint32 const itemEntry = SignetEntryFor(player);
    if (player->GetItemCount(itemEntry, false) > 0)
        return;

    uint32 const key = PlayerKey(player);
    TimePoint const now = Clock::now();
    {
        std::lock_guard<std::mutex> lock(g_gammaMutex);
        TimePoint& retry = g_signetRetryAt[key];
        if (now < retry)
            return;
        retry = now + std::chrono::seconds(SIGNET_RETRY_SECONDS);
    }

    if (player->AddItem(itemEntry, 1))
        Notify(player, "You receive your faction Gamma signet. Use it inside this Gamma dungeon to summon the Warden; the signet has a 2-minute summon cooldown.");
}

void GrantRally(Player* source, TimePoint now)
{
    if (!source || !source->GetMap())
        return;

    Group* group = source->GetGroup();
    Map::PlayerList const& players = source->GetMap()->GetPlayers();
    for (Map::PlayerList::const_iterator itr = players.begin(); itr != players.end(); ++itr)
    {
        Player* player = itr->GetSource();
        if (!IsHuman(player) || !player->IsAlive())
            continue;
        if (group && player->GetGroup() != group)
            continue;
        if (!group && player != source)
            continue;

        uint32 const key = PlayerKey(player);
        RallyState& state = g_rallyStates[key];
        if (!state.applied)
        {
            ApplyHaste(player, RALLY_HASTE_PERCENT, true);
            state.applied = true;
        }
        state.expires = now + std::chrono::seconds(10);
        Notify(player, "Rallying Cry: +20% haste for 10 seconds.");
    }
}

class TitanRuneGammaPlayerScript final : public PlayerScript
{
public:
    TitanRuneGammaPlayerScript() : PlayerScript("TitanRuneGammaPlayerScript") { }

    void OnPlayerLogin(Player* player) override
    {
        SummonWarden(player, false);
        EnsureGammaSignet(player);
    }

    void OnPlayerMapChanged(Player* player) override
    {
        {
            std::lock_guard<std::mutex> lock(g_gammaMutex);
            ClearPlayerState(player);
        }
        SummonWarden(player, false);
        EnsureGammaSignet(player);
    }

    void OnPlayerLogout(Player* player) override
    {
        std::lock_guard<std::mutex> lock(g_gammaMutex);
        ClearPlayerState(player);
    }

    void OnPlayerUpdate(Player* player, uint32 /*diff*/) override
    {
        if (!player)
            return;

        SummonWarden(player, false);
        EnsureGammaSignet(player);
        uint32 const key = PlayerKey(player);
        TimePoint const now = Clock::now();
        std::lock_guard<std::mutex> lock(g_gammaMutex);

        auto rally = g_rallyStates.find(key);
        if (rally != g_rallyStates.end() && rally->second.applied && now >= rally->second.expires)
        {
            ApplyHaste(player, RALLY_HASTE_PERCENT, false);
            g_rallyStates.erase(rally);
        }

        auto confessor = g_confessorStates.find(key);
        if (confessor != g_confessorStates.end() && confessor->second.stacks && now >= confessor->second.expires)
            confessor->second.stacks = 0;
    }
};

class TitanRuneGammaUnitScript final : public UnitScript
{
public:
    TitanRuneGammaUnitScript() : UnitScript("TitanRuneGammaUnitScript") { }

    void OnHeal(Unit* healer, Unit* /*receiver*/, uint32& /*gain*/) override
    {
        Player* player = healer ? healer->ToPlayer() : nullptr;
        if (!player || TitanRune::GetActiveMode(player->GetMap()) != TitanRuneMode::Gamma)
            return;

        uint32 const key = PlayerKey(player);
        TimePoint const now = Clock::now();
        std::lock_guard<std::mutex> lock(g_gammaMutex);
        auto role = g_playerBuffs.find(key);
        if (role == g_playerBuffs.end() || role->second != GammaBuff::Confessor)
            return;

        ConfessorState& state = g_confessorStates[key];
        if (now < state.lockedUntil)
            return;
        state.stacks = std::min<uint8>(5, uint8(state.stacks + 1));
        state.expires = TimePoint::max();
    }

    void OnDamage(Unit* attacker, Unit* victim, uint32& damage) override
    {
        if (!attacker || !victim || damage == 0)
            return;

        TimePoint const now = Clock::now();
        Player* player = attacker->ToPlayer();
        Creature* creature = victim->ToCreature();
        if (player && creature && TitanRune::GetActiveMode(player->GetMap()) == TitanRuneMode::Gamma)
        {
            std::lock_guard<std::mutex> lock(g_gammaMutex);
            uint32 const key = PlayerKey(player);

            auto shattered = g_shatteredTargets.find(CreatureKey(creature));
            if (shattered != g_shatteredTargets.end())
            {
                if (now < shattered->second)
                    damage = uint32(std::min<double>(double(damage) * 1.20, double(0xFFFFFFFFu)));
                else
                    g_shatteredTargets.erase(shattered);
            }

            auto role = g_playerBuffs.find(key);
            if (role != g_playerBuffs.end())
            {
                if (role->second == GammaBuff::Shatter && player->GetDistance(creature) <= 6.0f && roll_chance_f(SHATTER_PROC_CHANCE))
                {
                    g_shatteredTargets[CreatureKey(creature)] = now + std::chrono::seconds(10);
                    Notify(player, "Shatter Defenses: target takes 20% increased damage for 10 seconds.");
                }
                else if (role->second == GammaBuff::Rally && player->GetDistance(creature) > 6.0f)
                {
                    TimePoint& cooldown = g_rallyProcCooldowns[key];
                    if (now >= cooldown && roll_chance_f(RALLY_PROC_CHANCE))
                    {
                        cooldown = now + std::chrono::seconds(10);
                        GrantRally(player, now);
                    }
                }
                else if (role->second == GammaBuff::Confessor)
                {
                    ConfessorState& state = g_confessorStates[key];
                    if (state.stacks && now < state.expires)
                    {
                        damage = uint32(std::min<double>(double(damage) * (1.0 + 0.20 * state.stacks), double(0xFFFFFFFFu)));
                        state.expires = now + std::chrono::seconds(5);
                        state.lockedUntil = now + std::chrono::seconds(30);
                    }
                }
            }
        }

        Creature* enemy = attacker->ToCreature();
        Player* tank = victim->ToPlayer();
        if (!enemy || !tank || TitanRune::GetActiveMode(tank->GetMap()) != TitanRuneMode::Gamma)
            return;

        bool retaliate = false;
        {
            std::lock_guard<std::mutex> lock(g_gammaMutex);
            auto role = g_playerBuffs.find(PlayerKey(tank));
            if (role != g_playerBuffs.end() && role->second == GammaBuff::Thorns)
            {
                // The pinned core does not expose a post-dodge/parry/block UnitScript callback.
                // Approximate the live proc using the player's actual combined avoidance chance,
                // while keeping the documented live 1000-1400 damage range exact.
                float const avoidance = std::min<float>(75.0f,
                    tank->GetFloatValue(PLAYER_DODGE_PERCENTAGE) + tank->GetFloatValue(PLAYER_PARRY_PERCENTAGE) +
                    tank->GetFloatValue(PLAYER_BLOCK_PERCENTAGE));
                retaliate = roll_chance_f(avoidance);
            }
        }
        if (retaliate)
            Unit::DealDamage(tank, enemy, urand(THORNS_MIN_DAMAGE, THORNS_MAX_DAMAGE), nullptr,
                DIRECT_DAMAGE, SPELL_SCHOOL_MASK_NATURE, nullptr, false);
    }
};

class TitanRuneGammaMapScript final : public AllMapScript
{
public:
    TitanRuneGammaMapScript() : AllMapScript("TitanRuneGammaMapScript") { }

    void OnDestroyMap(Map* map) override
    {
        if (!map)
            return;
        uint64 const instanceKey = InstanceKey(map);
        uint32 const instanceId = map->GetInstanceId();
        std::lock_guard<std::mutex> lock(g_gammaMutex);
        g_wardenInstances.erase(instanceKey);
        for (auto itr = g_shatteredTargets.begin(); itr != g_shatteredTargets.end(); )
        {
            if (uint32(itr->first >> 32) == instanceId)
                itr = g_shatteredTargets.erase(itr);
            else
                ++itr;
        }
    }
};

class npc_titan_gamma_warden final : public CreatureScript
{
public:
    npc_titan_gamma_warden() : CreatureScript("npc_titan_gamma_warden") { }

    bool OnGossipHello(Player* player, Creature* creature) override
    {
        ClearGossipMenuFor(player);
        AddGossipItemFor(player, GOSSIP_ICON_CHAT, "Shatter Defenses - melee attacks can expose a target for +20% damage", GOSSIP_SENDER_MAIN, 1);
        AddGossipItemFor(player, GOSSIP_ICON_CHAT, "Rallying Cry - ranged attacks can grant the party +20% haste", GOSSIP_SENDER_MAIN, 2);
        AddGossipItemFor(player, GOSSIP_ICON_CHAT, "Confessor's Wrath - healing builds up to +100% damage for your next harmful cast", GOSSIP_SENDER_MAIN, 3);
        AddGossipItemFor(player, GOSSIP_ICON_CHAT, "Shield of Thorns - avoidance can retaliate for 1000-1400 Nature damage", GOSSIP_SENDER_MAIN, 4);
        SendGossipMenuFor(player, player->GetGossipTextId(creature), creature->GetGUID());
        return true;
    }

    bool OnGossipSelect(Player* player, Creature* creature, uint32 /*sender*/, uint32 action) override
    {
        if (!player || action < 1 || action > 4 || TitanRune::GetActiveMode(player->GetMap()) != TitanRuneMode::Gamma)
            return OnGossipHello(player, creature);

        {
            std::lock_guard<std::mutex> lock(g_gammaMutex);
            g_playerBuffs[PlayerKey(player)] = static_cast<GammaBuff>(action);
            g_confessorStates.erase(PlayerKey(player));
        }
        Notify(player, "Defense Protocol Gamma helper buff selected. You can speak to the Warden again to change it.");
        return OnGossipHello(player, creature);
    }
};

class item_titan_gamma_signet final : public ItemScript
{
public:
    item_titan_gamma_signet() : ItemScript("item_titan_gamma_signet") { }

    bool OnUse(Player* player, Item* item, SpellCastTargets const& /*targets*/) override
    {
        if (!player || !item || item->GetEntry() != SignetEntryFor(player) || !IsGammaGameplayMap(player))
        {
            Notify(player, "The Gamma signet only answers inside an active Defense Protocol Gamma dungeon for your faction.");
            return true;
        }

        uint32 const key = PlayerKey(player);
        TimePoint const now = Clock::now();
        {
            std::lock_guard<std::mutex> lock(g_gammaMutex);
            TimePoint& cooldown = g_signetCooldowns[key];
            if (now < cooldown)
            {
                Notify(player, "Your Gamma signet is still recharging.");
                return true;
            }
        }

        if (SummonWarden(player, true))
        {
            std::lock_guard<std::mutex> lock(g_gammaMutex);
            g_signetCooldowns[key] = now + std::chrono::seconds(SIGNET_COOLDOWN_SECONDS);
        }
        return true; // Suppress the cloned stock item's original use spell.
    }
};
}

void AddTitanRuneGammaScripts()
{
    new TitanRuneGammaPlayerScript();
    new TitanRuneGammaUnitScript();
    new TitanRuneGammaMapScript();
    new npc_titan_gamma_warden();
    new item_titan_gamma_signet();
}
