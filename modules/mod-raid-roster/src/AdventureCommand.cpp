#include "AdventureCommand.h"

#include "Group.h"
#include "IndividualProgression.h"
#include "ObjectMgr.h"
#include "Player.h"
#include "PlayerbotAI.h"
#include "RBAC.h"

#include <algorithm>
#include <array>
#include <cctype>
#include <string>
#include <utility>
#include <vector>

using namespace Acore::ChatCommands;

namespace
{
struct AdventureDestination
{
    char const* alias;
    char const* name;
    uint32 instanceMap;
    uint8 minLevel;
    uint8 minProgression;
};

// We intentionally store only stable instance map IDs. Exterior coordinates come from
// AzerothCore's own areatrigger data through GetGoBackTrigger(), so upstream DB corrections do not
// require coordinate updates in this fork.
constexpr std::array<AdventureDestination, 32> Destinations = {{
    {"ramparts",       "Hellfire Ramparts",          543, 60, 8},
    {"bloodfurnace",   "The Blood Furnace",          542, 60, 8},
    {"shatteredhalls", "The Shattered Halls",        540, 65, 8},
    {"slavepens",      "The Slave Pens",             547, 60, 8},
    {"underbog",       "The Underbog",               546, 61, 8},
    {"steamvault",     "The Steamvault",             545, 65, 8},
    {"manatombs",      "Mana-Tombs",                 557, 62, 8},
    {"auchenai",       "Auchenai Crypts",            558, 63, 8},
    {"sethekk",        "Sethekk Halls",              556, 65, 8},
    {"shadowlab",      "Shadow Labyrinth",           555, 67, 8},
    {"oldhillsbrad",   "Old Hillsbrad Foothills",    560, 66, 8},
    {"blackmorass",    "The Black Morass",           269, 68, 8},
    {"mechanar",       "The Mechanar",               554, 68, 8},
    {"botanica",       "The Botanica",               553, 68, 8},
    {"arcatraz",       "The Arcatraz",               552, 68, 8},
    {"magisters",      "Magisters' Terrace",         585, 70, 12},
    {"utgardekeep",    "Utgarde Keep",               574, 68, 13},
    {"nexus",          "The Nexus",                  576, 68, 13},
    {"azjol",          "Azjol-Nerub",                601, 68, 13},
    {"ahnkahet",       "Ahn'kahet: The Old Kingdom", 619, 68, 13},
    {"draktharon",     "Drak'Tharon Keep",           600, 72, 13},
    {"violethold",     "The Violet Hold",            608, 73, 13},
    {"gundrak",        "Gundrak",                    604, 74, 13},
    {"hallsofstone",   "Halls of Stone",             599, 75, 13},
    {"hallsoflightning","Halls of Lightning",        602, 77, 13},
    {"oculus",         "The Oculus",                 578, 77, 13},
    {"utgardepinnacle","Utgarde Pinnacle",           575, 77, 13},
    {"culling",        "The Culling of Stratholme",  595, 78, 13},
    {"trial",          "Trial of the Champion",      650, 80, 13},
    {"forgeofsouls",   "The Forge of Souls",         632, 80, 16},
    {"pitofsaron",     "Pit of Saron",               658, 80, 16},
    {"hallsofreflection","Halls of Reflection",       668, 80, 16},
}};

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
    value.erase(std::remove_if(value.begin(), value.end(), [](unsigned char c) {
        return std::isspace(c) || c == '-' || c == '_' || c == '\'' || c == ':';
    }), value.end());
    std::transform(value.begin(), value.end(), value.begin(), [](unsigned char c) {
        return static_cast<char>(std::tolower(c));
    });
    return value;
}

std::string Tokenize(std::string value)
{
    for (char& c : value)
    {
        unsigned char uc = static_cast<unsigned char>(c);
        if (std::isalnum(uc))
            c = static_cast<char>(std::tolower(uc));
        else
            c = ' ';
    }
    return " " + value + " ";
}

bool ContainsToken(std::string const& tokenized, std::string const& token)
{
    return tokenized.find(" " + token + " ") != std::string::npos;
}

AdventureDestination const* FindDestination(std::string const& value)
{
    std::string wanted = Normalize(value);
    for (AdventureDestination const& destination : Destinations)
        if (wanted == destination.alias || wanted == Normalize(destination.name))
            return &destination;
    return nullptr;
}

uint8 GetProgression(Player* player)
{
    return player ? sIndividualProgression->GetPlayerProgressionFromQuests(player) : 0;
}

bool CanTravel(Player* player, AdventureDestination const& destination, ChatHandler* handler)
{
    if (player->GetLevel() < destination.minLevel)
    {
        handler->PSendSysMessage("{} requires level {} (you are {}).", destination.name,
            uint32(destination.minLevel), uint32(player->GetLevel()));
        return false;
    }
    if (GetProgression(player) < destination.minProgression)
    {
        handler->PSendSysMessage("{} is not unlocked in your current progression era.", destination.name);
        return false;
    }
    if (player->IsInCombat())
    {
        handler->SendSysMessage("You cannot use adventure travel while in combat.");
        return false;
    }
    if (!player->IsAlive())
    {
        handler->SendSysMessage("You must be alive to use adventure travel.");
        return false;
    }
    return true;
}

bool CanPartyMemberTravel(Player* member, AdventureDestination const& destination, ChatHandler* handler)
{
    if (!member)
        return true;
    if (member->GetLevel() < destination.minLevel)
    {
        handler->PSendSysMessage("{} is level {} but {} requires level {}. Travel was cancelled for the whole party.",
            member->GetName(), uint32(member->GetLevel()), destination.name, uint32(destination.minLevel));
        return false;
    }
    if (IsRealPlayer(member) && GetProgression(member) < destination.minProgression)
    {
        handler->PSendSysMessage("{} has not unlocked {} yet. Travel was cancelled for the whole party.",
            member->GetName(), destination.name);
        return false;
    }
    if (member->IsInCombat())
    {
        handler->PSendSysMessage("{} is in combat. Travel was cancelled for the whole party.", member->GetName());
        return false;
    }
    if (!member->IsAlive())
    {
        handler->PSendSysMessage("{} is dead. Travel was cancelled for the whole party.", member->GetName());
        return false;
    }
    return true;
}
}

bool AdventureCommand::ResolveMention(std::string const& text, std::string& alias, std::string& displayName)
{
    std::string normalized = Normalize(text);
    std::string tokenized = Tokenize(text);

    // Full display names are safe to substring-match after punctuation/spacing normalization.
    // Bare command aliases are token-matched instead. This prevents aliases such as "trial" from
    // firing inside unrelated prose while still allowing natural messages such as "run nexus".
    for (AdventureDestination const& destination : Destinations)
    {
        if (normalized.find(Normalize(destination.name)) != std::string::npos)
        {
            alias = destination.alias;
            displayName = destination.name;
            return true;
        }
    }

    for (AdventureDestination const& destination : Destinations)
    {
        if (std::string(destination.alias) == "trial")
            continue; // use "toc" or the full "Trial of the Champion" name in natural chat.
        if (ContainsToken(tokenized, destination.alias))
        {
            alias = destination.alias;
            displayName = destination.name;
            return true;
        }
    }

    for (auto const& mention : CommonMentions)
    {
        if (!ContainsToken(tokenized, mention.first))
            continue;
        if (AdventureDestination const* destination = FindDestination(mention.second))
        {
            alias = destination->alias;
            displayName = destination->name;
            return true;
        }
    }
    return false;
}

bool AdventureCommand::IsDestinationUnlocked(Player* player, std::string const& destinationValue, std::string& reason)
{
    if (!player)
    {
        reason = "No player is available.";
        return false;
    }
    AdventureDestination const* destination = FindDestination(destinationValue);
    if (!destination)
    {
        reason = "That dungeon is not in the Adventure Travel catalog.";
        return false;
    }
    if (player->GetLevel() < destination->minLevel)
    {
        reason = std::string(destination->name) + " requires level " + std::to_string(destination->minLevel) + ".";
        return false;
    }
    if (GetProgression(player) < destination->minProgression)
    {
        reason = std::string(destination->name) + " is not unlocked in your current progression era.";
        return false;
    }
    reason.clear();
    return true;
}

ChatCommandTable AdventureCommand::GetCommands() const
{
    static ChatCommandTable sub = {{ "list", HandleList, SEC_PLAYER, Console::No }, { "go", HandleGo, SEC_PLAYER, Console::No }};
    static ChatCommandTable root = { { "adventure", sub } };
    return root;
}

bool AdventureCommand::HandleList(ChatHandler* handler)
{
    Player* player = handler->GetSession() ? handler->GetSession()->GetPlayer() : nullptr;
    if (!player)
        return false;
    uint8 progression = GetProgression(player);
    handler->SendSysMessage("Adventure travel destinations available to you:");
    for (AdventureDestination const& destination : Destinations)
        if (player->GetLevel() >= destination.minLevel && progression >= destination.minProgression)
            handler->PSendSysMessage("  .adventure go {} - {}", destination.alias, destination.name);
    return true;
}

bool AdventureCommand::HandleGo(ChatHandler* handler, Optional<std::string> destinationArg)
{
    Player* player = handler->GetSession() ? handler->GetSession()->GetPlayer() : nullptr;
    if (!player)
        return false;
    if (!destinationArg || destinationArg->empty())
    {
        handler->SendSysMessage("Usage: .adventure go <destination>. Use .adventure list to see unlocked destinations.");
        return true;
    }

    AdventureDestination const* destination = FindDestination(*destinationArg);
    if (!destination)
    {
        handler->SendSysMessage("Unknown destination. Use .adventure list to see unlocked destinations.");
        return true;
    }
    if (!CanTravel(player, *destination, handler))
        return true;

    AreaTriggerTeleport const* entrance = sObjectMgr->GetGoBackTrigger(destination->instanceMap);
    if (!entrance)
    {
        handler->PSendSysMessage("No safe exterior entrance is registered for {}. Travel was cancelled.", destination->name);
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
            if (!member)
                continue;
            if (!CanPartyMemberTravel(member, *destination, handler))
                return true;
            travelers.push_back(member);
        }
    }
    else
    {
        travelers.push_back(player);
    }

    uint32 moved = 0;
    for (Player* traveler : travelers)
        if (traveler->TeleportTo(entrance->target_mapId, entrance->target_X, entrance->target_Y,
                entrance->target_Z, entrance->target_Orientation))
            ++moved;

    if (moved != travelers.size())
    {
        handler->PSendSysMessage("Adventure travel to {} was only partially successful: {} of {} online traveler(s) moved. No additional teleport was forced.",
            destination->name, moved, uint32(travelers.size()));
        return true;
    }

    handler->PSendSysMessage("Adventure travel: {} player(s) sent to the entrance of {}.", moved, destination->name);
    return true;
}
