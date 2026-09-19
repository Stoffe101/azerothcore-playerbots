#ifndef MOD_ADMIN_PANEL_EXPANSION_H
#define MOD_ADMIN_PANEL_EXPANSION_H

#include "Define.h"

class Player;

enum class RealmEra : uint8
{
    Vanilla = 0,
    Tbc = 1,
    Wotlk = 2,
};

namespace AdminPanelExpansion
{
RealmEra CurrentEra();
void SetEra(RealmEra era);
bool IsTbcReleased();
bool IsWotlkReleased();
uint8 CurrentLevelCap();
uint8 CurrentProgressionLimit();
uint8 MinimumProgressionForCurrentEra();
uint8 PlayerProgression(Player* player);

// Exact manual progression control for the current character. The global live-expansion ceiling
// is always enforced. Stage 0 is supported explicitly by clearing the hidden progression quests.
bool SetPlayerProgression(Player* player, uint8 stage);

char const* CurrentExpansionName();
char const* EraKey(RealmEra era);
bool ParseEra(char const* value, RealmEra& era);
}

#endif
