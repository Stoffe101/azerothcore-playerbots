#include "AdventureControlStore.h"

#include "DatabaseEnv.h"
#include "Field.h"
#include "QueryResult.h"

#include <mutex>
#include <unordered_map>

namespace
{
std::mutex g_ratesMutex;
std::unordered_map<uint32, AdventureControlRates> g_rates;

AdventureControlRates Clamp(AdventureControlRates rates)
{
    auto clampOne = [](uint16 value) -> uint16
    {
        if (value > 1000)
            return 1000;
        return value;
    };

    rates.xpPercent = clampOne(rates.xpPercent);
    rates.goldPercent = clampOne(rates.goldPercent);
    rates.repPercent = clampOne(rates.repPercent);
    return rates;
}
}

namespace AdventureControlStore
{
AdventureControlRates Load(uint32 guid)
{
    AdventureControlRates rates;
    if (QueryResult result = CharacterDatabase.Query(
            "SELECT xp_percent, gold_percent, rep_percent FROM mod_adventure_controls WHERE guid = {} LIMIT 1",
            guid))
    {
        Field* fields = result->Fetch();
        rates.xpPercent = fields[0].Get<uint16>();
        rates.goldPercent = fields[1].Get<uint16>();
        rates.repPercent = fields[2].Get<uint16>();
        rates = Clamp(rates);
    }

    std::lock_guard<std::mutex> lock(g_ratesMutex);
    g_rates[guid] = rates;
    return rates;
}

AdventureControlRates Get(uint32 guid)
{
    std::lock_guard<std::mutex> lock(g_ratesMutex);
    auto itr = g_rates.find(guid);
    return itr != g_rates.end() ? itr->second : AdventureControlRates{};
}

void Save(uint32 guid, AdventureControlRates const& requested)
{
    AdventureControlRates rates = Clamp(requested);
    {
        std::lock_guard<std::mutex> lock(g_ratesMutex);
        g_rates[guid] = rates;
    }

    CharacterDatabase.Execute(
        "INSERT INTO mod_adventure_controls (guid, xp_percent, gold_percent, rep_percent) "
        "VALUES ({}, {}, {}, {}) ON DUPLICATE KEY UPDATE "
        "xp_percent=VALUES(xp_percent), gold_percent=VALUES(gold_percent), rep_percent=VALUES(rep_percent)",
        guid, rates.xpPercent, rates.goldPercent, rates.repPercent);
}

void Forget(uint32 guid)
{
    std::lock_guard<std::mutex> lock(g_ratesMutex);
    g_rates.erase(guid);
}
}
