#ifndef MOD_RAID_ROSTER_GROUP_COMPOSER_COMMAND_H
#define MOD_RAID_ROSTER_GROUP_COMPOSER_COMMAND_H

#include "Chat.h"
#include "CommandScript.h"

class GroupComposerCommand : public CommandScript
{
public:
    GroupComposerCommand() : CommandScript("GroupComposerCommand") { }
    Acore::ChatCommands::ChatCommandTable GetCommands() const override;

    static bool HandleBegin(ChatHandler* handler, std::string mode, std::string activity, std::string difficulty,
        uint32 size, uint32 tanks, uint32 healers, uint32 dps, uint32 preferGuild, uint32 fillWorld,
        uint32 keepMe, uint32 balanceClasses, uint32 balanceUtility, uint32 balanceRange,
        uint32 avoidDuplicates, uint32 minimumItemLevel);
    static bool HandlePreference(ChatHandler* handler, std::string role, std::string classToken,
        std::string spec, std::string strength);
    static bool HandleHumanRole(ChatHandler* handler, std::string name, std::string role);
    static bool HandleHuman(ChatHandler* handler, std::string name, std::string role);
    static bool HandlePin(ChatHandler* handler, std::string name, std::string role, std::string strength);
    static bool HandleArrangePreference(ChatHandler* handler, std::string name, uint32 subgroup);

    static bool HandleFind(ChatHandler* handler);
    static bool HandleArrange(ChatHandler* handler);
    static bool HandleMove(ChatHandler* handler, std::string name, uint32 subgroup);
    static bool HandleAssemble(ChatHandler* handler);
    static bool HandleQueue(ChatHandler* handler);
    static bool HandleAnchors(ChatHandler* handler);
    static bool HandleDiagnostics(ChatHandler* handler);
    static bool HandleClear(ChatHandler* handler);
    static bool HandleStatus(ChatHandler* handler);
};

void AddGroupComposerScripts();

#endif
