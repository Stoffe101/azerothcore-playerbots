#include "AdminPanelGameplay.h"

#include "Chat.h"
#include "CommandScript.h"
#include "Log.h"
#include "RBAC.h"
#include "ScriptMgr.h"

using namespace Acore::ChatCommands;

namespace
{
constexpr uint32 WATCHDOG_TICK_MS = 5000;
constexpr uint32 FIRST_REPAIR_DELAY_MS = 15000;
constexpr uint32 RETRY_DELAY_MS = 30000;
constexpr uint32 SAFE_STARTUP_BATCH = 10;
constexpr uint8 MAX_AUTOMATIC_REPAIRS = 4;

void PrintBotDiagnostics(ChatHandler* handler)
{
    if (!handler)
        return;

    AdminPanelGameplay::PopulationStats const stats = AdminPanelGameplay::GetPopulationStats();
    handler->PSendSysMessage(
        "[BotPopulation] online={} target={} batch={} activity={:.0f}% engine={} autologin={} accounts={}/{} assignedDB={} managerAccounts={} candidates={} pendingLogins={}",
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

        // A new target is a new population episode. This matters when the realm starts at 0,
        // the operator later asks for 500/1000, or they deliberately change the target after an
        // earlier exhausted repair cycle.
        if (!_haveTarget || stats.botTarget != _lastTarget)
        {
            _haveTarget = true;
            _lastTarget = stats.botTarget;
            _zeroElapsed = 0;
            _attempts = 0;
            _exhaustionLogged = false;
            _wasHealthy = stats.bots > 0;

            if (stats.botTarget > 0)
                LOG_INFO("server.loading", "[AdminPanel] Bot watchdog armed for target={} (online={})", stats.botTarget, stats.bots);
            return;
        }

        if (stats.botTarget == 0)
        {
            _zeroElapsed = 0;
            _attempts = 0;
            _exhaustionLogged = false;
            _wasHealthy = false;
            return;
        }

        if (stats.bots > 0)
        {
            // Seeing even one bot proves that the manager/pool is alive. Reset the outage budget
            // so a later collapse to zero gets a fresh set of automatic repair attempts instead
            // of being permanently ignored because the server was healthy once at startup.
            if (!_wasHealthy)
                LOG_INFO("server.loading", "[AdminPanel] Bot watchdog healthy: online={} target={}", stats.bots, stats.botTarget);
            _zeroElapsed = 0;
            _attempts = 0;
            _exhaustionLogged = false;
            _wasHealthy = true;
            return;
        }

        if (_wasHealthy)
        {
            LOG_WARN("server.loading", "[AdminPanel] Bot watchdog detected population collapse: target={} online=0", stats.botTarget);
            _wasHealthy = false;
            _zeroElapsed = 0;
            _attempts = 0;
            _exhaustionLogged = false;
        }

        _zeroElapsed += step;
        uint32 const delay = _attempts == 0 ? FIRST_REPAIR_DELAY_MS : RETRY_DELAY_MS;
        if (_zeroElapsed < delay)
            return;

        _zeroElapsed = 0;
        if (_attempts >= MAX_AUTOMATIC_REPAIRS)
        {
            if (!_exhaustionLogged)
            {
                _exhaustionLogged = true;
                LOG_ERROR(
                    "server.loading",
                    "[AdminPanel] Bot watchdog exhausted {}/{} automatic repairs: target={} online=0 accounts={}/{} assignedDB={} managerAccounts={} candidates={} pending={}. Use .botdiag/.botrepair after inspecting the first Playerbots error.",
                    uint32(_attempts),
                    uint32(MAX_AUTOMATIC_REPAIRS),
                    stats.botTarget,
                    stats.botAccounts,
                    stats.requiredBotAccounts,
                    stats.assignedBotAccounts,
                    stats.managerRandomAccounts,
                    stats.managerCandidates,
                    stats.pendingBotLogins);
            }
            return;
        }

        ++_attempts;
        LOG_WARN(
            "server.loading",
            "[AdminPanel] Bot watchdog: target={} but online=0; repair attempt {}/{} (accounts={}/{} assignedDB={} managerAccounts={} candidates={} pending={})",
            stats.botTarget,
            uint32(_attempts),
            uint32(MAX_AUTOMATIC_REPAIRS),
            stats.botAccounts,
            stats.requiredBotAccounts,
            stats.assignedBotAccounts,
            stats.managerRandomAccounts,
            stats.managerCandidates,
            stats.pendingBotLogins);

        AdminPanelGameplay::RepairBotPopulation();
    }

private:
    uint32 _tickElapsed = 0;
    uint32 _zeroElapsed = 0;
    uint32 _lastTarget = 0;
    uint8 _attempts = 0;
    bool _haveTarget = false;
    bool _wasHealthy = false;
    bool _exhaustionLogged = false;
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
        handler->SendSysMessage("[BotPopulation] Rebuilding RNDbot capacity/assignments/add-events and kicking the login manager...");
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
