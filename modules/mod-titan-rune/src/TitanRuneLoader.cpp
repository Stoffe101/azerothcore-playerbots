#include "TitanRuneSystem.h"
#include "Log.h"

void AddTitanRuneAffixScripts();
void AddTitanRuneShadowScripts();
void AddTitanRuneFamilyScripts();
void AddTitanRuneGammaScripts();
void AddTitanRuneRewardScripts();
void AddTitanRuneLootScripts();
void AddTitanRuneDeviceScripts();
void AddTitanRuneTitanScripts();
void AddTitanRunePendingRewardScripts();

void Addmod_titan_runeScripts()
{
    LOG_INFO("server.loading", "[TitanRune] Registering Titan Rune dungeon scripts.");
    AddTitanRunePendingRewardScripts();
    AddTitanRuneScripts();
    AddTitanRuneAffixScripts();
    AddTitanRuneShadowScripts();
    AddTitanRuneFamilyScripts();
    AddTitanRuneGammaScripts();
    AddTitanRuneRewardScripts();
    AddTitanRuneLootScripts();
    AddTitanRuneDeviceScripts();
    AddTitanRuneTitanScripts();
}
