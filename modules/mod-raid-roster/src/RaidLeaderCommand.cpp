#include "RaidLeaderCommand.h"
#include "RaidLeaderKnowledge.h"
#include "PBChatterOllama.h"

#include "Player.h"
#include "PlayerbotAI.h"
#include "RBAC.h"
#include "StringFormat.h"

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

void PrintGroundedBrief(ChatHandler* handler, Player* player, RaidLeaderKnowledge::Encounter const& encounter)
{
    handler->PSendSysMessage("=== {}: {} ===", encounter.raid, encounter.boss);
    handler->PSendSysMessage("Status: {}", RaidLeaderKnowledge::ReadinessName(encounter.readiness));
    handler->PSendSysMessage("Your detected role: {}", PlayerRole(player));
    handler->PSendSysMessage("Overview: {}", encounter.overview);
    handler->PSendSysMessage("YOUR JOB: {}", RoleJob(encounter, player));
    handler->PSendSysMessage("BOT AUTOMATION: {}", encounter.botAutomation);
    handler->PSendSysMessage("Playerbots strategy source: {}", encounter.playerbotStrategy);
    if (!encounter.caveat.empty())
        handler->PSendSysMessage("CAVEAT: {}", encounter.caveat);
}

void PrintEncounterSet(ChatHandler* handler, std::vector<RaidLeaderKnowledge::Encounter> const& encounters,
                       std::string& currentRaid)
{
    for (RaidLeaderKnowledge::Encounter const& encounter : encounters)
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
}
}

ChatCommandTable RaidLeaderCommand::GetCommands() const
{
    static ChatCommandTable sub =
    {
        { "list", HandleList, SEC_PLAYER, Console::No },
        { "boss", HandleBoss, SEC_PLAYER, Console::No },
        { "ai", HandleAi, SEC_PLAYER, Console::No },
    };
    static ChatCommandTable root = { { "raidbrief", sub } };
    return root;
}

bool RaidLeaderCommand::HandleList(ChatHandler* handler)
{
    handler->SendSysMessage("Grounded raid briefs currently available (TBC + WotLK, including current Ulduar/RS/VoA strategy coverage):");
    std::string currentRaid;
    PrintEncounterSet(handler, RaidLeaderKnowledge::Encounters(), currentRaid);
    // Supplemental rows deliberately come after the historical table. A raid header is printed
    // again when needed, which is clearer than pretending the two independently audited sets are
    // one source revision.
    currentRaid.clear();
    PrintEncounterSet(handler, RaidLeaderKnowledge::SupplementalEncounters(), currentRaid);
    handler->SendSysMessage("Use .raidbrief boss <alias> for deterministic truth, or .raidbrief ai <alias> for a local-model pre-pull callout grounded only in that truth.");
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

    RaidLeaderKnowledge::Encounter const* encounter = RaidLeaderKnowledge::FindAny(*boss);
    if (!encounter)
    {
        handler->SendSysMessage("No unambiguous grounded encounter brief matched that alias. Use .raidbrief list.");
        return true;
    }

    PrintGroundedBrief(handler, player, *encounter);
    return true;
}

bool RaidLeaderCommand::HandleAi(ChatHandler* handler, Optional<std::string> boss)
{
    Player* player = handler->GetSession() ? handler->GetSession()->GetPlayer() : nullptr;
    if (!player)
        return false;

    if (!boss || boss->empty())
    {
        handler->SendSysMessage("Usage: .raidbrief ai <boss alias>. Use .raidbrief list for available encounters.");
        return true;
    }

    RaidLeaderKnowledge::Encounter const* encounter = RaidLeaderKnowledge::FindAny(*boss);
    if (!encounter)
    {
        handler->SendSysMessage("No unambiguous grounded encounter brief matched that alias. Use .raidbrief list.");
        return true;
    }

    std::string const systemPrompt =
        "You are a local WoW raid-leader voice layer. The supplied encounter record is the only source of truth. "
        "Rewrite it as one concise pre-pull callout for the named player's role. Never add, infer, embellish, or correct mechanics. "
        "Never claim the bots can do anything not stated in BOT AUTOMATION or VERIFIED PLAYERBOT STRATEGY. "
        "Preserve any caveat or uncertainty. If the record is incomplete, say so. No markdown and no invented phase names.";

    std::string prompt = Acore::StringFormat(
        "Raid: {}\nBoss: {}\nReadiness: {}\nPlayer role: {}\nOverview: {}\nPLAYER JOB: {}\nBOT AUTOMATION: {}\n"
        "VERIFIED PLAYERBOT STRATEGY: {}\nCaveat: {}\n"
        "Return a short raid-leader callout, ideally under 180 characters, using only those facts.",
        encounter->raid,
        encounter->boss,
        RaidLeaderKnowledge::ReadinessName(encounter->readiness),
        PlayerRole(player),
        encounter->overview,
        RoleJob(*encounter, player),
        encounter->botAutomation,
        encounter->playerbotStrategy,
        encounter->caveat.empty() ? "none recorded" : encounter->caveat);

    std::string narration = PBChatterOllama::Ask(systemPrompt, prompt);
    if (narration.empty())
    {
        handler->SendSysMessage("[Local Raid Leader] Ollama is unavailable or returned no safe text. Falling back to the deterministic brief.");
        PrintGroundedBrief(handler, player, *encounter);
        return true;
    }

    handler->PSendSysMessage("[Local Raid Leader] {}: {}", encounter->boss, narration);
    handler->SendSysMessage("Grounding source: deterministic RaidLeaderKnowledge. If narration ever conflicts, .raidbrief boss is authoritative.");
    return true;
}
