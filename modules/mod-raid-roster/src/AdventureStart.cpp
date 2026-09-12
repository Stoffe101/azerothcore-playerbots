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
    factory.InitMounts();

    // Playerbots' generic WotLK mount setup may include flying at level 60 depending on its
    // bot configuration. Our TBC-first human start deliberately stops at fast ground riding;
    // flying remains something the player earns/trains during Outland progression.
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

    // One rare-quality, spec-aware starter pass. At the default ilvl 65 it is intentionally
    // strong enough for a pleasant Outland start but leaves normal TBC dungeon upgrades useful.
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

        if (g_AdventureStartProgression > 0 && player->IsInWorld())
        {
            uint8 current = sIndividualProgression->GetPlayerProgressionFromQuests(player);
            if (current < g_AdventureStartProgression)
            {
                sIndividualProgression->ForceUpdateProgressionState(
                    player,
                    static_cast<ProgressionState>(g_AdventureStartProgression));
            }
        }

        if (g_AdventureStartRevealMap)
            RevealAllMap(player);

        if (!state.starterInitialized)
        {
            if (g_AdventureStartStarterKit)
                GiveStarterKit(player);

            AdventureProgressionStore::MarkStarterInitialized(guid);
            player->SaveToDB(false, false);
        }

        // If a future character template already has talents on first login, this can grant the
        // starter set immediately. Normal fresh characters receive it after spending enough points.
        TryGiveSpecStarterGear(player);

        LOG_INFO(
            "server.loading",
            "[AdventureStart] Initialized {} at level {}, progression {}, mapReveal={}, starterKit={}",
            player->GetName(),
            player->GetLevel(),
            g_AdventureStartProgression,
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
