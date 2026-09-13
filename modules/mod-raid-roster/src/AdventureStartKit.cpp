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

bool IsWotlkRaidReady(AdventureStartProfile profile)
{
    return profile == AdventureStartProfile::WotlkRaidReady;
}

bool IsRaidReady(AdventureStartProfile profile)
{
    return IsTbcRaidReady(profile) || IsWotlkRaidReady(profile);
}

AdventureStartProfile StoredProfile(uint8 value)
{
    if (value == static_cast<uint8>(AdventureStartProfile::WotlkRaidReady))
        return AdventureStartProfile::WotlkRaidReady;
    if (value == static_cast<uint8>(AdventureStartProfile::TbcRaidReady))
        return AdventureStartProfile::TbcRaidReady;
    return AdventureStartProfile::TbcAdventure;
}

uint32 StartingGold(AdventureStartProfile profile)
{
    if (IsWotlkRaidReady(profile))
        return g_AdventureStartWotlkRaidReadyStartingGold;
    if (IsTbcRaidReady(profile))
        return g_AdventureStartTbcRaidReadyStartingGold;
    return g_AdventureStartStartingGold;
}

uint32 BasicItemLevel(AdventureStartProfile profile)
{
    if (IsWotlkRaidReady(profile))
        return g_AdventureStartWotlkRaidReadyBasicGearItemLevel;
    if (IsTbcRaidReady(profile))
        return g_AdventureStartTbcRaidReadyBasicGearItemLevel;
    return g_AdventureStartBasicGearItemLevel;
}

uint32 FinalItemLevel(AdventureStartProfile profile)
{
    if (IsWotlkRaidReady(profile))
        return g_AdventureStartWotlkRaidReadyGearItemLevel;
    if (IsTbcRaidReady(profile))
        return g_AdventureStartTbcRaidReadyGearItemLevel;
    return g_AdventureStartGearItemLevel;
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

    bool const raidReady = IsRaidReady(profile);
    bool const wotlkRaidReady = IsWotlkRaidReady(profile);
    uint32 const startingGold = StartingGold(profile);
    uint32 const basicIlvl = BasicItemLevel(profile);

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
    factory.InitReagents();
    factory.InitPotions();
    factory.InitFood();

    if (raidReady)
    {
        // Max riding plus a maintained mount bootstrap means the explicit raid-ready shortcuts are
        // actually ready to play rather than requiring a trainer/mount scavenger hunt first.
        if (player->GetSkillValue(SKILL_RIDING) < 300)
            player->SetSkill(SKILL_RIDING, 0, 300, 300);
        factory.InitMounts();

        // Glyphs are a Wrath system. Only the post-release WotLK shortcut receives them.
        if (wotlkRaidReady)
            factory.InitGlyphs(false);
    }
    else if (player->GetSkillValue(SKILL_RIDING) < 150)
    {
        // The level-60 adventure path starts with fast ground riding only. Flying remains part of
        // normal Outland progression.
        player->SetSkill(SKILL_RIDING, 0, 150, 150);
    }

    // Temporary gear prevents naked boosted characters while we wait for enough talent investment
    // to identify their intended role. Both raid-ready modes start in good blues before the final
    // spec-aware epic pass.
    if (g_AdventureStartBasicGear)
    {
        PlayerbotFactory::AutoGear(
            player,
            raidReady ? ITEM_QUALITY_RARE : ITEM_QUALITY_UNCOMMON,
            basicIlvl,
            false,
            false,
            raidReady);
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

    AdventureStartProfile const profile = StoredProfile(state.starterProfile);
    uint32 const targetIlvl = FinalItemLevel(profile);
    uint8 const specTab = AiFactory::GetPlayerSpecTab(player);

    // Adventure mode gets late-Vanilla raid epics. TBC raid-ready gets a pre-Kara ilvl-115 set.
    // WotLK raid-ready gets ilvl-200 epics, positioning Naxx as the first meaningful Wrath raid.
    PlayerbotFactory::AutoGear(
        player,
        ITEM_QUALITY_EPIC,
        targetIlvl,
        false,
        false,
        IsRaidReady(profile));

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
