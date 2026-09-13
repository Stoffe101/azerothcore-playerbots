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
    if (!player)
        return false;

    ProfileData const data = DataFor(profile);
    uint32 const guid = player->GetGUID().GetCounter();

    bool levelChanged = false;
    if (data.level > player->GetLevel())
    {
        player->GiveLevel(static_cast<uint8>(data.level));
        player->SetUInt32Value(PLAYER_XP, 0);
        levelChanged = true;
    }

    // Progression is exact to the profile's opening tier: stage 8 for TBC, stage 13 for WotLK.
    // The Admin Panel separately prevents the WotLK profile from being selected before the realm's
    // persistent WotLK release gate is open.
    if (data.progression > 0 && player->IsInWorld())
    {
        uint8 const current = sIndividualProgression->GetPlayerProgressionFromQuests(player);
        if (current < data.progression)
        {
            sIndividualProgression->ForceUpdateProgressionState(
                player,
                static_cast<ProgressionState>(data.progression));
        }
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

    if (data.teleport && player->IsInWorld())
        player->TeleportTo(data.map, data.x, data.y, data.z, data.o);

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
