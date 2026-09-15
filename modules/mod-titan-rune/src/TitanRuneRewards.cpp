#include "TitanRuneSystem.h"

#include "Map.h"
#include "ObjectMgr.h"
#include "Player.h"
#include "ScriptMgr.h"

// The core encounter-credit hook covers deaths AND scripted completions such as
// Tribunal, Mal'Ganis, the Argent Challenge and the Halls of Reflection escape.
// Its updated flag only becomes true when a new encounter-mask bit is committed.
class TitanRuneEncounterRewardScript final : public GlobalScript
{
public:
    TitanRuneEncounterRewardScript() : GlobalScript("TitanRuneEncounterRewardScript") { }

    void OnAfterUpdateEncounterState(Map* map, EncounterCreditType type, uint32 creditEntry,
        Unit* /*source*/, Difficulty /*difficulty*/, std::list<DungeonEncounter const*> const* /*encounters*/,
        uint32 dungeonCompleted, bool updated) override
    {
        if (!map || !updated)
            return;
        TitanRuneMode const mode = TitanRune::GetActiveMode(map);
        uint32 itemEntry = 0;
        char const* reason = nullptr;
        if (mode == TitanRuneMode::Gamma)
        {
            itemEntry = TitanRune::SCOURGESTONE_ITEM;
            reason = "Gamma encounter completed";
        }
        else if (dungeonCompleted && mode == TitanRuneMode::Beta)
        {
            itemEntry = TitanRune::SIDEREAL_ESSENCE_ITEM;
            reason = "Beta dungeon completed";
        }
        else if (dungeonCompleted && mode == TitanRuneMode::Alpha)
        {
            itemEntry = 45624; // Emblem of Conquest
            reason = "Defense Protocol Alpha completed";
        }
        else
            return;

        // Distinguish spell-credit encounters from creature entries in the existing ledger key.
        uint32 const encounterKey = creditEntry | (type == ENCOUNTER_CREDIT_CAST_SPELL ? 0x80000000u : 0u);
        for (auto const& ref : map->GetPlayers())
            TitanRune::QueuePlayerReward(ref.GetSource(), map->GetInstanceId(), encounterKey,
                mode, itemEntry, 1, reason);
    }
};

void AddTitanRuneRewardScripts()
{
    new TitanRuneEncounterRewardScript();
}
