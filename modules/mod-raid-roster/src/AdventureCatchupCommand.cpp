#include "AdventureCatchupCommand.h"

#include "AiFactory.h"
#include "DatabaseEnv.h"
#include "Field.h"
#include "IndividualProgression.h"
#include "Player.h"
#include "PlayerbotFactory.h"
#include "QueryResult.h"
#include "RBAC.h"
#include "SharedDefines.h"

#include <algorithm>
#include <array>
#include <cctype>
#include <mutex>
#include <string>

using namespace Acore::ChatCommands;

namespace
{
std::mutex g_catchupClaimMutex;

struct CatchupProfile
{
    char const* key;
    char const* label;
    uint8 stage;
    uint8 minLevel;
    uint32 quality;
    uint32 itemLevel;
    uint64 claimBit;
};

constexpr std::array<CatchupProfile, 9> MainProfiles = {{
    {"kara",    "Karazhan / Gruul / Magtheridon",                  8, 70, ITEM_QUALITY_RARE, 105, 1ull << 0},
    {"ssc",     "Serpentshrine Cavern / Tempest Keep",            9, 70, ITEM_QUALITY_EPIC, 120, 1ull << 1},
    {"hyjal",   "Hyjal Summit / Black Temple",                    10, 70, ITEM_QUALITY_EPIC, 128, 1ull << 2},
    {"sunwell", "Sunwell Plateau",                                12, 70, ITEM_QUALITY_EPIC, 141, 1ull << 4},
    {"naxx",    "Naxxramas / Eye of Eternity / Obsidian Sanctum", 13, 80, ITEM_QUALITY_RARE, 187, 1ull << 5},
    {"ulduar",  "Ulduar",                                         14, 80, ITEM_QUALITY_EPIC, 200, 1ull << 6},
    {"toc",     "Trial of the Crusader",                          15, 80, ITEM_QUALITY_EPIC, 219, 1ull << 7},
    {"icc",     "Icecrown Citadel",                               16, 80, ITEM_QUALITY_EPIC, 232, 1ull << 8},
    {"rs",      "Ruby Sanctum",                                   17, 80, ITEM_QUALITY_EPIC, 251, 1ull << 9},
}};

std::string Normalize(std::string value)
{
    std::transform(value.begin(), value.end(), value.begin(), [](unsigned char c)
    {
        return static_cast<char>(std::tolower(c));
    });
    value.erase(std::remove_if(value.begin(), value.end(), [](unsigned char c)
    {
        return !std::isalnum(c);
    }), value.end());
    return value;
}

CatchupProfile ZulAmanProfile()
{
    uint8 stage = static_cast<uint8>(std::clamp<int>(
        sIndividualProgression->RequiredZulAmanProgression,
        1,
        PROGRESSION_WOTLK_TIER_5));
    return {"za", "Zul'Aman", stage, 70, ITEM_QUALITY_EPIC, 125, 1ull << 3};
}

bool ResolveProfile(std::string const& raw, CatchupProfile& out)
{
    std::string key = Normalize(raw);

    if (key == "za" || key == "zulaman")
    {
        out = ZulAmanProfile();
        return true;
    }

    for (CatchupProfile const& profile : MainProfiles)
    {
        if (key == profile.key)
        {
            out = profile;
            return true;
        }
    }

    if (key == "karazhan" || key == "gruul" || key == "mag" || key == "magtheridon")
        out = MainProfiles[0];
    else if (key == "tk" || key == "tempestkeep" || key == "serpentshrine" || key == "serpentshrinecavern")
        out = MainProfiles[1];
    else if (key == "bt" || key == "blacktemple" || key == "mounthyjal" || key == "hyjalsummit")
        out = MainProfiles[2];
    else if (key == "swp" || key == "sunwellplateau")
        out = MainProfiles[3];
    else if (key == "naxxramas" || key == "eoe" || key == "eyeofeternity" || key == "os" || key == "obsidiansanctum")
        out = MainProfiles[4];
    else if (key == "totc" || key == "trialofthecrusader")
        out = MainProfiles[6];
    else if (key == "icecrown" || key == "icecrowncitadel")
        out = MainProfiles[7];
    else if (key == "ruby" || key == "rubysanctum")
        out = MainProfiles[8];
    else
        return false;

    return true;
}

uint64 LoadClaims(uint32 guid)
{
    std::lock_guard<std::mutex> lock(g_catchupClaimMutex);
    CharacterDatabase.DirectExecute(
        "INSERT IGNORE INTO mod_adventure_controls (guid) VALUES ({})",
        guid);

    if (QueryResult result = CharacterDatabase.Query(
            "SELECT catchup_claims FROM mod_adventure_controls WHERE guid = {} LIMIT 1",
            guid))
        return result->Fetch()[0].Get<uint64>();

    return 0;
}

bool TryClaim(uint32 guid, uint64 bit)
{
    std::lock_guard<std::mutex> lock(g_catchupClaimMutex);
    CharacterDatabase.DirectExecute(
        "INSERT IGNORE INTO mod_adventure_controls (guid) VALUES ({})",
        guid);

    uint64 claims = 0;
    if (QueryResult result = CharacterDatabase.Query(
            "SELECT catchup_claims FROM mod_adventure_controls WHERE guid = {} LIMIT 1",
            guid))
        claims = result->Fetch()[0].Get<uint64>();
    else
        return false;

    if ((claims & bit) != 0)
        return false;

    CharacterDatabase.DirectExecute(
        "UPDATE mod_adventure_controls SET catchup_claims = catchup_claims | {} WHERE guid = {}",
        bit,
        guid);
    return true;
}

bool EnsureProgression(ChatHandler* handler, Player* player, CatchupProfile const& profile)
{
    uint8 current = sIndividualProgression->GetPlayerProgressionFromQuests(player);
    if (current >= profile.stage)
        return true;

    sIndividualProgression->UpdateProgressionState(player, static_cast<ProgressionState>(profile.stage));
    sIndividualProgression->CheckAdjustments(player);
    sIndividualProgression->checkIPPhasing(player, player->GetAreaId());

    uint8 after = sIndividualProgression->GetPlayerProgressionFromQuests(player);
    if (after < profile.stage)
    {
        handler->PSendSysMessage(
            "Could not unlock {}. Progression stopped at stage {}. A server progression limit may be active.",
            profile.label,
            uint32(after));
        return false;
    }

    handler->PSendSysMessage("Unlocked {} before applying catch-up gear.", profile.label);
    return true;
}

bool ApplyProfile(ChatHandler* handler, Player* player, CatchupProfile const& profile)
{
    if (!player || !player->IsAlive())
    {
        handler->SendSysMessage("Catch-up gear can only be applied while alive.");
        return true;
    }

    if (player->IsInCombat())
    {
        handler->SendSysMessage("Leave combat before applying catch-up gear.");
        return true;
    }

    if (player->GetLevel() < profile.minLevel)
    {
        handler->PSendSysMessage(
            "{} catch-up gear requires level {}. You can still unlock the raid separately.",
            profile.label,
            uint32(profile.minLevel));
        return true;
    }

    if (!EnsureProgression(handler, player, profile))
        return true;

    uint32 guid = player->GetGUID().GetCounter();
    uint64 claims = LoadClaims(guid);
    if ((claims & profile.claimBit) != 0)
    {
        handler->PSendSysMessage(
            "You already claimed the {} catch-up gear package on this character.",
            profile.label);
        return true;
    }

    std::string specName = AiFactory::GetPlayerSpecName(player);
    if (specName.empty())
    {
        handler->SendSysMessage("Spend some talent points first so the server can identify your spec for catch-up gear.");
        return true;
    }

    if (!TryClaim(guid, profile.claimBit))
    {
        handler->PSendSysMessage(
            "You already claimed the {} catch-up gear package on this character.",
            profile.label);
        return true;
    }

    PlayerbotFactory::AutoGear(
        player,
        profile.quality,
        profile.itemLevel,
        true,
        false,
        false);

    player->SaveToDB(false, false);

    handler->PSendSysMessage(
        "Catch-up gear applied for {}: spec-aware incremental target ilvl {}. Better equipped items were kept.",
        profile.label,
        profile.itemLevel);
    handler->SendSysMessage(
        "This package is now claimed for this character. It gives entry-ready gear, not loot from the raid you just unlocked.");
    return true;
}
}

ChatCommandTable AdventureCatchupCommand::GetCommands() const
{
    static ChatCommandTable sub =
    {
        { "raid",   HandleRaid,   SEC_PLAYER, Console::No },
        { "next",   HandleNext,   SEC_PLAYER, Console::No },
        { "status", HandleStatus, SEC_PLAYER, Console::No },
    };
    static ChatCommandTable root = { { "catchup", sub } };
    return root;
}

bool AdventureCatchupCommand::HandleRaid(ChatHandler* handler, Optional<std::string> raid)
{
    Player* player = handler && handler->GetSession() ? handler->GetSession()->GetPlayer() : nullptr;
    if (!player)
        return false;

    if (!raid)
    {
        handler->SendSysMessage("Usage: .catchup raid <kara|ssc|hyjal|za|sunwell|naxx|ulduar|toc|icc|rs>");
        return true;
    }

    CatchupProfile profile{};
    if (!ResolveProfile(*raid, profile))
    {
        handler->PSendSysMessage("Unknown catch-up raid '{}'.", *raid);
        return true;
    }

    return ApplyProfile(handler, player, profile);
}

bool AdventureCatchupCommand::HandleNext(ChatHandler* handler)
{
    Player* player = handler && handler->GetSession() ? handler->GetSession()->GetPlayer() : nullptr;
    if (!player)
        return false;

    uint8 current = sIndividualProgression->GetPlayerProgressionFromQuests(player);
    for (CatchupProfile const& profile : MainProfiles)
    {
        if (profile.stage > current)
            return ApplyProfile(handler, player, profile);
    }

    handler->SendSysMessage("There is no later main raid tier with a catch-up package.");
    return true;
}

bool AdventureCatchupCommand::HandleStatus(ChatHandler* handler)
{
    Player* player = handler && handler->GetSession() ? handler->GetSession()->GetPlayer() : nullptr;
    if (!player)
        return false;

    uint64 claims = LoadClaims(player->GetGUID().GetCounter());
    handler->SendSysMessage("Catch-up packages (one claim per character/tier):");

    CatchupProfile za = ZulAmanProfile();
    for (CatchupProfile const& profile : MainProfiles)
        handler->PSendSysMessage("  {}: {} (target ilvl {})", profile.label, (claims & profile.claimBit) ? "CLAIMED" : "available", profile.itemLevel);
    handler->PSendSysMessage("  {}: {} (target ilvl {})", za.label, (claims & za.claimBit) ? "CLAIMED" : "available", za.itemLevel);
    return true;
}
