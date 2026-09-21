#ifndef MOD_RAID_ROSTER_WOWSIMS_SERVICE_H
#define MOD_RAID_ROSTER_WOWSIMS_SERVICE_H

#include <string>

class Player;

namespace WoWSimsService
{
std::string BuildCharacterSnapshot(Player* player);
bool ValidateCharacterSnapshot(Player* player, std::string& summary, std::string& error);
}

#endif
