#ifndef MOD_RAID_ROSTER_ADVENTURE_START_CONTROL_H
#define MOD_RAID_ROSTER_ADVENTURE_START_CONTROL_H

#include "Define.h"

class Player;

enum class AdventureStartProfile : uint8
{
    TbcAdventure = 0,
    TbcRaidReady = 1,
};

namespace AdventureStartControl
{
AdventureStartProfile GetDefaultProfile();
void SetDefaultProfile(AdventureStartProfile profile);
char const* ProfileName(AdventureStartProfile profile);

// True when the character currently matches the level/progression marker of a starter profile.
bool MatchesProfile(Player* player, AdventureStartProfile profile);

// Bootstrap a character into the requested profile. forceStarterReset is used by the GM
// "make this character TBC raid ready" action so an already-initialized level-60 starter gets a
// fresh level-70 kit and a new spec-aware pre-raid gear pass.
bool ApplyProfile(Player* player, AdventureStartProfile profile, bool forceStarterReset);

inline bool MakeTbcRaidReady(Player* player)
{
    return ApplyProfile(player, AdventureStartProfile::TbcRaidReady, true);
}
}

#endif
