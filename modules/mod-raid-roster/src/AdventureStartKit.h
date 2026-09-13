#ifndef MOD_RAID_ROSTER_ADVENTURE_START_KIT_H
#define MOD_RAID_ROSTER_ADVENTURE_START_KIT_H

class Player;

namespace AdventureStartKit
{
// Gives the one-time level-60/TBC starter package: class skills/spells, bags, consumables,
// fast-ground riding skill, minimum starting gold and a basic Outland-ready gear set.
bool GrantInitial(Player* player);

// Upgrades the basic gear to the configured rare/spec-aware starter set once the character has
// committed enough era-talent points for Playerbots' spec bridge to identify the intended tree.
// Returns true when no further polling is needed (already granted or granted by this call).
bool TryGiveSpecStarterGear(Player* player);
}

#endif
