#ifndef MOD_RAID_ROSTER_GEAR_H
#define MOD_RAID_ROSTER_GEAR_H

#include "Define.h"

class Player;

namespace RaidRosterGear
{
void EquipCatchup(Player* player, uint32 quality, uint32 itemLevel);
// Deterministic strip-and-rebuild gear pass for one roster bot, under its CURRENT
// (already-pinned) talent spec — the caller MUST force talents first, because all
// scoring reads the active talent tab. At bot level >= 50 it targets the master's
// average equipped item level (tier-set stage + ilvl-windowed off-pieces); below 50
// it equips best-in-slot for the bot's OWN level (open floor, ilvl ceiling derived from
// the bot's level). Candidates are gated on their effective required level in both
// bands. Same inputs => same gear.
// Returns false when the bot was skipped (not in world / below level 5) or gearing
// was too incomplete to trust (< 8 pieces equipped).
bool EquipForSpec(Player* bot, Player* master, int specTab, uint16 minimumItemLevel = 0);
}

#endif
