#ifndef MOD_TITAN_RUNE_SYSTEM_H
#define MOD_TITAN_RUNE_SYSTEM_H

#include "Define.h"

class Map;
class Player;

enum class TitanRuneMode : uint8
{
    Off = 0,
    Alpha = 1,
    Beta = 2,
    Gamma = 3,
};

namespace TitanRune
{
constexpr uint32 SIDEREAL_ESSENCE_ITEM = 900100;
constexpr uint32 SCOURGESTONE_ITEM = 900101;
constexpr uint32 COORDINATOR_ENTRY = 900110;
constexpr uint32 SIDEREAL_VENDOR_ENTRY = 900111;
constexpr uint32 SCOURGESTONE_VENDOR_ENTRY = 900112;

char const* ModeName(TitanRuneMode mode);
TitanRuneMode LoadSelectedMode(Player* player);
void SaveSelectedMode(Player* player, TitanRuneMode mode);
TitanRuneMode GetActiveMode(Map const* map);
bool IsSupportedDungeon(uint32 mapId, TitanRuneMode mode);
void ActivateForPlayer(Player* player);
}

void AddTitanRuneScripts();

#endif
