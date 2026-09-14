#include "RaidLeaderAuto.h"

#include "RaidLeaderKnowledge.h"
#include "PBChatterConfig.h"
#include "PBChatterQueue.h"

#include "Config.h"
#include "Creature.h"
#include "Group.h"
#include "Map.h"
#include "Player.h"
#include "PlayerbotAI.h"
#include "Playerbots.h"
#include "ScriptMgr.h"

#include <mutex>
#include <string>
#include <unordered_map>

namespace
{
constexpr uint32 POLL_MS = 500;
constexpr float PREPULL_RANGE = 55.0f;
constexpr std::size_t CHAT_LIMIT = 230;

bool g_enable = true;
bool g_useOllama = true;
bool g_briefOnPull = true;
bool g_retryAdvice = true;

struct BossState
{
    uint32 pollMs = 0;
    uint32 attempt = 0;
    bool inCombat = false;
    bool briefed = false;
};

struct Participants
{
    Player* human = nullptr;
    Player* speaker = nullptr;
};

std::mutex g_stateMutex;
std::unordered_map<uint64, BossState> g_states;

uint64 StateKey(Creature* creature)
{
    if (!creature || !creature->GetMap())
        return 0;
    return (static_cast<uint64>(creature->GetMap()->GetInstanceId()) << 32) |
           static_cast<uint64>(creature->GetGUID().GetCounter());
}

char const* PlayerRole(Player* player)
{
    if (!player)
        return "player";
    if (PlayerbotAI::IsTank(player, true))
        return "tank";
    if (PlayerbotAI::IsHeal(player, true))
        return "healer";
    return "DPS";
}

std::string const& RoleJob(RaidLeaderKnowledge::Encounter const& encounter, Player* player)
{
    if (PlayerbotAI::IsTank(player, true))
        return encounter.tankJob;
    if (PlayerbotAI::IsHeal(player, true))
        return encounter.healerJob;
    return encounter.dpsJob;
}

std::string ChatSafe(std::string text)
{
    if (text.size() <= CHAT_LIMIT)
        return text;
    text.resize(CHAT_LIMIT - 3);
    text += "...";
    return text;
}

Player* PickBotSpeaker(Group* group, Map* map)
{
    if (!group || !map)
        return nullptr;

    Player* firstBot = nullptr;
    Player* tankBot = nullptr;
    group->DoForAllMembers([&](Player* member)
    {
        if (!member || !member->IsAlive() || member->GetMap() != map || IsRealPlayer(member))
            return;
        if (!GET_PLAYERBOT_AI(member))
            return;
        if (!firstBot)
            firstBot = member;
        if (!tankBot && PlayerbotAI::IsTank(member, true))
            tankBot = member;
    });
    return tankBot ? tankBot : firstBot;
}

Participants FindParticipants(Creature* boss, bool requirePrepRange)
{
    Participants out;
    if (!boss || !boss->GetMap())
        return out;

    Map* map = boss->GetMap();
    map->DoForAllPlayers([&](Player* player)
    {
        if (out.human || !player || !player->IsAlive() || !IsRealPlayer(player) || !player->GetGroup())
            return;
        if (requirePrepRange && boss->GetDistance(player) > PREPULL_RANGE)
            return;

        Player* speaker = PickBotSpeaker(player->GetGroup(), map);
        if (!speaker)
            return;

        out.human = player;
        out.speaker = speaker;
    });
    return out;
}

std::string DeterministicLine(RaidLeaderKnowledge::Encounter const& encounter, Player* human, uint32 attempt)
{
    std::string line = "[Raid Lead] ";
    if (attempt > 1 && g_retryAdvice)
    {
        line += "Retry " + std::to_string(attempt) + " on " + encounter.boss + ". ";
        line += RoleJob(encounter, human);
        if (!encounter.caveat.empty())
            line += " " + encounter.caveat;
    }
    else
    {
        line += encounter.boss + ": " + encounter.overview + " ";
        line += std::string("Your ") + PlayerRole(human) + " job: " + RoleJob(encounter, human);
    }
    return ChatSafe(std::move(line));
}

void DeliverBrief(Creature* boss, RaidLeaderKnowledge::Encounter const& encounter,
                  Participants const& participants, uint32 attempt)
{
    if (!boss || !participants.human || !participants.speaker)
        return;

    PlayerbotAI* ai = GET_PLAYERBOT_AI(participants.speaker);
    if (!ai)
        return;

    Group* group = participants.human->GetGroup();
    if (!group)
        return;

    std::string fallback = DeterministicLine(encounter, participants.human, attempt);

    // Chatter disabled means there is no result-drain loop. The local-model rewrite can also be
    // disabled independently. In both cases the deterministic encounter record remains fully
    // functional, so raid leading never depends on Ollama being online.
    if (!g_useOllama || !g_PBChatEnable)
    {
        if (group->isRaidGroup())
            ai->SayToRaid(fallback);
        else
            ai->SayToParty(fallback);
        return;
    }

    PBChatJob job{};
    job.botGuid = participants.speaker->GetGUID().GetCounter();
    job.playerGuid = participants.human->GetGUID().GetCounter();
    job.playerName = participants.human->GetName();
    job.channel = group->isRaidGroup() ? PBChatChannel::Raid : PBChatChannel::Party;
    job.playerMessage = "[automatic grounded raid brief]";
    job.storeMemory = false;
    job.fallbackReply = fallback;
    job.groundedAgainstFallback = true;
    job.systemPrompt =
        "You are a local World of Warcraft raid-leader voice layer. The supplied encounter record is the only source of truth. "
        "Return exactly one concise raid-chat callout. Never add mechanics, timers, assignments, phase names, spell effects, or bot abilities not present in the record. "
        "Preserve uncertainty/caveats. If the record is sparse, stay sparse. No markdown.";

    job.prompt =
        "Boss: " + encounter.boss + "\n" +
        "Raid: " + encounter.raid + "\n" +
        "Attempt: " + std::to_string(attempt) + "\n" +
        "Human role: " + PlayerRole(participants.human) + "\n" +
        "Overview: " + encounter.overview + "\n" +
        "Human role job: " + RoleJob(encounter, participants.human) + "\n" +
        "Verified bot automation: " + encounter.botAutomation + "\n" +
        "Verified Playerbots strategy: " + encounter.playerbotStrategy + "\n" +
        "Caveat: " + (encounter.caveat.empty() ? std::string("none recorded") : encounter.caveat) + "\n" +
        "Write one practical callout under 220 characters. On retries, focus on the supplied role job/caveat rather than inventing a diagnosis.";

    PBChatterQueue::Submit(std::move(job));
}

class RaidLeaderAutoConfigScript final : public WorldScript
{
public:
    RaidLeaderAutoConfigScript() : WorldScript("RaidLeaderAutoConfigScript") { }

    void OnAfterConfigLoad(bool /*reload*/) override
    {
        g_enable = sConfigMgr->GetOption<bool>("PlayerbotChatter.RaidLeaderEnable", true);
        g_useOllama = sConfigMgr->GetOption<bool>("PlayerbotChatter.RaidLeaderUseOllama", true);
        g_briefOnPull = sConfigMgr->GetOption<bool>("PlayerbotChatter.RaidLeaderBriefOnPull", true);
        g_retryAdvice = sConfigMgr->GetOption<bool>("PlayerbotChatter.RaidLeaderRetryAdvice", true);
    }
};

class RaidLeaderAutoCreatureScript : public AllCreatureScript
{
public:
    RaidLeaderAutoCreatureScript() : AllCreatureScript("RaidLeaderAutoCreatureScript") { }

    void OnAllCreatureUpdate(Creature* creature, uint32 diff) override
    {
        if (!g_enable || !g_briefOnPull || !creature || !creature->GetMap() ||
            !creature->GetMap()->IsRaid() || !creature->IsDungeonBoss())
            return;

        RaidLeaderKnowledge::Encounter const* encounter = RaidLeaderKnowledge::FindAny(creature->GetName());
        if (!encounter || encounter->readiness == RaidLeaderKnowledge::Readiness::NotReady)
            return;

        uint64 const key = StateKey(creature);
        bool shouldPoll = false;
        bool wasInCombat = false;
        bool briefed = false;
        uint32 attempt = 0;

        {
            std::lock_guard<std::mutex> lock(g_stateMutex);
            BossState& state = g_states[key];
            state.pollMs += diff;
            if (state.pollMs >= POLL_MS)
            {
                state.pollMs = 0;
                shouldPoll = true;
            }
            wasInCombat = state.inCombat;
            state.inCombat = creature->IsInCombat();
            briefed = state.briefed;
            attempt = state.attempt;

            // A living boss leaving combat after having been engaged is an encounter reset/wipe.
            // Re-arm the brief for the next approach. We do not guess why the wipe happened.
            if (wasInCombat && !state.inCombat && creature->IsAlive())
                state.briefed = false;
        }

        if (!shouldPoll || !creature->IsAlive())
            return;

        bool const inCombat = creature->IsInCombat();
        bool const needsBrief = !briefed || (wasInCombat && !inCombat);
        if (!needsBrief)
            return;

        // Out of combat we announce while the raid is approaching the boss, which gives the local
        // model time to phrase the deterministic record before the pull. If somebody chain-pulls,
        // drop the distance requirement and still issue the same grounded call immediately.
        Participants participants = FindParticipants(creature, !inCombat);
        if (!participants.human || !participants.speaker)
            return;

        {
            std::lock_guard<std::mutex> lock(g_stateMutex);
            BossState& state = g_states[key];
            if (state.briefed)
                return; // another update/thread won the race
            ++state.attempt;
            state.briefed = true;
            attempt = state.attempt;
        }

        DeliverBrief(creature, *encounter, participants, attempt);
    }

    void OnCreatureRemoveWorld(Creature* creature) override
    {
        if (!creature)
            return;
        std::lock_guard<std::mutex> lock(g_stateMutex);
        g_states.erase(StateKey(creature));
    }
};
}

void AddRaidLeaderAutoScripts()
{
    new RaidLeaderAutoConfigScript();
    new RaidLeaderAutoCreatureScript();
}
