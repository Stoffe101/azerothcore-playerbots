#ifndef MOD_RAID_ROSTER_ADVENTURE_START_CONTROL_H
#define MOD_RAID_ROSTER_ADVENTURE_START_CONTROL_H

#include "Define.h"

class Player;

enum class AdventureStartProfile : uint8
{
    TbcAdventure = 0,
    TbcRaidReady = 1,
    WotlkRaidReady = 2,
    VanillaFresh = 3,
};

namespace AdventureStartControl
{
// Stable progression values mirrored from mod-individual-progression's ProgressionState. Keep the
// dependency itself inside AdventureStartControl.cpp: PlayerbotAI.h and IndividualProgression.h
// both expose a legacy unscoped GENERAL enumerator and cannot safely share a translation unit.
inline constexpr uint8 ProgressionStart = 0;
inline constexpr uint8 ProgressionMoltenCore = 1;
inline constexpr uint8 ProgressionPreAq = 4;
inline constexpr uint8 ProgressionPreTbc = 8;
inline constexpr uint8 ProgressionTbcTier1 = 9;
inline constexpr uint8 ProgressionTbcTier2 = 10;
inline constexpr uint8 ProgressionTbcTier4 = 12;
inline constexpr uint8 ProgressionWotlkEntry = 13;
inline constexpr uint8 ProgressionWotlkTier1 = 14;
inline constexpr uint8 ProgressionWotlkTier2 = 15;
inline constexpr uint8 ProgressionWotlkTier3 = 16;
inline constexpr uint8 ProgressionWotlkTier4 = 17;
inline constexpr uint8 ProgressionWotlkMax = 18;

uint8 CurrentProgression(Player* player);
bool HasPassedProgression(Player* player, uint8 progression);
uint8 RequiredZulGurubProgression();
uint8 RequiredZulAmanProgression();

AdventureStartProfile GetDefaultProfile();
void SetDefaultProfile(AdventureStartProfile profile);
char const* ProfileName(AdventureStartProfile profile);

// True when the character currently matches the level/progression marker of a starter profile.
bool MatchesProfile(Player* player, AdventureStartProfile profile);

// Raid-ready profiles represent a character whose mandatory endgame access/story gates are already
// complete. Returns true when missing completion state was repaired.
bool EnsureRaidReadyAccess(Player* player, AdventureStartProfile profile);

// Admin-only convenience boundary: after the normal WotLK raid-ready bootstrap, mark this
// character as having completed this realm's WotLK progression/access campaign. This advances the
// hidden Individual Progression milestone to max WotLK and repairs access/phasing quests, but does
// not fabricate heroic raid achievements.
bool CompleteWotlkExpansionAccess(Player* player);

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
