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

// Titan Rune currencies/emblems are scripted rewards rather than ordinary creature loot. Queue them
// durably before attempting inventory delivery so a full bag cannot permanently eat a boss reward.
void QueuePlayerReward(Player* player, uint32 instanceId, uint32 bossEntry, TitanRuneMode mode,
    uint32 itemEntry, uint32 count, char const* reason);
uint32 RetryPendingRewards(Player* player, bool notifyIfBlocked = false);
}

void AddTitanRuneScripts();

#endif
