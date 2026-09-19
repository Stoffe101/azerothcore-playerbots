#ifndef MOD_PLAYERBOT_CHATTER_AI_GUILD_STORE_H
#define MOD_PLAYERBOT_CHATTER_AI_GUILD_STORE_H

#include "Define.h"
#include <string>
#include <vector>

namespace PBAIGuildStore
{
struct Profile
{
    uint32 botGuid = 0;
    uint32 personaSeed = 0;
    uint8 temperament = 50;
    uint8 humor = 50;
    uint8 confidence = 50;
    uint8 sociability = 50;
    std::string preferredContent = "mixed";
};

struct Memory
{
    uint64 memoryId = 0;
    std::string type;
    uint8 importance = 0;
    uint8 relatedType = 0;
    uint32 relatedGuid = 0;
    std::string summary;
};

struct Relationship
{
    bool exists = false;
    uint16 familiarity = 0;
    int16 affinity = 0;
    uint16 trust = 0;
    uint32 sharedRuns = 0;
    uint32 sharedMinutes = 0;
    uint32 bossKills = 0;
    uint32 sharedDeaths = 0;
    uint32 wipes = 0;
    uint32 lootMoments = 0;
    uint32 duels = 0;
    uint16 guildLoyalty = 0;
    uint16 rivalry = 0;
};

enum class RelationshipSignal : uint8
{
    SharedMinute,
    BossKill,
    SharedDeath,
    Wipe,
    LootMoment,
    Duel,
    GuildHelp,
};

Profile GetOrCreateProfile(uint32 botGuid);
std::vector<Memory> GetRecentImportantMemories(uint32 botGuid, uint32 limit = 5);
std::vector<Memory> GetMemoriesRelatedTo(uint32 botGuid, uint8 relatedType, uint32 relatedGuid, uint32 limit = 3);
Relationship GetRelationship(uint32 botGuid, uint8 targetType, uint32 targetGuid);
uint64 RecordEvent(std::string eventType, uint32 actorGuid, uint32 targetGuid,
                   uint32 mapId, uint32 encounterId, std::string summary);
void AddMemory(uint32 botGuid, uint64 eventId, std::string memoryType, uint8 importance,
               uint8 relatedType, uint32 relatedGuid, std::string summary);
void TouchRelationship(uint32 botGuid, uint8 targetType, uint32 targetGuid,
                       uint16 familiarityGain, int16 affinityDelta, uint16 trustGain,
                       bool sharedRun);
void NoteRelationshipSignal(uint32 botGuid, uint8 targetType, uint32 targetGuid,
                            RelationshipSignal signal, uint32 amount = 1);
}

#endif
