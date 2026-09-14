#include "TitanRuneSystem.h"
#include "Log.h"

void AddTitanRuneSelectionGuardScripts();
void AddTitanRuneAffixScripts();
void AddTitanRuneShadowScripts();
void AddTitanRuneFamilyScripts();
void AddTitanRuneGammaScripts();
void AddTitanRuneRewardScripts();
void AddTitanRuneLootScripts();

void Addmod_titan_runeScripts()
{
    LOG_INFO("server.loading", "[TitanRune] Registering Titan Rune dungeon scripts.");
    // Register the selection guard first so an explicit real-group-leader Off choice cannot be
    // overridden by a member's personal next-dungeon preference during the same map-change event.
    AddTitanRuneSelectionGuardScripts();
    AddTitanRuneScripts();
    AddTitanRuneAffixScripts();
    AddTitanRuneShadowScripts();
    AddTitanRuneFamilyScripts();
    AddTitanRuneGammaScripts();
    AddTitanRuneRewardScripts();
    AddTitanRuneLootScripts();
}
