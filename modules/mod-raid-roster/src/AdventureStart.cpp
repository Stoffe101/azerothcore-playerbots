#include "ScriptMgr.h"
#include "Player.h"
#include "Log.h"
#include "IndividualProgression.h"
#include "Playerbots.h"
#include "RandomPlayerbotMgr.h"
#include "PlayerbotFactory.h"
#include "AiFactory.h"
#include "RaidRosterConfig.h"
#include "AdventureProgressionStore.h"

#include <array>
#include <map>

namespace
{
bool IsPlayerbot(Player* player)
{
    if (!player)
        return true;

    return sRandomPlayerbotMgr.IsRandomBot(player)
        || sRandomPlayerbotMgr.IsAddclassBot(player)
        || sPlayerbotsMgr.GetPlayerbotAI(player) != nullptr;
}

void RevealAllMap(Player* player)
{
    for (uint8 i = 0; i < PLAYER_EXPLORED_ZONES_SIZE; ++i)
        player->SetFlag(PLAYER_EXPLORED_ZONES_1 + i, 0xFFFFFFFF);
}

uint8 ApplyAdventureProgression(Player* player)
{
    if (!player || !player->IsInWorld())
        return 0;

    uint8 current = sIndividualProgression->GetPlayerProgressionFromQuests(player);
    if (!g_AdventureStartProgression || !sIndividualProgression->enabled)
        return current;

    if (current < g_AdventureStartProgression)
    {
        sIndividualProgression->UpdateProgressionState(
            player,
            static_cast<ProgressionState>(g_AdventureStartProgression));
        current = sIndividualProgression->GetPlayerProgressionFromQuests(player);
    }

    // IP's OnPlayerLogin has already run before AzerothCore fires OnPlayerFirstLogin. Re-derive
    // the current-era adjustments and phasing after changing the hidden progression quests.
    sIndividualProgression->CheckAdjustments(player);
    sIndividualProgression->checkIPPhasing(player, player->GetAreaId());
    return current;
}

uint32 GetSpentTalentPoints(Player* player)
{
    uint32 total = 0;
    std::map<uint8, uint32> tabs = AiFactory::GetPlayerSpecTabs(player);
    for (auto const& entry : tabs)
        total += entry.second;
    return total;
}

void GiveStarterKit(Player* player)
{
    // Reuse Playerbots' maintained class/spell/inventory helpers rather than maintaining a
    // second hand-written list of every class spell and level-appropriate consumable.
    PlayerbotFactory factory(player, player->GetLevel());

    player->LearnDefaultSkills();
    factory.InitSkills();
    factory.InitClassSpells();
    factory.InitAvailableSpells();
    factory.InitBags(false);

    // Do NOT call PlayerbotFactory::InitMounts() for a real level-60 player. Its thresholds come
    // from the global bot config, whose default flying threshold is level 60, so it can teach a
    // flying mount before our TBC-first player has earned flying. Grant only fast ground Riding
    // here; an explicitly ground-only mount grant can be added after its spell selection is
    // independently validated.
    player->SetSkill(SKILL_RIDING, 0, 150, 150);

    factory.InitAmmo();
    factory.InitPotions();
    factory.InitFood();

    uint32 const targetCopper = g_AdventureStartStartingGold * 10000u;
    uint32 const currentCopper = player->GetMoney();
    if (currentCopper < targetCopper)
        player->ModifyMoney(static_cast<int32>(targetCopper - currentCopper));
}

void TryGiveSpecStarterGear(Player* player)
{
    if (!g_AdventureStartAutoGear || !player || IsPlayerbot(player))
        return;

    uint32 guid = player->GetGUID().GetCounter();
    AdventureProgressionStore::State state = AdventureProgressionStore::LoadOrCreate(guid);
    if (!state.starterInitialized || state.starterGearGranted)
        return;

    uint32 spent = GetSpentTalentPoints(player);
    if (spent < g_AdventureStartGearMinTalentPoints)
        return;

    uint8 specTab = AiFactory::GetPlayerSpecTab(player);

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
        "[AdventureStart] Granted spec-aware starter gear to {} (specTab={}, spentTalents={}, targetIlvl={})",
        player->GetName(),
        specTab,
        spent,
        g_AdventureStartGearItemLevel);
}

void QueueCrossedLevelCaches(Player* player, uint8 oldLevel)
{
    if (!g_AdventureProgressionCachesEnable || !player || IsPlayerbot(player))
        return;

    static constexpr std::array<uint8, 2> milestones = {65, 70};

    uint8 newLevel = player->GetLevel();
    uint32 guid = player->GetGUID().GetCounter();
    AdventureProgressionStore::State state = AdventureProgressionStore::LoadOrCreate(guid);

    uint16 earned = 0;
    uint8 highest = state.lastLevelCache;
    for (uint8 milestone : milestones)
    {
        if (oldLevel < milestone && newLevel >= milestone && state.lastLevelCache < milestone)
        {
            ++earned;
            highest = milestone;
        }
    }

    if (!earned)
        return;

    AdventureProgressionStore::AddPendingCache(guid, earned);
    AdventureProgressionStore::SetLastLevelCache(guid, highest);

    LOG_INFO(
        "server.loading",
        "[AdventureProgression] {} earned {} progression cache(s) by reaching level {}",
        player->GetName(),
        earned,
        newLevel);
}
}

class AdventureStartPlayerScript : public PlayerScript
{
public:
    AdventureStartPlayerScript() : PlayerScript("AdventureStartPlayerScript") { }

    void OnPlayerFirstLogin(Player* player) override
    {
        if (!g_AdventureStartEnable || !player || IsPlayerbot(player))
            return;

        uint32 guid = player->GetGUID().GetCounter();
        AdventureProgressionStore::State state = AdventureProgressionStore::LoadOrCreate(guid);

        if (g_AdventureStartLevel > player->GetLevel())
        {
            player->GiveLevel(static_cast<uint8>(g_AdventureStartLevel));
            player->InitTalentForLevel();
            player->SetUInt32Value(PLAYER_XP, 0);
        }

        uint8 const appliedProgression = ApplyAdventureProgression(player);

        if (g_AdventureStartRevealMap)
            RevealAllMap(player);

        if (!state.starterInitialized)
        {
            if (g_AdventureStartStarterKit)
                GiveStarterKit(player);

            AdventureProgressionStore::MarkStarterInitialized(guid);
            player->SaveToDB(false, false);
        }

        TryGiveSpecStarterGear(player);

        if (sIndividualProgression->enabled && g_AdventureStartProgression > 0 && appliedProgression < g_AdventureStartProgression)
        {
            LOG_WARN(
                "server.loading",
                "[AdventureStart] {} requested progression {} but IP applied only {} (check IndividualProgression.ProgressionLimit/config)",
                player->GetName(),
                g_AdventureStartProgression,
                appliedProgression);
        }

        LOG_INFO(
            "server.loading",
            "[AdventureStart] Initialized {} at level {}, progression {}, mapReveal={}, starterKit={}",
            player->GetName(),
            player->GetLevel(),
            appliedProgression,
            g_AdventureStartRevealMap ? 1 : 0,
            g_AdventureStartStarterKit ? 1 : 0);
    }

    void OnPlayerLearnTalents(Player* player, uint32 /*talentId*/, uint32 /*talentRank*/, uint32 /*spellid*/) override
    {
        TryGiveSpecStarterGear(player);
    }

    void OnPlayerLevelChanged(Player* player, uint8 oldLevel) override
    {
        QueueCrossedLevelCaches(player, oldLevel);
    }
};

void AddAdventureStartScripts()
{
    new AdventureStartPlayerScript();
}
