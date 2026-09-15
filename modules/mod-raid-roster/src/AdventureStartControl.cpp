#include "AdventureStartControl.h"

#include "AdventureProgressionStore.h"
#include "AdventureStartKit.h"
#include "RaidRosterConfig.h"

#include "IndividualProgression.h"
#include "Log.h"
#include "Player.h"

namespace
{
struct ProfileData
{
    uint32 level;
    uint8 progression;
    bool teleport;
    uint32 map;
    float x;
    float y;
    float z;
    float o;
};

ProfileData DataFor(AdventureStartProfile profile)
{
    if (profile == AdventureStartProfile::WotlkRaidReady)
    {
        return {
            g_AdventureStartWotlkRaidReadyLevel,
            g_AdventureStartWotlkRaidReadyProgression,
            g_AdventureStartWotlkRaidReadyTeleport,
            g_AdventureStartWotlkRaidReadyTeleportMap,
            g_AdventureStartWotlkRaidReadyTeleportX,
            g_AdventureStartWotlkRaidReadyTeleportY,
            g_AdventureStartWotlkRaidReadyTeleportZ,
            g_AdventureStartWotlkRaidReadyTeleportO,
        };
    }

    if (profile == AdventureStartProfile::TbcRaidReady)
    {
        return {
            g_AdventureStartTbcRaidReadyLevel,
            g_AdventureStartTbcRaidReadyProgression,
            g_AdventureStartTbcRaidReadyTeleport,
            g_AdventureStartTbcRaidReadyTeleportMap,
            g_AdventureStartTbcRaidReadyTeleportX,
            g_AdventureStartTbcRaidReadyTeleportY,
            g_AdventureStartTbcRaidReadyTeleportZ,
            g_AdventureStartTbcRaidReadyTeleportO,
        };
    }

    return {
        g_AdventureStartLevel,
        g_AdventureStartProgression,
        g_AdventureStartTeleport,
        g_AdventureStartTeleportMap,
        g_AdventureStartTeleportX,
        g_AdventureStartTeleportY,
        g_AdventureStartTeleportZ,
        g_AdventureStartTeleportO,
    };
}

void RevealAllMap(Player* player)
{
    for (uint8 i = 0; i < PLAYER_EXPLORED_ZONES_SIZE; ++i)
        player->SetFlag(PLAYER_EXPLORED_ZONES_1 + i, 0xFFFFFFFF);
}
}

namespace AdventureStartControl
{
AdventureStartProfile GetDefaultProfile()
{
    if (g_AdventureStartDefaultProfile == static_cast<uint8>(AdventureStartProfile::WotlkRaidReady))
        return AdventureStartProfile::WotlkRaidReady;
    if (g_AdventureStartDefaultProfile == static_cast<uint8>(AdventureStartProfile::TbcRaidReady))
        return AdventureStartProfile::TbcRaidReady;
    return AdventureStartProfile::TbcAdventure;
}

void SetDefaultProfile(AdventureStartProfile profile)
{
    g_AdventureStartDefaultProfile = static_cast<uint8>(profile);
    LOG_INFO("server.loading", "[AdventureStart] Runtime default profile set to {}", ProfileName(profile));
}

char const* ProfileName(AdventureStartProfile profile)
{
    if (profile == AdventureStartProfile::WotlkRaidReady)
        return "wotlkraid";
    if (profile == AdventureStartProfile::TbcRaidReady)
        return "tbcraid";
    return "tbc";
}

bool MatchesProfile(Player* player, AdventureStartProfile profile)
{
    if (!player)
        return false;

    ProfileData const data = DataFor(profile);
    if (player->GetLevel() != data.level)
        return false;

    uint8 const current = sIndividualProgression->GetPlayerProgressionFromQuests(player);
    return current == data.progression;
}

bool ApplyProfile(Player* player, AdventureStartProfile profile, bool forceStarterReset)
{
    if (!player || !player->IsInWorld())
        return false;

    ProfileData const data = DataFor(profile);
    uint32 const guid = player->GetGUID().GetCounter();

    // Reject unavailable profiles before level, inventory, talents or starter state can change.
    if (data.progression > 0 && (!sIndividualProgression->enabled ||
        (sIndividualProgression->progressionLimit && data.progression > sIndividualProgression->progressionLimit)))
    {
        LOG_WARN("server.loading", "[AdventureStart] Profile {} is outside the enabled progression ceiling for {}.",
            ProfileName(profile), player->GetName());
        return false;
    }

    // Starter profiles are normal forward progression, not a back-door around Individual
    // Progression. Respect IP enablement and the configured live-expansion ceiling. The Admin
    // Panel already opens that ceiling before WotLK raid-ready can be selected.
    if (data.progression > 0 && player->IsInWorld() && sIndividualProgression->enabled)
    {
        uint8 const current = sIndividualProgression->GetPlayerProgressionFromQuests(player);
        if (current < data.progression)
            sIndividualProgression->UpdateProgressionState(player, static_cast<ProgressionState>(data.progression));

        // Individual Progression's normal login hook runs before OnPlayerFirstLogin. Reapply the
        // progression-derived state immediately after changing the hidden progression quests so a
        // new starter does not wait for a later zone/equipment event to receive correct phasing.
        sIndividualProgression->CheckAdjustments(player);
        sIndividualProgression->checkIPPhasing(player, player->GetAreaId());

        uint8 const applied = sIndividualProgression->GetPlayerProgressionFromQuests(player);
        if (applied < data.progression)
        {
            LOG_WARN(
                "server.loading",
                "[AdventureStart] {} requested profile={} progression={} but IP applied only {} (enabled={}, limit={})",
                player->GetName(), ProfileName(profile), data.progression, applied,
                sIndividualProgression->enabled ? 1 : 0, sIndividualProgression->progressionLimit);
            return false;
        }
    }
    else if (data.progression > 0 && player->IsInWorld())
    {
        LOG_WARN(
            "server.loading",
            "[AdventureStart] Refusing profile={} progression={} for {} because Individual Progression is disabled.",
            ProfileName(profile), data.progression, player->GetName());
        return false;
    }

    bool levelChanged = false;
    if (data.level > player->GetLevel())
    {
        player->GiveLevel(static_cast<uint8>(data.level));
        player->SetUInt32Value(PLAYER_XP, 0);
        levelChanged = true;
    }

    if (levelChanged)
        player->InitTalentForLevel();

    if (g_AdventureStartRevealMap)
        RevealAllMap(player);

    AdventureProgressionStore::State state = AdventureProgressionStore::LoadOrCreate(guid);
    if (forceStarterReset || state.starterProfile != static_cast<uint8>(profile))
        AdventureProgressionStore::PrepareStarterProfile(guid, static_cast<uint8>(profile));

    if (!AdventureStartKit::GrantInitial(player, profile))
        return false;

    // Existing characters often already have a committed spec when the GM presses a raid-ready
    // button. Give the final spec-aware set immediately in that case instead of making the player
    // relog or spend another talent point just to trigger the normal starter-gear poller.
    AdventureStartKit::TryGiveSpecStarterGear(player);

    if (data.teleport && player->IsInWorld())
        player->TeleportTo(data.map, data.x, data.y, data.z, data.o);

    // A newly-created DK that is boosted while still in Ebon Hold only calculates the quest-gated
    // DK talent pool (25 points at level 80). The raid-ready shortcut deliberately skips that intro,
    // so an unspecced DK must receive the normal level-based WotLK pool instead. The stock LFG
    // manager also hard-locks every DK out of dungeon finder until the faction-specific final intro
    // quest is rewarded (13188 Alliance / 13189 Horde), so mark that final gate as completed as part
    // of the same intentional starter-zone skip.
    if (profile == AdventureStartProfile::WotlkRaidReady && player->getClass() == CLASS_DEATH_KNIGHT)
    {
        uint32 const dkIntroCompletionQuest = player->GetTeamId() == TEAM_ALLIANCE ? 13188u : 13189u;
        if (!player->IsQuestRewarded(dkIntroCompletionQuest))
            player->SetRewardedQuest(dkIntroCompletionQuest);

        player->InitTalentForLevel();
        uint32 const expectedTalentPoints = player->GetLevel() >= 10 ? player->GetLevel() - 9 : 0;
        if (player->GetTalentMap().empty() && player->GetFreeTalentPoints() < expectedTalentPoints)
            player->SetFreeTalentPoints(expectedTalentPoints);
        player->SendTalentsInfoData(false);
    }

    player->SaveToDB(false, false);

    LOG_INFO(
        "server.loading",
        "[AdventureStart] Applied profile={} to {}: level={}, progression={}, teleport={} map={} xyz=({:.2f},{:.2f},{:.2f})",
        ProfileName(profile),
        player->GetName(),
        player->GetLevel(),
        data.progression,
        data.teleport ? 1 : 0,
        data.map,
        data.x,
        data.y,
        data.z);
    return true;
}
}
