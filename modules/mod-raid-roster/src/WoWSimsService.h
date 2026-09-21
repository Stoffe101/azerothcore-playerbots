#ifndef MOD_RAID_ROSTER_WOWSIMS_SERVICE_H
#define MOD_RAID_ROSTER_WOWSIMS_SERVICE_H

#include "Define.h"

#include <string>

class Player;

namespace WoWSimsService
{
std::string BuildCharacterSnapshot(Player* player);
std::string BuildBagCandidateSnapshot(Player* player);
bool BuildBagCandidateManifest(Player* player, std::string& summary, std::string& error);
bool BuildBaselineRequest(Player* player, std::string& summary, std::string& error);
bool ValidateCharacterSnapshot(Player* player, std::string& summary, std::string& error);
bool QueueBagComparison(Player* player, uint64& jobId, std::string& error);
void StartAsyncWorker();
void StopAsyncWorker();
void TickAsyncResults();
}

#endif
