#include "SmartLootStore.h"

#include "DatabaseEnv.h"
#include "Field.h"
#include "QueryResult.h"

#include <mutex>

namespace
{
std::mutex g_smartLootStoreMutex;
}

namespace SmartLootStore
{
bool PersonalLootEnabled(uint32 guid)
{
    std::lock_guard<std::mutex> lock(g_smartLootStoreMutex);
    if (QueryResult result = CharacterDatabase.Query(
            "SELECT personal_loot FROM mod_smart_loot_pref WHERE guid = {} LIMIT 1", guid))
        return result->Fetch()[0].Get<uint8>() != 0;
    return false;
}

void SetPersonalLootEnabled(uint32 guid, bool enabled)
{
    std::lock_guard<std::mutex> lock(g_smartLootStoreMutex);
    CharacterDatabase.DirectExecute(
        "INSERT INTO mod_smart_loot_pref (guid, personal_loot) VALUES ({}, {}) "
        "ON DUPLICATE KEY UPDATE personal_loot=VALUES(personal_loot)",
        guid, enabled ? 1 : 0);
}

uint16 IncrementDryStreak(uint32 guid, uint32 mapId, uint32 bossEntry)
{
    std::lock_guard<std::mutex> lock(g_smartLootStoreMutex);

    // The returned streak is used immediately for diagnostics/protection decisions, so the write
    // must have completed before the SELECT. Execute() is asynchronous and was a race here.
    CharacterDatabase.DirectExecute(
        "INSERT INTO mod_bad_luck_streak (guid, map_id, boss_entry, dry_kills) VALUES ({}, {}, {}, 1) "
        "ON DUPLICATE KEY UPDATE dry_kills=LEAST(dry_kills + 1, 65535)",
        guid, mapId, bossEntry);

    if (QueryResult result = CharacterDatabase.Query(
            "SELECT dry_kills FROM mod_bad_luck_streak "
            "WHERE guid = {} AND map_id = {} AND boss_entry = {} LIMIT 1",
            guid, mapId, bossEntry))
        return result->Fetch()[0].Get<uint16>();
    return 0;
}

void ResetDryStreak(uint32 guid, uint32 mapId, uint32 bossEntry)
{
    std::lock_guard<std::mutex> lock(g_smartLootStoreMutex);
    CharacterDatabase.DirectExecute(
        "UPDATE mod_bad_luck_streak SET dry_kills=0 WHERE guid={} AND map_id={} AND boss_entry={}",
        guid, mapId, bossEntry);
}

std::vector<BadLuckRow> LoadDryStreaks(uint32 guid)
{
    std::lock_guard<std::mutex> lock(g_smartLootStoreMutex);
    std::vector<BadLuckRow> rows;
    QueryResult result = CharacterDatabase.Query(
        "SELECT map_id, boss_entry, dry_kills FROM mod_bad_luck_streak "
        "WHERE guid={} AND dry_kills>0 ORDER BY dry_kills DESC, last_kill_time DESC LIMIT 20",
        guid);
    if (!result)
        return rows;

    do
    {
        Field* fields = result->Fetch();
        rows.push_back({fields[0].Get<uint32>(), fields[1].Get<uint32>(), fields[2].Get<uint16>()});
    } while (result->NextRow());
    return rows;
}
}
