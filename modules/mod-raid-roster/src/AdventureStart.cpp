#include "ScriptMgr.h"
#include "Player.h"
#include "WorldSession.h"
#include "Log.h"
#include "IndividualProgression.h"
#include "RaidRosterConfig.h"
#include "AdventureProgressionStore.h"
#include "AdventureStartKit.h"

#include <mutex>
#include <unordered_map>

namespace
{
std::unordered_map<uint32, uint32> g_starterGearPollMs;
std::mutex g_starterGearPollMutex;
constexpr uint32 STARTER_GEAR_POLL_MS = 2000;

bool IsPlayerbot(Player* player)
{
    // mod-playerbots marks bot sessions before the playerbot AI object itself is attached.
    // Using the session flag avoids pulling Playerbots.h/PlayerbotAI.h into the same translation
    // unit as IndividualProgression.h, whose global GENERAL enumerator otherwise collides with
    // PlayerbotAI.h's GENERAL enumerator at compile time.
    return !player || !player->GetSession() || player->GetSession()->IsBot();
}

bool IsDeathKnight(Player* player)
{
    return player && player->getClass() == CLASS_DEATH_KNIGHT;
}

void RevealAllMap(Player* player)
{
    for (uint8 i = 0; i < PLAYER_EXPLORED_ZONES_SIZE; ++i)
        player->SetFlag(PLAYER_EXPLORED_ZONES_1 + i, 0xFFFFFFFF);
}

void TrackStarterGear(Player* player)
{
    if (!player || !g_AdventureStartAutoGear)
        return;

    if (AdventureStartKit::TryGiveSpecStarterGear(player))
        return;

    std::lock_guard<std::mutex> lock(g_starterGearPollMutex);
    g_starterGearPollMs[player->GetGUID().GetCounter()] = 0;
}

void StopTrackingStarterGear(uint32 guid)
{
    std::lock_guard<std::mutex> lock(g_starterGearPollMutex);
    g_starterGearPollMs.erase(guid);
}

bool ShouldPollStarterGear(Player* player, uint32 diff)
{
    if (!player)
        return false;

    std::lock_guard<std::mutex> lock(g_starterGearPollMutex);
    auto it = g_starterGearPollMs.find(player->GetGUID().GetCounter());
    if (it == g_starterGearPollMs.end())
        return false;

    it->second += diff;
    if (it->second < STARTER_GEAR_POLL_MS)
        return false;

    it->second = 0;
    return true;
}

bool MatchesUninitializedAdventureProfile(Player* player)
{
    if (!player)
        return false;
    if (player->GetLevel() != g_AdventureStartLevel)
        return false;

    // GetPlayerProgressionFromQuests is safe during OnPlayerLogin too; EraTalents uses the same
    // query there. Do not require IsInWorld(), otherwise an already-created starter character can
    // miss the one-time recovery path before the world-insertion phase finishes.
    uint8 const current = sIndividualProgression->GetPlayerProgressionFromQuests(player);
    return current == g_AdventureStartProgression;
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

        // Death Knights are a WotLK-only class on this progression setup and have their own
        // stage-13 bootstrap. Never pull a fresh DK backwards into the TBC start flow.
        if (IsDeathKnight(player))
        {
            LOG_INFO("server.loading", "[AdventureStart] Skipping Death Knight {}", player->GetName());
            return;
        }

        bool levelChanged = false;
        if (g_AdventureStartLevel > player->GetLevel())
        {
            player->GiveLevel(static_cast<uint8>(g_AdventureStartLevel));
            player->SetUInt32Value(PLAYER_XP, 0);
            levelChanged = true;
        }

        // Match the verified faction-leader expansion flow: only force the IP state here.
        // mod-era-talents detects the era crossing and performs its existing talent wipe,
        // tree switch, spell reconcile, glyph handling and addon sync on the normal poll.
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

        // Recalculate native talent points only after the level/progression bootstrap. Era talents
        // use their own point accounting, but keeping the core state correct avoids stale UI/state.
        if (levelChanged)
            player->InitTalentForLevel();

        if (g_AdventureStartRevealMap)
            RevealAllMap(player);

        // Skills/spells, bags, consumables, minimum gold and a modest immediate gear set. The
        // PlayerbotFactory-heavy work lives in AdventureStartKit.cpp specifically so this file can
        // keep IndividualProgression.h without reviving the PlayerbotAI GENERAL enum collision.
        AdventureStartKit::GrantInitial(player);
        TrackStarterGear(player);

        if (g_AdventureStartTeleport && player->IsInWorld())
        {
            player->TeleportTo(
                g_AdventureStartTeleportMap,
                g_AdventureStartTeleportX,
                g_AdventureStartTeleportY,
                g_AdventureStartTeleportZ,
                g_AdventureStartTeleportO);
        }

        LOG_INFO(
            "server.loading",
            "[AdventureStart] Initialized {} at level {}, progression {}, mapReveal={}, starterKit={}, teleport={} map={} xyz=({:.2f},{:.2f},{:.2f}) o={:.2f}",
            player->GetName(),
            player->GetLevel(),
            g_AdventureStartProgression,
            g_AdventureStartRevealMap ? 1 : 0,
            g_AdventureStartStarterKit ? 1 : 0,
            g_AdventureStartTeleport ? 1 : 0,
            g_AdventureStartTeleportMap,
            g_AdventureStartTeleportX,
            g_AdventureStartTeleportY,
            g_AdventureStartTeleportZ,
            g_AdventureStartTeleportO);
    }

    void OnPlayerLogin(Player* player) override
    {
        if (!g_AdventureStartEnable || !player || IsPlayerbot(player) || IsDeathKnight(player))
            return;

        uint32 const guid = player->GetGUID().GetCounter();
        AdventureProgressionStore::State state = AdventureProgressionStore::LoadOrCreate(guid);

        if (!state.starterInitialized)
        {
            // Recovery path for characters created while AdventureStart only handled level/stage/
            // teleport. It is intentionally narrow: exactly the configured starter level + stage.
            // That fixes the already-created test character without handing starter loot to normal
            // progressed characters on every login.
            if (MatchesUninitializedAdventureProfile(player))
            {
                LOG_INFO("server.loading", "[AdventureStart] Backfilling missing starter kit for {}", player->GetName());
                AdventureStartKit::GrantInitial(player);
                TrackStarterGear(player);
            }
            return;
        }

        if (!state.starterGearGranted)
            TrackStarterGear(player);
    }

    void OnPlayerLearnTalents(Player* player, uint32 /*talentId*/, uint32 /*talentRank*/, uint32 /*spellid*/) override
    {
        if (!g_AdventureStartEnable || !player || IsPlayerbot(player) || IsDeathKnight(player))
            return;
        TrackStarterGear(player);
    }

    void OnPlayerUpdate(Player* player, uint32 diff) override
    {
        if (!g_AdventureStartEnable || !player || IsPlayerbot(player) || IsDeathKnight(player) || !player->IsInWorld())
            return;
        if (!ShouldPollStarterGear(player, diff))
            return;

        if (AdventureStartKit::TryGiveSpecStarterGear(player))
            StopTrackingStarterGear(player->GetGUID().GetCounter());
    }
};

void AddAdventureStartScripts()
{
    new AdventureStartPlayerScript();
}
