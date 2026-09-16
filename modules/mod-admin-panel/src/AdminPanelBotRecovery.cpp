#include "AdminPanelGameplay.h"

#include "Chat.h"
#include "CommandScript.h"
#include "Log.h"
#include "RBAC.h"
#include "ScriptMgr.h"
#include "UpdateTime.h"

using namespace Acore::ChatCommands;

namespace
{
constexpr uint32 WATCHDOG_TICK_MS = 5000;
constexpr uint32 SAFE_STARTUP_BATCH = 10;
constexpr uint32 PROVISION_ACCOUNTS_PER_STEP = 2;
constexpr uint32 MAX_PENDING_LOGINS = 20;
constexpr uint32 WORLD_TICK_BACKPRESSURE_MS = 250;
constexpr uint32 ZERO_POPULATION_REPAIR_MS = 15000;
constexpr uint32 STALL_DIAGNOSTIC_MS = 60000;

void PrintBotDiagnostics(ChatHandler* handler)
{
    if (!handler)
        return;

    AdminPanelGameplay::PopulationStats const stats = AdminPanelGameplay::GetPopulationStats();
    handler->PSendSysMessage(
        "[BotPopulation] state={} online={} target={} batch={} activity={:.0f}% engine={} autologin={} accounts={}/{} assignedDB={} managerAccounts={} selectedCandidates={} usableCapacity={} pendingLogins={}",
        stats.populationState,
        stats.bots,
        stats.botTarget,
        stats.botBatch,
        stats.botActivity,
        stats.botEngineEnabled ? 1 : 0,
        stats.botAutologinEnabled ? 1 : 0,
        stats.botAccounts,
        stats.requiredBotAccounts,
        stats.assignedBotAccounts,
        stats.managerRandomAccounts,
        stats.managerCandidates,
        stats.candidateCapacity,
        stats.pendingBotLogins);
}

class AdminPanelBotRecoveryWorld final : public WorldScript
{
public:
    AdminPanelBotRecoveryWorld() : WorldScript("AdminPanelBotRecoveryWorld") { }

    void OnStartup() override
    {
        AdminPanelGameplay::PopulationStats const stats = AdminPanelGameplay::GetPopulationStats();
        if (!stats.botTarget || stats.botBatch <= SAFE_STARTUP_BATCH)
            return;

        // Fresh installs and older .env files may still carry the historical
        // RANDOM_BOTS_PER_INTERVAL=150 tuning. That value was useful for steady-state maintenance
        // at huge populations but is brutal during a cold login ramp. AdminPanel is now the
        // population authority, so clamp the live startup ramp before the first normal world tick.
        LOG_WARN(
            "server.loading",
            "[AdminPanel] Clamping unsafe cold-start bot batch {} -> {} for target {}",
            stats.botBatch,
            SAFE_STARTUP_BATCH,
            stats.botTarget);
        AdminPanelGameplay::SetBotTarget(stats.botTarget, SAFE_STARTUP_BATCH);
    }

    void OnUpdate(uint32 diff) override
    {
        _tickElapsed += diff;
        if (_tickElapsed < WATCHDOG_TICK_MS)
            return;

        uint32 const step = _tickElapsed;
        _tickElapsed = 0;

        AdminPanelGameplay::PopulationStats const stats = AdminPanelGameplay::GetPopulationStats();

        if (!_haveTarget || stats.botTarget != _lastTarget)
        {
            _haveTarget = true;
            _lastTarget = stats.botTarget;
            _zeroElapsed = 0;
            _stallElapsed = 0;
            _lastOnline = stats.bots;
            _lastCapacity = stats.candidateCapacity;
            LOG_INFO(
                "server.loading",
                "[AdminPanel] Population controller target={} online={} usableCapacity={} selectedCandidates={} pending={}",
                stats.botTarget, stats.bots, stats.candidateCapacity, stats.managerCandidates,
                stats.pendingBotLogins);
        }

        if (stats.botTarget == 0)
        {
            _zeroElapsed = 0;
            return;
        }

        bool const capacityMissing = stats.botAccounts < stats.requiredBotAccounts ||
            stats.candidateCapacity < stats.botTarget;
        if (capacityMissing)
        {
            bool const loginBackpressure = stats.pendingBotLogins >= MAX_PENDING_LOGINS;
            bool const worldBackpressure = sWorldUpdateTime.GetLastUpdateTime() >= WORLD_TICK_BACKPRESSURE_MS;
            if (!loginBackpressure && !worldBackpressure)
                AdminPanelGameplay::AdvanceBotPopulationCapacity(PROVISION_ACCOUNTS_PER_STEP);
        }

        if (stats.bots == 0 && stats.managerCandidates == 0 && stats.pendingBotLogins == 0)
        {
            _zeroElapsed += step;
            if (_zeroElapsed >= ZERO_POPULATION_REPAIR_MS)
            {
                _zeroElapsed = 0;
                LOG_WARN(
                    "server.loading",
                    "[AdminPanel] Population recovery: target={} online=0 selectedCandidates=0 pending=0 usableCapacity={}",
                    stats.botTarget, stats.candidateCapacity);
                AdminPanelGameplay::RepairBotPopulation();
            }
        }
        else
        {
            _zeroElapsed = 0;
        }

        if (stats.bots != _lastOnline || stats.candidateCapacity != _lastCapacity)
        {
            _lastOnline = stats.bots;
            _lastCapacity = stats.candidateCapacity;
            _stallElapsed = 0;
        }
        else if (stats.bots != stats.botTarget)
        {
            _stallElapsed += step;
            if (_stallElapsed >= STALL_DIAGNOSTIC_MS)
            {
                _stallElapsed = 0;
                LOG_WARN(
                    "server.loading",
                    "[AdminPanel] Population convergence stalled: state={} online={} target={} usableCapacity={} selectedCandidates={} pending={} lastWorldTickMs={}",
                    stats.populationState, stats.bots, stats.botTarget, stats.candidateCapacity,
                    stats.managerCandidates, stats.pendingBotLogins, sWorldUpdateTime.GetLastUpdateTime());
            }
        }
        else
        {
            _stallElapsed = 0;
        }
    }

private:
    uint32 _tickElapsed = 0;
    uint32 _zeroElapsed = 0;
    uint32 _stallElapsed = 0;
    uint32 _lastTarget = 0;
    uint32 _lastOnline = 0;
    uint32 _lastCapacity = 0;
    bool _haveTarget = false;
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
        handler->SendSysMessage("[BotPopulation] Running one bounded capacity/assignment recovery step and kicking the login manager...");
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
