#include "EncounterLifecycle.h"

#include "Chat.h"
#include "CommandScript.h"
#include "Group.h"
#include "InstanceScript.h"
#include "Map.h"
#include "ObjectAccessor.h"
#include "Player.h"
#include "PlayerbotAI.h"
#include "Playerbots.h"
#include "RaidRosterConfig.h"
#include "RBAC.h"
#include "ScriptMgr.h"
#include "SharedDefines.h"

#include <algorithm>
#include <mutex>
#include <unordered_map>
#include <vector>

using namespace Acore::ChatCommands;

namespace
{
constexpr uint32 RECOVERY_MAX_WAIT_MS = 120000;

struct PendingRecovery
{
    uint32 anchorGuid = 0;
    uint32 mapId = 0;
    uint32 elapsedMs = 0;
};

struct PendingPrep
{
    uint32 anchorGuid = 0;
    uint32 mapId = 0;
    uint32 elapsedMs = 0;
};

std::mutex g_pendingMutex;
std::unordered_map<uint32, PendingRecovery> g_recoveries;
std::unordered_map<uint32, PendingPrep> g_preps;
uint32 g_tickAccumulator = 0;

bool IsInstance(Player* player)
{
    if (!player || !player->GetMap())
        return false;
    return player->GetMap()->IsDungeon() || player->GetMap()->IsRaid();
}

Player* AnchorHuman(Group* group)
{
    if (!group)
        return nullptr;

    Player* anchor = nullptr;
    group->DoForAllMembers([&](Player* member)
    {
        if (!member || !IsRealPlayer(member))
            return;
        if (!anchor || member->GetGUID().GetCounter() < anchor->GetGUID().GetCounter())
            anchor = member;
    });
    return anchor;
}

bool FullyDead(Group* group)
{
    if (!group)
        return false;

    uint32 online = 0;
    uint32 humans = 0;
    bool alive = false;
    group->DoForAllMembers([&](Player* member)
    {
        if (!member)
            return;
        ++online;
        if (IsRealPlayer(member))
            ++humans;
        if (member->IsAlive())
            alive = true;
    });
    return online > 0 && humans > 0 && !alive;
}

bool GroupIsOutOfCombat(Group* group)
{
    if (!group)
        return false;

    bool inCombat = false;
    group->DoForAllMembers([&](Player* member)
    {
        if (member && member->IsInCombat())
            inCombat = true;
    });
    return !inCombat;
}

bool EncounterHasReset(Player* anchor)
{
    if (!anchor || !anchor->GetMap())
        return false;

    // Do not infer a boss reset from elapsed time. AzerothCore itself uses this instance signal
    // to decide whether players may enter during an active encounter, so it is the authoritative
    // safety gate for automatic post-wipe resurrection.
    InstanceScript* instance = anchor->GetMap()->GetInstanceScript();
    return instance && !instance->IsEncounterInProgress();
}

bool SafeToRecover(Player* anchor)
{
    Group* group = anchor ? anchor->GetGroup() : nullptr;
    return group && FullyDead(group) && GroupIsOutOfCombat(group) && EncounterHasReset(anchor);
}

bool SameInstanceGroup(Player* anchor, uint32 mapId)
{
    if (!anchor || !anchor->GetGroup() || anchor->GetMapId() != mapId || !IsInstance(anchor))
        return false;

    bool sameMap = true;
    anchor->GetGroup()->DoForAllMembers([&](Player* member)
    {
        if (member && member->GetMapId() != mapId)
            sameMap = false;
    });
    return sameMap;
}

void QueueRecovery(Player* participant)
{
    if (!g_EncounterLifecycleEnable || !g_WipeRecoveryEnable || !participant || !IsInstance(participant))
        return;

    Group* group = participant->GetGroup();
    if (!group || !FullyDead(group))
        return;

    Player* anchor = AnchorHuman(group);
    if (!anchor)
        return;

    PendingRecovery pending;
    pending.anchorGuid = anchor->GetGUID().GetCounter();
    pending.mapId = participant->GetMapId();

    std::lock_guard<std::mutex> lock(g_pendingMutex);
    // Repeated death hooks from the same wipe converge on one pending recovery.
    g_recoveries.emplace(pending.anchorGuid, pending);
}

void QueuePrep(Player* player)
{
    if (!g_EncounterLifecycleEnable || !g_AutoPrepEnable || !player || !IsRealPlayer(player) || !IsInstance(player))
        return;

    Group* group = player->GetGroup();
    if (!group)
        return;

    Player* anchor = AnchorHuman(group);
    if (anchor != player)
        return;

    PendingPrep pending;
    pending.anchorGuid = player->GetGUID().GetCounter();
    pending.mapId = player->GetMapId();

    std::lock_guard<std::mutex> lock(g_pendingMutex);
    g_preps[pending.anchorGuid] = pending;
}

void Recover(Player* anchor)
{
    Group* group = anchor ? anchor->GetGroup() : nullptr;
    if (!group || !SafeToRecover(anchor))
        return;

    uint32 resurrected = 0;
    group->DoForAllMembers([&](Player* member)
    {
        if (!member || member->IsAlive())
            return;
        if (IsRealPlayer(member) && !g_WipeRecoveryResurrectHumans)
            return;

        member->ResurrectPlayer(1.0f, false);
        member->SpawnCorpseBones();
        ++resurrected;

        if (!IsRealPlayer(member))
        {
            if (PlayerbotAI* ai = GET_PLAYERBOT_AI(member))
            {
                ai->ChangeEngineOnNonCombat();
                ai->ChangeStrategy("+follow,-stay,-passive", BOT_STATE_NON_COMBAT);
                ai->Reset();
            }
        }
    });

    if (anchor->GetSession())
    {
        ChatHandler handler(anchor->GetSession());
        handler.PSendSysMessage(
            "Guild Recovery: recovered {} group member(s) after the encounter fully reset. No boss was pulled or rewarded.",
            resurrected);
    }

    EncounterLifecycle::PrepareGroup(anchor);
}

class EncounterLifecyclePlayerScript : public PlayerScript
{
public:
    EncounterLifecyclePlayerScript()
        : PlayerScript("EncounterLifecyclePlayerScript", {
            PLAYERHOOK_ON_PLAYER_JUST_DIED,
            PLAYERHOOK_ON_MAP_CHANGED,
        }) { }

    void OnPlayerJustDied(Player* player) override
    {
        QueueRecovery(player);
    }

    void OnPlayerMapChanged(Player* player) override
    {
        QueuePrep(player);
    }
};

class EncounterLifecycleWorldScript : public WorldScript
{
public:
    EncounterLifecycleWorldScript() : WorldScript("EncounterLifecycleWorldScript") { }
    void OnUpdate(uint32 diff) override { EncounterLifecycle::Tick(diff); }
};

class EncounterLifecycleCommand : public CommandScript
{
public:
    EncounterLifecycleCommand() : CommandScript("EncounterLifecycleCommand") { }

    ChatCommandTable GetCommands() const override
    {
        static ChatCommandTable sub = {
            { "prep", HandlePrep, SEC_PLAYER, Console::No },
        };
        static ChatCommandTable root = { { "encounter", sub } };
        return root;
    }

    static bool HandlePrep(ChatHandler* handler)
    {
        Player* player = handler && handler->GetSession() ? handler->GetSession()->GetPlayer() : nullptr;
        if (!player)
            return false;
        if (!player->GetGroup())
        {
            handler->SendSysMessage("Encounter Prep: form a group first.");
            return true;
        }
        if (player->IsInCombat())
        {
            handler->SendSysMessage("Encounter Prep: finish combat first.");
            return true;
        }
        EncounterLifecycle::PrepareGroup(player);
        handler->SendSysMessage("Encounter Prep requested for the group.");
        return true;
    }
};
}

void EncounterLifecycle::PrepareGroup(Player* anchor)
{
    if (!g_EncounterLifecycleEnable || !g_AutoPrepEnable || !anchor || !anchor->GetGroup() || anchor->IsInCombat())
        return;

    Group* group = anchor->GetGroup();
    group->DoForAllMembers([&](Player* member)
    {
        if (!member || IsRealPlayer(member) || !member->IsAlive() || member->IsInCombat())
            return;

        PlayerbotAI* ai = GET_PLAYERBOT_AI(member);
        if (!ai)
            return;

        ai->ChangeEngineOnNonCombat();
        ai->ChangeStrategy("+follow,-stay,-passive", BOT_STATE_NON_COMBAT);

        // Let Playerbots own class-specific buff selection. We only request its existing action.
        ai->DoSpecificAction("buff");

        if (g_AutoPrepWarlockSupport && member->getClass() == CLASS_WARLOCK)
        {
            ai->ChangeStrategy("+ss healer", BOT_STATE_NON_COMBAT);
            ai->DoSpecificAction("create healthstone");
            ai->DoSpecificAction("create soulstone");
            // The ss-healer non-combat strategy uses the created stone on a suitable healer.
            ai->DoNextAction(true);
        }

        if (g_AutoPrepSmartPets)
        {
            if (member->getClass() == CLASS_HUNTER)
            {
                ai->DoSpecificAction("revive pet");
                ai->DoSpecificAction("call pet");
            }
            else if (member->getClass() == CLASS_WARLOCK)
            {
                // Default spec pet strategies already select imp/felhunter/felguard appropriately.
                // A minimal non-combat tick asks that existing strategy to correct a missing/wrong pet.
                ai->DoNextAction(true);
            }
        }
    });
}

void EncounterLifecycle::Tick(uint32 diff)
{
    if (!g_EncounterLifecycleEnable)
        return;

    g_tickAccumulator += diff;
    if (g_tickAccumulator < 500)
        return;
    uint32 step = g_tickAccumulator;
    g_tickAccumulator = 0;

    std::vector<PendingRecovery> recoveryWork;
    std::vector<PendingPrep> prepWork;
    {
        std::lock_guard<std::mutex> lock(g_pendingMutex);
        for (auto& pair : g_recoveries)
        {
            pair.second.elapsedMs += step;
            recoveryWork.push_back(pair.second);
        }
        for (auto& pair : g_preps)
        {
            pair.second.elapsedMs += step;
            prepWork.push_back(pair.second);
        }
    }

    for (PendingPrep const& pending : prepWork)
    {
        if (pending.elapsedMs < 1500)
            continue;

        Player* anchor = ObjectAccessor::FindConnectedPlayer(
            ObjectGuid::Create<HighGuid::Player>(static_cast<ObjectGuid::LowType>(pending.anchorGuid)));
        if (anchor && SameInstanceGroup(anchor, pending.mapId))
            PrepareGroup(anchor);

        std::lock_guard<std::mutex> lock(g_pendingMutex);
        g_preps.erase(pending.anchorGuid);
    }

    for (PendingRecovery const& pending : recoveryWork)
    {
        if (pending.elapsedMs < g_WipeRecoveryDelayMs)
            continue;

        Player* anchor = ObjectAccessor::FindConnectedPlayer(
            ObjectGuid::Create<HighGuid::Player>(static_cast<ObjectGuid::LowType>(pending.anchorGuid)));

        // Any manual recovery, logout or instance/group change cancels the automatic recovery.
        if (!anchor || !SameInstanceGroup(anchor, pending.mapId) || !FullyDead(anchor->GetGroup()))
        {
            std::lock_guard<std::mutex> lock(g_pendingMutex);
            g_recoveries.erase(pending.anchorGuid);
            continue;
        }

        // Keep waiting while the instance still marks a boss IN_PROGRESS. The elapsed delay is
        // only a settling delay; it is never used as evidence that the encounter has reset.
        if (!SafeToRecover(anchor))
        {
            if (pending.elapsedMs >= RECOVERY_MAX_WAIT_MS)
            {
                if (anchor->GetSession())
                    ChatHandler(anchor->GetSession()).SendSysMessage(
                        "Guild Recovery: cancelled because the instance never reported a safe post-wipe reset.");
                std::lock_guard<std::mutex> lock(g_pendingMutex);
                g_recoveries.erase(pending.anchorGuid);
            }
            continue;
        }

        Recover(anchor);
        std::lock_guard<std::mutex> lock(g_pendingMutex);
        g_recoveries.erase(pending.anchorGuid);
    }
}

void AddEncounterLifecycleScripts()
{
    new EncounterLifecyclePlayerScript();
    new EncounterLifecycleWorldScript();
    new EncounterLifecycleCommand();
}
