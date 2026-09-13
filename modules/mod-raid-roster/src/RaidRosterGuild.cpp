#include "RaidRosterGuild.h"

#include "CharacterCache.h"
#include "Guild.h"
#include "GuildMgr.h"
#include "Log.h"
#include "ObjectAccessor.h"
#include "ObjectGuid.h"
#include "Player.h"
#include "Mgr/Guild/PlayerbotGuildMgr.h"

namespace RaidRosterGuild
{
SyncResult SyncRosterToOwnerGuild(Player* owner, std::vector<RaidRosterRow> const& rows)
{
    SyncResult result;
    if (!owner)
        return result;

    uint32 const targetGuildId = owner->GetGuildId();
    Guild* targetGuild = targetGuildId ? sGuildMgr->GetGuildById(targetGuildId) : nullptr;
    if (!targetGuild)
        return result;

    result.ownerHasGuild = true;
    result.guildId = targetGuildId;

    for (RaidRosterRow const& row : rows)
    {
        ObjectGuid const guid = ObjectGuid::Create<HighGuid::Player>(row.botGuid);

        uint32 currentGuildId = sCharacterCache->GetCharacterGuildIdByGuid(guid);
        if (Player* online = ObjectAccessor::FindConnectedPlayer(guid))
        {
            // The connected Player is authoritative if its in-memory state has already moved.
            if (online->GetGuildId())
                currentGuildId = online->GetGuildId();
        }

        if (currentGuildId == targetGuildId)
        {
            if (targetGuild->GetMember(guid))
            {
                ++result.alreadyMember;
                continue;
            }

            // Cache/player says the target guild but the Guild object does not. Let AddMember
            // repair the missing membership instead of performing direct SQL surgery.
            if (targetGuild->AddMember(guid, GUILD_RANK_NONE))
                ++result.joined;
            else
                ++result.failed;
            continue;
        }

        bool movedFromBotGuild = false;
        if (currentGuildId)
        {
            // Never rip a reserved character out of another real player's guild. This can only
            // happen after a manual guild move because roster creation already excludes such bots.
            if (PlayerbotGuildMgr::instance().IsRealGuild(currentGuildId))
            {
                ++result.blockedRealGuild;
                LOG_WARN(
                    "server.loading",
                    "[RaidRoster] Guild sync skipped bot guid {}: already belongs to real guild {} (owner guild {})",
                    row.botGuid,
                    currentGuildId,
                    targetGuildId);
                continue;
            }

            Guild* previousGuild = sGuildMgr->GetGuildById(currentGuildId);
            if (!previousGuild)
            {
                ++result.failed;
                LOG_WARN(
                    "server.loading",
                    "[RaidRoster] Guild sync could not resolve synthetic guild {} for bot guid {}",
                    currentGuildId,
                    row.botGuid);
                continue;
            }

            previousGuild->DeleteMember(guid, false, true, false);
            movedFromBotGuild = true;
        }

        if (!targetGuild->AddMember(guid, GUILD_RANK_NONE))
        {
            ++result.failed;
            LOG_WARN(
                "server.loading",
                "[RaidRoster] Guild sync failed to add bot guid {} to owner guild {}",
                row.botGuid,
                targetGuildId);
            continue;
        }

        if (movedFromBotGuild)
            ++result.movedFromBotGuild;
        else
            ++result.joined;
    }

    LOG_INFO(
        "server.loading",
        "[RaidRoster] Guild sync owner={} guild={} managed={} already={} joined={} moved-from-bot-guild={} blocked-real={} failed={}",
        owner->GetGUID().GetCounter(),
        result.guildId,
        result.Managed(),
        result.alreadyMember,
        result.joined,
        result.movedFromBotGuild,
        result.blockedRealGuild,
        result.failed);

    return result;
}
}
