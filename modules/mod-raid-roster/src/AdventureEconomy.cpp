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

#include <algorithm>
#include <mutex>

namespace
{
constexpr uint32 COPPER_PER_GOLD = 10000;
std::mutex g_bountyClaimMutex;

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

bool ClaimBossBounty(uint32 playerGuid, uint32 mapId, uint32 creatureEntry, uint32 rewardCopper)
{
    // A kill-reward hook can be reached through more than one map worker. Serialize the check and
    // claim in-process, and persist the claim synchronously before any money is created.
    std::lock_guard<std::mutex> lock(g_bountyClaimMutex);
    if (HasClaimedBossBounty(playerGuid, mapId, creatureEntry))
        return false;

    CharacterDatabase.DirectExecute(
        "INSERT IGNORE INTO mod_adventure_boss_bounty "
        "(player_guid, map_id, creature_entry, reward_copper) VALUES ({}, {}, {}, {})",
        playerGuid,
        mapId,
        creatureEntry,
        rewardCopper);

    return HasClaimedBossBounty(playerGuid, mapId, creatureEntry);
}

void ReleaseBossBounty(uint32 playerGuid, uint32 mapId, uint32 creatureEntry)
{
    std::lock_guard<std::mutex> lock(g_bountyClaimMutex);
    CharacterDatabase.DirectExecute(
        "DELETE FROM mod_adventure_boss_bounty "
        "WHERE player_guid = {} AND map_id = {} AND creature_entry = {}",
        playerGuid,
        mapId,
        creatureEntry);
}

uint32 ReserveDailyRepeatReward(uint32 playerGuid, uint32 requestedCopper, uint32 dailyCapCopper)
{
    if (!requestedCopper || !dailyCapCopper)
        return 0;

    std::lock_guard<std::mutex> lock(g_bountyClaimMutex);

    uint32 alreadyEarned = 0;
    if (QueryResult result = CharacterDatabase.Query(
        "SELECT earned_copper FROM mod_adventure_daily_activity "
        "WHERE player_guid = {} AND reward_date = CURDATE() LIMIT 1",
        playerGuid))
    {
        Field* fields = result->Fetch();
        alreadyEarned = fields[0].Get<uint32>();
    }

    if (alreadyEarned >= dailyCapCopper)
        return 0;

    uint32 const reserved = std::min(requestedCopper, dailyCapCopper - alreadyEarned);
    CharacterDatabase.DirectExecute(
        "INSERT INTO mod_adventure_daily_activity (player_guid, reward_date, earned_copper, boss_kills) "
        "VALUES ({}, CURDATE(), {}, 1) "
        "ON DUPLICATE KEY UPDATE earned_copper = earned_copper + {}, boss_kills = boss_kills + 1",
        playerGuid,
        reserved,
        reserved);
    return reserved;
}

void ReleaseDailyRepeatReward(uint32 playerGuid, uint32 rewardCopper)
{
    if (!rewardCopper)
        return;

    std::lock_guard<std::mutex> lock(g_bountyClaimMutex);
    CharacterDatabase.DirectExecute(
        "UPDATE mod_adventure_daily_activity "
        "SET earned_copper = GREATEST(earned_copper - {}, 0), "
        "boss_kills = IF(boss_kills > 0, boss_kills - 1, 0) "
        "WHERE player_guid = {} AND reward_date = CURDATE()",
        rewardCopper,
        playerGuid);
}

bool AwardMoney(Player* player, uint32 rewardCopper)
{
    return player && rewardCopper && player->ModifyMoney(static_cast<int32>(rewardCopper));
}
}

class AdventureEconomyPlayerScript : public PlayerScript
{
public:
    AdventureEconomyPlayerScript() : PlayerScript("AdventureEconomyPlayerScript") { }

    void OnPlayerRewardKillRewarder(
        Player* player,
        KillRewarder* rewarder,
        bool /*isDungeon*/,
        float& /*rate*/) override
    {
        if (!g_AdventureEconomyEnable || !player || IsPlayerbot(player) || !rewarder)
            return;

        Unit* victim = rewarder->GetVictim();
        Creature* boss = victim ? victim->ToCreature() : nullptr;
        if (!boss || !boss->IsDungeonBoss())
            return;

        Map* map = boss->GetMap();
        if (!map || !(map->IsDungeon() || map->IsRaid()))
            return;

        // KillRewarder passes isDungeon=false for an ungrouped killer. Use the actual map type so
        // a legitimate solo/cleanup boss kill cannot silently miss its activity reward.
        bool const isRaid = map->IsRaid();
        uint32 const playerGuid = player->GetGUID().GetCounter();
        uint32 const mapId = map->GetId();
        uint32 const creatureEntry = boss->GetEntry();

        uint32 const firstKillGold = isRaid
            ? g_AdventureEconomyRaidBossFirstKillGold
            : g_AdventureEconomyDungeonBossFirstKillGold;
        uint32 const firstKillCopper = firstKillGold * COPPER_PER_GOLD;

        // The persistent first-kill row is also the switch from milestone rewards to repeatable
        // activity income. Record it even when the administrator configured the first-kill payout
        // to zero, otherwise that boss could never enter the repeat-reward path.
        if (ClaimBossBounty(playerGuid, mapId, creatureEntry, firstKillCopper))
        {
            if (!firstKillCopper)
                return;

            if (!AwardMoney(player, firstKillCopper))
            {
                ReleaseBossBounty(playerGuid, mapId, creatureEntry);
                LOG_WARN(
                    "server.loading",
                    "[AdventureEconomy] Could not award {} copper to {} for boss {} on map {}; first-kill claim released",
                    firstKillCopper,
                    player->GetName(),
                    creatureEntry,
                    mapId);
                return;
            }

            if (WorldSession* session = player->GetSession())
            {
                ChatHandler(session).PSendSysMessage(
                    "Adventurer bounty: {} gold for your first defeat of {}.",
                    firstKillGold,
                    boss->GetName());
            }

            LOG_INFO(
                "server.loading",
                "[AdventureEconomy] {} earned {}g first-kill bounty for {} (entry {}, map {}, raid={})",
                player->GetName(),
                firstKillGold,
                boss->GetName(),
                creatureEntry,
                mapId,
                isRaid ? 1 : 0);
            return;
        }

        uint32 const repeatGold = isRaid
            ? g_AdventureEconomyRaidBossRepeatGold
            : g_AdventureEconomyDungeonBossRepeatGold;
        uint32 const requestedCopper = repeatGold * COPPER_PER_GOLD;
        uint32 const dailyCapCopper = g_AdventureEconomyDailyRepeatCapGold * COPPER_PER_GOLD;
        uint32 const rewardCopper = ReserveDailyRepeatReward(playerGuid, requestedCopper, dailyCapCopper);
        if (!rewardCopper)
            return;

        if (!AwardMoney(player, rewardCopper))
        {
            ReleaseDailyRepeatReward(playerGuid, rewardCopper);
            LOG_WARN(
                "server.loading",
                "[AdventureEconomy] Could not award {} repeat copper to {}; daily reservation released",
                rewardCopper,
                player->GetName());
            return;
        }

        if (WorldSession* session = player->GetSession())
        {
            ChatHandler(session).PSendSysMessage(
                "Adventurer activity: {}g {}s for defeating {}. Repeat rewards are capped at {}g per day.",
                rewardCopper / COPPER_PER_GOLD,
                (rewardCopper % COPPER_PER_GOLD) / 100,
                boss->GetName(),
                g_AdventureEconomyDailyRepeatCapGold);
        }

        LOG_INFO(
            "server.loading",
            "[AdventureEconomy] {} earned {} repeat copper for {} (entry {}, map {}, raid={})",
            player->GetName(),
            rewardCopper,
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
