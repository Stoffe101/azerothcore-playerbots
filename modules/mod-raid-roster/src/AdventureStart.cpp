#include "ScriptMgr.h"
#include "Player.h"
#include "WorldSession.h"
#include "Log.h"
#include "RaidRosterConfig.h"
#include "AdventureProgressionStore.h"
#include "AdventureStartControl.h"
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
    // Using the session flag also keeps PlayerbotAI.h out of this translation unit.
    return !player || !player->GetSession() || player->GetSession()->IsBot();
}

bool IsDeathKnight(Player* player)
{
    return player && player->getClass() == CLASS_DEATH_KNIGHT;
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
}

class AdventureStartPlayerScript : public PlayerScript
{
public:
    AdventureStartPlayerScript() : PlayerScript("AdventureStartPlayerScript") { }

    void OnPlayerFirstLogin(Player* player) override
    {
        if (!g_AdventureStartEnable || !player || IsPlayerbot(player))
            return;

        // Death Knights are already a WotLK class with their own stage-13 start rules. Do not run
        // the generic first-login bootstrap on them; the GM raid-ready action can still be used
        // manually later if desired.
        if (IsDeathKnight(player))
        {
            LOG_INFO("server.loading", "[AdventureStart] Skipping Death Knight {}", player->GetName());
            return;
        }

        AdventureStartProfile const profile = AdventureStartControl::GetDefaultProfile();
        if (AdventureStartControl::ApplyProfile(player, profile, true))
            TrackStarterGear(player);
    }

    void OnPlayerLogin(Player* player) override
    {
        if (!g_AdventureStartEnable || !player || IsPlayerbot(player) || IsDeathKnight(player))
            return;

        uint32 const guid = player->GetGUID().GetCounter();
        AdventureProgressionStore::State state = AdventureProgressionStore::LoadOrCreate(guid);

        if (!state.starterInitialized)
        {
            // Recovery for characters created during earlier AdventureStart revisions. Match either
            // supported profile exactly so normal progressed characters never receive a starter kit.
            AdventureStartProfile recoveredProfile;
            bool matched = false;
            if (AdventureStartControl::MatchesProfile(player, AdventureStartProfile::RaidReady))
            {
                recoveredProfile = AdventureStartProfile::RaidReady;
                matched = true;
            }
            else if (AdventureStartControl::MatchesProfile(player, AdventureStartProfile::TbcAdventure))
            {
                recoveredProfile = AdventureStartProfile::TbcAdventure;
                matched = true;
            }

            if (matched)
            {
                LOG_INFO(
                    "server.loading",
                    "[AdventureStart] Backfilling missing starter kit for {} as profile={}",
                    player->GetName(), AdventureStartControl::ProfileName(recoveredProfile));
                if (AdventureStartControl::ApplyProfile(player, recoveredProfile, false))
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
