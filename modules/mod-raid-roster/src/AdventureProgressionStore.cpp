#include "AdventureProgressionStore.h"
#include "DatabaseEnv.h"
#include "Field.h"
#include "QueryResult.h"

#include <mutex>

namespace AdventureProgressionStore
{
namespace
{
std::mutex g_progressionMutex;

void EnsureRowUnlocked(uint32 playerGuid)
{
    CharacterDatabase.DirectExecute(
        "INSERT IGNORE INTO mod_adventure_progression (player_guid) VALUES ({})",
        playerGuid);
}
}

State LoadOrCreate(uint32 playerGuid)
{
    std::lock_guard<std::mutex> lock(g_progressionMutex);
    EnsureRowUnlocked(playerGuid);

    State state;
    QueryResult result = CharacterDatabase.Query(
        "SELECT starter_initialized, starter_gear_granted, starter_spec_tab, pending_caches, last_level_cache "
        "FROM mod_adventure_progression WHERE player_guid = {}",
        playerGuid);

    if (!result)
        return state;

    Field* fields = result->Fetch();
    state.starterInitialized = fields[0].Get<uint8>() != 0;
    state.starterGearGranted = fields[1].Get<uint8>() != 0;
    state.starterSpecTab = fields[2].Get<uint8>();
    state.pendingCaches = fields[3].Get<uint16>();
    state.lastLevelCache = fields[4].Get<uint8>();
    return state;
}

void MarkStarterInitialized(uint32 playerGuid)
{
    std::lock_guard<std::mutex> lock(g_progressionMutex);
    EnsureRowUnlocked(playerGuid);
    CharacterDatabase.DirectExecute(
        "UPDATE mod_adventure_progression SET starter_initialized = 1 WHERE player_guid = {}",
        playerGuid);
}

void MarkStarterGearGranted(uint32 playerGuid, uint8 specTab)
{
    std::lock_guard<std::mutex> lock(g_progressionMutex);
    EnsureRowUnlocked(playerGuid);
    CharacterDatabase.DirectExecute(
        "UPDATE mod_adventure_progression SET starter_gear_granted = 1, starter_spec_tab = {} WHERE player_guid = {}",
        specTab, playerGuid);
}

void AddPendingCache(uint32 playerGuid, uint16 count)
{
    if (!count)
        return;

    std::lock_guard<std::mutex> lock(g_progressionMutex);
    EnsureRowUnlocked(playerGuid);
    CharacterDatabase.DirectExecute(
        "UPDATE mod_adventure_progression SET pending_caches = LEAST(65535, pending_caches + {}) WHERE player_guid = {}",
        count, playerGuid);
}

bool ConsumePendingCache(uint32 playerGuid)
{
    std::lock_guard<std::mutex> lock(g_progressionMutex);
    EnsureRowUnlocked(playerGuid);

    QueryResult result = CharacterDatabase.Query(
        "SELECT pending_caches FROM mod_adventure_progression WHERE player_guid = {}",
        playerGuid);
    if (!result || result->Fetch()[0].Get<uint16>() == 0)
        return false;

    CharacterDatabase.DirectExecute(
        "UPDATE mod_adventure_progression SET pending_caches = pending_caches - 1 "
        "WHERE player_guid = {} AND pending_caches > 0",
        playerGuid);
    return true;
}

void SetLastLevelCache(uint32 playerGuid, uint8 level)
{
    std::lock_guard<std::mutex> lock(g_progressionMutex);
    EnsureRowUnlocked(playerGuid);
    CharacterDatabase.DirectExecute(
        "UPDATE mod_adventure_progression SET last_level_cache = {} WHERE player_guid = {}",
        level, playerGuid);
}
}
