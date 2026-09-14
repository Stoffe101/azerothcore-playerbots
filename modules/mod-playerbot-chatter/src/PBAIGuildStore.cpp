#include "PBAIGuildStore.h"
#include "DatabaseEnv.h"
#include "Field.h"
#include "QueryResult.h"

#include <algorithm>
#include <atomic>
#include <chrono>

namespace PBAIGuildStore
{
namespace
{
std::atomic<uint32> g_eventSequence{0};

uint32 Mix(uint32 value)
{
    value ^= value >> 16;
    value *= 0x7feb352dU;
    value ^= value >> 15;
    value *= 0x846ca68bU;
    value ^= value >> 16;
    return value;
}

uint8 StableTrait(uint32 seed, uint32 salt)
{
    return static_cast<uint8>(25 + (Mix(seed ^ salt) % 51));
}

std::string PreferredContent(uint32 seed)
{
    switch (Mix(seed ^ 0xA17E20B5U) % 4)
    {
        case 0: return "dungeons";
        case 1: return "raids";
        case 2: return "pvp";
        default: return "mixed";
    }
}

uint64 NextEventId()
{
    uint64 nowMs = static_cast<uint64>(std::chrono::duration_cast<std::chrono::milliseconds>(
        std::chrono::system_clock::now().time_since_epoch()).count());
    uint64 sequence = static_cast<uint64>(g_eventSequence.fetch_add(1, std::memory_order_relaxed) & 0xFFFFu);
    return (nowMs << 16) | sequence;
}

Memory ReadMemory(Field* fields)
{
    Memory memory;
    memory.memoryId = fields[0].Get<uint64>();
    memory.type = fields[1].Get<std::string>();
    memory.importance = fields[2].Get<uint8>();
    memory.relatedType = fields[3].Get<uint8>();
    memory.relatedGuid = fields[4].Get<uint32>();
    memory.summary = fields[5].Get<std::string>();
    return memory;
}
}

Profile GetOrCreateProfile(uint32 botGuid)
{
    Profile profile;
    profile.botGuid = botGuid;

    QueryResult result = CharacterDatabase.Query(
        "SELECT persona_seed, temperament, humor, confidence, sociability, preferred_content "
        "FROM mod_ai_guild_profile WHERE bot_guid = {}",
        botGuid);

    if (!result)
    {
        profile.personaSeed = Mix(botGuid ^ 0x51A1B07U);
        profile.temperament = StableTrait(profile.personaSeed, 0x10U);
        profile.humor = StableTrait(profile.personaSeed, 0x20U);
        profile.confidence = StableTrait(profile.personaSeed, 0x30U);
        profile.sociability = StableTrait(profile.personaSeed, 0x40U);
        profile.preferredContent = PreferredContent(profile.personaSeed);

        CharacterDatabase.DirectExecute(
            "INSERT IGNORE INTO mod_ai_guild_profile "
            "(bot_guid, persona_seed, temperament, humor, confidence, sociability, preferred_content) "
            "VALUES ({}, {}, {}, {}, {}, {}, '{}')",
            botGuid,
            profile.personaSeed,
            profile.temperament,
            profile.humor,
            profile.confidence,
            profile.sociability,
            profile.preferredContent);

        result = CharacterDatabase.Query(
            "SELECT persona_seed, temperament, humor, confidence, sociability, preferred_content "
            "FROM mod_ai_guild_profile WHERE bot_guid = {}",
            botGuid);
    }

    if (!result)
        return profile;

    Field* fields = result->Fetch();
    profile.personaSeed = fields[0].Get<uint32>();
    profile.temperament = fields[1].Get<uint8>();
    profile.humor = fields[2].Get<uint8>();
    profile.confidence = fields[3].Get<uint8>();
    profile.sociability = fields[4].Get<uint8>();
    profile.preferredContent = fields[5].Get<std::string>();
    return profile;
}

std::vector<Memory> GetRecentImportantMemories(uint32 botGuid, uint32 limit)
{
    std::vector<Memory> memories;
    limit = std::clamp<uint32>(limit, 1, 20);

    QueryResult result = CharacterDatabase.Query(
        "SELECT memory_id, memory_type, importance, related_type, related_guid, summary "
        "FROM mod_ai_guild_memory WHERE bot_guid = {} "
        "ORDER BY importance DESC, occurred_at DESC LIMIT {}",
        botGuid, limit);

    if (!result)
        return memories;

    do
    {
        memories.push_back(ReadMemory(result->Fetch()));
    } while (result->NextRow());

    return memories;
}

std::vector<Memory> GetMemoriesRelatedTo(uint32 botGuid, uint8 relatedType, uint32 relatedGuid, uint32 limit)
{
    std::vector<Memory> memories;
    limit = std::clamp<uint32>(limit, 1, 10);

    QueryResult result = CharacterDatabase.Query(
        "SELECT memory_id, memory_type, importance, related_type, related_guid, summary "
        "FROM mod_ai_guild_memory WHERE bot_guid = {} AND related_type = {} AND related_guid = {} "
        "ORDER BY importance DESC, occurred_at DESC LIMIT {}",
        botGuid, relatedType, relatedGuid, limit);

    if (!result)
        return memories;

    do
    {
        memories.push_back(ReadMemory(result->Fetch()));
    } while (result->NextRow());

    return memories;
}

Relationship GetRelationship(uint32 botGuid, uint8 targetType, uint32 targetGuid)
{
    Relationship relationship;
    QueryResult result = CharacterDatabase.Query(
        "SELECT familiarity, affinity, trust, shared_runs FROM mod_ai_guild_relationship "
        "WHERE bot_guid = {} AND target_type = {} AND target_guid = {} LIMIT 1",
        botGuid, targetType, targetGuid);

    if (!result)
        return relationship;

    Field* fields = result->Fetch();
    relationship.exists = true;
    relationship.familiarity = fields[0].Get<uint16>();
    relationship.affinity = fields[1].Get<int16>();
    relationship.trust = fields[2].Get<uint16>();
    relationship.sharedRuns = fields[3].Get<uint32>();
    return relationship;
}

uint64 RecordEvent(std::string eventType, uint32 actorGuid, uint32 targetGuid,
                   uint32 mapId, uint32 encounterId, std::string summary)
{
    if (eventType.empty())
        eventType = "event";
    if (eventType.size() > 32)
        eventType.resize(32);
    if (summary.size() > 500)
        summary.resize(500);

    uint64 eventId = NextEventId();
    CharacterDatabase.EscapeString(eventType);
    CharacterDatabase.EscapeString(summary);

    CharacterDatabase.Execute(
        "INSERT INTO mod_ai_guild_event "
        "(event_id, event_type, actor_guid, target_guid, map_id, encounter_id, summary) "
        "VALUES ({}, '{}', {}, {}, {}, {}, '{}')",
        eventId,
        eventType,
        actorGuid,
        targetGuid,
        mapId,
        encounterId,
        summary);

    return eventId;
}

void AddMemory(uint32 botGuid, uint64 eventId, std::string memoryType, uint8 importance,
               uint8 relatedType, uint32 relatedGuid, std::string summary)
{
    if (summary.empty())
        return;

    if (importance > 100)
        importance = 100;
    if (memoryType.size() > 32)
        memoryType.resize(32);
    if (summary.size() > 500)
        summary.resize(500);

    CharacterDatabase.EscapeString(memoryType);
    CharacterDatabase.EscapeString(summary);

    CharacterDatabase.Execute(
        "INSERT INTO mod_ai_guild_memory "
        "(bot_guid, event_id, memory_type, importance, related_type, related_guid, summary) "
        "VALUES ({}, {}, '{}', {}, {}, {}, '{}')",
        botGuid, eventId, memoryType, importance, relatedType, relatedGuid, summary);
}

void TouchRelationship(uint32 botGuid, uint8 targetType, uint32 targetGuid,
                       uint16 familiarityGain, int16 affinityDelta, uint16 trustGain,
                       bool sharedRun)
{
    CharacterDatabase.Execute(
        "INSERT INTO mod_ai_guild_relationship "
        "(bot_guid, target_type, target_guid, familiarity, affinity, trust, shared_runs, last_interaction) "
        "VALUES ({}, {}, {}, {}, {}, {}, {}, CURRENT_TIMESTAMP) "
        "ON DUPLICATE KEY UPDATE "
        "familiarity = LEAST(65535, familiarity + VALUES(familiarity)), "
        "affinity = GREATEST(-1000, LEAST(1000, affinity + VALUES(affinity))), "
        "trust = LEAST(65535, trust + VALUES(trust)), "
        "shared_runs = shared_runs + VALUES(shared_runs), "
        "last_interaction = CURRENT_TIMESTAMP",
        botGuid,
        targetType,
        targetGuid,
        familiarityGain,
        affinityDelta,
        trustGain,
        sharedRun ? 1 : 0);
}
}
