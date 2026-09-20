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

uint8 LevelCap(Era era);
uint8 RealmLevelCap();
uint8 ProgressionCeiling(Era era);
uint8 RealmProgressionCeiling();
uint8 MinimumProgression(Era era);
uint8 RealmMinimumProgression();
bool IsEraReleased(Era era);

char const* Name(Era era);
char const* Token(Era era);
char const* Key(Era era);
bool Parse(std::string_view value, Era& era);
}

#endif
