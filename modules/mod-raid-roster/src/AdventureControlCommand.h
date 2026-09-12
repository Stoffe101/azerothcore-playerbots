#ifndef MOD_RAID_ROSTER_ADVENTURE_CONTROL_COMMAND_H
#define MOD_RAID_ROSTER_ADVENTURE_CONTROL_COMMAND_H

#include "CommandScript.h"
#include "Chat.h"

class AdventureControlCommand : public CommandScript
{
public:
    AdventureControlCommand() : CommandScript("AdventureControlCommand") { }
    Acore::ChatCommands::ChatCommandTable GetCommands() const override;

    static bool HandleStatus(ChatHandler* handler);
    static bool HandlePreset(ChatHandler* handler, Optional<std::string> preset);
    static bool HandleXp(ChatHandler* handler, Optional<uint32> percent);
    static bool HandleGold(ChatHandler* handler, Optional<uint32> percent);
    static bool HandleRep(ChatHandler* handler, Optional<uint32> percent);
    static bool HandleFinishQuest(ChatHandler* handler, Optional<uint32> questId);
    static bool HandleFinishAllQuests(ChatHandler* handler);
    static bool HandleProgressList(ChatHandler* handler);
    static bool HandleProgressAdvance(ChatHandler* handler, Optional<uint32> stage);
};

#endif
