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
#include "Ai/Dungeon/DungeonClear/Util/DcRun.h"

#include <mutex>
#include <string>
#include <unordered_map>
#include <vector>

namespace
{
constexpr uint32 ENTRY_DELAY_MS = 2000;
constexpr uint32 WIPE_RETRY_DELAY_MS = 7500;
constexpr uint32 RETRY_STEP_MS = 2000;
constexpr uint32 MAX_WAIT_MS = 300000;

struct PendingAutoDrive
{
    uint32 humanGuid = 0;
    uint32 mapId = 0;
    uint32 instanceId = 0;
    uint32 elapsedMs = 0;
    uint32 readyAfterMs = ENTRY_DELAY_MS;
};

std::mutex g_autoDriveMutex;
std::unordered_map<uint32, PendingAutoDrive> g_autoDrive;

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
        if (!member || member->GetMap() != anchor->GetMap() || IsRealPlayer(member))
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
    group->DoForAllMembers([&](Player* member)
    {
        if (!member || member->GetMap() != participant->GetMap())
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
    pending.instanceId = human->GetInstanceId();
    pending.readyAfterMs = readyAfterMs;

    std::lock_guard<std::mutex> lock(g_autoDriveMutex);
    g_autoDrive[pending.humanGuid] = pending;
}

bool TryStart(Player* anchor)
{
    if (!g_AutoDungeonClearEnable || !anchor || !anchor->GetGroup() || !anchor->IsAlive() ||
        anchor->IsInCombat() || !IsSupportedInstance(anchor))
        return false;

    for (GroupReference* ref = anchor->GetGroup()->GetFirstMember(); ref; ref = ref->next())
        if (Player* member = ref->GetSource())
            if (member->GetMap() == anchor->GetMap() && member->IsInCombat())
                return false;

    // Delegate leadership to mod-dungeon-clear itself, including its human-tank route guide.
    // Raids use the module's Main Tank / best-geared election. This is not reimplemented
    // here because duplicate leader rules are exactly how two bots end up fighting over a route.
    Player* leader = DcLeaderSignal::FindLeaderTank(anchor);
    if (!leader || !leader->IsAlive() || leader->IsInCombat())
        return false;

    PlayerbotAI* leaderAI = GET_PLAYERBOT_AI(leader);
    if (!leaderAI)
        return false;
    if (DcRun::Of(leaderAI).enabled)
        return true;

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
            PLAYERHOOK_ON_LOGIN,
            PLAYERHOOK_ON_UPDATE,
            PLAYERHOOK_ON_LOGOUT,
            PLAYERHOOK_ON_PLAYER_JUST_DIED,
        }) { }

    void OnPlayerLogin(Player* player) override
    {
        Queue(player, ENTRY_DELAY_MS);
    }

    void OnPlayerMapChanged(Player* player) override
    {
        Queue(player, ENTRY_DELAY_MS);
    }

    void OnPlayerJustDied(Player* player) override
    {
        if (player && IsSupportedInstance(player) && GroupFullyDead(player))
            player->GetGroup()->DoForAllMembers([](Player* member)
            {
                Queue(member, WIPE_RETRY_DELAY_MS);
            });
    }

    void OnPlayerLogout(Player* player) override
    {
        std::lock_guard<std::mutex> lock(g_autoDriveMutex);
        g_autoDrive.erase(player->GetGUID().GetCounter());
    }

    void OnPlayerUpdate(Player* anchor, uint32 diff) override
    {
        if (!g_AutoDungeonClearEnable || !anchor || !IsRealPlayer(anchor))
            return;

        uint32 const guid = anchor->GetGUID().GetCounter();
        PendingAutoDrive pending;
        {
            std::lock_guard<std::mutex> lock(g_autoDriveMutex);
            auto it = g_autoDrive.find(guid);
            if (it == g_autoDrive.end())
                return;
            // Wipe recovery can take longer than the entry retry window.
            if (!anchor->IsAlive())
                return;
            it->second.elapsedMs += diff;
            if (it->second.elapsedMs < it->second.readyAfterMs)
                return;
            pending = it->second;
        }

        // Run on the player's map update, alongside its group and bot AI.
        bool const done = anchor->GetMapId() != pending.mapId ||
            anchor->GetInstanceId() != pending.instanceId || !anchor->GetGroup() ||
            (SameInstanceGroup(anchor, pending.mapId) && TryStart(anchor)) ||
            pending.elapsedMs >= MAX_WAIT_MS;
        std::lock_guard<std::mutex> lock(g_autoDriveMutex);
        auto it = g_autoDrive.find(guid);
        if (it == g_autoDrive.end() || it->second.mapId != pending.mapId ||
            it->second.instanceId != pending.instanceId || it->second.elapsedMs != pending.elapsedMs)
            return;
        if (done)
            g_autoDrive.erase(it);
        else
            it->second.readyAfterMs = it->second.elapsedMs + RETRY_STEP_MS;
    }
};
}

void AddAutoDungeonClearScripts()
{
    new AutoDungeonClearPlayerScript();
}
