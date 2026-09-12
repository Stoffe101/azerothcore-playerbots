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

Profile GetOrCreateProfile(uint32 botGuid);
std::vector<Memory> GetRecentImportantMemories(uint32 botGuid, uint32 limit = 5);
void AddMemory(uint32 botGuid, uint64 eventId, std::string memoryType, uint8 importance,
               uint8 relatedType, uint32 relatedGuid, std::string summary);
void TouchRelationship(uint32 botGuid, uint8 targetType, uint32 targetGuid,
                       uint16 familiarityGain, int16 affinityDelta, uint16 trustGain,
                       bool sharedRun);
}

#endif
