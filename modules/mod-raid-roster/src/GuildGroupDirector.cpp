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
    std::vector<uint32> expectedHumanGuids;
    std::vector<uint32> expectedBotGuids;
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

uint32 CountWords(std::string const& text)
{
    uint32 words = 0;
    bool inWord = false;
    for (unsigned char c : text)
    {
        bool const alnum = std::isalnum(c) != 0;
        if (alnum && !inWord)
            ++words;
        inWord = alnum;
    }
    return words;
}

bool LooksLikeGroupRequest(std::string const& original)
{
    std::string text = Lower(original);

    // Require grouping/action language instead of treating every question about a dungeon as a
    // group request. This deliberately does NOT accept broad cues such as "anyone" or "can we"
    // on their own: "anyone know if Ramparts loot is good?" must remain ordinary guild chat.
    static constexpr char const* cues[] = {
        "up for", "wanna run", "want to run", "who wants to run", "who wants in",
        "let's run", "lets run", "lfg", "need group", "group for", "party for",
        "queue for", "run some", "run the", "run "
    };
    for (char const* cue : cues)
        if (text.find(cue) != std::string::npos)
            return true;

    // Preserve natural one-word shorthand such as "ramps?" without turning arbitrary questions
    // into actions. Multi-word questions need an explicit grouping cue above.
    return text.find('?') != std::string::npos && CountWords(text) == 1;
}

std::vector<Player*> RealHumans(Player* master)
{
    std::vector<Player*> humans;
    if (!master)
        return humans;

    if (Group* group = master->GetGroup())
    {
        for (GroupReference* reference = group->GetFirstMember(); reference; reference = reference->next())
        {
            Player* member = reference->GetSource();
            if (member && IsRealPlayer(member))
                humans.push_back(member);
        }
    }
    else
    {
        humans.push_back(master);
    }
    return humans;
}

uint32 CountOnlineMembers(Group* group)
{
    if (!group)
        return 0;

    uint32 count = 0;
    for (GroupReference* reference = group->GetFirstMember(); reference; reference = reference->next())
        if (reference->GetSource())
            ++count;
    return count;
}

bool HasOfflineMember(Group* group)
{
    return group && group->GetMembersCount() != CountOnlineMembers(group);
}

std::vector<uint32> GuidCounters(std::vector<Player*> const& players)
{
    std::vector<uint32> guids;
    guids.reserve(players.size());
    for (Player* player : players)
        if (player)
            guids.push_back(player->GetGUID().GetCounter());
    std::sort(guids.begin(), guids.end());
    return guids;
}

bool ValidateHumanPartyForDestination(Player* master, std::string const& alias, ChatHandler& handler)
{
    if (Group* group = master ? master->GetGroup() : nullptr)
    {
        if (HasOfflineMember(group))
        {
            handler.SendSysMessage("Guild Director: your current group has an offline member. Remove/reconnect them before automatic formation so party capacity is deterministic.");
            return false;
        }
    }

    std::vector<Player*> humans = RealHumans(master);
    if (humans.empty() || humans.size() > 5)
    {
        handler.SendSysMessage("Guild Director: this dungeon requires between one and five online real players in the current party.");
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

bool PrepareRosterBots(
    Player* master,
    ChatHandler& handler,
    std::vector<uint32>& expectedHumanGuids,
    std::vector<uint32>& expectedBotGuids)
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
    expectedHumanGuids = GuidCounters(humans);
    expectedBotGuids.clear();
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

    // Normal 5-player composition is one tank, one healer, three DPS. Do not silently turn a
    // two-tank/two-healer human lineup into something the director calls "balanced".
    if (humanTanks > 1 || humanHeals > 1 || humanDps > 3)
    {
        handler.PSendSysMessage(
            "Guild Director: current human roles are {} tank / {} healer / {} DPS. Automatic 5-player formation supports at most 1 tank, 1 healer and 3 DPS; adjust the human lineup/specs first.",
            humanTanks, humanHeals, humanDps);
        return false;
    }

    uint32 botsNeeded = 5u - static_cast<uint32>(humans.size());
    uint32 needTank = humanTanks == 0 ? 1 : 0;
    uint32 needHeal = humanHeals == 0 ? 1 : 0;

    if (needTank + needHeal > botsNeeded)
    {
        handler.PSendSysMessage(
            "Guild Director: the current {}-human lineup leaves only {} bot slot(s), but both a tank and healer are still missing. Change a spec or party lineup first.",
            uint32(humans.size()), botsNeeded);
        return false;
    }

    uint32 needDps = botsNeeded - needTank - needHeal;
    if (humanDps + needDps != 3)
    {
        handler.SendSysMessage("Guild Director: could not produce an exact 1 tank / 1 healer / 3 DPS composition from the current human lineup.");
        return false;
    }

    PlayerbotMgr* mgr = GET_PLAYERBOT_MGR(master);
    if (!mgr || !master->GetSession())
    {
        handler.SendSysMessage("Guild Director: Playerbot manager/session is unavailable.");
        return false;
    }

    auto eligible = [level = master->GetLevel()](RaidRosterRow const& row)
    {
        return RaidCompEligible(row.band, level);
    };

    Group* currentGroup = master->GetGroup();
    std::vector<RaidRosterRow> wanted;
    auto chooseRole = [&](uint8 role, uint32 needed) -> bool
    {
        std::vector<RaidRosterRow> alreadyGrouped;
        std::vector<RaidRosterRow> offline;
        for (RaidRosterRow const& row : rows)
        {
            if (row.role != role || !eligible(row))
                continue;

            ObjectGuid guid = ObjectGuid::Create<HighGuid::Player>(row.botGuid);
            Player* bot = mgr->GetPlayerBot(guid);
            if (!bot)
            {
                offline.push_back(row);
                continue;
            }

            // An online roster bot outside this party is not treated as ready. Selecting it would
            // make formation wait forever because AddPlayerBot's login invite path will not run.
            if (currentGroup && bot->GetGroup() == currentGroup)
                alreadyGrouped.push_back(row);
        }

        Acore::Containers::RandomShuffle(offline);
        for (RaidRosterRow const& row : alreadyGrouped)
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
        handler.SendSysMessage("Guild Director: the persistent roster does not currently have enough eligible, available bots for the required roles. A roster bot may already be online outside this party.");
        return false;
    }

    std::unordered_set<uint32> rosterGuids;
    for (RaidRosterRow const& row : rows)
        rosterGuids.insert(row.botGuid);

    // Do not silently hijack a group containing manually-added non-roster bots. Those may be
    // deliberate companions. Humans are fine; persistent roster bots are managed below.
    if (currentGroup)
    {
        for (GroupReference* reference = currentGroup->GetFirstMember(); reference; reference = reference->next())
        {
            Player* member = reference->GetSource();
            if (member && !IsRealPlayer(member) && !rosterGuids.count(member->GetGUID().GetCounter()))
            {
                handler.SendSysMessage("Guild Director: your current party contains a non-roster bot, so I left the group untouched.");
                return false;
            }
        }
    }

    std::set<uint32> wantedGuids;
    for (RaidRosterRow const& row : wanted)
    {
        wantedGuids.insert(row.botGuid);
        expectedBotGuids.push_back(row.botGuid);
    }
    std::sort(expectedBotGuids.begin(), expectedBotGuids.end());

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

void QueueRequest(
    Player* player,
    std::string alias,
    std::string name,
    std::vector<uint32> expectedHumanGuids,
    std::vector<uint32> expectedBotGuids)
{
    PendingDungeonRequest pending;
    pending.playerGuid = player->GetGUID().GetCounter();
    pending.destinationAlias = std::move(alias);
    pending.destinationName = std::move(name);
    pending.expectedHumanGuids = std::move(expectedHumanGuids);
    pending.expectedBotGuids = std::move(expectedBotGuids);

    std::lock_guard<std::mutex> lock(g_pendingMutex);
    g_pending[pending.playerGuid] = std::move(pending);
}

void RemoveRequest(uint32 guid)
{
    std::lock_guard<std::mutex> lock(g_pendingMutex);
    g_pending.erase(guid);
}

bool ExactOnlineComposition(Group* group, PendingDungeonRequest const& pending)
{
    if (!group)
        return false;

    std::vector<uint32> humans;
    std::vector<uint32> bots;
    for (GroupReference* reference = group->GetFirstMember(); reference; reference = reference->next())
    {
        Player* member = reference->GetSource();
        if (!member)
            continue;
        (IsRealPlayer(member) ? humans : bots).push_back(member->GetGUID().GetCounter());
    }
    std::sort(humans.begin(), humans.end());
    std::sort(bots.begin(), bots.end());
    return humans == pending.expectedHumanGuids && bots == pending.expectedBotGuids;
}

bool HasUnexpectedOnlineMember(Group* group, PendingDungeonRequest const& pending)
{
    if (!group)
        return false;

    std::unordered_set<uint32> expectedHumans(pending.expectedHumanGuids.begin(), pending.expectedHumanGuids.end());
    std::unordered_set<uint32> expectedBots(pending.expectedBotGuids.begin(), pending.expectedBotGuids.end());
    for (GroupReference* reference = group->GetFirstMember(); reference; reference = reference->next())
    {
        Player* member = reference->GetSource();
        if (!member)
            continue;
        uint32 guid = member->GetGUID().GetCounter();
        if (IsRealPlayer(member))
        {
            if (!expectedHumans.count(guid))
                return true;
        }
        else if (!expectedBots.count(guid))
        {
            return true;
        }
    }
    return false;
}

class GuildGroupDirectorPlayerScript : public PlayerScript
{
public:
    GuildGroupDirectorPlayerScript()
        : PlayerScript("GuildGroupDirectorPlayerScript", { PLAYERHOOK_ON_BEFORE_SEND_CHAT_MESSAGE }) { }

    void OnPlayerBeforeSendChatMessage(Player* player, uint32& type, uint32& /*lang*/, std::string& msg) override
    {
        if (!g_GuildDirectorEnable || !player || !IsRealPlayer(player) || type != CHAT_MSG_GUILD || !player->GetSession())
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

        std::vector<uint32> expectedHumans;
        std::vector<uint32> expectedBots;
        handler.PSendSysMessage("Guild Director: forming a balanced group for {}.", name);
        if (!PrepareRosterBots(player, handler, expectedHumans, expectedBots))
            return;

        QueueRequest(player, alias, name, std::move(expectedHumans), std::move(expectedBots));
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
        if (!player || !player->GetSession())
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
        if (!group)
            continue;

        if (group->GetLeaderGUID() != player->GetGUID() || HasOfflineMember(group) || HasUnexpectedOnlineMember(group, pending))
        {
            handler.SendSysMessage("Guild Director: group composition changed while forming. Automatic travel was cancelled.");
            RemoveRequest(pending.playerGuid);
            continue;
        }

        uint32 const online = CountOnlineMembers(group);
        if (online < 5)
            continue;
        if (online != 5 || group->GetMembersCount() != 5 || !ExactOnlineComposition(group, pending))
        {
            handler.SendSysMessage("Guild Director: the ready party does not exactly match the requested human/roster lineup. Automatic travel was cancelled.");
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

        // Only sync once every exact selected companion is actually present. The existing sync path
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
