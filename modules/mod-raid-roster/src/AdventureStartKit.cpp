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

bool IsRaidReady(AdventureStartProfile profile)
{
    return profile == AdventureStartProfile::RaidReady;
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

    // A disabled starter kit is still considered initialized. Otherwise every login would keep
    // entering the recovery path forever when an administrator intentionally turns the kit off.
    if (!g_AdventureStartStarterKit)
    {
        AdventureProgressionStore::MarkStarterInitialized(guid, static_cast<uint8>(profile));
        return true;
    }

    bool const raidReady = IsRaidReady(profile);
    uint32 const startingGold = raidReady ? g_AdventureStartRaidReadyStartingGold : g_AdventureStartStartingGold;
    uint32 const basicIlvl = raidReady ? g_AdventureStartRaidReadyBasicGearItemLevel : g_AdventureStartBasicGearItemLevel;

    // Keep PlayerbotFactory isolated in this translation unit. AdventureStartControl.cpp includes
    // IndividualProgression.h, while PlayerbotFactory -> PlayerbotAI.h defines a conflicting
    // unscoped GENERAL enumerator. Splitting the helpers avoids that compile-time collision.
    PlayerbotFactory factory(player, player->GetLevel());

    // Reuse the maintained Playerbots class bootstrap instead of hard-coding every class's weapon
    // skills and spell ranks. Professions remain a normal gameplay choice.
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
        // The explicit max-level shortcut is intentionally convenience-heavy: max riding plus the
        // Playerbots mount bootstrap gives the character a usable ground/flying mount immediately.
        if (player->GetSkillValue(SKILL_RIDING) < 300)
            player->SetSkill(SKILL_RIDING, 0, 300, 300);
        factory.InitMounts();
    }
    else
    {
        // TBC adventure start gets fast ground riding only. Flying remains something to earn in
        // Outland, preserving that part of the expansion progression.
        if (player->GetSkillValue(SKILL_RIDING) < 150)
            player->SetSkill(SKILL_RIDING, 0, 150, 150);
    }

    // Temporary gear prevents a naked boosted character while we wait for enough talent points to
    // identify the intended role/spec. TBC gets greens; raid-ready gets heroic-ish blues.
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

    AdventureStartProfile const profile = state.starterProfile == static_cast<uint8>(AdventureStartProfile::RaidReady)
        ? AdventureStartProfile::RaidReady
        : AdventureStartProfile::TbcAdventure;
    uint32 const targetIlvl = IsRaidReady(profile)
        ? g_AdventureStartRaidReadyGearItemLevel
        : g_AdventureStartGearItemLevel;
    uint8 const specTab = AiFactory::GetPlayerSpecTab(player);

    // Both modes end on epics, but at different power bands: late-Vanilla raid gear for the TBC
    // adventure and Naxx-ready ilvl-200 gear for the explicit max-level shortcut.
    PlayerbotFactory::AutoGear(
        player,
        ITEM_QUALITY_EPIC,
        targetIlvl,
        false,
        false,
        false);

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
