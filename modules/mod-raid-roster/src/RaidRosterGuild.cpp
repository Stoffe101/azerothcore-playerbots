#include "RaidRosterGuild.h"

#include "CharacterCache.h"
#include "Guild.h"
#include "GuildMgr.h"
#include "Log.h"
#include "ObjectAccessor.h"
#include "ObjectGuid.h"
#include "Player.h"
#include "Playerbots.h"
#include "RandomPlayerbotMgr.h"
#include "ScriptMgr.h"
#include "Mgr/Guild/PlayerbotGuildMgr.h"

namespace
{
// PlayerbotGuildMgr::IsRealGuild() is backed by its own cache, which is intentionally refreshed
// only periodically. For a safety decision such as "may we move this bot out of its current
// guild?", classify from the current guild leader/account instead. Unknown state is treated as
// real and therefore protected. This makes it impossible for a stale/missing bot-guild cache entry
// to cause us to steal a companion from somebody else's newly-created human guild.
bool IsHumanLedGuild(uint32 guildId)
{
    Guild* guild = guildId ? sGuildMgr->GetGuildById(guildId) : nullptr;
    if (!guild)
        return true;

    CharacterCacheEntry const* leader = sCharacterCache->GetCharacterCacheByGuid(guild->GetLeaderGUID());
    if (!leader || !leader->AccountId)
        return true;

    bool const randomBotAccount = sRandomPlayerbotMgr.IsAccountType(leader->AccountId, 1);
    bool const addClassAccount = sRandomPlayerbotMgr.IsAccountType(leader->AccountId, 2);
    return !randomBotAccount && !addClassAccount;
}
}

namespace RaidRosterGuild
{
SyncResult SyncRosterToGuild(Player* owner, Guild* targetGuild, std::vector<RaidRosterRow> const& rows)
{
    SyncResult result;
    if (!owner || !targetGuild)
        return result;

    uint32 const targetGuildId = targetGuild->GetId();
    if (!targetGuildId)
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
            {
                PlayerbotGuildMgr::instance().OnGuildUpdate(targetGuild);
                ++result.joined;
            }
            else
                ++result.failed;
            continue;
        }

        bool movedFromBotGuild = false;
        if (currentGuildId)
        {
            // Never rip a reserved character out of another real player's guild. The decision is
            // deliberately made from the current guild leader account, not PlayerbotGuildMgr's
            // eventually-consistent guild cache.
            if (IsHumanLedGuild(currentGuildId))
            {
                ++result.blockedRealGuild;
                LOG_WARN(
                    "server.loading",
                    "[RaidRoster] Guild sync skipped bot guid {}: already belongs to human-led guild {} (owner guild {})",
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

            // canDeleteGuild=true lets AzerothCore clean up an empty synthetic bot guild if this
            // character happened to be its final member/leader. We never dereference the old
            // pointer afterwards unless GuildMgr still owns that guild.
            previousGuild->DeleteMember(guid, false, true, true);
            if (Guild* survivingGuild = sGuildMgr->GetGuildById(currentGuildId))
                PlayerbotGuildMgr::instance().OnGuildUpdate(survivingGuild);
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

        PlayerbotGuildMgr::instance().OnGuildUpdate(targetGuild);
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

SyncResult SyncRosterToOwnerGuild(Player* owner, std::vector<RaidRosterRow> const& rows)
{
    if (!owner || !owner->GetGuildId())
        return {};
    return SyncRosterToGuild(owner, sGuildMgr->GetGuildById(owner->GetGuildId()), rows);
}
}

namespace
{
void SyncExistingRoster(Player* player, Guild* explicitGuild = nullptr)
{
    if (!player || !IsRealPlayer(player))
        return;

    uint32 const ownerGuid = player->GetGUID().GetCounter();
    std::vector<RaidRosterRow> const rows = RaidRosterStore::Load(ownerGuid);
    if (rows.empty())
        return;

    RaidRosterGuild::SyncResult const result = explicitGuild
        ? RaidRosterGuild::SyncRosterToGuild(player, explicitGuild, rows)
        : RaidRosterGuild::SyncRosterToOwnerGuild(player, rows);

    if (result.ownerHasGuild && !result.Complete())
    {
        LOG_WARN(
            "server.loading",
            "[RaidRoster] Owner-guild migration incomplete for {}: guild={} managed={}/{} blocked-real={} failed={}",
            player->GetName(),
            result.guildId,
            result.Managed(),
            uint32(rows.size()),
            result.blockedRealGuild,
            result.failed);
    }
}

class RaidRosterGuildPlayerScript final : public PlayerScript
{
public:
    RaidRosterGuildPlayerScript()
        : PlayerScript("RaidRosterGuildPlayerScript", { PLAYERHOOK_ON_LOGIN }) { }

    void OnPlayerLogin(Player* player) override
    {
        // Migrates rosters created before real guild membership was enforced. It is idempotent,
        // and does nothing for bots or humans without a guild/roster.
        SyncExistingRoster(player);
    }
};

class RaidRosterGuildScript final : public GuildScript
{
public:
    RaidRosterGuildScript()
        : GuildScript("RaidRosterGuildScript", { GUILDHOOK_ON_ADD_MEMBER, GUILDHOOK_ON_CREATE }) { }

    void OnAddMember(Guild* guild, Player* player, uint8& /*rank*/) override
    {
        // Handles a human joining a guild after their persistent roster already existed. Passing
        // the concrete Guild* avoids depending on GuildMgr update ordering during the join hook.
        SyncExistingRoster(player, guild);
    }

    void OnCreate(Guild* guild, Player* leader, std::string const& /*name*/) override
    {
        // Handles creating the player's guild after their persistent roster already existed. The
        // guild object is valid here even before it has necessarily been inserted into GuildMgr.
        SyncExistingRoster(leader, guild);
    }
};
}

void AddRaidRosterGuildScripts()
{
    new RaidRosterGuildPlayerScript();
    new RaidRosterGuildScript();
}
