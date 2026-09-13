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
}

namespace AdventureStartKit
{
bool GrantInitial(Player* player)
{
    if (!g_AdventureStartStarterKit || !player)
        return false;

    uint32 const guid = player->GetGUID().GetCounter();
    AdventureProgressionStore::State state = AdventureProgressionStore::LoadOrCreate(guid);
    if (state.starterInitialized)
        return true;

    // Keep PlayerbotFactory isolated in this translation unit. AdventureStart.cpp includes
    // IndividualProgression.h, while PlayerbotFactory -> PlayerbotAI.h defines a conflicting
    // unscoped GENERAL enumerator. Splitting the helpers avoids reintroducing that build failure.
    PlayerbotFactory factory(player, player->GetLevel());

    // Reuse the maintained Playerbots class bootstrap instead of hard-coding nine classes worth
    // of weapon/class skills, spell ranks, ammo, consumables and bag setup. Professions are not
    // initialized here.
    player->LearnDefaultSkills();
    factory.InitSkills();
    factory.InitClassSpells();
    factory.InitAvailableSpells();
    factory.InitBags(false);
    factory.InitAmmo();
    factory.InitPotions();
    factory.InitFood();

    // Fast ground riding only. Deliberately do NOT call InitMounts(): its level-60 thresholds can
    // grant flying, which should still be earned normally in Outland.
    if (player->GetSkillValue(SKILL_RIDING) < 150)
        player->SetSkill(SKILL_RIDING, 0, 150, 150);

    // A fresh level-60 character should not arrive at the Dark Portal naked. This first set is
    // intentionally only green/late-Vanilla quality; once the player commits to a talent tree we
    // replace it with the spec-aware rare set below. applyFinishers=false avoids bot-only enchants.
    if (g_AdventureStartBasicGear)
    {
        PlayerbotFactory::AutoGear(
            player,
            ITEM_QUALITY_UNCOMMON,
            g_AdventureStartBasicGearItemLevel,
            false,
            false,
            false);
    }

    uint32 const targetCopper = g_AdventureStartStartingGold * COPPER_PER_GOLD;
    uint32 const currentCopper = player->GetMoney();
    if (currentCopper < targetCopper)
        player->ModifyMoney(static_cast<int32>(targetCopper - currentCopper));

    AdventureProgressionStore::MarkStarterInitialized(guid);
    player->SaveToDB(false, false);

    LOG_INFO(
        "server.loading",
        "[AdventureStart] Starter kit granted to {} (gold={}g, basicGear={}, basicIlvl={})",
        player->GetName(),
        g_AdventureStartStartingGold,
        g_AdventureStartBasicGear ? 1 : 0,
        g_AdventureStartBasicGearItemLevel);
    return true;
}

bool TryGiveSpecStarterGear(Player* player)
{
    if (!player)
        return true;

    uint32 const guid = player->GetGUID().GetCounter();
    AdventureProgressionStore::State state = AdventureProgressionStore::LoadOrCreate(guid);

    if (!g_AdventureStartAutoGear || state.starterGearGranted)
        return true;
    if (!state.starterInitialized)
        return false;

    uint32 const spent = SpentTalentPoints(player);
    if (spent < g_AdventureStartGearMinTalentPoints)
        return false;

    uint8 const specTab = AiFactory::GetPlayerSpecTab(player);

    PlayerbotFactory::AutoGear(
        player,
        ITEM_QUALITY_RARE,
        g_AdventureStartGearItemLevel,
        false,
        false,
        false);

    AdventureProgressionStore::MarkStarterGearGranted(guid, specTab);
    player->SaveToDB(false, false);

    LOG_INFO(
        "server.loading",
        "[AdventureStart] Spec-aware starter gear granted to {} (specTab={}, spentTalents={}, targetIlvl={})",
        player->GetName(),
        specTab,
        spent,
        g_AdventureStartGearItemLevel);
    return true;
}
}
