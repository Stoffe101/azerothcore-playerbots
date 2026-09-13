#ifndef MOD_RAID_ROSTER_ADVENTURE_COMMAND_H
#define MOD_RAID_ROSTER_ADVENTURE_COMMAND_H

#include "AdventureCatalog.h"
#include "CommandScript.h"
#include "Chat.h"
#include <string>

class Player;

class AdventureCommand : public CommandScript
{
public:
    AdventureCommand() : CommandScript("AdventureCommand") { }
    Acore::ChatCommands::ChatCommandTable GetCommands() const override;

    static bool HandleList(ChatHandler* handler);
    static bool HandleGo(ChatHandler* handler, Optional<std::string> destination);

    // Shared deterministic destination helpers used by the guild/group director and Adventure
    // Guide. Dungeon chat parsing and the UI therefore consume the same catalog and gates.
    static bool ResolveMention(std::string const& text, std::string& alias, std::string& displayName);
    static bool IsDestinationUnlocked(Player* player, std::string const& destination, std::string& reason);

    // Safe party travel for either a dungeon or raid catalog entry. Only the group leader may
    // move an existing group; everybody must be alive and out of combat. Exterior coordinates are
    // resolved from AzerothCore's area-trigger DB, never hard-coded here.
    static bool TravelToEntrance(ChatHandler* handler, AdventureActivity const& activity);
};

#endif
