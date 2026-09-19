#include "TitanRuneSystem.h"

#include "Chat.h"
#include "Group.h"
#include "Map.h"
#include "ObjectAccessor.h"
#include "Player.h"
#include "ScriptMgr.h"
#include "ScriptedGossip.h"
#include "TemporarySummon.h"
#include "WorldSession.h"

#include <chrono>
#include <cmath>
#include <cstdint>
#include <mutex>
#include <string>
#include <unordered_map>
#include <unordered_set>
#include <vector>

namespace
{
using Clock = std::chrono::steady_clock;
using TimePoint = Clock::time_point;

constexpr uint32 MYSTERIOUS_DEVICE_ENTRY = 900113;
constexpr uint32 PROTOCOL_ORB_ENTRY = 900114;
constexpr uint32 CHANNEL_SECONDS = 3;
constexpr float CHANNEL_MOVE_TOLERANCE = 1.5f;

struct PendingActivation
{
    TitanRuneMode mode = TitanRuneMode::Off;
    uint64 groupGuid = 0;
    uint64 leaderGuid = 0;
};

struct ChannelState
{
    uint64 instanceKey = 0;
    TitanRuneMode mode = TitanRuneMode::Off;
    float x = 0.0f;
    float y = 0.0f;
    float z = 0.0f;
    TimePoint finishes{};
};

std::mutex g_deviceMutex;
std::unordered_set<uint64> g_deviceInstances;
std::unordered_set<uint64> g_orbInstances;
std::unordered_set<uint64> g_activatingInstances;
std::unordered_map<uint64, PendingActivation> g_pending;
std::unordered_map<uint64, std::unordered_set<uint32>> g_completedHumans;
std::unordered_map<uint32, ChannelState> g_channels;

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

bool IsHuman(Player const* player)
{
    return player && player->GetSession() && !player->GetSession()->IsBot();
}

bool IsFrozenHalls(uint32 mapId)
{
    return mapId == 632 || mapId == 658 || mapId == 668;
}

bool IsEligibleInstance(Map const* map)
{
    if (!map || !map->IsDungeon() || map->GetDifficulty() != DUNGEON_DIFFICULTY_HEROIC || IsFrozenHalls(map->GetId()))
        return false;

    return TitanRune::IsSupportedDungeon(map->GetId(), TitanRuneMode::Alpha) ||
        TitanRune::IsSupportedDungeon(map->GetId(), TitanRuneMode::Beta) ||
        TitanRune::IsSupportedDungeon(map->GetId(), TitanRuneMode::Gamma);
}

void Notify(Player* player, std::string const& text)
{
    if (!IsHuman(player))
        return;
    ChatHandler(player->GetSession()).PSendSysMessage("[Titan Rune] {}", text);
}

Player* CurrentHumanLeader(Player* player)
{
    if (!player)
        return nullptr;

    Group* group = player->GetGroup();
    if (!group)
        return player;

    Player* leader = ObjectAccessor::FindPlayer(group->GetLeaderGUID());
    if (!leader)
        return nullptr;
    if (IsHuman(leader))
        return leader->GetMap() == player->GetMap() ? leader : nullptr;

    // A playerbot-led group cannot operate gossip. Let the human party member operate the device;
    // playerbots still count as automatic protocol-channel participants.
    return player;
}

bool CanChooseProtocol(Player* player)
{
    if (!IsHuman(player))
        return false;

    Group* group = player->GetGroup();
    if (!group)
        return true;

    Player* leader = ObjectAccessor::FindPlayer(group->GetLeaderGUID());
    if (!leader)
        return false;
    if (!IsHuman(leader))
        return true;
    return leader == player;
}

std::vector<Player*> RequiredHumans(Player* reference)
{
    std::vector<Player*> required;
    if (!reference || !reference->GetMap())
        return required;

    Group* group = reference->GetGroup();
    Map::PlayerList const& players = reference->GetMap()->GetPlayers();
    for (Map::PlayerList::const_iterator itr = players.begin(); itr != players.end(); ++itr)
    {
        Player* player = itr->GetSource();
        if (!IsHuman(player))
            continue;
        if (group && player->GetGroup() != group)
            continue;
        if (!group && player != reference)
            continue;
        required.push_back(player);
    }

    if (required.empty() && IsHuman(reference))
        required.push_back(reference);
    return required;
}

std::vector<uint32> RequiredHumanKeys(Player* reference)
{
    std::vector<uint32> keys;
    for (Player* player : RequiredHumans(reference))
        keys.push_back(PlayerKey(player));
    return keys;
}

void SpawnDevice(Player* player)
{
    if (!IsHuman(player) || !player->IsInWorld() || !IsEligibleInstance(player->GetMap()))
        return;

    uint64 const key = InstanceKey(player->GetMap());
    {
        std::lock_guard<std::mutex> lock(g_deviceMutex);
        if (!g_deviceInstances.insert(key).second)
            return;
    }

    TempSummon* device = player->SummonCreature(MYSTERIOUS_DEVICE_ENTRY,
        player->GetPositionX() + 2.0f, player->GetPositionY(), player->GetPositionZ(), player->GetOrientation(),
        TEMPSUMMON_TIMED_OR_DEAD_DESPAWN, 6 * HOUR * IN_MILLISECONDS);
    if (!device)
    {
        std::lock_guard<std::mutex> lock(g_deviceMutex);
        g_deviceInstances.erase(key);
        return;
    }

    if (TitanRune::GetActiveMode(player->GetMap()) == TitanRuneMode::Off)
        Notify(player, "A Mysterious Device is available. It can activate Alpha, Beta or Gamma without changing your Dalaran next-dungeon setting.");
}

void SpawnProtocolOrb(Player* player)
{
    if (!player || !player->GetMap())
        return;

    uint64 const key = InstanceKey(player->GetMap());
    {
        std::lock_guard<std::mutex> lock(g_deviceMutex);
        if (!g_orbInstances.insert(key).second)
            return;
    }

    TempSummon* orb = player->SummonCreature(PROTOCOL_ORB_ENTRY,
        player->GetPositionX() + 3.0f, player->GetPositionY(), player->GetPositionZ(), player->GetOrientation(),
        TEMPSUMMON_TIMED_OR_DEAD_DESPAWN, 6 * HOUR * IN_MILLISECONDS);
    if (!orb)
    {
        std::lock_guard<std::mutex> lock(g_deviceMutex);
        g_orbInstances.erase(key);
    }
}

bool AllRequiredHumansCompleteLocked(uint64 key, std::vector<uint32> const& required)
{
    auto completed = g_completedHumans.find(key);
    if (completed == g_completedHumans.end())
        return false;

    for (uint32 playerKey : required)
        if (!completed->second.count(playerKey))
            return false;
    return !required.empty();
}

bool TryClaimActivation(uint64 key, TitanRuneMode mode, std::vector<uint32> const& required)
{
    std::lock_guard<std::mutex> lock(g_deviceMutex);
    auto pending = g_pending.find(key);
    if (pending == g_pending.end() || pending->second.mode != mode)
        return false;
    if (!AllRequiredHumansCompleteLocked(key, required))
        return false;
    return g_activatingInstances.insert(key).second;
}

void BroadcastProgress(Player* reference, uint64 key)
{
    std::vector<Player*> const required = RequiredHumans(reference);
    std::unordered_set<uint32> completedSnapshot;
    {
        std::lock_guard<std::mutex> lock(g_deviceMutex);
        auto completed = g_completedHumans.find(key);
        if (completed != g_completedHumans.end())
            completedSnapshot = completed->second;
    }

    std::size_t complete = 0;
    for (Player* player : required)
        if (completedSnapshot.count(PlayerKey(player)))
            ++complete;

    std::string const message = "Defense Protocol channel progress: " + std::to_string(complete) + "/" +
        std::to_string(required.size()) + " human player(s). Playerbots count automatically.";
    for (Player* player : required)
        Notify(player, message);
}

void ReleaseActivationClaim(uint64 key)
{
    std::lock_guard<std::mutex> lock(g_deviceMutex);
    g_activatingInstances.erase(key);
}

void ActivatePending(Player* finisher, TitanRuneMode mode, uint64 key)
{
    if (!finisher || !finisher->GetMap())
    {
        ReleaseActivationClaim(key);
        return;
    }

    {
        Group* group = finisher->GetGroup();
        uint64 const groupGuid = group ? group->GetGUID().GetRawValue() : 0;
        uint64 const leaderGuid = group ? group->GetLeaderGUID().GetRawValue() : finisher->GetGUID().GetRawValue();
        std::lock_guard<std::mutex> lock(g_deviceMutex);
        auto pending = g_pending.find(key);
        if (pending == g_pending.end() || pending->second.groupGuid != groupGuid ||
            pending->second.leaderGuid != leaderGuid)
        {
            g_activatingInstances.erase(key);
            return;
        }
    }

    Player* activator = CurrentHumanLeader(finisher);
    // Device confirmation must never temporarily overwrite a durable next-run preference.
    TitanRune::ActivateModeForPlayer(activator, mode);

    if (TitanRune::GetActiveMode(finisher->GetMap()) == mode)
    {
        Notify(finisher, std::string("Defense Protocol ") + TitanRune::ModeName(mode) +
            " activated by the Mysterious Device. Your saved next-dungeon setting is unchanged.");
        std::lock_guard<std::mutex> lock(g_deviceMutex);
        g_activatingInstances.erase(key);
        g_pending.erase(key);
        g_completedHumans.erase(key);
        for (auto itr = g_channels.begin(); itr != g_channels.end(); )
        {
            if (itr->second.instanceKey == key)
                itr = g_channels.erase(itr);
            else
                ++itr;
        }
    }
    else
    {
        ReleaseActivationClaim(key);
        Notify(finisher, "The protocol channel completed, but instance activation was rejected. Check group leadership and dungeon support.");
    }
}

void BeginChannel(Player* player)
{
    if (!IsHuman(player) || !player->GetMap())
        return;
    if (player->IsInCombat())
    {
        Notify(player, "You must be out of combat to channel the Defense Protocol Orb.");
        return;
    }

    uint64 const key = InstanceKey(player->GetMap());
    TitanRuneMode mode = TitanRuneMode::Off;
    bool alreadyComplete = false;
    {
        std::lock_guard<std::mutex> lock(g_deviceMutex);
        auto pending = g_pending.find(key);
        if (pending == g_pending.end())
        {
            mode = TitanRuneMode::Off;
        }
        else
        {
            mode = pending->second.mode;
            alreadyComplete = g_completedHumans[key].count(PlayerKey(player)) != 0;
            if (!alreadyComplete)
            {
                ChannelState state;
                state.instanceKey = key;
                state.mode = mode;
                state.x = player->GetPositionX();
                state.y = player->GetPositionY();
                state.z = player->GetPositionZ();
                state.finishes = Clock::now() + std::chrono::seconds(CHANNEL_SECONDS);
                g_channels[PlayerKey(player)] = state;
            }
        }
    }

    if (mode == TitanRuneMode::Off)
    {
        Notify(player, "No protocol is awaiting confirmation. Use the Mysterious Device first.");
        return;
    }

    if (alreadyComplete)
    {
        std::vector<uint32> const required = RequiredHumanKeys(player);
        BroadcastProgress(player, key);
        if (TryClaimActivation(key, mode, required))
            ActivatePending(player, mode, key);
        else
            Notify(player, "Your protocol channel is already complete. Waiting for the remaining human party members.");
        return;
    }

    Notify(player, std::string("Channeling Defense Protocol ") + TitanRune::ModeName(mode) +
        " for 3 seconds. Do not move or enter combat.");
}

class TitanRuneDevicePlayerScript final : public PlayerScript
{
public:
    TitanRuneDevicePlayerScript() : PlayerScript("TitanRuneDevicePlayerScript") { }

    void OnPlayerLogin(Player* player) override
    {
        SpawnDevice(player);
    }

    void OnPlayerMapChanged(Player* player) override
    {
        {
            std::lock_guard<std::mutex> lock(g_deviceMutex);
            g_channels.erase(PlayerKey(player));
        }
        SpawnDevice(player);
    }

    void OnPlayerLogout(Player* player) override
    {
        std::lock_guard<std::mutex> lock(g_deviceMutex);
        g_channels.erase(PlayerKey(player));
    }

    void OnPlayerUpdate(Player* player, uint32 /*diff*/) override
    {
        if (!IsHuman(player) || !player->IsInWorld())
            return;

        SpawnDevice(player);

        uint32 const playerKey = PlayerKey(player);
        ChannelState channel;
        bool hasChannel = false;
        {
            std::lock_guard<std::mutex> lock(g_deviceMutex);
            auto itr = g_channels.find(playerKey);
            if (itr != g_channels.end())
            {
                channel = itr->second;
                hasChannel = true;
            }
        }
        if (!hasChannel)
            return;

        if (!player->GetMap() || InstanceKey(player->GetMap()) != channel.instanceKey ||
            TitanRune::GetActiveMode(player->GetMap()) != TitanRuneMode::Off)
        {
            std::lock_guard<std::mutex> lock(g_deviceMutex);
            g_channels.erase(playerKey);
            return;
        }

        float const dx = player->GetPositionX() - channel.x;
        float const dy = player->GetPositionY() - channel.y;
        float const dz = player->GetPositionZ() - channel.z;
        if (player->IsInCombat() || (dx * dx + dy * dy + dz * dz) > CHANNEL_MOVE_TOLERANCE * CHANNEL_MOVE_TOLERANCE)
        {
            {
                std::lock_guard<std::mutex> lock(g_deviceMutex);
                g_channels.erase(playerKey);
            }
            Notify(player, "Defense Protocol channel interrupted. Return to the orb and try again.");
            return;
        }

        if (Clock::now() < channel.finishes)
            return;

        bool accepted = false;
        {
            std::lock_guard<std::mutex> lock(g_deviceMutex);
            auto pending = g_pending.find(channel.instanceKey);
            if (pending != g_pending.end() && pending->second.mode == channel.mode)
            {
                g_channels.erase(playerKey);
                g_completedHumans[channel.instanceKey].insert(playerKey);
                accepted = true;
            }
            else
                g_channels.erase(playerKey);
        }
        if (!accepted)
            return;

        Notify(player, "Your Defense Protocol channel is complete.");
        BroadcastProgress(player, channel.instanceKey);

        std::vector<uint32> const required = RequiredHumanKeys(player);
        if (TryClaimActivation(channel.instanceKey, channel.mode, required))
            ActivatePending(player, channel.mode, channel.instanceKey);
    }
};

class TitanRuneDeviceMapScript final : public AllMapScript
{
public:
    TitanRuneDeviceMapScript() : AllMapScript("TitanRuneDeviceMapScript") { }

    void OnDestroyMap(Map* map) override
    {
        if (!map)
            return;

        uint64 const key = InstanceKey(map);
        std::lock_guard<std::mutex> lock(g_deviceMutex);
        g_deviceInstances.erase(key);
        g_orbInstances.erase(key);
        g_activatingInstances.erase(key);
        g_pending.erase(key);
        g_completedHumans.erase(key);
        for (auto itr = g_channels.begin(); itr != g_channels.end(); )
        {
            if (itr->second.instanceKey == key)
                itr = g_channels.erase(itr);
            else
                ++itr;
        }
    }
};

class npc_titan_mysterious_device final : public CreatureScript
{
public:
    npc_titan_mysterious_device() : CreatureScript("npc_titan_mysterious_device") { }

    bool OnGossipHello(Player* player, Creature* creature) override
    {
        ClearGossipMenuFor(player);
        if (!player || !player->GetMap())
            return true;

        TitanRuneMode const active = TitanRune::GetActiveMode(player->GetMap());
        if (active != TitanRuneMode::Off)
        {
            AddGossipItemFor(player, GOSSIP_ICON_CHAT,
                std::string("Defense Protocol ") + TitanRune::ModeName(active) + " is active in this instance.",
                GOSSIP_SENDER_MAIN, 90000);
        }
        else
        {
            uint64 const key = InstanceKey(player->GetMap());
            TitanRuneMode pendingMode = TitanRuneMode::Off;
            {
                std::lock_guard<std::mutex> lock(g_deviceMutex);
                auto pending = g_pending.find(key);
                if (pending != g_pending.end())
                    pendingMode = pending->second.mode;
            }

            if (pendingMode != TitanRuneMode::Off)
            {
                AddGossipItemFor(player, GOSSIP_ICON_CHAT,
                    std::string("Defense Protocol ") + TitanRune::ModeName(pendingMode) +
                    " is awaiting party confirmation. Channel the nearby orb.", GOSSIP_SENDER_MAIN, 90000);
            }
            else if (!CanChooseProtocol(player))
            {
                AddGossipItemFor(player, GOSSIP_ICON_CHAT,
                    "Only the human group leader can choose the protocol. If a playerbot is leader, any human party member may choose.",
                    GOSSIP_SENDER_MAIN, 90000);
            }
            else
            {
                if (TitanRune::IsSupportedDungeon(player->GetMapId(), TitanRuneMode::Alpha))
                    AddGossipItemFor(player, GOSSIP_ICON_CHAT, "Prepare Defense Protocol Alpha", GOSSIP_SENDER_MAIN, 101);
                if (TitanRune::IsSupportedDungeon(player->GetMapId(), TitanRuneMode::Beta))
                    AddGossipItemFor(player, GOSSIP_ICON_CHAT, "Prepare Defense Protocol Beta", GOSSIP_SENDER_MAIN, 102);
                if (TitanRune::IsSupportedDungeon(player->GetMapId(), TitanRuneMode::Gamma))
                    AddGossipItemFor(player, GOSSIP_ICON_CHAT, "Prepare Defense Protocol Gamma", GOSSIP_SENDER_MAIN, 103);
            }
        }

        SendGossipMenuFor(player, player->GetGossipTextId(creature), creature->GetGUID());
        return true;
    }

    bool OnGossipSelect(Player* player, Creature* creature, uint32 /*sender*/, uint32 action) override
    {
        if (!player || !player->GetMap() || action < 101 || action > 103 ||
            TitanRune::GetActiveMode(player->GetMap()) != TitanRuneMode::Off || !CanChooseProtocol(player))
            return OnGossipHello(player, creature);

        TitanRuneMode const mode = static_cast<TitanRuneMode>(action - 100);
        if (!TitanRune::IsSupportedDungeon(player->GetMapId(), mode))
            return OnGossipHello(player, creature);

        uint64 const key = InstanceKey(player->GetMap());
        {
            std::lock_guard<std::mutex> lock(g_deviceMutex);
            g_pending[key].mode = mode;
            Group* group = player->GetGroup();
            g_pending[key].groupGuid = group ? group->GetGUID().GetRawValue() : 0;
            g_pending[key].leaderGuid = group ? group->GetLeaderGUID().GetRawValue() : player->GetGUID().GetRawValue();
            g_completedHumans[key].clear();
            g_activatingInstances.erase(key);
            for (auto itr = g_channels.begin(); itr != g_channels.end(); )
            {
                if (itr->second.instanceKey == key)
                    itr = g_channels.erase(itr);
                else
                    ++itr;
            }
        }

        SpawnProtocolOrb(player);
        Notify(player, std::string("Defense Protocol ") + TitanRune::ModeName(mode) +
            " prepared. Every human party member in the instance must channel the orb; playerbots count automatically.");
        return OnGossipHello(player, creature);
    }
};

class npc_titan_protocol_orb final : public CreatureScript
{
public:
    npc_titan_protocol_orb() : CreatureScript("npc_titan_protocol_orb") { }

    bool OnGossipHello(Player* player, Creature* creature) override
    {
        ClearGossipMenuFor(player);
        if (!player || !player->GetMap())
            return true;

        TitanRuneMode pendingMode = TitanRuneMode::Off;
        uint64 const key = InstanceKey(player->GetMap());
        {
            std::lock_guard<std::mutex> lock(g_deviceMutex);
            auto pending = g_pending.find(key);
            if (pending != g_pending.end())
                pendingMode = pending->second.mode;
        }

        if (TitanRune::GetActiveMode(player->GetMap()) != TitanRuneMode::Off)
            AddGossipItemFor(player, GOSSIP_ICON_CHAT, "The Defense Protocol has already been activated.", GOSSIP_SENDER_MAIN, 90000);
        else if (pendingMode == TitanRuneMode::Off)
            AddGossipItemFor(player, GOSSIP_ICON_CHAT, "No Defense Protocol is prepared. Use the Mysterious Device first.", GOSSIP_SENDER_MAIN, 90000);
        else
            AddGossipItemFor(player, GOSSIP_ICON_CHAT,
                std::string("Channel Defense Protocol ") + TitanRune::ModeName(pendingMode) + " (3 seconds)",
                GOSSIP_SENDER_MAIN, 201);

        SendGossipMenuFor(player, player->GetGossipTextId(creature), creature->GetGUID());
        return true;
    }

    bool OnGossipSelect(Player* player, Creature* creature, uint32 /*sender*/, uint32 action) override
    {
        if (action == 201)
            BeginChannel(player);
        return OnGossipHello(player, creature);
    }
};
}

void AddTitanRuneDeviceScripts()
{
    new TitanRuneDevicePlayerScript();
    new TitanRuneDeviceMapScript();
    new npc_titan_mysterious_device();
    new npc_titan_protocol_orb();
}
