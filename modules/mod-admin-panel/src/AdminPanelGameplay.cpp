#include "AdminPanelGameplay.h"

#include "EraTalentIP.h"
#include "EraTalents.h"
#include "EraTalentsComms.h"
#include "Group.h"
#include "Log.h"
#include "Pet.h"
#include "Player.h"
#include "PlayerbotAIConfig.h"
#include "PlayerbotFactory.h"
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

    for (auto const& entry : sWorldSessionMgr->GetAllSessions())
    {
        WorldSession* session = entry.second;
        if (!session)
            continue;
        Player* player = session->GetPlayer();
        if (!player || !player->IsInWorld())
            continue;

        if (session->IsBot())
            ++stats.bots;
        else
            ++stats.realPlayers;
    }

    stats.botTarget = sPlayerbotAIConfig.maxRandomBots;
    stats.botBatch = sPlayerbotAIConfig.randomBotsPerInterval;
    stats.botActivity = sRandomPlayerbotMgr.getActivityPercentage();
    return stats;
}

void SetBotTarget(uint32 target, uint32 batch)
{
    target = std::min(target, MAX_BOT_TARGET);
    batch = std::max<uint32>(1, std::min<uint32>(batch ? batch : DEFAULT_BOT_BATCH, 50));

    // Runtime population control has to enable BOTH switches. Setting only randomBotAutologin is
    // not enough because RandomPlayerbotMgr::UpdateAIInternal also exits when enabled == false.
    sPlayerbotAIConfig.enabled = true;
    sPlayerbotAIConfig.randomBotAutologin = true;
    sPlayerbotAIConfig.minRandomBots = target;
    sPlayerbotAIConfig.maxRandomBots = target;
    sPlayerbotAIConfig.randomBotsPerInterval = batch;

    if (target > 0)
    {
        // Account-type assignment is calculated from MaxRandomBots. A realm that booted with a
        // zero target may therefore have every RNDbot account marked unassigned; merely changing
        // maxRandomBots at runtime leaves the manager with an empty account pool. Rebuild that pool
        // now, then run one throttled manager tick so the GUI button has an immediate visible effect.
        sRandomPlayerbotMgr.AssignAccountTypes();
        sRandomPlayerbotMgr.UpdateAIInternal(0, false);
    }

    LOG_INFO(
        "server.loading",
        "[AdminPanel] Random-bot target={} batch={} enabled={} autologin={} assigned-refresh={}",
        target,
        batch,
        sPlayerbotAIConfig.enabled ? 1 : 0,
        sPlayerbotAIConfig.randomBotAutologin ? 1 : 0,
        target > 0 ? 1 : 0);
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

    // Only touch professions/secondary skills the character already knows. This preserves the
    // normal two-primary-profession choice while making the admin shortcut genuinely useful.
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

        // WotLK Grand Master cap. Setting step 6 keeps the profession rank coherent even if the
        // character learned the profession before being boosted. We intentionally do NOT teach
        // every recipe; this is a skill/rank max button, not an unlock-every-recipe cheat.
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

    // Make room first, then directly replace the old set. secondChance=true avoids the factory
    // needing to autostore every equipped item into the backpack before it can equip the new set.
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
    // Raise activity while raiding without changing the configured population target.
    SetBotActivity(100.0f);
    return prepared;
}
}
