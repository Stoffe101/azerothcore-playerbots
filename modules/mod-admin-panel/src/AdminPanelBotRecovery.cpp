#include "AdminPanelGameplay.h"

#include "Chat.h"
#include "CommandScript.h"
#include "Log.h"
#include "RBAC.h"
#include "ScriptMgr.h"

using namespace Acore::ChatCommands;

namespace
{
constexpr uint32 FIRST_REPAIR_DELAY_MS = 15000;
constexpr uint32 RETRY_DELAY_MS = 30000;
constexpr uint8 MAX_AUTOMATIC_REPAIRS = 4;

void PrintBotDiagnostics(ChatHandler* handler)
{
    if (!handler)
        return;

    AdminPanelGameplay::PopulationStats const stats = AdminPanelGameplay::GetPopulationStats();
    handler->PSendSysMessage(
        "[BotPopulation] online={} target={} batch={} activity={:.0f}% engine={} autologin={} pool={}/{} assignedAccounts={}",
        stats.bots,
        stats.botTarget,
        stats.botBatch,
        stats.botActivity,
        stats.botEngineEnabled ? 1 : 0,
        stats.botAutologinEnabled ? 1 : 0,
        stats.botAccounts,
        stats.requiredBotAccounts,
        stats.assignedBotAccounts);
}

class AdminPanelBotRecoveryWorld final : public WorldScript
{
public:
    AdminPanelBotRecoveryWorld() : WorldScript("AdminPanelBotRecoveryWorld") { }

    void OnUpdate(uint32 diff) override
    {
        _elapsed += diff;
        uint32 const delay = _attempts == 0 ? FIRST_REPAIR_DELAY_MS : RETRY_DELAY_MS;
        if (_elapsed < delay)
            return;
        _elapsed = 0;

        AdminPanelGameplay::PopulationStats const stats = AdminPanelGameplay::GetPopulationStats();
        if (stats.botTarget == 0 || stats.bots > 0)
        {
            // Once the manager has demonstrated that it can actually log a bot in, stop doing
            // expensive recovery checks. Normal Playerbots population management owns the ramp.
            if (stats.bots > 0)
                _healthy = true;
            return;
        }

        if (_healthy || _attempts >= MAX_AUTOMATIC_REPAIRS)
            return;

        ++_attempts;
        LOG_WARN(
            "server.loading",
            "[AdminPanel] Bot watchdog: target={} but online=0 after {}s; repair attempt {}/{} (pool={}/{} assigned={})",
            stats.botTarget,
            (_attempts == 1 ? FIRST_REPAIR_DELAY_MS : RETRY_DELAY_MS) / 1000,
            uint32(_attempts),
            uint32(MAX_AUTOMATIC_REPAIRS),
            stats.botAccounts,
            stats.requiredBotAccounts,
            stats.assignedBotAccounts);

        AdminPanelGameplay::RepairBotPopulation();
    }

private:
    uint32 _elapsed = 0;
    uint8 _attempts = 0;
    bool _healthy = false;
};

class AdminPanelBotRecoveryCommands final : public CommandScript
{
public:
    AdminPanelBotRecoveryCommands() : CommandScript("AdminPanelBotRecoveryCommands") { }

    ChatCommandTable GetCommands() const override
    {
        static ChatCommandTable table =
        {
            { "botdiag", HandleDiag, SEC_ADMINISTRATOR, Console::Yes },
            { "botrepair", HandleRepair, SEC_ADMINISTRATOR, Console::Yes },
        };
        return table;
    }

    static bool HandleDiag(ChatHandler* handler)
    {
        PrintBotDiagnostics(handler);
        return true;
    }

    static bool HandleRepair(ChatHandler* handler)
    {
        PrintBotDiagnostics(handler);
        handler->SendSysMessage("[BotPopulation] Running RNDbot account/character-pool repair and kicking the login manager...");
        AdminPanelGameplay::RepairBotPopulation();
        PrintBotDiagnostics(handler);
        return true;
    }
};
}

void AddAdminPanelBotRecoveryScripts()
{
    new AdminPanelBotRecoveryWorld();
    new AdminPanelBotRecoveryCommands();
}
