#ifndef MOD_RAID_ROSTER_ADVENTURE_COMMAND_H
#define MOD_RAID_ROSTER_ADVENTURE_COMMAND_H

#include "CommandScript.h"
#include "Chat.h"

class AdventureCommand : public CommandScript
{
public:
    AdventureCommand() : CommandScript("AdventureCommand") { }
    Acore::ChatCommands::ChatCommandTable GetCommands() const override;

    static bool HandleList(ChatHandler* handler);
    static bool HandleGo(ChatHandler* handler, Optional<std::string> destination);
};

#endif
