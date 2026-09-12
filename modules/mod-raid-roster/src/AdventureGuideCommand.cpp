#include "AdventureGuideCommand.h"

#include "AdventureCatalog.h"
#include "AdventureCommand.h"
#include "IndividualProgression.h"
#include "Player.h"
#include "PlayerbotAI.h"
#include "RaidRosterCommand.h"
#include "RaidRosterStore.h"
#include "RBAC.h"

#include <algorithm>
#include <cctype>
#include <string>

using namespace Acore::ChatCommands;

namespace
{
Player* GetPlayer(ChatHandler* handler)
{
    return handler && handler->GetSession() ? handler->GetSession()->GetPlayer() : nullptr;
}

std::string Lower(std::string value)
{
    std::transform(value.begin(), value.end(), value.begin(), [](unsigned char c)
    {
        return static_cast<char>(std::tolower(c));
    });
    return value;
}

bool MatchesKind(AdventureActivity const& activity, Optional<std::string> kind)
{
    if (!kind || kind->empty() || Lower(*kind) == "all")
        return true;
    std::string value = Lower(*kind);
    if (value == "dungeon" || value == "dungeons")
        return activity.kind == AdventureActivityKind::Dungeon;
    if (value == "raid" || value == "raids")
        return activity.kind == AdventureActivityKind::Raid;
    return false;
}

char const* KindName(AdventureActivityKind kind)
{
    return kind == AdventureActivityKind::Dungeon ? "Dungeon" : "Raid";
}

void PrintReadyLine(ChatHandler* handler, Player* player, AdventureActivity const& activity)
{
    std::string reason;
    bool unlocked = AdventureCatalog::IsUnlocked(player, activity, reason);
    handler->PSendSysMessage(
        "[AG] {}|{}|{}|{}|{}|{}|{}|{}",
        activity.alias,
        activity.name,
        KindName(activity.kind),
        AdventureCatalog::SupportLabel(activity.support),
        uint32(activity.minLevel),
        uint32(activity.preferredSize),
        unlocked ? "UNLOCKED" : "LOCKED",
        unlocked ? activity.supportNote : reason);
}
}

ChatCommandTable AdventureGuideCommand::GetCommands() const
{
    static ChatCommandTable sub =
    {
        { "finder", HandleFinder, SEC_PLAYER, Console::No },
        { "compat", HandleCompatibility, SEC_PLAYER, Console::No },
        { "roadmap", HandleRoadmap, SEC_PLAYER, Console::No },
        { "go", HandleGo, SEC_PLAYER, Console::No },
        { "prepare", HandlePrepare, SEC_PLAYER, Console::No },
    };
    static ChatCommandTable root = { { "guide", sub } };
    return root;
}

bool AdventureGuideCommand::HandleFinder(ChatHandler* handler, Optional<std::string> kind)
{
    Player* player = GetPlayer(handler);
    if (!player)
        return false;

    handler->SendSysMessage("[AG] BEGIN|FINDER");
    for (AdventureActivity const& activity : AdventureCatalog::All())
    {
        if (activity.support != AdventureSupport::Ready || !MatchesKind(activity, kind))
            continue;
        PrintReadyLine(handler, player, activity);
    }
    handler->SendSysMessage("[AG] END|FINDER");
    return true;
}

bool AdventureGuideCommand::HandleCompatibility(ChatHandler* handler, Optional<std::string> kind)
{
    Player* player = GetPlayer(handler);
    if (!player)
        return false;

    handler->SendSysMessage("[AG] BEGIN|COMPAT");
    for (AdventureActivity const& activity : AdventureCatalog::All())
    {
        if (!MatchesKind(activity, kind))
            continue;
        PrintReadyLine(handler, player, activity);
    }
    handler->SendSysMessage("[AG] END|COMPAT");
    return true;
}

bool AdventureGuideCommand::HandleRoadmap(ChatHandler* handler)
{
    Player* player = GetPlayer(handler);
    if (!player)
        return false;

    uint8 progression = sIndividualProgression->GetPlayerProgressionFromQuests(player);
    handler->PSendSysMessage("[AG] ROADMAP|LEVEL|{}", uint32(player->GetLevel()));
    handler->PSendSysMessage("[AG] ROADMAP|PROGRESSION|{}", uint32(progression));

    if (player->GetLevel() < 70)
    {
        handler->SendSysMessage("[AG] ROADMAP|NOW|Level through Outland and run Guild Ready TBC dungeons.");
        handler->SendSysMessage("[AG] ROADMAP|NEXT|Reach 70, then Karazhan / Gruul / Magtheridon.");
        return true;
    }

    if (progression <= 8)
    {
        handler->SendSysMessage("[AG] ROADMAP|NOW|Karazhan / Gruul / Magtheridon are your first raid tier.");
        handler->SendSysMessage("[AG] ROADMAP|NEXT|Serpentshrine Cavern / Tempest Keep.");
    }
    else if (progression == 9)
    {
        handler->SendSysMessage("[AG] ROADMAP|NOW|Serpentshrine Cavern / Tempest Keep.");
        handler->SendSysMessage("[AG] ROADMAP|NEXT|Hyjal Summit / Black Temple.");
    }
    else if (progression <= 11)
    {
        handler->SendSysMessage("[AG] ROADMAP|NOW|Hyjal Summit / Black Temple.");
        handler->SendSysMessage("[AG] ROADMAP|NEXT|Zul'Aman catch-up; Sunwell remains experimental in this fork until validated.");
    }
    else if (progression == 12)
    {
        handler->SendSysMessage("[AG] ROADMAP|NOW|Zul'Aman is Guild Ready. Sunwell is still experimental.");
        handler->SendSysMessage("[AG] ROADMAP|NEXT|Advance to Wrath when you want Naxxramas / EoE / Obsidian Sanctum.");
    }
    else if (progression == 13)
    {
        handler->SendSysMessage("[AG] ROADMAP|NOW|Naxxramas / Eye of Eternity / Obsidian Sanctum / Onyxia are Guild Ready.");
        handler->SendSysMessage("[AG] ROADMAP|NEXT|Ulduar is experimental, not normal Finder content yet.");
    }
    else if (progression == 14)
    {
        handler->SendSysMessage("[AG] ROADMAP|NOW|Ulduar is available but marked experimental/WIP.");
        handler->SendSysMessage("[AG] ROADMAP|NEXT|Trial of the Crusader is not Finder Ready; ICC becomes the next green target later.");
    }
    else if (progression == 15)
    {
        handler->SendSysMessage("[AG] ROADMAP|NOW|Trial of the Crusader is WIP and excluded from the normal Finder.");
        handler->SendSysMessage("[AG] ROADMAP|NEXT|Icecrown Citadel at progression 16.");
    }
    else if (progression == 16)
    {
        handler->SendSysMessage("[AG] ROADMAP|NOW|Icecrown Citadel normal mode is Guild Ready.");
        handler->SendSysMessage("[AG] ROADMAP|NEXT|Ruby Sanctum is experimental/WIP.");
    }
    else
    {
        handler->SendSysMessage("[AG] ROADMAP|NOW|You are in late/final WotLK progression.");
        handler->SendSysMessage("[AG] ROADMAP|NEXT|ICC remains the reliable endgame target; experimental raids stay opt-in.");
    }

    return true;
}

bool AdventureGuideCommand::HandleGo(ChatHandler* handler, Optional<std::string> alias)
{
    Player* player = GetPlayer(handler);
    if (!player)
        return false;
    if (!alias || alias->empty())
    {
        handler->SendSysMessage("Usage: .guide go <activity>. Use .guide finder first.");
        return true;
    }

    AdventureActivity const* activity = AdventureCatalog::Find(*alias);
    if (!activity || activity->support != AdventureSupport::Ready)
    {
        handler->SendSysMessage("Adventure Guide only offers travel for Guild Ready activities.");
        return true;
    }

    std::string reason;
    if (!AdventureCatalog::IsUnlocked(player, *activity, reason))
    {
        handler->PSendSysMessage("Adventure Guide: {}", reason);
        return true;
    }

    return AdventureCommand::TravelToEntrance(handler, *activity);
}

bool AdventureGuideCommand::HandlePrepare(ChatHandler* handler, Optional<std::string> alias)
{
    Player* player = GetPlayer(handler);
    if (!player)
        return false;
    if (!alias || alias->empty())
    {
        handler->SendSysMessage("Usage: .guide prepare <raid>. Dungeon party formation is handled by the Guild Director.");
        return true;
    }

    AdventureActivity const* activity = AdventureCatalog::Find(*alias);
    if (!activity || activity->kind != AdventureActivityKind::Raid || activity->support != AdventureSupport::Ready)
    {
        handler->SendSysMessage("That activity is not a Guild Ready raid. Only green raids can be prepared automatically.");
        return true;
    }

    std::string reason;
    if (!AdventureCatalog::IsUnlocked(player, *activity, reason))
    {
        handler->PSendSysMessage("Adventure Guide: {}", reason);
        return true;
    }

    uint32 owner = player->GetGUID().GetCounter();
    if (!RaidRosterStore::Exists(owner))
    {
        handler->PSendSysMessage("Adventure Guide: creating your persistent roster for {}...", activity->name);
        RaidRosterCommand::HandleCreate(handler);
    }
    if (!RaidRosterStore::Exists(owner))
    {
        handler->SendSysMessage("Adventure Guide could not create the persistent roster.");
        return true;
    }

    RaidRosterCommand::HandleLogin(
        handler,
        Optional<uint32>(activity->preferredSize),
        {});
    handler->PSendSysMessage(
        "Adventure Guide: preparing {} players for {}. Bot logins are asynchronous; use the Travel button once the roster is present.",
        uint32(activity->preferredSize), activity->name);
    return true;
}
