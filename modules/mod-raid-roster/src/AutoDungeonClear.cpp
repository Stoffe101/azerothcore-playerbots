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
#include "Ai/Dungeon/DungeonClear/Util/DcLeaderSignal.h"

#include <mutex>
#include <string>
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
    if (!player || !player->GetMap() || !player->GetMap()->IsDungeon())
        return false;
    if (player->GetMap()->IsRaid() && !g_AutoDungeonClearRaids)
        return false;
    return true;
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
    if (!g_AutoDungeonClearEnable || !human || !IsRealPlayer(human) || !IsSupportedInstance(human) || !human->GetGroup())
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
    if (!g_AutoDungeonClearEnable || !anchor || !anchor->GetGroup() || !anchor->IsAlive() ||
        anchor->IsInCombat() || !IsSupportedInstance(anchor))
        return false;

    // Delegate leadership to mod-dungeon-clear itself. Parties choose their sole bot tank; raids
    // use the module's Main Tank / best-geared election. This is intentionally not reimplemented
    // here because duplicate leader rules are exactly how two bots end up fighting over a route.
    Player* leader = DcLeaderSignal::FindLeaderTank(anchor);
    if (!leader || !leader->IsAlive() || leader->IsInCombat())
        return false;

    PlayerbotAI* leaderAI = GET_PLAYERBOT_AI(leader);
    if (!leaderAI)
        return false;

    // Use the real player as Event owner so dungeon-clear's normal authorization path is obeyed.
    // The action is idempotent enough for our short retry window, and its own map/boss validation
    // decides whether the current instance actually has a supported route.
    Event event("raid-roster auto dungeon clear", std::string(), anchor);
    return leaderAI->DoSpecificAction("dc on", event, true);
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
        if (!g_AutoDungeonClearEnable)
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
