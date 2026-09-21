#include "AdventureStartControl.h"

#include "AdventureProgressionStore.h"
#include "AdventureStartKit.h"
#include "EraPolicy.h"
#include "RaidRosterConfig.h"

#include "IndividualProgression.h"
#include "Log.h"
#include "Player.h"

#include <array>
#include <mutex>
#include <unordered_map>

namespace
{
std::mutex g_nextProfileMutex;
std::unordered_map<uint32, AdventureStartProfile> g_nextProfileByAccount;

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
    if (profile == AdventureStartProfile::VanillaFresh)
        return { 1, AdventureStartControl::ProgressionStart, false, 0, 0.f, 0.f, 0.f, 0.f };

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
uint8 CurrentProgression(Player* player)
{
    if (!player || !sIndividualProgression->enabled)
        return ProgressionStart;
    return sIndividualProgression->GetPlayerProgressionFromQuests(player);
}

bool HasPassedProgression(Player* player, uint8 progression)
{
    if (!player)
        return false;
    if (!sIndividualProgression->enabled || progression == ProgressionStart)
        return true;
    return sIndividualProgression->hasPassedProgression(player, static_cast<ProgressionState>(progression));
}

uint8 RequiredZulGurubProgression()
{
    return sIndividualProgression->enabled
        ? static_cast<uint8>(sIndividualProgression->RequiredZulGurubProgression)
        : ProgressionStart;
}

uint8 RequiredZulAmanProgression()
{
    return sIndividualProgression->enabled
        ? static_cast<uint8>(sIndividualProgression->RequiredZulAmanProgression)
        : ProgressionStart;
}

AdventureStartProfile GetDefaultProfile()
{
    if (g_AdventureStartDefaultProfile == static_cast<uint8>(AdventureStartProfile::VanillaFresh))
        return AdventureStartProfile::VanillaFresh;
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

void SetNextProfileOverride(uint32 accountId, AdventureStartProfile profile)
{
    if (!accountId)
        return;
    std::lock_guard<std::mutex> lock(g_nextProfileMutex);
    g_nextProfileByAccount[accountId] = profile;
}

bool ClearNextProfileOverride(uint32 accountId)
{
    if (!accountId)
        return false;
    std::lock_guard<std::mutex> lock(g_nextProfileMutex);
    return g_nextProfileByAccount.erase(accountId) != 0;
}

bool PeekNextProfileOverride(uint32 accountId, AdventureStartProfile& profile)
{
    if (!accountId)
        return false;
    std::lock_guard<std::mutex> lock(g_nextProfileMutex);
    auto const itr = g_nextProfileByAccount.find(accountId);
    if (itr == g_nextProfileByAccount.end())
        return false;
    profile = itr->second;
    return true;
}

bool ConsumeNextProfileOverride(uint32 accountId, AdventureStartProfile& profile)
{
    if (!accountId)
        return false;
    std::lock_guard<std::mutex> lock(g_nextProfileMutex);
    auto const itr = g_nextProfileByAccount.find(accountId);
    if (itr == g_nextProfileByAccount.end())
        return false;
    profile = itr->second;
    g_nextProfileByAccount.erase(itr);
    return true;
}

char const* ProfileName(AdventureStartProfile profile)
{
    if (profile == AdventureStartProfile::VanillaFresh)
        return "vanilla";
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

bool EnsureRaidReadyAccess(Player* player, AdventureStartProfile profile)
{
    if (!player || profile != AdventureStartProfile::WotlkRaidReady)
        return false;

    // A WotLK raid-ready boost is deliberately past the mandatory Frozen Halls story gate. Do not
    // complete arbitrary Northrend quests; only record the faction-specific access chain that gates
    // Forge of Souls -> Pit of Saron -> Halls of Reflection.
    static constexpr std::array<uint32, 6> AllianceFrozenHalls = {
        24510u, // Inside the Frozen Citadel
        24499u, // Echoes of Tortured Souls
        24683u, // The Pit of Saron
        24498u, // The Path to the Citadel
        24710u, // Deliverance from the Pit
        24711u, // Frostmourne
    };
    static constexpr std::array<uint32, 6> HordeFrozenHalls = {
        24506u, // Inside the Frozen Citadel
        24511u, // Echoes of Tortured Souls
        24682u, // The Pit of Saron
        24507u, // The Path to the Citadel
        24712u, // Deliverance from the Pit
        24713u, // Frostmourne
    };

    auto const& quests = player->GetTeamId() == TEAM_ALLIANCE ? AllianceFrozenHalls : HordeFrozenHalls;
    bool changed = false;
    for (uint32 questId : quests)
    {
        if (player->IsQuestRewarded(questId))
            continue;

        // Raid-ready skips the story rather than granting its normal rewards. Remove an in-progress
        // copy if present, then persist only the rewarded/access flag used by AzerothCore gates.
        player->RemoveActiveQuest(questId, false);
        player->SetRewardedQuest(questId);
        player->SendQuestUpdate(questId);
        changed = true;
    }

    if (changed)
        LOG_INFO("server.loading", "[AdventureStart] Repaired WotLK raid-ready Frozen Halls access for {}.", player->GetName());
    return changed;
}

bool CompleteWotlkExpansionAccess(Player* player)
{
    if (!player || !player->IsInWorld() || !sIndividualProgression->enabled)
        return false;

    // The Admin Panel action is intentionally a full WotLK access skip. Individual Progression
    // stores raid milestones as hidden quests, so moving to tier 5 (18) represents having cleared
    // every WotLK progression gate, including the stage-16 Forge of Souls / ICC gate.
    sIndividualProgression->ForceUpdateProgressionState(player, PROGRESSION_WOTLK_TIER_5);
    if (!sIndividualProgression->hasPassedProgression(player, PROGRESSION_WOTLK_TIER_5))
        return false;

    // Keep the two real WotLK campaign/access chains used by this stack in sync with that skip:
    // Battle for the Undercity drives capital-city phasing, while Frozen Halls drives Pit/HoR entry.
    uint32 const undercityQuest = player->GetTeamId() == TEAM_ALLIANCE ? BATTLE_UNDERCITY_ALLIANCE : BATTLE_UNDERCITY_HORDE;
    if (!player->IsQuestRewarded(undercityQuest))
    {
        player->RemoveActiveQuest(undercityQuest, false);
        player->SetRewardedQuest(undercityQuest);
        player->SendQuestUpdate(undercityQuest);
    }

    if (player->IsClass(CLASS_DEATH_KNIGHT))
    {
        uint32 const dkIntroCompletionQuest = player->GetTeamId() == TEAM_ALLIANCE ? 13188u : 13189u;
        if (!player->IsQuestRewarded(dkIntroCompletionQuest))
        {
            player->RemoveActiveQuest(dkIntroCompletionQuest, false);
            player->SetRewardedQuest(dkIntroCompletionQuest);
            player->SendQuestUpdate(dkIntroCompletionQuest);
        }
    }

    EnsureRaidReadyAccess(player, AdventureStartProfile::WotlkRaidReady);
    sIndividualProgression->CheckAdjustments(player);
    sIndividualProgression->checkIPPhasing(player, player->GetAreaId());
    player->SaveToDB(false, false);

    LOG_INFO("server.loading",
        "[AdventureStart] Completed WotLK expansion access for {}: progression={}, Frozen Halls/Undercity access repaired.",
        player->GetName(), uint32(sIndividualProgression->GetPlayerProgressionFromQuests(player)));
    return true;
}

bool ApplyProfile(Player* player, AdventureStartProfile profile, bool forceStarterReset)
{
    if (!player || !player->IsInWorld())
        return false;

    // Vanilla is a genuinely clean start. Do not grant levels, gear, map reveal or teleport.
    // This profile exists so the global expansion gate can make fresh realms start at level 1
    // without disabling AdventureStart for later TBC/WotLK convenience profiles.
    if (profile == AdventureStartProfile::VanillaFresh)
    {
        LOG_INFO("server.loading", "[AdventureStart] Vanilla fresh start left {} untouched at level {}.", player->GetName(), player->GetLevel());
        return true;
    }

    // Starter profiles synthesize inventory/equipment. Refuse before progression, level or starter
    // state changes when the central chronology snapshot is missing/stale.
    if (g_AdventureStartStarterKit && !EraPolicy::ItemProvenanceReady())
    {
        LOG_ERROR(
            "server.loading",
            "[AdventureStart] Refusing profile {} for {}: ERA-07 item provenance unavailable ({}).",
            ProfileName(profile),
            player->GetName(),
            EraPolicy::ItemProvenanceError());
        return false;
    }

    ProfileData const data = DataFor(profile);
    uint32 const guid = player->GetGUID().GetCounter();

    // Reject future-era profiles before level, inventory, talents or starter state can change.
    if (!sIndividualProgression->enabled ||
        !EraPolicy::IsLevelAllowed(static_cast<uint8>(data.level)) ||
        (data.progression > 0 && !EraPolicy::IsProgressionAllowed(data.progression)))
    {
        LOG_WARN(
            "server.loading",
            "[AdventureStart] Profile {} is outside live era {} (levelCap={}, progressionCeiling={}) for {}.",
            ProfileName(profile),
            EraPolicy::Name(EraPolicy::CurrentRealmEra()),
            uint32(EraPolicy::RealmLevelCap()),
            uint32(EraPolicy::RealmProgressionCeiling()),
            player->GetName());
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

    EnsureRaidReadyAccess(player, profile);
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
