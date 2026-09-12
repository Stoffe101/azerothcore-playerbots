#include "GuildGroupDirector.h"

#include "AdventureCommand.h"
#include "RaidRosterCommand.h"
#include "RaidRosterConfig.h"
#include "RaidRosterStore.h"

#include "Chat.h"
#include "Group.h"
#include "ObjectAccessor.h"
#include "ObjectGuid.h"
#include "Player.h"
#include "Playerbots.h"
#include "ScriptMgr.h"
#include "SharedDefines.h"

#include <algorithm>
#include <cctype>
#include <mutex>
#include <string>
#include <unordered_map>
#include <vector>

namespace
{
struct PendingDungeonRequest
{
    uint32 playerGuid = 0;
    std::string destinationAlias;
    std::string destinationName;
    uint32 elapsedMs = 0;
};

std::mutex g_pendingMutex;
std::unordered_map<uint32, PendingDungeonRequest> g_pending;
uint32 g_tickAccumulator = 0;

std::string Lower(std::string value)
{
    std::transform(value.begin(), value.end(), value.begin(), [](unsigned char c)
    {
        return static_cast<char>(std::tolower(c));
    });
    return value;
}

bool LooksLikeGroupRequest(std::string const& original)
{
    std::string text = Lower(original);

    // Deliberately conservative. A destination mention alone is not enough because guildmates
    // should still be able to say things like "Ramparts loot sucks" without being teleported.
    static constexpr char const* cues[] = {
        "anyone", "up for", "wanna", "want to", "who wants", "can we", "should we",
        "let's", "lets ", "lfg", "need group", "group for", "do some", "queue for"
    };
    for (char const* cue : cues)
        if (text.find(cue) != std::string::npos)
            return true;

    // Short player-style requests such as "run ramps?" or simply "ramps?" are accepted only
    // when phrased as a question.
    if (text.find('?') != std::string::npos)
        return true;

    return false;
}

uint32 CountRealHumans(Group* group)
{
    if (!group)
        return 1;

    uint32 count = 0;
    group->DoForAllMembers([&](Player* member)
    {
        if (member && IsRealPlayer(member))
            ++count;
    });
    return count;
}

void QueueRequest(Player* player, std::string alias, std::string name)
{
    PendingDungeonRequest pending;
    pending.playerGuid = player->GetGUID().GetCounter();
    pending.destinationAlias = std::move(alias);
    pending.destinationName = std::move(name);

    std::lock_guard<std::mutex> lock(g_pendingMutex);
    g_pending[pending.playerGuid] = std::move(pending);
}

void RemoveRequest(uint32 guid)
{
    std::lock_guard<std::mutex> lock(g_pendingMutex);
    g_pending.erase(guid);
}

class GuildGroupDirectorPlayerScript : public PlayerScript
{
public:
    GuildGroupDirectorPlayerScript()
        : PlayerScript("GuildGroupDirectorPlayerScript", { PLAYERHOOK_ON_BEFORE_SEND_CHAT_MESSAGE }) { }

    void OnPlayerBeforeSendChatMessage(Player* player, uint32& type, uint32& /*lang*/, std::string& msg) override
    {
        if (!g_GuildDirectorEnable || !player || !IsRealPlayer(player) || type != CHAT_MSG_GUILD)
            return;

        std::string alias;
        std::string name;
        if (!AdventureCommand::ResolveMention(msg, alias, name) || !LooksLikeGroupRequest(msg))
            return;

        ChatHandler handler(player->GetSession());

        if (!g_RaidRosterEnable)
        {
            handler.SendSysMessage("Guild Director recognized the dungeon request, but RaidRoster is disabled.");
            return;
        }

        if (!player->IsAlive())
        {
            handler.SendSysMessage("Guild Director: resurrect before forming the dungeon group.");
            return;
        }
        if (player->IsInCombat())
        {
            handler.SendSysMessage("Guild Director: finish combat first, then ask again.");
            return;
        }

        std::string lockedReason;
        if (!AdventureCommand::IsDestinationUnlocked(player, alias, lockedReason))
        {
            handler.PSendSysMessage("Guild Director: {}", lockedReason);
            return;
        }

        Group* group = player->GetGroup();
        if (group && group->GetLeaderGUID() != player->GetGUID())
        {
            handler.SendSysMessage("Guild Director: only the current group leader can start automatic guild grouping.");
            return;
        }

        // HandleLogin currently models one real player + roster bots. Do not overfill a party that
        // already contains a second human. Multi-human role accounting is the next director slice.
        if (group && CountRealHumans(group) > 1)
        {
            handler.PSendSysMessage(
                "Guild Director recognized {}. Automatic multi-human filling is not enabled yet, so I left your current group untouched.",
                name);
            return;
        }

        uint32 owner = player->GetGUID().GetCounter();
        if (!RaidRosterStore::Exists(owner))
        {
            handler.PSendSysMessage("Guild Director: building your persistent guild roster for {}...", name);
            RaidRosterCommand::HandleCreate(&handler);
        }

        if (!RaidRosterStore::Exists(owner))
        {
            handler.SendSysMessage("Guild Director could not create a persistent roster. Check the server log / addclass pool.");
            return;
        }

        handler.PSendSysMessage("Guild Director: forming a balanced group for {}.", name);
        RaidRosterCommand::HandleLogin(&handler, Optional<uint32>(5), Optional<std::string>());
        QueueRequest(player, alias, name);
    }
};

class GuildGroupDirectorWorldScript : public WorldScript
{
public:
    GuildGroupDirectorWorldScript() : WorldScript("GuildGroupDirectorWorldScript") { }

    void OnUpdate(uint32 diff) override
    {
        GuildGroupDirector::Tick(diff);
    }
};
}

void GuildGroupDirector::Tick(uint32 diff)
{
    if (!g_GuildDirectorEnable)
        return;

    g_tickAccumulator += diff;
    if (g_tickAccumulator < 500)
        return;
    uint32 step = g_tickAccumulator;
    g_tickAccumulator = 0;

    std::vector<PendingDungeonRequest> work;
    {
        std::lock_guard<std::mutex> lock(g_pendingMutex);
        work.reserve(g_pending.size());
        for (auto& [guid, pending] : g_pending)
        {
            pending.elapsedMs += step;
            work.push_back(pending);
        }
    }

    for (PendingDungeonRequest const& pending : work)
    {
        Player* player = ObjectAccessor::FindConnectedPlayer(
            ObjectGuid::Create<HighGuid::Player>(static_cast<ObjectGuid::LowType>(pending.playerGuid)));
        if (!player)
        {
            RemoveRequest(pending.playerGuid);
            continue;
        }

        ChatHandler handler(player->GetSession());

        if (pending.elapsedMs >= g_GuildDirectorReadyTimeoutMs)
        {
            handler.PSendSysMessage(
                "Guild Director: party formation for {} timed out. No teleport was performed.",
                pending.destinationName);
            RemoveRequest(pending.playerGuid);
            continue;
        }

        Group* group = player->GetGroup();
        if (!group || group->GetMembersCount() < 5)
            continue;

        if (group->GetLeaderGUID() != player->GetGUID() || CountRealHumans(group) != 1)
        {
            handler.SendSysMessage("Guild Director: group composition changed while forming. Automatic travel was cancelled.");
            RemoveRequest(pending.playerGuid);
            continue;
        }

        // Bot logins are asynchronous. Only sync once all four companions are actually present.
        // The existing sync path handles level, era, spec and gear for the persistent roster.
        RaidRosterCommand::HandleSync(&handler);

        if (g_GuildDirectorAutoTravel)
        {
            AdventureCommand::HandleGo(
                &handler,
                Optional<std::string>(pending.destinationAlias));
        }
        else
        {
            handler.PSendSysMessage(
                "Guild Director: group for {} is ready. AutoTravel is disabled.",
                pending.destinationName);
        }

        RemoveRequest(pending.playerGuid);
    }
}

void AddGuildGroupDirectorScripts()
{
    new GuildGroupDirectorPlayerScript();
    new GuildGroupDirectorWorldScript();
}
