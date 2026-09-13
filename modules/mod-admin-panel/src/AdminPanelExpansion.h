#ifndef MOD_ADMIN_PANEL_EXPANSION_H
#define MOD_ADMIN_PANEL_EXPANSION_H

#include "Define.h"

namespace AdminPanelExpansion
{
// TBC is the default live expansion. WotLK only becomes available after the administrator
// deliberately releases it; that persisted state is applied again on every worldserver start.
bool IsWotlkReleased();
void SetWotlkReleased(bool released);
uint8 CurrentLevelCap();
uint8 CurrentProgressionLimit();
char const* CurrentExpansionName();
}

#endif
