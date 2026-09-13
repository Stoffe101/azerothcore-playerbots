#include "TitanRuneSystem.h"
#include "Log.h"

void Addmod_titan_runeScripts()
{
    LOG_INFO("server.loading", "[TitanRune] Registering Titan Rune dungeon scripts.");
    AddTitanRuneScripts();
}
