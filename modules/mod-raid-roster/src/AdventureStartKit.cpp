#include "AdventureStartKit.h"
#include "AdventureProgressionStore.h"
#include "RaidRosterConfig.h"

#include "AiFactory.h"
#include "Log.h"
#include "Player.h"
#include "PlayerbotFactory.h"

#include <map>

namespace
{
constexpr uint32 COPPER_PER_GOLD = 10000u;

uint32 SpentTalentPoints(Player* player)
{
    uint32 total = 0;
    std::map<uint8, uint32> tabs = AiFactory::GetPlayerSpecTabs(player);
    for (auto const& entry : tabs)
        total += entry.second;
    return total;
}

bool IsTbcRaidReady(AdventureStartProfile profile)
{
    return profile == AdventureStartProfile::TbcRaidReady;
}
}

namespace AdventureStartKit
{
bool GrantInitial(Player* player, AdventureStartProfile profile)
{
    if (!player)
        return false;

    uint32 const guid = player->GetGUID().GetCounter();
    AdventureProgressionStore::State state = AdventureProgressionStore::LoadOrCreate(guid);
    if (state.starterInitialized)
        return true;

    if (!g_AdventureStartStarterKit)
    {
        AdventureProgressionStore::MarkStarterInitialized(guid, static_cast<uint8>(profile));
        return true;
    }

    bool const raidReady = IsTbcRaidReady(profile);
    uint32 const startingGold = raidReady ? g_AdventureStartTbcRaidReadyStartingGold : g_AdventureStartStartingGold;
    uint32 const basicIlvl = raidReady ? g_AdventureStartTbcRaidReadyBasicGearItemLevel : g_AdventureStartBasicGearItemLevel;

    // Keep PlayerbotFactory isolated in this translation unit. AdventureStartControl.cpp includes
    // IndividualProgression.h, while PlayerbotFactory -> PlayerbotAI.h defines a conflicting
    // unscoped GENERAL enumerator. Splitting the helpers avoids that compile-time collision.
    PlayerbotFactory factory(player, player->GetLevel());

    player->LearnDefaultSkills();
    factory.InitSkills();
    factory.InitClassSpells();
    factory.InitAvailableSpells();
    factory.InitBags(false);
    factory.InitAmmo();
    factory.InitPotions();
    factory.InitFood();

    if (raidReady)
    {
        // A deliberate max-level TBC shortcut should actually feel ready to play. Give max TBC-era
        // riding and let the maintained Playerbots mount bootstrap choose usable ground/flying mounts.
        if (player->GetSkillValue(SKILL_RIDING) < 300)
            player->SetSkill(SKILL_RIDING, 0, 300, 300);
        factory.InitMounts();
    }
    else if (player->GetSkillValue(SKILL_RIDING) < 150)
    {
        // The level-60 adventure path starts with fast ground riding only. Flying remains part of
        // normal Outland progression.
        player->SetSkill(SKILL_RIDING, 0, 150, 150);
    }

    // Temporary gear prevents naked boosted characters while we wait for enough talent investment
    // to identify their intended role. The adventure path starts in replaceable greens; the level-70
    // shortcut starts in heroic-quality blues and then receives the spec-aware pre-raid epic pass.
    if (g_AdventureStartBasicGear)
    {
        PlayerbotFactory::AutoGear(
            player,
            raidReady ? ITEM_QUALITY_RARE : ITEM_QUALITY_UNCOMMON,
            basicIlvl,
            false,
            false,
            false);
    }

    uint32 const targetCopper = startingGold * COPPER_PER_GOLD;
    uint32 const currentCopper = player->GetMoney();
    if (currentCopper < targetCopper)
        player->ModifyMoney(static_cast<int32>(targetCopper - currentCopper));

    AdventureProgressionStore::MarkStarterInitialized(guid, static_cast<uint8>(profile));
    player->SaveToDB(false, false);

    LOG_INFO(
        "server.loading",
        "[AdventureStart] Starter kit granted to {} (profile={}, gold={}g, basicGear={}, basicIlvl={})",
        player->GetName(),
        AdventureStartControl::ProfileName(profile),
        startingGold,
        g_AdventureStartBasicGear ? 1 : 0,
        basicIlvl);
    return true;
}

bool TryGiveSpecStarterGear(Player* player)
{
    if (!player || !g_AdventureStartStarterKit || !g_AdventureStartAutoGear)
        return true;

    uint32 const guid = player->GetGUID().GetCounter();
    AdventureProgressionStore::State state = AdventureProgressionStore::LoadOrCreate(guid);

    if (state.starterGearGranted)
        return true;
    if (!state.starterInitialized)
        return false;

    uint32 const spent = SpentTalentPoints(player);
    if (spent < g_AdventureStartGearMinTalentPoints)
        return false;

    AdventureStartProfile const profile = state.starterProfile == static_cast<uint8>(AdventureStartProfile::TbcRaidReady)
        ? AdventureStartProfile::TbcRaidReady
        : AdventureStartProfile::TbcAdventure;
    uint32 const targetIlvl = IsTbcRaidReady(profile)
        ? g_AdventureStartTbcRaidReadyGearItemLevel
        : g_AdventureStartGearItemLevel;
    uint8 const specTab = AiFactory::GetPlayerSpecTab(player);

    // Adventure mode gets late-Vanilla raid epics (AQ40/Naxx40 power band). TBC raid-ready gets a
    // spec-scored ilvl-115 pre-raid set suitable for starting Kara/Gruul/Mag without skipping the
    // TBC raid ladder itself.
    PlayerbotFactory::AutoGear(
        player,
        ITEM_QUALITY_EPIC,
        targetIlvl,
        false,
        false,
        IsTbcRaidReady(profile));

    AdventureProgressionStore::MarkStarterGearGranted(guid, specTab);
    player->SaveToDB(false, false);

    LOG_INFO(
        "server.loading",
        "[AdventureStart] Spec-aware epic starter gear granted to {} (profile={}, specTab={}, spentTalents={}, targetIlvl={})",
        player->GetName(),
        AdventureStartControl::ProfileName(profile),
        specTab,
        spent,
        targetIlvl);
    return true;
}
}
