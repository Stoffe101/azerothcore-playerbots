#ifndef MOD_ADMIN_PANEL_EXPANSION_H
#define MOD_ADMIN_PANEL_EXPANSION_H

#include "Define.h"

class Player;

namespace AdminPanelExpansion
{
// TBC is the default live expansion. WotLK only becomes available after the administrator
// deliberately releases it; that persisted state is applied again on every worldserver start.
bool IsWotlkReleased();
void SetWotlkReleased(bool released);
uint8 CurrentLevelCap();
uint8 CurrentProgressionLimit();
uint8 PlayerProgression(Player* player);

// Exact manual progression control for the current character. The global live-expansion ceiling
// is always enforced, so a TBC realm cannot be accidentally pushed into stage 13 by the panel.
bool SetPlayerProgression(Player* player, uint8 stage);

char const* CurrentExpansionName();
}

#endif
