#include "AdminPanelGameplay.h"

#include "DatabaseEnv.h"
#include "EraTalentIP.h"
#include "EraTalents.h"
#include "EraTalentsComms.h"
#include "Group.h"
#include "Log.h"
#include "Pet.h"
#include "Player.h"
#include "PlayerbotAIConfig.h"
#include "PlayerbotFactory.h"
#include "QueryResult.h"
#include "RandomPlayerbotFactory.h"
#include "RandomPlayerbotMgr.h"
#include "WorldSession.h"
#include "WorldSessionMgr.h"

#include <algorithm>
#include <array>

namespace
{
constexpr uint32 COPPER_PER_GOLD = 10000u;
constexpr uint32 MAX_BOT_TARGET = 1000u;
constexpr uint32 DEFAULT_BOT_BATCH = 10u;
constexpr uint32 TBC_PRE_RAID_ILVL = 115u;

uint32 CountBotAccounts()
{
    QueryResult result = LoginDatabase.Query(
        "SELECT COUNT(*) FROM account WHERE username LIKE '{}%%'",
        sPlayerbotAIConfig.randomBotAccountPrefix.c_str());
    return result ? static_cast<uint32>(result->Fetch()[0].Get<uint64>()) : 0u;
}

uint32 CountAssignedBotAccounts()
{
    QueryResult result = PlayerbotsDatabase.Query(
        "SELECT COUNT(*) FROM playerbots_account_type WHERE account_type = 1");
    return result ? static_cast<uint32>(result->Fetch()[0].Get<uint64>()) : 0u;
}

uint32 RequiredBotAccounts()
{
    if (!sPlayerbotAIConfig.maxRandomBots)
        return 0u;
    return RandomPlayerbotFactory::CalculateTotalAccountCount();
}

void RestoreUnit(Unit* unit)
{
    if (!unit)
        return;

    unit->SetFullHealth();
    Powers const primary = unit->getPowerType();
    unit->SetPower(primary, unit->GetMaxPower(primary));
    if (primary != POWER_MANA && unit->GetMaxPower(POWER_MANA) > 0)
        unit->SetPower(POWER_MANA, unit->GetMaxPower(POWER_MANA));
}

void PrepareOne(Player* player)
{
    if (!player)
        return;

    if (!player->IsAlive())
    {
        player->ResurrectPlayer(1.0f);
        player->SpawnCorpseBones();
    }

    player->DurabilityRepairAll(false, 0.0f, false);
    RestoreUnit(player);
    RestoreUnit(player->GetPet());

    PlayerbotFactory factory(player, player->GetLevel());
    factory.InitBags(false);
    factory.InitAmmo();
    factory.InitPotions();
    factory.InitFood();
    factory.InitReagents();
    player->SaveToDB(false, false);
}
}

namespace AdminPanelGameplay
{
PopulationStats GetPopulationStats()
{
    PopulationStats stats;
    stats.sessions = sWorldSessionMgr->GetActiveSessionCount();

    // Random Playerbots own their bot WorldSessions outside the ordinary real-player
    // WorldSessionMgr accounting path. Count the manager's actual live bot collection
    // so AdminPanel/watchdog does not report a healthy population as 0/N.
    stats.bots = sRandomPlayerbotMgr.GetPlayerbotsCount();

    for (auto const& entry : sWorldSessionMgr->GetAllSessions())
    {
        WorldSession* session = entry.second;
        if (!session)
            continue;
        Player* player = session->GetPlayer();
        if (!player || !player->IsInWorld())
            continue;

        if (!session->IsBot())
            ++stats.realPlayers;
    }

    stats.botTarget = sPlayerbotAIConfig.maxRandomBots;
    stats.botBatch = sPlayerbotAIConfig.randomBotsPerInterval;
    stats.botActivity = sRandomPlayerbotMgr.getActivityPercentage();
    stats.botEngineEnabled = sPlayerbotAIConfig.enabled;
    stats.botAutologinEnabled = sPlayerbotAIConfig.randomBotAutologin;
    stats.botAccounts = CountBotAccounts();
    stats.assignedBotAccounts = CountAssignedBotAccounts();
    stats.requiredBotAccounts = stats.botTarget ? RequiredBotAccounts() : 0u;
    stats.managerCandidates = sRandomPlayerbotMgr.GetRandomBotCandidateCount();
    stats.managerRandomAccounts = sRandomPlayerbotMgr.GetRandomBotAccountPoolCount();
    stats.pendingBotLogins = sRandomPlayerbotMgr.GetPendingBotLoginCount();
    return stats;
}

void RepairBotPopulation()
{
    if (!sPlayerbotAIConfig.maxRandomBots)
        return;

    uint32 const beforeAccounts = CountBotAccounts();
    uint32 const beforeAssigned = CountAssignedBotAccounts();
    uint32 const required = RequiredBotAccounts();

    // MaxRandomBots is consumed by RandomPlayerbotFactory during PlayerbotAIConfig startup. The
    // Admin Panel can raise that value later at runtime. Extend only missing account/character
    // capacity, then let the Playerbots-side recovery API rebuild stale ephemeral add-event state.
    if (beforeAccounts < required || beforeAssigned == 0)
    {
        LOG_WARN(
            "server.loading",
            "[AdminPanel] RNDbot pool insufficient: accounts={} assigned={} required={}; extending pool now",
            beforeAccounts,
            beforeAssigned,
            required);
        RandomPlayerbotFactory::CreateRandomBots();
    }

    sRandomPlayerbotMgr.RepairRandomBotPopulationState();

    LOG_INFO(
        "server.loading",
        "[AdminPanel] RNDbot repair complete: accounts {}->{} assigned {}->{} required={} target={} batch={} candidates={} pending={} managerAccounts={}",
        beforeAccounts,
        CountBotAccounts(),
        beforeAssigned,
        CountAssignedBotAccounts(),
        required,
        sPlayerbotAIConfig.maxRandomBots,
        sPlayerbotAIConfig.randomBotsPerInterval,
        sRandomPlayerbotMgr.GetRandomBotCandidateCount(),
        sRandomPlayerbotMgr.GetPendingBotLoginCount(),
        sRandomPlayerbotMgr.GetRandomBotAccountPoolCount());
}

void SetBotTarget(uint32 target, uint32 batch)
{
    target = std::min(target, MAX_BOT_TARGET);
    batch = std::max<uint32>(1, std::min<uint32>(batch ? batch : DEFAULT_BOT_BATCH, 50));

    // RandomPlayerbotMgr exits early unless both switches are on. AdminPanel is intentionally
    // authoritative for runtime population, even if an older persistent playerbots.conf says off.
    sPlayerbotAIConfig.enabled = true;
    sPlayerbotAIConfig.randomBotAutologin = true;
    sPlayerbotAIConfig.minRandomBots = target;
    sPlayerbotAIConfig.maxRandomBots = target;
    sPlayerbotAIConfig.randomBotsPerInterval = batch;

    if (target > 0)
        RepairBotPopulation();

    LOG_INFO(
        "server.loading",
        "[AdminPanel] Random-bot target={} batch={} enabled={} autologin={} accounts={} assigned={} candidates={} pending={}",
        target,
        batch,
        sPlayerbotAIConfig.enabled ? 1 : 0,
        sPlayerbotAIConfig.randomBotAutologin ? 1 : 0,
        CountBotAccounts(),
        CountAssignedBotAccounts(),
        sRandomPlayerbotMgr.GetRandomBotCandidateCount(),
        sRandomPlayerbotMgr.GetPendingBotLoginCount());
}

void SetBotActivity(float percent)
{
    percent = std::max(0.0f, std::min(100.0f, percent));
    sRandomPlayerbotMgr.setActivityPercentage(percent);
}

bool GiveGold(Player* player, uint32 gold)
{
    if (!player || !gold)
        return false;

    uint64 const addCopper = uint64(gold) * COPPER_PER_GOLD;
    uint64 const newMoney = std::min<uint64>(uint64(MAX_MONEY_AMOUNT), uint64(player->GetMoney()) + addCopper);
    player->SetMoney(static_cast<uint32>(newMoney));
    player->SaveToDB(false, false);
    return true;
}

void Repair(Player* player)
{
    if (!player)
        return;
    player->DurabilityRepairAll(false, 0.0f, false);
}

void Restore(Player* player)
{
    if (!player)
        return;
    if (!player->IsAlive())
    {
        player->ResurrectPlayer(1.0f);
        player->SpawnCorpseBones();
    }
    RestoreUnit(player);
    RestoreUnit(player->GetPet());
}

void MaxSkills(Player* player)
{
    if (!player)
        return;
    player->UpdateSkillsToMaxSkillsForLevel();
    player->SaveToDB(false, false);
}

uint32 MaxProfessions(Player* player)
{
    if (!player)
        return 0;

    static constexpr std::array<uint16, 14> professionSkills = {
        SKILL_ALCHEMY,
        SKILL_BLACKSMITHING,
        SKILL_ENCHANTING,
        SKILL_ENGINEERING,
        SKILL_HERBALISM,
        SKILL_JEWELCRAFTING,
        SKILL_LEATHERWORKING,
        SKILL_MINING,
        SKILL_SKINNING,
        SKILL_TAILORING,
        SKILL_INSCRIPTION,
        SKILL_COOKING,
        SKILL_FIRST_AID,
        SKILL_FISHING,
    };

    uint32 changed = 0;
    for (uint16 skill : professionSkills)
    {
        if (!player->HasSkill(skill))
            continue;

        constexpr uint16 WOTLK_PROFESSION_CAP = 450;
        if (player->GetPureSkillValue(skill) != WOTLK_PROFESSION_CAP ||
            player->GetPureMaxSkillValue(skill) != WOTLK_PROFESSION_CAP ||
            player->GetSkillStep(skill) != 6)
        {
            player->SetSkill(skill, 6, WOTLK_PROFESSION_CAP, WOTLK_PROFESSION_CAP);
            ++changed;
        }
    }

    player->SaveToDB(false, false);
    return changed;
}

void RefreshConsumables(Player* player)
{
    if (!player)
        return;
    PlayerbotFactory factory(player, player->GetLevel());
    factory.InitBags(false);
    factory.InitAmmo();
    factory.InitPotions();
    factory.InitFood();
    factory.InitReagents();
    player->SaveToDB(false, false);
}

void ResetEraTalents(Player* player)
{
    if (!player)
        return;
    EraId const era = EraFromIP(player);
    if (!EraHasTalentTrees(era))
    {
        player->resetTalents(true);
        player->SendTalentsInfoData(false);
        return;
    }

    EraTalents::Reset(player, era);
    EraTalentsComms::SendSync(player);
    player->SaveToDB(false, false);
}

void RegearTbcPreRaid(Player* player)
{
    if (!player)
        return;

    PlayerbotFactory factory(player, player->GetLevel());
    factory.InitBags(false);
    PlayerbotFactory::AutoGear(
        player,
        ITEM_QUALITY_EPIC,
        TBC_PRE_RAID_ILVL,
        false,
        true,
        true);
    player->SaveToDB(false, false);
}

uint32 PrepareGroup(Player* leader)
{
    if (!leader)
        return 0;

    Group* group = leader->GetGroup();
    if (!group)
    {
        PrepareOne(leader);
        return 1;
    }

    uint32 prepared = 0;
    for (GroupReference* ref = group->GetFirstMember(); ref; ref = ref->next())
    {
        Player* member = ref->GetSource();
        if (!member || !member->IsInWorld())
            continue;
        PrepareOne(member);
        ++prepared;
    }
    return prepared;
}

uint32 SummonGroup(Player* leader)
{
    if (!leader)
        return 0;

    Group* group = leader->GetGroup();
    if (!group)
        return 0;

    uint32 summoned = 0;
    for (GroupReference* ref = group->GetFirstMember(); ref; ref = ref->next())
    {
        Player* member = ref->GetSource();
        if (!member || !member->IsInWorld() || member == leader)
            continue;
        if (member->TeleportTo(
                leader->GetMapId(),
                leader->GetPositionX(),
                leader->GetPositionY(),
                leader->GetPositionZ(),
                leader->GetOrientation()))
            ++summoned;
    }
    return summoned;
}

uint32 RaidNight(Player* leader)
{
    uint32 const prepared = PrepareGroup(leader);
    SetBotActivity(100.0f);
    return prepared;
}
}
