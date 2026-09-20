#ifndef MOD_RAID_ROSTER_ERA_POLICY_H
#define MOD_RAID_ROSTER_ERA_POLICY_H

#include "Define.h"

#include <string_view>

namespace EraPolicy
{
enum class Era : uint8
{
    Vanilla = 0,
    Tbc = 1,
    Wotlk = 2,
};

Era CurrentRealmEra();
void ApplyRealmEra(Era era);
void SyncRuntimeBotCaps();

Era EraForLevel(uint8 level);
Era EraForProgression(uint8 progression);
uint8 LevelCap(Era era);
uint8 RealmLevelCap();
bool IsLevelAllowed(uint8 level);
uint8 ProgressionCeiling(Era era);
uint8 RealmProgressionCeiling();
uint8 MinimumProgression(Era era);
uint8 RealmMinimumProgression();
bool IsProgressionAllowed(uint8 progression);
bool IsEraReleased(Era era);

Era RequiredEraForClass(uint8 classId);
bool IsClassAllowed(uint8 classId);
Era RequiredEraForRace(uint8 raceId);
bool IsRaceAllowed(uint8 raceId);

Era RequiredEraForProfession(uint32 skillId);
bool IsProfessionAllowed(uint32 skillId);
uint16 ProfessionSkillCap(Era era);
uint16 RealmProfessionSkillCap();

bool TryMapEra(uint32 mapId, Era& era);
bool IsMapAllowed(uint32 mapId);

char const* Name(Era era);
char const* Token(Era era);
char const* Key(Era era);
bool Parse(std::string_view value, Era& era);
}

#endif
