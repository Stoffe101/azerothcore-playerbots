#ifndef MOD_RAID_ROSTER_ADVENTURE_START_KIT_H
#define MOD_RAID_ROSTER_ADVENTURE_START_KIT_H

#include "AdventureStartControl.h"

class Player;

namespace AdventureStartKit
{
// Gives the one-time class/bootstrap package for the selected profile: skills/spells, bags,
// consumables, riding, minimum gold and a temporary gear set. forceReset is handled by the
// caller through AdventureProgressionStore::PrepareStarterProfile.
bool GrantInitial(Player* player, AdventureStartProfile profile);

// Upgrades temporary gear to the profile's configured spec-aware epic set once enough talents are
// committed. Returns true when no further polling is needed (already granted or granted now).
bool TryGiveSpecStarterGear(Player* player);
}

#endif
