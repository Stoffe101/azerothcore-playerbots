#ifndef MOD_RAID_ROSTER_GROUP_COMPOSER_RESERVE_H
#define MOD_RAID_ROSTER_GROUP_COMPOSER_RESERVE_H

#include "Define.h"
#include "ObjectGuid.h"

#include <string>

class Player;

namespace GroupComposer
{
struct Plan;

namespace Reserve
{
constexpr uint32 GLOBAL_LIMIT = 80;
constexpr uint32 PER_OWNER_LIMIT = 40;

bool AvailableTo(uint32 ownerGuidLow, ObjectGuid guid);
bool AcquirePlan(Player* owner, Plan const& plan, std::string& error);
void ReleaseUnjoined(Player* owner);
void ReleaseOwner(uint32 ownerGuidLow);
void Update(uint32 diff);
uint32 TotalLeased();
uint32 OwnerLeased(uint32 ownerGuidLow);
std::string Status(uint32 ownerGuidLow);
}
}

#endif
