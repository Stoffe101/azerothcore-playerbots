#include "ScriptMgr.h"

#include "AdventureCatalog.h"

#include "Creature.h"
#include "DatabaseEnv.h"
#include "Group.h"
#include "KillRewarder.h"
#include "Map.h"
#include "Player.h"
#include "Playerbots.h"

#include <algorithm>
#include <mutex>

namespace
{
std::mutex g_historyMutex;

std::string ActivityIdFor(uint32 mapId, uint32 creatureEntry)
{
    for (AdventureActivity const& activity : AdventureCatalog::All())
        if (activity.instanceMap == mapId && activity.finalBossEntry == creatureEntry && activity.composerId)
            return activity.composerId;
    return "";
}

bool EventAlreadyRecorded(uint32 playerGuid, uint32 mapId, uint32 instanceId, uint32 creatureEntry)
{
    return CharacterDatabase.Query(
        "SELECT 1 FROM mod_adventure_progression_event "
        "WHERE player_guid = {} AND map_id = {} AND instance_id = {} AND creature_entry = {} LIMIT 1",
        playerGuid, mapId, instanceId, creatureEntry) != nullptr;
}

void RecordBossKill(Player* player, Creature* boss)
{
    if (!player || !boss || !IsRealPlayer(player))
        return;

    Map* map = boss->GetMap();
    if (!map || !(map->IsDungeon() || map->IsRaid()) || !boss->IsDungeonBoss())
        return;

    uint32 const playerGuid = player->GetGUID().GetCounter();
    uint32 const guildId = player->GetGuildId();
    uint32 const mapId = map->GetId();
    uint32 const instanceId = map->GetInstanceId();
    uint32 const creatureEntry = boss->GetEntry();
    std::string const activityId = ActivityIdFor(mapId, creatureEntry);
    uint8 const difficulty = uint8(map->GetDifficulty());
    uint8 const groupSize = player->GetGroup()
        ? static_cast<uint8>(std::min<uint32>(255u, player->GetGroup()->GetMembersCount()))
        : 1u;

    std::lock_guard<std::mutex> lock(g_historyMutex);
    if (EventAlreadyRecorded(playerGuid, mapId, instanceId, creatureEntry))
        return;

    CharacterDatabase.DirectExecute(
        "INSERT IGNORE INTO mod_adventure_progression_event "
        "(player_guid, guild_id, map_id, instance_id, creature_entry, activity_id, difficulty, group_size) "
        "VALUES ({}, {}, {}, {}, {}, '{}', {}, {})",
        playerGuid, guildId, mapId, instanceId, creatureEntry, activityId, uint32(difficulty), uint32(groupSize));

    if (!EventAlreadyRecorded(playerGuid, mapId, instanceId, creatureEntry))
        return;

    CharacterDatabase.DirectExecute(
        "INSERT INTO mod_adventure_progression_history "
        "(player_guid, map_id, creature_entry, activity_id, difficulty, first_guild_id, last_guild_id, first_group_size, last_group_size, clear_count) "
        "VALUES ({}, {}, {}, '{}', {}, {}, {}, {}, {}, 1) "
        "ON DUPLICATE KEY UPDATE "
        "activity_id = IF(activity_id = '', VALUES(activity_id), activity_id), "
        "last_guild_id = VALUES(last_guild_id), "
        "last_group_size = VALUES(last_group_size), "
        "last_kill_at = CURRENT_TIMESTAMP, "
        "clear_count = clear_count + 1",
        playerGuid, mapId, creatureEntry, activityId, uint32(difficulty), guildId, guildId, uint32(groupSize), uint32(groupSize));
}
}

class AdventureProgressionHistoryPlayerScript : public PlayerScript
{
public:
    AdventureProgressionHistoryPlayerScript() : PlayerScript("AdventureProgressionHistoryPlayerScript") { }

    void OnPlayerRewardKillRewarder(
        Player* player,
        KillRewarder* rewarder,
        bool /*isDungeon*/,
        float& /*rate*/) override
    {
        if (!player || !rewarder)
            return;

        Unit* victim = rewarder->GetVictim();
        Creature* boss = victim ? victim->ToCreature() : nullptr;
        RecordBossKill(player, boss);
    }
};

void AddAdventureProgressionHistoryScripts()
{
    new AdventureProgressionHistoryPlayerScript();
}
