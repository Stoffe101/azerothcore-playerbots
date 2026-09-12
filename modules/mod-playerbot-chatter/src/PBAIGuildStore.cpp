#include "PBAIGuildStore.h"
#include "DatabaseEnv.h"
#include "Field.h"
#include "QueryResult.h"

#include <algorithm>

namespace PBAIGuildStore
{
namespace
{
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
    // Keep defaults recognizable without generating cartoonishly extreme personalities.
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

        CharacterDatabase.Execute(
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

        // Another world thread may have inserted first. Read the canonical persisted row.
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
        Field* fields = result->Fetch();
        Memory memory;
        memory.memoryId = fields[0].Get<uint64>();
        memory.type = fields[1].Get<std::string>();
        memory.importance = fields[2].Get<uint8>();
        memory.relatedType = fields[3].Get<uint8>();
        memory.relatedGuid = fields[4].Get<uint32>();
        memory.summary = fields[5].Get<std::string>();
        memories.push_back(std::move(memory));
    } while (result->NextRow());

    return memories;
}

void AddMemory(uint32 botGuid, uint64 eventId, std::string memoryType, uint8 importance,
               uint8 relatedType, uint32 relatedGuid, std::string summary)
{
    if (summary.empty())
        return;

    if (importance > 100)
        importance = 100;

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
