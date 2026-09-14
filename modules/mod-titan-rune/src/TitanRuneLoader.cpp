#include "TitanRuneSystem.h"
#include "Log.h"

void AddTitanRuneAffixScripts();

void Addmod_titan_runeScripts()
{
    LOG_INFO("server.loading", "[TitanRune] Registering Titan Rune dungeon scripts.");
    AddTitanRuneScripts();
    AddTitanRuneAffixScripts();
}
