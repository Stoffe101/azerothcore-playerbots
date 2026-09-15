#include "TitanRuneSystem.h"

#include "Creature.h"
#include "Map.h"
#include "Player.h"
#include "ScriptMgr.h"
#include "WorldSession.h"

namespace
{
constexpr uint32 EMBLEM_OF_CONQUEST = 45624;

uint32 FinalBossEntry(uint32 mapId)
{
    switch (mapId)
    {
        case 574: return 23954; // Ingvar the Plunderer
        case 575: return 26861; // King Ymiron
        case 576: return 26723; // Keristrasza
        case 578: return 27656; // Ley-Guardian Eregos
        case 595: return 26533; // Mal'Ganis
        case 599: return 27978; // Sjonnir the Ironshaper
        case 600: return 26632; // The Prophet Tharon'ja
        case 601: return 29120; // Anub'arak
        case 602: return 28923; // Loken
        case 604: return 29306; // Gal'darah
        case 608: return 31134; // Cyanigosa
        case 619: return 29311; // Herald Volazj
        default: return 0;
    }
}

class TitanRuneAlphaRewardScript final : public UnitScript
{
public:
    TitanRuneAlphaRewardScript() : UnitScript("TitanRuneAlphaRewardScript") { }

    void OnUnitDeath(Unit* unit, Unit* /*killer*/) override
    {
        Creature* boss = unit ? unit->ToCreature() : nullptr;
        if (!boss || !boss->IsDungeonBoss() || !boss->GetMap())
            return;

        Map* map = boss->GetMap();
        if (TitanRune::GetActiveMode(map) != TitanRuneMode::Alpha ||
            boss->GetEntry() != FinalBossEntry(map->GetId()))
            return;

        // Wrath Classic Defense Protocol Alpha awards one Emblem of Conquest for the final boss.
        // Route it through the same durable per-player ledger as Beta/Gamma currency so a full bag
        // cannot permanently eat the completion reward.
        Map::PlayerList const& players = map->GetPlayers();
        for (Map::PlayerList::const_iterator itr = players.begin(); itr != players.end(); ++itr)
        {
            Player* rewardPlayer = itr->GetSource();
            if (!rewardPlayer || !rewardPlayer->GetSession() || rewardPlayer->GetSession()->IsBot())
                continue;

            TitanRune::QueuePlayerReward(rewardPlayer, map->GetInstanceId(), boss->GetEntry(),
                TitanRuneMode::Alpha, EMBLEM_OF_CONQUEST, 1, "Defense Protocol Alpha completed");
        }
    }
};
}

void AddTitanRuneRewardScripts()
{
    new TitanRuneAlphaRewardScript();
}
