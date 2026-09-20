#include "RaidRosterEra.h"
#include "EraPolicy.h"
#include "IndividualProgression.h"   // pulls Player.h etc.; see RaidRosterEra.h for why this is isolated

// Set a synced bot's IP era to match the master's, so the bot shares the master's content tier,
// difficulty scaling, and grouping eligibility. IP stores progression as rewarded hidden quests
// 66000+stage; both getter and setter require the unit to be in world (bots are, since
// .raidroster sync runs on logged-in bots). This file hard-depends on IP being in the build
// (setup.sh always clones it).
void RaidRosterEra::SyncBotToMaster(Player* master, Player* bot)
{
    if (!master->IsInWorld() || !bot->IsInWorld())
        return;
    // Source of truth = master's live era.
    uint8 state = sIndividualProgression->GetPlayerProgressionFromQuests(master);
    // Fallback by level, but never infer an era the realm has not released.
    if (state == 0)
    {
        EraPolicy::Era fallbackEra = EraPolicy::EraForLevel(master->GetLevel());
        EraPolicy::Era const realmEra = EraPolicy::CurrentRealmEra();
        if (static_cast<uint8>(fallbackEra) > static_cast<uint8>(realmEra))
            fallbackEra = realmEra;
        state = EraPolicy::MinimumProgression(fallbackEra);
    }

    // Dirty/dev characters may already carry future hidden progression quests. Do not copy
    // that contamination into a bot while the realm is simulating an earlier era.
    if (state > EraPolicy::RealmProgressionCeiling())
        state = EraPolicy::RealmProgressionCeiling();
    if (state == 0)
    {
        // ForceUpdateProgressionState early-returns on stage 0 (landmine), so demote a
        // previously-advanced bot to Vanilla by clearing the hidden progression quests directly.
        // A freshly-created roster bot has none, so this is normally a no-op.
        for (uint32 i = 1; i <= 18; ++i)
            if (bot->IsQuestRewarded(66000 + i))
                bot->RemoveRewardedQuest(66000 + i);
    }
    else
    {
        sIndividualProgression->ForceUpdateProgressionState(bot, static_cast<ProgressionState>(state));
    }
}
