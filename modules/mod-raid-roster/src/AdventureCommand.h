#ifndef MOD_RAID_ROSTER_ADVENTURE_COMMAND_H
#define MOD_RAID_ROSTER_ADVENTURE_COMMAND_H

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

    // Shared deterministic destination helpers used by the guild/group director. These expose
    // the same table and era/level gates as `.adventure`, so natural-language grouping cannot
    // drift away from the travel backend's source of truth.
    static bool ResolveMention(std::string const& text, std::string& alias, std::string& displayName);
    static bool IsDestinationUnlocked(Player* player, std::string const& destination, std::string& reason);
};

#endif
