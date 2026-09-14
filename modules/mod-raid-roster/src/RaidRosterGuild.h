#ifndef MOD_RAID_ROSTER_GUILD_H
#define MOD_RAID_ROSTER_GUILD_H

#include "Define.h"
#include "RaidRosterStore.h"

#include <vector>

class Guild;
class Player;

namespace RaidRosterGuild
{
struct SyncResult
{
    bool ownerHasGuild = false;
    uint32 guildId = 0;
    uint32 alreadyMember = 0;
    uint32 joined = 0;
    uint32 movedFromBotGuild = 0;
    uint32 blockedRealGuild = 0;
    uint32 failed = 0;

    bool Complete() const { return ownerHasGuild && blockedRealGuild == 0 && failed == 0; }
    uint32 Managed() const { return alreadyMember + joined + movedFromBotGuild; }
};

// Makes the owner's persistent roster a real part of a concrete in-game guild. Bots may be moved
// out of synthetic/random-bot guilds, but this never steals a character from another real-player-
// led guild. Supplying Guild* directly also works safely while a newly-created guild has not yet
// been inserted into GuildMgr.
SyncResult SyncRosterToGuild(Player* owner, Guild* targetGuild, std::vector<RaidRosterRow> const& rows);

// Convenience wrapper that resolves the owner's current guild from GuildMgr.
SyncResult SyncRosterToOwnerGuild(Player* owner, std::vector<RaidRosterRow> const& rows);
}

// Registers migration/sync hooks for existing rosters when their human owner logs in, creates a
// guild, or joins one after the roster already existed.
void AddRaidRosterGuildScripts();

#endif
