#include "GroupComposerReserve.h"

#include "GroupComposerTypes.h"

#include "CharacterCache.h"
#include "Group.h"
#include "ObjectAccessor.h"
#include "Player.h"
#include "PlayerbotAIConfig.h"
#include "RandomPlayerbotMgr.h"

#include <ctime>
#include <sstream>
#include <unordered_map>
#include <unordered_set>
#include <vector>

namespace GroupComposer::Reserve
{
namespace
{
struct Lease
{
    uint32 owner = 0;
    time_t acquired = 0;
    bool randomBot = false;
};

std::unordered_map<uint32, Lease> s_leases;
std::unordered_map<uint32, std::unordered_set<uint32>> s_byOwner;
uint32 s_updateAccumulator = 0;

bool IsRandomBotCharacter(ObjectGuid guid)
{
    uint32 account = sCharacterCache->GetCharacterAccountIdByGuid(guid);
    return account && sPlayerbotAIConfig.IsInRandomAccountList(account);
}

void ReleaseBot(uint32 botLow)
{
    auto itr = s_leases.find(botLow);
    if (itr == s_leases.end()) return;

    Lease lease = itr->second;
    if (lease.randomBot)
        sRandomPlayerbotMgr.ReleaseGroupComposerBot(ObjectGuid::Create<HighGuid::Player>(botLow));

    auto ownerItr = s_byOwner.find(lease.owner);
    if (ownerItr != s_byOwner.end())
    {
        ownerItr->second.erase(botLow);
        if (ownerItr->second.empty()) s_byOwner.erase(ownerItr);
    }
    s_leases.erase(itr);
}
}

uint32 TotalLeased()
{
    return static_cast<uint32>(s_leases.size());
}

uint32 OwnerLeased(uint32 ownerGuidLow)
{
    auto itr = s_byOwner.find(ownerGuidLow);
    return itr == s_byOwner.end() ? 0u : static_cast<uint32>(itr->second.size());
}

bool AvailableTo(uint32 ownerGuidLow, ObjectGuid guid)
{
    auto itr = s_leases.find(guid.GetCounter());
    return itr == s_leases.end() || itr->second.owner == ownerGuidLow;
}

bool AcquirePlan(Player* owner, Plan const& plan, std::string& error)
{
    if (!owner)
    {
        error = "Composer reserve has no live owner.";
        return false;
    }

    uint32 ownerLow = owner->GetGUID().GetCounter();
    std::vector<ObjectGuid> requested;
    requested.reserve(plan.members.size());
    std::unordered_set<uint32> unique;

    for (Member const& member : plan.members)
    {
        if (member.human) continue;
        if (unique.insert(member.guid.GetCounter()).second)
            requested.push_back(member.guid);
    }

    if (requested.size() > PER_OWNER_LIMIT)
    {
        error = "This roster needs " + std::to_string(requested.size()) +
            " bot slots, above the per-player Composer reserve limit of 40.";
        return false;
    }

    uint32 additional = 0;
    for (ObjectGuid guid : requested)
    {
        auto lease = s_leases.find(guid.GetCounter());
        if (lease == s_leases.end()) ++additional;
        else if (lease->second.owner != ownerLow)
        {
            error = "Selected bot is already leased to another player's active Composer roster. Run Find Roster again.";
            return false;
        }
    }

    if (OwnerLeased(ownerLow) + additional > PER_OWNER_LIMIT)
    {
        error = "Your active Composer leases would exceed 40 bot slots. Finish or disband the existing Composer group first.";
        return false;
    }
    if (TotalLeased() + additional > GLOBAL_LIMIT)
    {
        std::ostringstream out;
        out << "Composer reserve capacity is busy (" << TotalLeased() << '/' << GLOBAL_LIMIT
            << " slots in use). This roster needs " << additional << " more slot(s).";
        error = out.str();
        return false;
    }

    std::vector<uint32> acquired;
    for (ObjectGuid guid : requested)
    {
        uint32 low = guid.GetCounter();
        if (s_leases.count(low)) continue;

        bool randomBot = IsRandomBotCharacter(guid);
        if (randomBot && !sRandomPlayerbotMgr.ActivateGroupComposerBot(guid))
        {
            for (uint32 rollback : acquired) ReleaseBot(rollback);
            error = "No safe ordinary world-bot slot could be rotated out for the requested Composer roster.";
            return false;
        }

        s_leases.emplace(low, Lease{ ownerLow, time(nullptr), randomBot });
        s_byOwner[ownerLow].insert(low);
        acquired.push_back(low);
    }

    return true;
}

void ReleaseUnjoined(Player* owner)
{
    if (!owner) return;
    uint32 ownerLow = owner->GetGUID().GetCounter();
    auto itr = s_byOwner.find(ownerLow);
    if (itr == s_byOwner.end()) return;

    Group* group = owner->GetGroup();
    std::vector<uint32> release;
    for (uint32 botLow : itr->second)
    {
        ObjectGuid guid = ObjectGuid::Create<HighGuid::Player>(botLow);
        if (!group || !group->IsMember(guid)) release.push_back(botLow);
    }
    for (uint32 botLow : release) ReleaseBot(botLow);
}

void ReleaseOwner(uint32 ownerGuidLow)
{
    auto itr = s_byOwner.find(ownerGuidLow);
    if (itr == s_byOwner.end()) return;
    std::vector<uint32> release(itr->second.begin(), itr->second.end());
    for (uint32 botLow : release) ReleaseBot(botLow);
}

void Update(uint32 diff)
{
    s_updateAccumulator += diff;
    if (s_updateAccumulator < 5000) return;
    s_updateAccumulator = 0;

    time_t now = time(nullptr);
    std::vector<uint32> release;
    for (auto const& entry : s_leases)
    {
        uint32 botLow = entry.first;
        Lease const& lease = entry.second;
        if (now - lease.acquired < 180) continue; // prepared previews stay reserved for three minutes

        ObjectGuid ownerGuid = ObjectGuid::Create<HighGuid::Player>(lease.owner);
        ObjectGuid botGuid = ObjectGuid::Create<HighGuid::Player>(botLow);
        Player* owner = ObjectAccessor::FindConnectedPlayer(ownerGuid);

        // A committed bot belongs to the live group, not merely to the owner's current network
        // session. Preserve that lease through a temporary disconnect as long as CharacterCache
        // still says owner and bot share the same persisted group. Once the owner actually leaves
        // the group (or the bot is kicked), the lease naturally becomes releasable.
        if (owner)
        {
            Group* group = owner->GetGroup();
            if (group && group->IsMember(botGuid)) continue;
        }
        else
        {
            ObjectGuid ownerGroup = sCharacterCache->GetCharacterGroupGuidByGuid(ownerGuid);
            ObjectGuid botGroup = sCharacterCache->GetCharacterGroupGuidByGuid(botGuid);
            if (!ownerGroup.IsEmpty() && ownerGroup == botGroup) continue;
        }

        release.push_back(botLow);
    }

    for (uint32 botLow : release) ReleaseBot(botLow);
}

std::string Status(uint32 ownerGuidLow)
{
    std::ostringstream out;
    out << "Composer reserve " << TotalLeased() << '/' << GLOBAL_LIMIT
        << " global; " << OwnerLeased(ownerGuidLow) << '/' << PER_OWNER_LIMIT << " yours.";
    return out.str();
}
}
