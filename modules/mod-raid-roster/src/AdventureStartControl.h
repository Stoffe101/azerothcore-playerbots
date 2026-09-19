#ifndef MOD_RAID_ROSTER_ADVENTURE_START_CONTROL_H
#define MOD_RAID_ROSTER_ADVENTURE_START_CONTROL_H

#include "Define.h"

class Player;

enum class AdventureStartProfile : uint8
{
    TbcAdventure = 0,
    TbcRaidReady = 1,
    WotlkRaidReady = 2,
};

namespace AdventureStartControl
{
AdventureStartProfile GetDefaultProfile();
void SetDefaultProfile(AdventureStartProfile profile);
char const* ProfileName(AdventureStartProfile profile);

// True when the character currently matches the level/progression marker of a starter profile.
bool MatchesProfile(Player* player, AdventureStartProfile profile);

// Raid-ready profiles represent a character whose mandatory endgame access/story gates are already
// complete. Returns true when missing completion state was repaired.
bool EnsureRaidReadyAccess(Player* player, AdventureStartProfile profile);

// Bootstrap a character into the requested profile. forceStarterReset is used by GM convenience
// actions so an already-initialized character receives a fresh starter kit and a new spec-aware
// gear pass for the selected era.
bool ApplyProfile(Player* player, AdventureStartProfile profile, bool forceStarterReset);

inline bool MakeTbcRaidReady(Player* player)
{
    return ApplyProfile(player, AdventureStartProfile::TbcRaidReady, true);
}

inline bool MakeWotlkRaidReady(Player* player)
{
    return ApplyProfile(player, AdventureStartProfile::WotlkRaidReady, true);
}
}

#endif
