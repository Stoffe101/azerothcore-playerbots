#ifndef MOD_RAID_ROSTER_ADVENTURE_GUIDE_COMMAND_H
#define MOD_RAID_ROSTER_ADVENTURE_GUIDE_COMMAND_H

#include "CommandScript.h"
#include "Chat.h"

class AdventureGuideCommand : public CommandScript
{
public:
    AdventureGuideCommand() : CommandScript("AdventureGuideCommand") { }
    Acore::ChatCommands::ChatCommandTable GetCommands() const override;

    static bool HandleFinder(ChatHandler* handler, Optional<std::string> kind);
    static bool HandleCompatibility(ChatHandler* handler, Optional<std::string> kind);
    static bool HandleRoadmap(ChatHandler* handler);
    static bool HandleGo(ChatHandler* handler, Optional<std::string> alias);
    static bool HandlePrepare(ChatHandler* handler, Optional<std::string> alias);
};

#endif
