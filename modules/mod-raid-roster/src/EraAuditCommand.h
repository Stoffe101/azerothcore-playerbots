#ifndef MOD_RAID_ROSTER_ERA_AUDIT_COMMAND_H
#define MOD_RAID_ROSTER_ERA_AUDIT_COMMAND_H

#include "Chat.h"
#include "CommandScript.h"

class EraAuditCommand : public CommandScript
{
public:
    EraAuditCommand() : CommandScript("EraAuditCommand") { }
    Acore::ChatCommands::ChatCommandTable GetCommands() const override;
    static bool HandleAudit(ChatHandler* handler);
};

#endif
