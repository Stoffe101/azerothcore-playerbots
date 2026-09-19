#ifndef MOD_RAID_ROSTER_ADVENTURE_CATCHUP_COMMAND_H
#define MOD_RAID_ROSTER_ADVENTURE_CATCHUP_COMMAND_H

#include "CommandScript.h"
#include "Chat.h"

class AdventureCatchupCommand : public CommandScript
{
public:
    AdventureCatchupCommand() : CommandScript("AdventureCatchupCommand") { }
    Acore::ChatCommands::ChatCommandTable GetCommands() const override;

    static bool HandleRaid(ChatHandler* handler, Optional<std::string> raid);
    static bool HandleNext(ChatHandler* handler);
    static bool HandleStatus(ChatHandler* handler);
};

#endif
