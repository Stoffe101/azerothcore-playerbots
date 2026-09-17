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
bool EquipForSpec(Player* bot, Player* master, int specTab);

// Group Composer finalization is role-aware because WotLK talent tabs are not always a
// complete PvE build identity. The important example is Druid Feral: Playerbots ships
// separate Bear PvE and Cat PvE premades even though both live in talent tab 1. This
// helper locks the correct Playerbots PvE premade for the requested active role, then
// refreshes glyphs/AI/supplies before delegating to the deterministic gear pass above.
bool EquipForComposerRole(Player* bot, Player* master, int specTab, uint8 role);
}

// GroupComposerCommand.cpp historically calls EquipForSpec after it has performed the
// generic talent-tab reconciliation. Redirect that single call to the richer finalizer
// without changing every other RaidRoster caller. The command header is included before
// this file in that translation unit, so the guard is a narrow, compile-time scope marker.
// No other translation unit sees this macro.
#if defined(MOD_RAID_ROSTER_GROUP_COMPOSER_COMMAND_H)
#define EquipForSpec(bot, master, specTab) EquipForComposerRole((bot), (master), (specTab), role)
#endif

#endif
