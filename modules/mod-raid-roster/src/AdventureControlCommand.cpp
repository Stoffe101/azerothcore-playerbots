#include "AdventureControlCommand.h"

#include "AdventureControlStore.h"
#include "EraPolicy.h"
#include "IndividualProgression.h"
#include "Player.h"
#include "QuestDef.h"
#include "RBAC.h"

#include <algorithm>
#include <array>
#include <cctype>
#include <string>

using namespace Acore::ChatCommands;

namespace
{
struct ProgressionLabel
{
    uint8 stage;
    char const* name;
};

constexpr std::array<ProgressionLabel, 19> ProgressionLabels = {{
    {0,  "Fresh progression"},
    {1,  "Molten Core complete"},
    {2,  "Onyxia complete"},
    {3,  "Blackwing Lair complete"},
    {4,  "Pre-AQ unlocked"},
    {5,  "AQ War Effort complete"},
    {6,  "Ahn'Qiraj complete"},
    {7,  "Naxxramas 40 complete"},
    {8,  "TBC entry tier unlocked (Karazhan/Gruul/Magtheridon)"},
    {9,  "TBC Tier 1 complete (SSC/TK unlock path)"},
    {10, "TBC Tier 2 complete (Hyjal/Black Temple unlock path)"},
    {11, "Reserved / legacy stage"},
    {12, "Sunwell tier unlocked"},
    {13, "Wrath entry tier unlocked (Naxx/EoE/OS)"},
    {14, "Ulduar tier unlocked"},
    {15, "Trial of the Crusader tier unlocked"},
    {16, "Icecrown Citadel tier unlocked"},
    {17, "Ruby Sanctum tier unlocked"},
    {18, "Final WotLK progression stage"},
}};

constexpr std::array<uint8, 10> RaidProgressionSteps = {{ 8, 9, 10, 12, 13, 14, 15, 16, 17, 18 }};

Player* GetPlayer(ChatHandler* handler)
{
    return handler && handler->GetSession() ? handler->GetSession()->GetPlayer() : nullptr;
}

uint16 ClampPercent(uint32 value)
{
    return static_cast<uint16>(std::min<uint32>(value, 1000));
}

std::string Lower(std::string value)
{
    std::transform(value.begin(), value.end(), value.begin(), [](unsigned char c)
    {
        return static_cast<char>(std::tolower(c));
    });
    return value;
}

std::string NormalizeToken(std::string value)
{
    value = Lower(value);
    value.erase(std::remove_if(value.begin(), value.end(), [](unsigned char c)
    {
        return !std::isalnum(c);
    }), value.end());
    return value;
}

char const* ProgressionName(uint8 stage)
{
    for (ProgressionLabel const& entry : ProgressionLabels)
        if (entry.stage == stage)
            return entry.name;
    return "Unknown stage";
}

void PrintRates(ChatHandler* handler, Player* player)
{
    AdventureControlRates rates = AdventureControlStore::Get(player->GetGUID().GetCounter());
    handler->PSendSysMessage(
        "Personal playstyle multipliers: XP {}%, Gold {}%, Reputation {}%. These multiply the realm's configured base rates.",
        rates.xpPercent, rates.goldPercent, rates.repPercent);
}

bool SetOneRate(ChatHandler* handler, Optional<uint32> percent, char const* label, uint16 AdventureControlRates::*field)
{
    Player* player = GetPlayer(handler);
    if (!player)
        return false;
    if (!percent)
    {
        handler->PSendSysMessage("Usage: .playstyle {} <0-1000>. 100 = normal personal multiplier, 200 = 2x on top of realm rates.", label);
        return true;
    }

    AdventureControlRates rates = AdventureControlStore::Get(player->GetGUID().GetCounter());
    rates.*field = ClampPercent(*percent);
    AdventureControlStore::Save(player->GetGUID().GetCounter(), rates);
    PrintRates(handler, player);
    return true;
}

bool AdvanceProgression(ChatHandler* handler, Player* player, uint8 target, char const* requestedLabel)
{
    if (!EraPolicy::IsProgressionAllowed(target))
    {
        handler->PSendSysMessage(
            "{} belongs to {} and is locked while the live realm era is {}.",
            requestedLabel,
            EraPolicy::Name(EraPolicy::EraForProgression(target)),
            EraPolicy::Name(EraPolicy::CurrentRealmEra()));
        return true;
    }

    uint8 current = sIndividualProgression->GetPlayerProgressionFromQuests(player);
    if (target <= current)
    {
        handler->PSendSysMessage(
            "{} is already available at your current progression stage {} - {}.",
            requestedLabel, uint32(current), ProgressionName(current));
        return true;
    }

    sIndividualProgression->UpdateProgressionState(player, static_cast<ProgressionState>(target));
    sIndividualProgression->CheckAdjustments(player);
    sIndividualProgression->checkIPPhasing(player, player->GetAreaId());

    uint8 after = sIndividualProgression->GetPlayerProgressionFromQuests(player);
    if (after < target)
    {
        handler->PSendSysMessage(
            "Could not advance all the way to {}. Progression stopped at stage {} - {}. A server progression limit may be active.",
            requestedLabel, uint32(after), ProgressionName(after));
        return true;
    }

    handler->PSendSysMessage(
        "Raid progression advanced: {} is now unlocked. Current stage {} - {}.",
        requestedLabel, uint32(after), ProgressionName(after));
    return true;
}

int ResolveRaidStage(std::string const& raw)
{
    std::string raid = NormalizeToken(raw);

    if (raid == "kara" || raid == "karazhan" || raid == "gruul" || raid == "gruulslair" ||
        raid == "mag" || raid == "magtheridon" || raid == "magtheridonslair")
        return 8;

    if (raid == "ssc" || raid == "serpentshrine" || raid == "serpentshrinecavern" ||
        raid == "tk" || raid == "tempestkeep" || raid == "theeye")
        return 9;

    if (raid == "hyjal" || raid == "mounthyjal" || raid == "hyjalsummit" ||
        raid == "bt" || raid == "blacktemple")
        return 10;

    if (raid == "za" || raid == "zulaman")
        return std::clamp<int>(sIndividualProgression->RequiredZulAmanProgression, 1, PROGRESSION_WOTLK_TIER_5);

    if (raid == "sunwell" || raid == "swp" || raid == "sunwellplateau")
        return 12;

    if (raid == "naxx" || raid == "naxxramas" || raid == "eoe" || raid == "eyeofeternity" ||
        raid == "os" || raid == "obsidiansanctum")
        return 13;

    if (raid == "ulduar")
        return 14;

    if (raid == "toc" || raid == "totc" || raid == "trialofthecrusader")
        return 15;

    if (raid == "icc" || raid == "icecrown" || raid == "icecrowncitadel")
        return 16;

    if (raid == "rs" || raid == "ruby" || raid == "rubysanctum")
        return 17;

    if (raid == "final" || raid == "wotlkfinal")
        return 18;

    return -1;
}

char const* RaidLabelForStage(uint8 stage)
{
    switch (stage)
    {
        case 8:  return "Karazhan / Gruul / Magtheridon";
        case 9:  return "Serpentshrine Cavern / Tempest Keep";
        case 10: return "Hyjal Summit / Black Temple";
        case 12: return "Sunwell Plateau";
        case 13: return "Naxxramas / Eye of Eternity / Obsidian Sanctum";
        case 14: return "Ulduar";
        case 15: return "Trial of the Crusader";
        case 16: return "Icecrown Citadel";
        case 17: return "Ruby Sanctum";
        case 18: return "final WotLK progression";
        default: return "requested raid tier";
    }
}
}

ChatCommandTable AdventureControlCommand::GetCommands() const
{
    static ChatCommandTable quest =
    {
        { "finish",    HandleFinishQuest,     SEC_PLAYER, Console::No },
        { "finishall", HandleFinishAllQuests, SEC_PLAYER, Console::No },
    };
    static ChatCommandTable progress =
    {
        { "list",    HandleProgressList,    SEC_PLAYER, Console::No },
        { "advance", HandleProgressAdvance, SEC_PLAYER, Console::No },
    };
    static ChatCommandTable raid =
    {
        { "list",   HandleRaidList,   SEC_PLAYER, Console::No },
        { "unlock", HandleRaidUnlock, SEC_PLAYER, Console::No },
        { "next",   HandleRaidNext,   SEC_PLAYER, Console::No },
    };
    static ChatCommandTable sub =
    {
        { "status",   HandleStatus, SEC_PLAYER, Console::No },
        { "preset",   HandlePreset, SEC_PLAYER, Console::No },
        { "xp",       HandleXp,     SEC_PLAYER, Console::No },
        { "gold",     HandleGold,   SEC_PLAYER, Console::No },
        { "rep",      HandleRep,    SEC_PLAYER, Console::No },
        { "quest",    quest },
        { "progress", progress },
        { "raid",     raid },
    };
    static ChatCommandTable root = { { "playstyle", sub } };
    return root;
}

bool AdventureControlCommand::HandleStatus(ChatHandler* handler)
{
    Player* player = GetPlayer(handler);
    if (!player)
        return false;

    PrintRates(handler, player);
    uint8 stage = sIndividualProgression->GetPlayerProgressionFromQuests(player);
    handler->PSendSysMessage("Progression stage: {} - {}", uint32(stage), ProgressionName(stage));
    handler->SendSysMessage("Presets: normal, boosted, fast, turbo, insane. Use .playstyle raid list for raid shortcuts or .playstyle progress list for every progression stage.");
    return true;
}

bool AdventureControlCommand::HandlePreset(ChatHandler* handler, Optional<std::string> preset)
{
    Player* player = GetPlayer(handler);
    if (!player)
        return false;
    if (!preset)
    {
        handler->SendSysMessage("Usage: .playstyle preset <normal|boosted|fast|turbo|insane>");
        return true;
    }

    std::string name = Lower(*preset);
    AdventureControlRates rates;
    if (name == "normal")       rates = {100, 100, 100};
    else if (name == "boosted") rates = {150, 150, 150};
    else if (name == "fast")    rates = {200, 200, 200};
    else if (name == "turbo")   rates = {300, 250, 300};
    else if (name == "insane")  rates = {500, 500, 500};
    else
    {
        handler->SendSysMessage("Unknown preset. Use normal, boosted, fast, turbo, or insane.");
        return true;
    }

    AdventureControlStore::Save(player->GetGUID().GetCounter(), rates);
    handler->PSendSysMessage("Playstyle preset '{}' applied.", name);
    PrintRates(handler, player);
    return true;
}

bool AdventureControlCommand::HandleXp(ChatHandler* handler, Optional<uint32> percent)
{
    return SetOneRate(handler, percent, "xp", &AdventureControlRates::xpPercent);
}

bool AdventureControlCommand::HandleGold(ChatHandler* handler, Optional<uint32> percent)
{
    return SetOneRate(handler, percent, "gold", &AdventureControlRates::goldPercent);
}

bool AdventureControlCommand::HandleRep(ChatHandler* handler, Optional<uint32> percent)
{
    return SetOneRate(handler, percent, "rep", &AdventureControlRates::repPercent);
}

bool AdventureControlCommand::HandleFinishQuest(ChatHandler* handler, Optional<uint32> questId)
{
    Player* player = GetPlayer(handler);
    if (!player)
        return false;
    if (!questId)
    {
        handler->SendSysMessage("Usage: .playstyle quest finish <questId>. This completes objectives but does not auto-turn-in the quest.");
        return true;
    }

    QuestStatus status = player->GetQuestStatus(*questId);
    if (status != QUEST_STATUS_INCOMPLETE)
    {
        handler->PSendSysMessage("Quest {} is not currently incomplete in your quest log.", *questId);
        return true;
    }

    player->CompleteQuest(*questId);
    handler->PSendSysMessage("Quest {} objectives completed. Turn it in normally to preserve rewards and chain flow.", *questId);
    return true;
}

bool AdventureControlCommand::HandleFinishAllQuests(ChatHandler* handler)
{
    Player* player = GetPlayer(handler);
    if (!player)
        return false;

    uint32 completed = 0;
    for (uint16 slot = 0; slot < MAX_QUEST_LOG_SIZE; ++slot)
    {
        uint32 questId = player->GetQuestSlotQuestId(slot);
        if (!questId || player->GetQuestStatus(questId) != QUEST_STATUS_INCOMPLETE)
            continue;
        player->CompleteQuest(questId);
        ++completed;
    }

    handler->PSendSysMessage(
        "Completed objectives for {} active quest(s). Nothing was auto-rewarded; turn them in normally.", completed);
    return true;
}

bool AdventureControlCommand::HandleProgressList(ChatHandler* handler)
{
    Player* player = GetPlayer(handler);
    if (!player)
        return false;

    uint8 current = sIndividualProgression->GetPlayerProgressionFromQuests(player);
    handler->PSendSysMessage("Current progression: {} - {}", uint32(current), ProgressionName(current));
    for (ProgressionLabel const& entry : ProgressionLabels)
        handler->PSendSysMessage("  {} - {}", uint32(entry.stage), entry.name);
    handler->SendSysMessage("Use .playstyle progress advance <stage>. This only advances the server's content-gating progression; it does not fake-complete every normal quest.");
    return true;
}

bool AdventureControlCommand::HandleProgressAdvance(ChatHandler* handler, Optional<uint32> stage)
{
    Player* player = GetPlayer(handler);
    if (!player)
        return false;
    if (!stage || *stage > PROGRESSION_WOTLK_TIER_5)
    {
        handler->SendSysMessage("Usage: .playstyle progress advance <1-18>. Use .playstyle progress list for labels.");
        return true;
    }

    uint8 target = static_cast<uint8>(*stage);
    return AdvanceProgression(handler, player, target, ProgressionName(target));
}

bool AdventureControlCommand::HandleRaidList(ChatHandler* handler)
{
    Player* player = GetPlayer(handler);
    if (!player)
        return false;

    uint8 current = sIndividualProgression->GetPlayerProgressionFromQuests(player);
    handler->PSendSysMessage("Current raid progression: stage {} - {}", uint32(current), ProgressionName(current));
    handler->SendSysMessage("Raid shortcuts (forward-only):");
    handler->SendSysMessage("  kara / gruul / magtheridon -> Karazhan, Gruul's Lair, Magtheridon's Lair");
    handler->SendSysMessage("  ssc / tk -> Serpentshrine Cavern, Tempest Keep");
    handler->SendSysMessage("  hyjal / bt -> Hyjal Summit, Black Temple");
    handler->PSendSysMessage("  za -> Zul'Aman (currently requires progression stage {})", sIndividualProgression->RequiredZulAmanProgression);
    handler->SendSysMessage("  sunwell -> Sunwell Plateau");
    handler->SendSysMessage("  naxx / eoe / os -> Wrath entry raids");
    handler->SendSysMessage("  ulduar -> Ulduar");
    handler->SendSysMessage("  toc -> Trial of the Crusader");
    handler->SendSysMessage("  icc -> Icecrown Citadel");
    handler->SendSysMessage("  rs -> Ruby Sanctum");
    handler->SendSysMessage("Use .playstyle raid unlock <name>, or .playstyle raid next to skip to the next main raid tier.");
    return true;
}

bool AdventureControlCommand::HandleRaidUnlock(ChatHandler* handler, Optional<std::string> raid)
{
    Player* player = GetPlayer(handler);
    if (!player)
        return false;
    if (!raid)
    {
        handler->SendSysMessage("Usage: .playstyle raid unlock <kara|ssc|tk|hyjal|bt|za|sunwell|naxx|ulduar|toc|icc|rs>");
        return true;
    }

    int resolved = ResolveRaidStage(*raid);
    if (resolved < 0)
    {
        handler->PSendSysMessage("Unknown raid shortcut '{}'. Use .playstyle raid list.", *raid);
        return true;
    }

    uint8 target = static_cast<uint8>(resolved);
    std::string normalized = NormalizeToken(*raid);
    char const* label = RaidLabelForStage(target);
    if (normalized == "za" || normalized == "zulaman")
        label = "Zul'Aman";

    return AdvanceProgression(handler, player, target, label);
}

bool AdventureControlCommand::HandleRaidNext(ChatHandler* handler)
{
    Player* player = GetPlayer(handler);
    if (!player)
        return false;

    uint8 current = sIndividualProgression->GetPlayerProgressionFromQuests(player);
    for (uint8 target : RaidProgressionSteps)
    {
        if (target > current)
            return AdvanceProgression(handler, player, target, RaidLabelForStage(target));
    }

    handler->SendSysMessage("You are already at the final WotLK progression stage.");
    return true;
}
