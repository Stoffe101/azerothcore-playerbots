#ifndef MOD_RAID_ROSTER_WOWSIMS_COMMAND_H
#define MOD_RAID_ROSTER_WOWSIMS_COMMAND_H

#include "Chat.h"
#include "CommandScript.h"

class WoWSimsCommand : public CommandScript
{
public:
    WoWSimsCommand() : CommandScript("WoWSimsCommand") { }

    Acore::ChatCommands::ChatCommandTable GetCommands() const override;

    static bool HandleSnapshot(ChatHandler* handler);
    static bool HandleRequest(ChatHandler* handler);
    static bool HandleValidate(ChatHandler* handler);
};

#endif
