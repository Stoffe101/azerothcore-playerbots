#include "EraAuditCommand.h"

#include "AdventureCatalog.h"
#include "DatabaseEnv.h"
#include "EraPolicy.h"
#include "Field.h"
#include "IndividualProgression.h"
#include "Player.h"
#include "PlayerbotAIConfig.h"
#include "RandomPlayerbotMgr.h"
#include "RBAC.h"

#include <sstream>
#include <string>
#include <vector>

using namespace Acore::ChatCommands;

namespace
{
enum class AuditState
{
    Pass,
    Warn,
    Fail,
};

char const* Label(AuditState state)
{
    switch (state)
    {
        case AuditState::Pass: return "PASS";
        case AuditState::Warn: return "WARN";
        case AuditState::Fail: return "FAIL";
    }
    return "WARN";
}

void Emit(ChatHandler* handler, AuditState state, char const* section, std::string const& detail)
{
    handler->PSendSysMessage("[EraAudit] {} {} - {}", Label(state), section, detail);
}

std::string AccountList()
{
    std::ostringstream out;
    bool first = true;
    for (uint32 accountId : sPlayerbotAIConfig.randomBotAccounts)
    {
        if (!first)
            out << ',';
        first = false;
        out << accountId;
    }
    return out.str();
}

std::string JoinExamples(std::vector<std::string> const& examples)
{
    std::ostringstream out;
    for (size_t i = 0; i < examples.size(); ++i)
    {
        if (i)
            out << ", ";
        out << examples[i];
    }
    return out.str();
}
}

ChatCommandTable EraAuditCommand::GetCommands() const
{
    static ChatCommandTable sub =
    {
        { "audit", HandleAudit, SEC_GAMEMASTER, Console::No },
    };
    static ChatCommandTable root = { { "era", sub } };
    return root;
}

bool EraAuditCommand::HandleAudit(ChatHandler* handler)
{
    if (!handler)
        return true;

    EraPolicy::Era const era = EraPolicy::CurrentRealmEra();
    uint8 const cap = EraPolicy::RealmLevelCap();
    uint8 const progression = EraPolicy::RealmProgressionCeiling();

    uint32 failures = 0;
    uint32 warnings = 0;
    auto report = [&](AuditState state, char const* section, std::string const& detail)
    {
        if (state == AuditState::Fail) ++failures;
        else if (state == AuditState::Warn) ++warnings;
        Emit(handler, state, section, detail);
    };

    handler->PSendSysMessage(
        "[EraAudit] realm={} levelCap={} progressionCeiling={}",
        EraPolicy::Name(era),
        uint32(cap),
        uint32(progression));

    bool const ipCapOk = sIndividualProgression->BotAccountsMaxLevel == cap;
    bool const randomCapOk = sPlayerbotAIConfig.randomBotMaxLevel == cap;
    report(
        ipCapOk && randomCapOk ? AuditState::Pass : AuditState::Fail,
        "CAPS",
        "IP bot cap=" + std::to_string(sIndividualProgression->BotAccountsMaxLevel) +
            ", Playerbots runtime max=" + std::to_string(sPlayerbotAIConfig.randomBotMaxLevel) +
            ", expected=" + std::to_string(cap));

    uint32 onlineRandom = 0;
    uint32 onlineOverCap = 0;
    std::vector<std::string> onlineExamples;
    for (Player* bot : sRandomPlayerbotMgr.GetPlayers())
    {
        if (!bot || !bot->IsInWorld())
            continue;
        ++onlineRandom;
        if (bot->GetLevel() <= cap)
            continue;

        ++onlineOverCap;
        if (onlineExamples.size() < 5)
            onlineExamples.push_back(bot->GetName() + "(Lv" + std::to_string(bot->GetLevel()) + ")");
    }
    report(
        onlineOverCap ? AuditState::Fail : AuditState::Pass,
        "RANDOM_BOTS_ONLINE",
        "online=" + std::to_string(onlineRandom) +
            ", overCap=" + std::to_string(onlineOverCap) +
            (onlineExamples.empty() ? "" : ", examples=" + JoinExamples(onlineExamples)));

    std::string const accountList = AccountList();
    if (accountList.empty())
    {
        report(AuditState::Warn, "RANDOM_BOTS_STORED", "random-bot account pool is empty/not loaded");
    }
    else
    {
        uint64 stored = 0;
        uint64 storedOverCap = 0;
        if (QueryResult result = CharacterDatabase.Query(
                "SELECT COUNT(*), SUM(level > {}) FROM characters WHERE account IN ({})",
                uint32(cap),
                accountList))
        {
            Field* fields = result->Fetch();
            stored = fields[0].Get<uint64>();
            storedOverCap = fields[1].IsNull() ? 0 : fields[1].Get<uint64>();
        }

        std::vector<std::string> storedExamples;
        if (storedOverCap)
        {
            if (QueryResult result = CharacterDatabase.Query(
                    "SELECT name, level FROM characters WHERE account IN ({}) AND level > {} "
                    "ORDER BY level DESC, guid LIMIT 5",
                    accountList,
                    uint32(cap)))
            {
                do
                {
                    Field* fields = result->Fetch();
                    storedExamples.push_back(
                        fields[0].Get<std::string>() + "(Lv" + std::to_string(fields[1].Get<uint8>()) + ")");
                } while (result->NextRow());
            }
        }

        report(
            storedOverCap ? AuditState::Warn : AuditState::Pass,
            "RANDOM_BOTS_STORED",
            "stored=" + std::to_string(stored) +
                ", quarantinedOverCap=" + std::to_string(storedOverCap) +
                (storedExamples.empty() ? "" : ", examples=" + JoinExamples(storedExamples)));
    }

    bool const outlandExpected = EraPolicy::IsEraReleased(EraPolicy::Era::Tbc);
    bool const northrendExpected = EraPolicy::IsEraReleased(EraPolicy::Era::Wotlk);
    bool const outlandActual = EraPolicy::IsMapAllowed(530);
    bool const northrendActual = EraPolicy::IsMapAllowed(571);
    bool const mapPolicyOk = outlandExpected == outlandActual && northrendExpected == northrendActual;
    report(
        mapPolicyOk ? AuditState::Pass : AuditState::Fail,
        "MAPS",
        "Outland=" + std::string(outlandActual ? "open" : "locked") +
            " (expected " + (outlandExpected ? "open" : "locked") + "), Northrend=" +
            (northrendActual ? "open" : "locked") + " (expected " +
            (northrendExpected ? "open" : "locked") + ")");

    uint32 futureActivities = 0;
    uint32 futureMapLeaks = 0;
    std::vector<std::string> activityExamples;
    for (AdventureActivity const& activity : AdventureCatalog::All())
    {
        if (EraPolicy::IsEraReleased(activity.era))
            continue;
        ++futureActivities;

        if (activity.instanceMap && EraPolicy::IsMapAllowed(activity.instanceMap))
        {
            ++futureMapLeaks;
            if (activityExamples.size() < 5)
                activityExamples.push_back(activity.composerId);
        }
    }
    report(
        futureMapLeaks ? AuditState::Fail : AuditState::Pass,
        "COMPOSER_FUTURE_MAPS",
        "futureActivities=" + std::to_string(futureActivities) +
            ", mapLeaks=" + std::to_string(futureMapLeaks) +
            (activityExamples.empty() ? "" : ", examples=" + JoinExamples(activityExamples)));

    AuditState const summary = failures ? AuditState::Fail : (warnings ? AuditState::Warn : AuditState::Pass);
    handler->PSendSysMessage(
        "[EraAudit] {} SUMMARY - failures={} warnings={} (read-only)",
        Label(summary),
        failures,
        warnings);
    return true;
}
