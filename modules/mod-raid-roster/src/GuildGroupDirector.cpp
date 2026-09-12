#include "GuildGroupDirector.h"

#include "AdventureCommand.h"
#include "RaidRosterCommand.h"
#include "RaidRosterComp.h"
#include "RaidRosterConfig.h"
#include "RaidRosterStore.h"

#include "Chat.h"
#include "Containers.h"
#include "Group.h"
#include "ObjectAccessor.h"
#include "ObjectGuid.h"
#include "Player.h"
#include "PlayerbotAI.h"
#include "PlayerbotMgr.h"
#include "Playerbots.h"
#include "ScriptMgr.h"
#include "SharedDefines.h"

#include <algorithm>
#include <cctype>
#include <mutex>
#include <set>
#include <string>
#include <unordered_map>
#include <unordered_set>
#include <vector>

namespace
{
struct PendingDungeonRequest
{
    uint32 playerGuid = 0;
    std::string destinationAlias;
    std::string destinationName;
    uint32 expectedHumans = 1;
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
    return text.find('?') != std::string::npos;
}

std::vector<Player*> RealHumans(Player* master)
{
    std::vector<Player*> humans;
    if (!master)
        return humans;

    if (Group* group = master->GetGroup())
    {
        group->DoForAllMembers([&](Player* member)
        {
            if (member && IsRealPlayer(member))
                humans.push_back(member);
        });
    }
    else
    {
        humans.push_back(master);
    }
    return humans;
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

bool ValidateHumanPartyForDestination(Player* master, std::string const& alias, ChatHandler& handler)
{
    std::vector<Player*> humans = RealHumans(master);
    if (humans.size() > 5)
    {
        handler.SendSysMessage("Guild Director: this dungeon is a 5-player activity and your current group has more than five real players.");
        return false;
    }

    for (Player* human : humans)
    {
        if (!human->IsAlive())
        {
            handler.PSendSysMessage("Guild Director: {} is dead. Resurrect before forming/travelling.", human->GetName());
            return false;
        }
        if (human->IsInCombat())
        {
            handler.PSendSysMessage("Guild Director: {} is in combat. Finish combat first.", human->GetName());
            return false;
        }

        std::string reason;
        if (!AdventureCommand::IsDestinationUnlocked(human, alias, reason))
        {
            handler.PSendSysMessage("Guild Director: {} cannot enter yet: {}", human->GetName(), reason);
            return false;
        }
    }

    return true;
}

bool PrepareRosterBots(Player* master, ChatHandler& handler, uint32& expectedHumans)
{
    if (!master)
        return false;

    uint32 owner = master->GetGUID().GetCounter();
    std::vector<RaidRosterRow> rows = RaidRosterStore::Load(owner);
    if (rows.empty())
    {
        handler.SendSysMessage("Guild Director: persistent roster is empty.");
        return false;
    }

    std::vector<Player*> humans = RealHumans(master);
    expectedHumans = static_cast<uint32>(humans.size());
    if (humans.empty() || humans.size() > 5)
        return false;

    uint32 humanTanks = 0;
    uint32 humanHeals = 0;
    uint32 humanDps = 0;
    for (Player* human : humans)
    {
        if (PlayerbotAI::IsTank(human, true))
            ++humanTanks;
        else if (PlayerbotAI::IsHeal(human, true))
            ++humanHeals;
        else
            ++humanDps;
    }

    uint32 botsNeeded = 5u - static_cast<uint32>(humans.size());
    uint32 needTank = humanTanks >= 1 ? 0 : 1;
    uint32 needHeal = humanHeals >= 1 ? 0 : 1;

    if (needTank + needHeal > botsNeeded)
    {
        handler.PSendSysMessage(
            "Guild Director: the current {}-human lineup leaves only {} bot slot(s), but both a tank and healer are still missing. Change a spec or party lineup first.",
            uint32(humans.size()), botsNeeded);
        return false;
    }

    uint32 needDps = botsNeeded - needTank - needHeal;

    PlayerbotMgr* mgr = GET_PLAYERBOT_MGR(master);
    if (!mgr)
    {
        handler.SendSysMessage("Guild Director: Playerbot manager is unavailable.");
        return false;
    }

    auto eligible = [level = master->GetLevel()](RaidRosterRow const& row)
    {
        return RaidCompEligible(row.band, level);
    };

    std::vector<RaidRosterRow> wanted;
    auto chooseRole = [&](uint8 role, uint32 needed) -> bool
    {
        std::vector<RaidRosterRow> online;
        std::vector<RaidRosterRow> offline;
        for (RaidRosterRow const& row : rows)
        {
            if (row.role != role || !eligible(row))
                continue;
            ObjectGuid guid = ObjectGuid::Create<HighGuid::Player>(row.botGuid);
            (mgr->GetPlayerBot(guid) ? online : offline).push_back(row);
        }

        Acore::Containers::RandomShuffle(offline);
        for (RaidRosterRow const& row : online)
        {
            if (!needed)
                break;
            wanted.push_back(row);
            --needed;
        }
        for (RaidRosterRow const& row : offline)
        {
            if (!needed)
                break;
            wanted.push_back(row);
            --needed;
        }
        return needed == 0;
    };

    if (!chooseRole(0, needTank) || !chooseRole(1, needHeal) || !chooseRole(2, needDps))
    {
        handler.SendSysMessage("Guild Director: the persistent roster does not currently have enough eligible bots for the required roles.");
        return false;
    }

    std::unordered_set<uint32> rosterGuids;
    for (RaidRosterRow const& row : rows)
        rosterGuids.insert(row.botGuid);

    // Do not silently hijack a group containing manually-added non-roster bots. Those may be
    // deliberate companions. Humans are fine; persistent roster bots are managed below.
    if (Group* group = master->GetGroup())
    {
        bool unmanagedBot = false;
        group->DoForAllMembers([&](Player* member)
        {
            if (member && !IsRealPlayer(member) && !rosterGuids.count(member->GetGUID().GetCounter()))
                unmanagedBot = true;
        });
        if (unmanagedBot)
        {
            handler.SendSysMessage("Guild Director: your current party contains a non-roster bot, so I left the group untouched.");
            return false;
        }
    }

    std::set<uint32> wantedGuids;
    for (RaidRosterRow const& row : wanted)
        wantedGuids.insert(row.botGuid);

    // Re-running the request should converge on exactly the selected persistent companions.
    for (RaidRosterRow const& row : rows)
    {
        if (wantedGuids.count(row.botGuid))
            continue;
        ObjectGuid guid = ObjectGuid::Create<HighGuid::Player>(row.botGuid);
        if (mgr->GetPlayerBot(guid))
            mgr->LogoutPlayerBot(guid);
    }

    uint32 accountId = master->GetSession()->GetAccountId();
    for (RaidRosterRow const& row : wanted)
    {
        ObjectGuid guid = ObjectGuid::Create<HighGuid::Player>(row.botGuid);
        if (!mgr->GetPlayerBot(guid))
            mgr->AddPlayerBot(guid, accountId);
    }

    handler.PSendSysMessage(
        "Guild Director: filling {} slot(s): {} tank, {} healer, {} DPS. Humans already in party: {} ({} tank / {} healer / {} DPS).",
        botsNeeded, needTank, needHeal, needDps, uint32(humans.size()), humanTanks, humanHeals, humanDps);
    return true;
}

void QueueRequest(Player* player, std::string alias, std::string name, uint32 expectedHumans)
{
    PendingDungeonRequest pending;
    pending.playerGuid = player->GetGUID().GetCounter();
    pending.destinationAlias = std::move(alias);
    pending.destinationName = std::move(name);
    pending.expectedHumans = expectedHumans;

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

        Group* group = player->GetGroup();
        if (group && group->GetLeaderGUID() != player->GetGUID())
        {
            handler.SendSysMessage("Guild Director: only the current group leader can start automatic guild grouping.");
            return;
        }

        if (!ValidateHumanPartyForDestination(player, alias, handler))
            return;

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

        uint32 expectedHumans = 1;
        handler.PSendSysMessage("Guild Director: forming a balanced group for {}.", name);
        if (!PrepareRosterBots(player, handler, expectedHumans))
            return;

        QueueRequest(player, alias, name, expectedHumans);
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

        if (group->GetMembersCount() != 5 || group->GetLeaderGUID() != player->GetGUID() ||
            CountRealHumans(group) != pending.expectedHumans)
        {
            handler.SendSysMessage("Guild Director: group composition changed while forming. Automatic travel was cancelled.");
            RemoveRequest(pending.playerGuid);
            continue;
        }

        // Revalidate humans at the moment of departure in case somebody changed state/era after
        // the initial request while asynchronous bot logins were finishing.
        if (!ValidateHumanPartyForDestination(player, pending.destinationAlias, handler))
        {
            RemoveRequest(pending.playerGuid);
            continue;
        }

        // Only sync once every selected companion is actually present. The existing sync path
        // handles level, era, spec and gear for online persistent roster bots.
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
