#include "AdventureGuideCommand.h"

#include "AdventureCatalog.h"
#include "AdventureCommand.h"
#include "IndividualProgression.h"
#include "Item.h"
#include "ItemTemplate.h"
#include "Player.h"
#include "RaidRosterCommand.h"
#include "RaidRosterStore.h"
#include "RBAC.h"

#include <algorithm>
#include <cctype>
#include <string>
#include <vector>

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

uint32 AverageEquippedItemLevel(Player* player)
{
    if (!player)
        return 0;

    uint32 total = 0;
    uint32 pieces = 0;
    for (uint8 slot = EQUIPMENT_SLOT_START; slot < EQUIPMENT_SLOT_END; ++slot)
    {
        // Shirts and tabards are cosmetic and would make the readiness estimate noisy.
        if (slot == EQUIPMENT_SLOT_BODY || slot == EQUIPMENT_SLOT_TABARD)
            continue;

        Item* item = player->GetItemByPos(INVENTORY_SLOT_BAG_0, slot);
        ItemTemplate const* proto = item ? item->GetTemplate() : nullptr;
        if (!proto || !proto->ItemLevel)
            continue;

        total += proto->ItemLevel;
        ++pieces;
    }

    return pieces ? total / pieces : 0;
}

uint32 SuggestedItemLevel(AdventureActivity const& activity)
{
    // These are advisory bands, not fake lockouts. Leveling dungeons deliberately return zero so
    // the normal WotLK/TBC leveling curve remains level/progression driven. Endgame values are
    // conservative entry targets used only for Finder guidance.
    if (activity.kind == AdventureActivityKind::Dungeon)
    {
        if (activity.minLevel < 70)
            return 0;
        if (activity.minProgression < 13)
            return std::string(activity.alias) == "magisters" ? 110 : 90;
        if (activity.minLevel < 80)
            return 0;
        if (std::string(activity.alias) == "forgeofsouls" || std::string(activity.alias) == "pitofsaron" ||
            std::string(activity.alias) == "hallsofreflection")
            return 200;
        return 187;
    }

    if (activity.minProgression <= 8)
        return 110;
    if (activity.minProgression == 9)
        return 120;
    if (activity.minProgression <= 11)
        return 130;
    if (activity.minProgression == 12)
        return 135;
    if (activity.minProgression == 13)
        return 187;
    if (activity.minProgression == 14)
        return 200;
    if (activity.minProgression == 15)
        return 219;
    if (activity.minProgression == 16)
        return 232;
    return 245;
}

bool GearComfortable(Player* player, AdventureActivity const& activity)
{
    uint32 const target = SuggestedItemLevel(activity);
    if (!target)
        return true;

    uint32 const equipped = AverageEquippedItemLevel(player);
    // Keep gear advisory rather than a hard gate: below 90% of the target gets a visible warning,
    // while a skilled or deliberately undergeared player can still form/travel to unlocked content.
    return equipped && equipped * 100u >= target * 90u;
}

// Player readiness is deliberately separate from encounter support. "Guild Ready" answers
// whether this fork trusts the bots/content; this answers whether the activity makes sense for
// this player now using progression, level and an advisory equipped-item-level band.
int PlayerReadinessRank(Player* player, AdventureActivity const& activity, bool* unlockedOut = nullptr)
{
    std::string reason;
    bool const unlocked = AdventureCatalog::IsUnlocked(player, activity, reason);
    if (unlockedOut)
        *unlockedOut = unlocked;
    if (!unlocked)
        return 3; // LOCKED

    bool const gearComfortable = GearComfortable(player, activity);
    uint8 const progression = sIndividualProgression->GetPlayerProgressionFromQuests(player);
    uint8 const level = player->GetLevel();

    bool sweetSpot = false;
    if (activity.kind == AdventureActivityKind::Raid)
    {
        sweetSpot = progression == activity.minProgression;
    }
    else
    {
        sweetSpot = level >= activity.minLevel &&
            level <= uint8(std::min<uint32>(80u, uint32(activity.minLevel) + 3u));
    }

    if (sweetSpot && gearComfortable)
        return 0; // RECOMMENDED
    if (gearComfortable)
        return 1; // READY
    return 2;     // GEAR LOW, still unlocked and playable.
}

char const* PlayerReadinessName(Player* player, AdventureActivity const& activity, bool unlocked)
{
    if (!unlocked)
        return "LOCKED";

    switch (PlayerReadinessRank(player, activity))
    {
        case 0: return "RECOMMENDED";
        case 1: return "READY";
        case 2: return "GEAR LOW";
        default: return "LOCKED";
    }
}

void PrintReadyLine(ChatHandler* handler, Player* player, AdventureActivity const& activity)
{
    std::string reason;
    bool const unlocked = AdventureCatalog::IsUnlocked(player, activity, reason);
    handler->PSendSysMessage(
        "[AG] {}|{}|{}|{}|{}|{}|{}|{}|{}|{}|{}",
        activity.alias,
        activity.name,
        KindName(activity.kind),
        AdventureCatalog::SupportLabel(activity.support),
        uint32(activity.minLevel),
        uint32(activity.preferredSize),
        unlocked ? "UNLOCKED" : "LOCKED",
        unlocked ? activity.supportNote : reason,
        PlayerReadinessName(player, activity, unlocked),
        AverageEquippedItemLevel(player),
        SuggestedItemLevel(activity));
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

    // Finder is ordered for the current player instead of dumping the static catalog in expansion
    // order. Current sweet-spot activities come first, then other unlocked Guild Ready content,
    // undergeared-but-unlocked choices, then the nearest locked activities.
    std::vector<AdventureActivity const*> rows;
    for (AdventureActivity const& activity : AdventureCatalog::All())
    {
        if (activity.support == AdventureSupport::Ready && MatchesKind(activity, kind))
            rows.push_back(&activity);
    }

    std::stable_sort(rows.begin(), rows.end(), [player](AdventureActivity const* a, AdventureActivity const* b)
    {
        int const ar = PlayerReadinessRank(player, *a);
        int const br = PlayerReadinessRank(player, *b);
        if (ar != br)
            return ar < br;

        if (a->minProgression != b->minProgression)
            return ar == 3 ? a->minProgression < b->minProgression : a->minProgression > b->minProgression;
        if (a->minLevel != b->minLevel)
            return ar == 3 ? a->minLevel < b->minLevel : a->minLevel > b->minLevel;
        return a->name < b->name;
    });

    handler->SendSysMessage("[AG] BEGIN|FINDER");
    for (AdventureActivity const* activity : rows)
        PrintReadyLine(handler, player, *activity);
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
    handler->PSendSysMessage("[AG] ROADMAP|ITEMLEVEL|{}", AverageEquippedItemLevel(player));

    if (player->GetLevel() < 70)
    {
        handler->SendSysMessage("[AG] ROADMAP|NOW|Level through Outland and run Guild Ready TBC dungeons.");
        handler->SendSysMessage("[AG] ROADMAP|NEXT|Reach 70, then Karazhan / Gruul / Magtheridon.");
        return true;
    }

    if (progression <= 8)
    {
        handler->SendSysMessage("[AG] ROADMAP|NOW|Karazhan / Gruul / Magtheridon are your first raid tier. Around ilvl 110 is a comfortable entry target.");
        handler->SendSysMessage("[AG] ROADMAP|NEXT|Serpentshrine Cavern / Tempest Keep.");
    }
    else if (progression == 9)
    {
        handler->SendSysMessage("[AG] ROADMAP|NOW|Serpentshrine Cavern / Tempest Keep. Around ilvl 120 is a comfortable entry target.");
        handler->SendSysMessage("[AG] ROADMAP|NEXT|Hyjal Summit / Black Temple.");
    }
    else if (progression <= 11)
    {
        handler->SendSysMessage("[AG] ROADMAP|NOW|Hyjal Summit / Black Temple. Around ilvl 130 is a comfortable entry target.");
        handler->SendSysMessage("[AG] ROADMAP|NEXT|Zul'Aman catch-up; Sunwell remains experimental in this fork until validated.");
    }
    else if (progression == 12)
    {
        handler->SendSysMessage("[AG] ROADMAP|NOW|Zul'Aman is Guild Ready. Sunwell is still experimental.");
        handler->SendSysMessage("[AG] ROADMAP|NEXT|Advance to Wrath when you want Naxxramas / EoE / Obsidian Sanctum.");
    }
    else if (progression == 13)
    {
        handler->SendSysMessage("[AG] ROADMAP|NOW|Naxxramas / Eye of Eternity / Obsidian Sanctum / Onyxia are Guild Ready. Aim for roughly ilvl 187+.");
        handler->SendSysMessage("[AG] ROADMAP|NEXT|Ulduar is experimental, not normal Finder content yet.");
    }
    else if (progression == 14)
    {
        handler->SendSysMessage("[AG] ROADMAP|NOW|Ulduar is available but marked experimental/WIP. Roughly ilvl 200+ is a sensible entry band.");
        handler->SendSysMessage("[AG] ROADMAP|NEXT|Trial of the Crusader is not Finder Ready; ICC becomes the next green target later.");
    }
    else if (progression == 15)
    {
        handler->SendSysMessage("[AG] ROADMAP|NOW|Trial of the Crusader is WIP and excluded from the normal Finder.");
        handler->SendSysMessage("[AG] ROADMAP|NEXT|Icecrown Citadel at progression 16; build toward roughly ilvl 232+.");
    }
    else if (progression == 16)
    {
        handler->SendSysMessage("[AG] ROADMAP|NOW|Icecrown Citadel normal mode is Guild Ready. Roughly ilvl 232+ is the Finder comfort target.");
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
