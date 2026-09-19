#include "AdventureCommand.h"

#include "Group.h"
#include "ObjectMgr.h"
#include "Player.h"
#include "RBAC.h"
#include "WorldSession.h"

#include <algorithm>
#include <array>
#include <cctype>
#include <string>
#include <utility>
#include <vector>

using namespace Acore::ChatCommands;

namespace
{
constexpr std::array<std::pair<char const*, char const*>, 20> CommonMentions = {{
    {"ramps", "ramparts"}, {"furnace", "bloodfurnace"}, {"shh", "shatteredhalls"},
    {"pens", "slavepens"}, {"slabs", "shadowlab"}, {"ohb", "oldhillsbrad"},
    {"mech", "mechanar"}, {"mgt", "magisters"}, {"oldkingdom", "ahnkahet"},
    {"dtk", "draktharon"}, {"vh", "violethold"}, {"hos", "hallsofstone"},
    {"hol", "hallsoflightning"}, {"cos", "culling"}, {"toc", "trial"},
    {"fos", "forgeofsouls"}, {"pos", "pitofsaron"}, {"hor", "hallsofreflection"},
    {"uk", "utgardekeep"}, {"up", "utgardepinnacle"},
}};

std::string Normalize(std::string value)
{
    value.erase(std::remove_if(value.begin(), value.end(), [](unsigned char c)
    {
        return std::isspace(c) || c == '-' || c == '_' || c == '\'' || c == ':' || c == '/';
    }), value.end());
    std::transform(value.begin(), value.end(), value.begin(), [](unsigned char c)
    {
        return static_cast<char>(std::tolower(c));
    });
    return value;
}

std::string Tokenize(std::string value)
{
    for (char& c : value)
    {
        unsigned char uc = static_cast<unsigned char>(c);
        c = std::isalnum(uc) ? static_cast<char>(std::tolower(uc)) : ' ';
    }
    return " " + value + " ";
}

bool ContainsToken(std::string const& tokenized, std::string const& token)
{
    return tokenized.find(" " + token + " ") != std::string::npos;
}

AdventureActivity const* FindReadyDungeon(std::string const& value)
{
    AdventureActivity const* activity = AdventureCatalog::Find(value);
    if (!activity || activity->kind != AdventureActivityKind::Dungeon || activity->support != AdventureSupport::Ready)
        return nullptr;
    return activity;
}

bool IsRealOnlinePlayer(Player* player)
{
    return player && player->GetSession() && !player->GetSession()->IsBot();
}
}

bool AdventureCommand::ResolveMention(std::string const& text, std::string& alias, std::string& displayName)
{
    std::string normalized = Normalize(text);

    for (AdventureActivity const& activity : AdventureCatalog::All())
    {
        if (activity.kind != AdventureActivityKind::Dungeon || activity.support != AdventureSupport::Ready)
            continue;
        if (normalized.find(Normalize(activity.name)) != std::string::npos ||
            normalized.find(Normalize(activity.alias)) != std::string::npos)
        {
            alias = activity.alias;
            displayName = activity.name;
            return true;
        }
    }

    std::string tokenized = Tokenize(text);
    for (auto const& mention : CommonMentions)
    {
        if (!ContainsToken(tokenized, mention.first))
            continue;
        if (AdventureActivity const* activity = FindReadyDungeon(mention.second))
        {
            alias = activity->alias;
            displayName = activity->name;
            return true;
        }
    }

    return false;
}

bool AdventureCommand::IsDestinationUnlocked(Player* player, std::string const& destinationValue, std::string& reason)
{
    AdventureActivity const* activity = FindReadyDungeon(destinationValue);
    if (!activity)
    {
        reason = "That dungeon is not currently Guild Ready in the Adventure catalog.";
        return false;
    }
    return AdventureCatalog::IsUnlocked(player, *activity, reason);
}

ChatCommandTable AdventureCommand::GetCommands() const
{
    static ChatCommandTable sub =
    {
        { "list", HandleList, SEC_PLAYER, Console::No },
        { "go",   HandleGo,   SEC_PLAYER, Console::No },
    };
    static ChatCommandTable root = { { "adventure", sub } };
    return root;
}

bool AdventureCommand::HandleList(ChatHandler* handler)
{
    Player* player = handler->GetSession() ? handler->GetSession()->GetPlayer() : nullptr;
    if (!player)
        return false;

    handler->SendSysMessage("Guild Ready adventure-travel dungeons available to you:");
    for (AdventureActivity const& activity : AdventureCatalog::All())
    {
        if (activity.kind != AdventureActivityKind::Dungeon || activity.support != AdventureSupport::Ready)
            continue;
        std::string reason;
        if (AdventureCatalog::IsUnlocked(player, activity, reason))
            handler->PSendSysMessage("  .adventure go {} - {}", activity.alias, activity.name);
    }
    return true;
}

bool AdventureCommand::HandleGo(ChatHandler* handler, Optional<std::string> destinationArg)
{
    Player* player = handler->GetSession() ? handler->GetSession()->GetPlayer() : nullptr;
    if (!player)
        return false;

    if (!destinationArg || destinationArg->empty())
    {
        handler->SendSysMessage("Usage: .adventure go <destination>. Use .adventure list to see Guild Ready destinations.");
        return true;
    }

    AdventureActivity const* activity = FindReadyDungeon(*destinationArg);
    if (!activity)
    {
        handler->SendSysMessage("That dungeon is not currently Guild Ready. Use .adventure list.");
        return true;
    }

    std::string reason;
    if (!AdventureCatalog::IsUnlocked(player, *activity, reason))
    {
        handler->PSendSysMessage("Adventure travel cancelled: {}", reason);
        return true;
    }

    return TravelToEntrance(handler, *activity);
}

bool AdventureCommand::TravelToEntrance(ChatHandler* handler, AdventureActivity const& activity)
{
    Player* player = handler && handler->GetSession() ? handler->GetSession()->GetPlayer() : nullptr;
    if (!player)
        return false;

    if (player->IsInCombat())
    {
        handler->SendSysMessage("You cannot use adventure travel while in combat.");
        return true;
    }
    if (!player->IsAlive())
    {
        handler->SendSysMessage("You must be alive to use adventure travel.");
        return true;
    }

    AreaTriggerTeleport const* entrance = sObjectMgr->GetGoBackTrigger(activity.instanceMap);
    if (!entrance)
    {
        handler->PSendSysMessage("No safe exterior entrance is registered for {}. Travel was cancelled.", activity.name);
        return true;
    }

    std::vector<Player*> travelers;
    if (Group* group = player->GetGroup())
    {
        if (group->GetLeaderGUID() != player->GetGUID())
        {
            handler->SendSysMessage("Only the group leader can move the party with adventure travel.");
            return true;
        }

        for (GroupReference* reference = group->GetFirstMember(); reference; reference = reference->next())
        {
            Player* member = reference->GetSource();
            if (!member || !member->IsInWorld())
                continue;

            if (member->IsInCombat())
            {
                handler->PSendSysMessage("{} is in combat. Travel was cancelled for the whole group.", member->GetName());
                return true;
            }
            if (!member->IsAlive())
            {
                handler->PSendSysMessage("{} is dead. Travel was cancelled for the whole group.", member->GetName());
                return true;
            }

            // Real players retain individual progression. Do not drag a human through a dungeon
            // they have not unlocked just because the group leader has. Playerbots follow the
            // group/roster progression path and do not need human hidden-quest gating here.
            if (IsRealOnlinePlayer(member))
            {
                std::string memberReason;
                if (!AdventureCatalog::IsUnlocked(member, activity, memberReason))
                {
                    handler->PSendSysMessage(
                        "{} cannot travel to {} yet: {} Travel was cancelled for the whole group.",
                        member->GetName(), activity.name, memberReason);
                    return true;
                }
            }

            travelers.push_back(member);
        }
    }
    else
        travelers.push_back(player);

    uint32 moved = 0;
    for (Player* traveler : travelers)
    {
        if (traveler->TeleportTo(
                entrance->target_mapId,
                entrance->target_X,
                entrance->target_Y,
                entrance->target_Z,
                entrance->target_Orientation))
            ++moved;
    }

    if (moved != travelers.size())
    {
        handler->PSendSysMessage(
            "Adventure travel to {} was partially successful: {} of {} online traveler(s) moved. Failed teleports were not forced.",
            activity.name, moved, uint32(travelers.size()));
        return true;
    }

    handler->PSendSysMessage("Adventure travel: {} player(s) sent to the entrance of {}.", moved, activity.name);
    return true;
}
