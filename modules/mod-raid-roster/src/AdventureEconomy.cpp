#include "ScriptMgr.h"
#include "RaidRosterConfig.h"

#include "Chat.h"
#include "Creature.h"
#include "DatabaseEnv.h"
#include "KillRewarder.h"
#include "Log.h"
#include "Map.h"
#include "Player.h"
#include "Playerbots.h"
#include "RandomPlayerbotMgr.h"
#include "WorldSession.h"

namespace
{
constexpr uint32 COPPER_PER_GOLD = 10000;

bool IsPlayerbot(Player* player)
{
    if (!player)
        return true;

    return sRandomPlayerbotMgr.IsRandomBot(player)
        || sRandomPlayerbotMgr.IsAddclassBot(player)
        || sPlayerbotsMgr.GetPlayerbotAI(player) != nullptr;
}

bool HasClaimedBossBounty(uint32 playerGuid, uint32 mapId, uint32 creatureEntry)
{
    QueryResult result = CharacterDatabase.Query(
        "SELECT 1 FROM mod_adventure_boss_bounty "
        "WHERE player_guid = {} AND map_id = {} AND creature_entry = {} LIMIT 1",
        playerGuid,
        mapId,
        creatureEntry);

    return result != nullptr;
}

void RecordBossBounty(uint32 playerGuid, uint32 mapId, uint32 creatureEntry, uint32 rewardCopper)
{
    CharacterDatabase.Execute(
        "INSERT IGNORE INTO mod_adventure_boss_bounty "
        "(player_guid, map_id, creature_entry, reward_copper) VALUES ({}, {}, {}, {})",
        playerGuid,
        mapId,
        creatureEntry,
        rewardCopper);
}
}

class AdventureEconomyPlayerScript : public PlayerScript
{
public:
    AdventureEconomyPlayerScript() : PlayerScript("AdventureEconomyPlayerScript") { }

    void OnPlayerRewardKillRewarder(
        Player* player,
        KillRewarder* rewarder,
        bool isDungeon,
        float& /*rate*/) override
    {
        if (!g_AdventureEconomyEnable || !player || IsPlayerbot(player) || !rewarder || !isDungeon)
            return;

        Unit* victim = rewarder->GetVictim();
        Creature* boss = victim ? victim->ToCreature() : nullptr;
        if (!boss || !boss->IsDungeonBoss())
            return;

        Map* map = boss->GetMap();
        if (!map)
            return;

        bool const isRaid = map->IsRaid();
        uint32 rewardGold = isRaid
            ? g_AdventureEconomyRaidBossFirstKillGold
            : g_AdventureEconomyDungeonBossFirstKillGold;

        if (!rewardGold)
            return;

        uint32 const playerGuid = player->GetGUID().GetCounter();
        uint32 const mapId = map->GetId();
        uint32 const creatureEntry = boss->GetEntry();

        // One reward per character, map and boss entry. This makes adventuring profitable
        // without turning the easiest repeatable boss into an infinite gold printer.
        if (HasClaimedBossBounty(playerGuid, mapId, creatureEntry))
            return;

        uint32 const rewardCopper = rewardGold * COPPER_PER_GOLD;
        if (!player->ModifyMoney(static_cast<int32>(rewardCopper)))
        {
            LOG_WARN(
                "server.loading",
                "[AdventureEconomy] Could not award {} copper to {} for boss {} on map {}",
                rewardCopper,
                player->GetName(),
                creatureEntry,
                mapId);
            return;
        }

        RecordBossBounty(playerGuid, mapId, creatureEntry, rewardCopper);

        if (WorldSession* session = player->GetSession())
        {
            ChatHandler(session).PSendSysMessage(
                "Adventurer bounty: {} gold for your first defeat of {}.",
                rewardGold,
                boss->GetName());
        }

        LOG_INFO(
            "server.loading",
            "[AdventureEconomy] {} earned {}g first-kill bounty for {} (entry {}, map {}, raid={})",
            player->GetName(),
            rewardGold,
            boss->GetName(),
            creatureEntry,
            mapId,
            isRaid ? 1 : 0);
    }
};

void AddAdventureEconomyScripts()
{
    new AdventureEconomyPlayerScript();
}
