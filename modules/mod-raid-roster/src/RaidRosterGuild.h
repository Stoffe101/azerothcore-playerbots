#ifndef MOD_RAID_ROSTER_GUILD_H
#define MOD_RAID_ROSTER_GUILD_H

#include "Define.h"
#include "RaidRosterStore.h"

#include <vector>

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

// Makes the owner's persistent roster a real part of the owner's in-game guild.
// Bots may be moved out of synthetic/random-bot guilds, but this function never steals a
// character from another real-player-led guild. Safe to call repeatedly.
SyncResult SyncRosterToOwnerGuild(Player* owner, std::vector<RaidRosterRow> const& rows);
}

// Registers migration/sync hooks for existing rosters when their human owner logs in, creates a
// guild, or joins one after the roster already existed.
void AddRaidRosterGuildScripts();

#endif
