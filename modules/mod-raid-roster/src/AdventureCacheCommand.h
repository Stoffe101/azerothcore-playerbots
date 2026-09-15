#ifndef MOD_RAID_ROSTER_ADVENTURE_CACHE_COMMAND_H
#define MOD_RAID_ROSTER_ADVENTURE_CACHE_COMMAND_H

#include "CommandScript.h"
#include "Chat.h"

class AdventureCacheCommand : public CommandScript
{
public:
    AdventureCacheCommand() : CommandScript("AdventureCacheCommand") { }
    Acore::ChatCommands::ChatCommandTable GetCommands() const override;

    static bool HandleStatus(ChatHandler* handler);
    static bool HandleOpen(ChatHandler* handler);
};

#endif
