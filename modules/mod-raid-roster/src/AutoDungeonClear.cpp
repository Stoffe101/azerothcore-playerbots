#include "AutoDungeonClear.h"

#include "Group.h"
#include "Map.h"
#include "ObjectAccessor.h"
#include "ObjectGuid.h"
#include "Player.h"
#include "PlayerbotAI.h"
#include "Playerbots.h"
#include "RaidRosterConfig.h"
#include "ScriptMgr.h"
#include "Bot/Engine/WorldPacket/Event.h"

#include <mutex>
#include <unordered_map>
#include <vector>

namespace
{
constexpr uint32 ENTRY_DELAY_MS = 2000;
constexpr uint32 WIPE_RETRY_DELAY_MS = 7500;
constexpr uint32 RETRY_STEP_MS = 2000;
constexpr uint32 MAX_WAIT_MS = 30000;

struct PendingAutoDrive
{
    uint32 humanGuid = 0;
    uint32 mapId = 0;
    uint32 elapsedMs = 0;
    uint32 readyAfterMs = ENTRY_DELAY_MS;
};

std::mutex g_autoDriveMutex;
std::unordered_map<uint32, PendingAutoDrive> g_autoDrive;
uint32 g_autoDriveTick = 0;

bool IsSupportedInstance(Player* player)
{
    return player && player->GetMap() && player->GetMap()->IsDungeon();
}

bool SameInstanceGroup(Player* anchor, uint32 mapId)
{
    if (!anchor || !anchor->GetGroup() || !IsSupportedInstance(anchor) || anchor->GetMapId() != mapId)
        return false;

    bool anyBotHere = false;
    anchor->GetGroup()->DoForAllMembers([&](Player* member)
    {
        if (!member || member->GetMapId() != mapId || IsRealPlayer(member))
            return;
        if (GET_PLAYERBOT_AI(member))
            anyBotHere = true;
    });
    return anyBotHere;
}

bool GroupFullyDead(Player* participant)
{
    Group* group = participant ? participant->GetGroup() : nullptr;
    if (!group)
        return false;

    bool sawMember = false;
    bool alive = false;
    uint32 mapId = participant->GetMapId();
    group->DoForAllMembers([&](Player* member)
    {
        if (!member || member->GetMapId() != mapId)
            return;
        sawMember = true;
        if (member->IsAlive())
            alive = true;
    });
    return sawMember && !alive;
}

void Queue(Player* human, uint32 readyAfterMs)
{
    if (!g_EncounterLifecycleEnable || !human || !IsRealPlayer(human) || !IsSupportedInstance(human) || !human->GetGroup())
        return;

    PendingAutoDrive pending;
    pending.humanGuid = human->GetGUID().GetCounter();
    pending.mapId = human->GetMapId();
    pending.readyAfterMs = readyAfterMs;

    std::lock_guard<std::mutex> lock(g_autoDriveMutex);
    g_autoDrive[pending.humanGuid] = pending;
}

bool TryStart(Player* anchor)
{
    if (!anchor || !anchor->GetGroup() || !anchor->IsAlive() || anchor->IsInCombat() || !IsSupportedInstance(anchor))
        return false;

    Group* group = anchor->GetGroup();
    uint32 mapId = anchor->GetMapId();
    bool hasAliveBotTank = false;
    std::vector<PlayerbotAI*> bots;

    group->DoForAllMembers([&](Player* member)
    {
        if (!member || member->GetMapId() != mapId || !member->IsAlive() || member->IsInCombat() || IsRealPlayer(member))
            return;

        PlayerbotAI* ai = GET_PLAYERBOT_AI(member);
        if (!ai)
            return;

        bots.push_back(ai);
        if (PlayerbotAI::IsTank(member, true))
            hasAliveBotTank = true;
    });

    // mod-dungeon-clear deliberately drives a bot tank. If the human is the only tank we leave
    // combat ownership with the human instead of forcing a DPS/healer bot to become a bad puller.
    // A future navigator-only path can cover human-tank groups without stealing their role.
    if (!hasAliveBotTank || bots.empty())
        return false;

    // Party chat normally fans "dc on" to every bot. Do the same server-side so the module's own
    // leader election remains authoritative: followers install their follow-tank strategies while
    // exactly one bot tank becomes the route/pull leader. The real player is the Event owner, so
    // mod-dungeon-clear's authorization rules are satisfied without GM shortcuts or fake masters.
    bool anyAccepted = false;
    for (PlayerbotAI* ai : bots)
    {
        Event event("raid-roster auto dungeon clear", std::string(), anchor);
        anyAccepted = ai->DoSpecificAction("dc on", event, true) || anyAccepted;
    }
    return anyAccepted;
}

class AutoDungeonClearPlayerScript : public PlayerScript
{
public:
    AutoDungeonClearPlayerScript()
        : PlayerScript("AutoDungeonClearPlayerScript", {
            PLAYERHOOK_ON_MAP_CHANGED,
            PLAYERHOOK_ON_PLAYER_JUST_DIED,
        }) { }

    void OnPlayerMapChanged(Player* player) override
    {
        Queue(player, ENTRY_DELAY_MS);
    }

    void OnPlayerJustDied(Player* player) override
    {
        if (player && IsRealPlayer(player) && IsSupportedInstance(player) && GroupFullyDead(player))
            Queue(player, WIPE_RETRY_DELAY_MS);
    }
};

class AutoDungeonClearWorldScript : public WorldScript
{
public:
    AutoDungeonClearWorldScript() : WorldScript("AutoDungeonClearWorldScript") { }

    void OnUpdate(uint32 diff) override
    {
        if (!g_EncounterLifecycleEnable)
            return;

        g_autoDriveTick += diff;
        if (g_autoDriveTick < 500)
            return;
        uint32 step = g_autoDriveTick;
        g_autoDriveTick = 0;

        std::vector<PendingAutoDrive> work;
        {
            std::lock_guard<std::mutex> lock(g_autoDriveMutex);
            for (auto& pair : g_autoDrive)
            {
                pair.second.elapsedMs += step;
                work.push_back(pair.second);
            }
        }

        for (PendingAutoDrive const& pending : work)
        {
            if (pending.elapsedMs < pending.readyAfterMs)
                continue;

            Player* anchor = ObjectAccessor::FindConnectedPlayer(
                ObjectGuid::Create<HighGuid::Player>(static_cast<ObjectGuid::LowType>(pending.humanGuid)));

            bool done = false;
            if (!anchor || !SameInstanceGroup(anchor, pending.mapId))
                done = true;
            else if (TryStart(anchor))
                done = true;
            else if (pending.elapsedMs >= MAX_WAIT_MS)
                done = true;

            std::lock_guard<std::mutex> lock(g_autoDriveMutex);
            auto it = g_autoDrive.find(pending.humanGuid);
            if (it == g_autoDrive.end())
                continue;
            if (done)
                g_autoDrive.erase(it);
            else
                it->second.readyAfterMs = it->second.elapsedMs + RETRY_STEP_MS;
        }
    }
};
}

void AddAutoDungeonClearScripts()
{
    new AutoDungeonClearPlayerScript();
    new AutoDungeonClearWorldScript();
}
