#ifndef MOD_RAID_ROSTER_RAID_LEADER_COMMAND_H
#define MOD_RAID_ROSTER_RAID_LEADER_COMMAND_H

#include "Chat.h"
#include "CommandScript.h"

class RaidLeaderCommand : public CommandScript
{
public:
    RaidLeaderCommand() : CommandScript("RaidLeaderCommand") { }
    Acore::ChatCommands::ChatCommandTable GetCommands() const override;

    static bool HandleList(ChatHandler* handler);
    static bool HandleBoss(ChatHandler* handler, Optional<std::string> boss);
};

#endif
