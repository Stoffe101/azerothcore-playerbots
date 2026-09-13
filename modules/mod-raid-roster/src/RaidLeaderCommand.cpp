#include "RaidLeaderCommand.h"
#include "RaidLeaderKnowledge.h"

#include "Player.h"
#include "PlayerbotAI.h"
#include "RBAC.h"

using namespace Acore::ChatCommands;

namespace
{
char const* PlayerRole(Player* player)
{
    if (!player)
        return "unknown";
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
}

ChatCommandTable RaidLeaderCommand::GetCommands() const
{
    static ChatCommandTable sub =
    {
        { "list", HandleList, SEC_PLAYER, Console::No },
        { "boss", HandleBoss, SEC_PLAYER, Console::No },
    };
    static ChatCommandTable root = { { "raidbrief", sub } };
    return root;
}

bool RaidLeaderCommand::HandleList(ChatHandler* handler)
{
    handler->SendSysMessage("Grounded raid briefs currently available (TBC + WotLK):");
    std::string currentRaid;
    for (RaidLeaderKnowledge::Encounter const& encounter : RaidLeaderKnowledge::Encounters())
    {
        if (encounter.raid != currentRaid)
        {
            currentRaid = encounter.raid;
            handler->PSendSysMessage("{}:", currentRaid);
        }
        handler->PSendSysMessage(
            "  [{}] {}",
            RaidLeaderKnowledge::ReadinessName(encounter.readiness),
            encounter.boss);
    }
    handler->SendSysMessage("Use .raidbrief boss <alias>, e.g. .raidbrief boss aran or .raidbrief boss gruul.");
    return true;
}

bool RaidLeaderCommand::HandleBoss(ChatHandler* handler, Optional<std::string> boss)
{
    Player* player = handler->GetSession() ? handler->GetSession()->GetPlayer() : nullptr;
    if (!player)
        return false;

    if (!boss || boss->empty())
    {
        handler->SendSysMessage("Usage: .raidbrief boss <boss alias>. Use .raidbrief list for available encounters.");
        return true;
    }

    RaidLeaderKnowledge::Encounter const* encounter = RaidLeaderKnowledge::Find(*boss);
    if (!encounter)
    {
        handler->SendSysMessage("No unambiguous grounded encounter brief matched that alias. Use .raidbrief list.");
        return true;
    }

    handler->PSendSysMessage("=== {}: {} ===", encounter->raid, encounter->boss);
    handler->PSendSysMessage("Status: {}", RaidLeaderKnowledge::ReadinessName(encounter->readiness));
    handler->PSendSysMessage("Your detected role: {}", PlayerRole(player));
    handler->PSendSysMessage("Overview: {}", encounter->overview);
    handler->PSendSysMessage("YOUR JOB: {}", RoleJob(*encounter, player));
    handler->PSendSysMessage("BOT AUTOMATION: {}", encounter->botAutomation);
    handler->PSendSysMessage("Playerbots strategy source: {}", encounter->playerbotStrategy);
    if (!encounter->caveat.empty())
        handler->PSendSysMessage("CAVEAT: {}", encounter->caveat);

    return true;
}