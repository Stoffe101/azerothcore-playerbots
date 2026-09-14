#include "TitanRuneSystem.h"
#include "Log.h"

void AddTitanRuneAffixScripts();
void AddTitanRuneShadowScripts();
void AddTitanRuneFamilyScripts();
void AddTitanRuneGammaScripts();

void Addmod_titan_runeScripts()
{
    LOG_INFO("server.loading", "[TitanRune] Registering Titan Rune dungeon scripts.");
    AddTitanRuneScripts();
    AddTitanRuneAffixScripts();
    AddTitanRuneShadowScripts();
    AddTitanRuneFamilyScripts();
    AddTitanRuneGammaScripts();
}
