#include "TitanRuneSystem.h"

#include "Chat.h"
#include "Creature.h"
#include "Group.h"
#include "Map.h"
#include "ObjectAccessor.h"
#include "Player.h"
#include "ScriptMgr.h"
#include "WorldSession.h"

namespace
{
constexpr uint32 EMBLEM_OF_CONQUEST = 45624;

bool IsFrozenHalls(uint32 mapId)
{
    return mapId == 632 || mapId == 658 || mapId == 668; // Forge of Souls / Pit of Saron / Halls of Reflection
}

bool IsFrozenHallsHeroic(Player* player)
{
    Map* map = player ? player->GetMap() : nullptr;
    return map && map->IsDungeon() && map->GetDifficulty() == DUNGEON_DIFFICULTY_HEROIC && IsFrozenHalls(map->GetId());
}

void EnsureFrozenHallsGammaRewards(Player* player)
{
    if (!player || !player->IsInWorld() || !IsFrozenHallsHeroic(player) ||
        TitanRune::GetActiveMode(player->GetMap()) != TitanRuneMode::Off)
        return;

    // Blizzard shipped the three Frozen Halls heroics with Gamma rewards enabled BY DEFAULT while
    // deliberately preserving their normal Heroic health, damage and mechanics. Activate our
    // existing reward-only Gamma mode without changing the player's chosen protocol for the next
    // ordinary Titan Rune dungeon. ActivateForPlayer normally lets a real group leader's selection
    // win, so temporarily override whichever real player is actually the selector, then restore it.
    Player* selector = player;
    if (Group* group = player->GetGroup())
    {
        if (Player* leader = ObjectAccessor::FindPlayer(group->GetLeaderGUID()))
        {
            if (leader->GetSession() && !leader->GetSession()->IsBot())
                selector = leader;
        }
    }

    TitanRuneMode const selected = TitanRune::LoadSelectedMode(selector);
    TitanRune::SaveSelectedMode(selector, TitanRuneMode::Gamma);
    TitanRune::ActivateForPlayer(player);
    TitanRune::SaveSelectedMode(selector, selected);
}

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

class TitanRuneFrozenHallsPlayerScript final : public PlayerScript
{
public:
    TitanRuneFrozenHallsPlayerScript() : PlayerScript("TitanRuneFrozenHallsPlayerScript") { }

    void OnPlayerLogin(Player* player) override
    {
        EnsureFrozenHallsGammaRewards(player);
    }

    void OnPlayerMapChanged(Player* player) override
    {
        EnsureFrozenHallsGammaRewards(player);
    }
};

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
        // The 3.3.5 item exists natively, so unlike Sidereal/Scourgestone no custom currency shim is
        // necessary. Standard heroic/phase loot remains owned by the core/progression stack.
        map->DoForAllPlayers([&](Player* rewardPlayer)
        {
            if (!rewardPlayer || !rewardPlayer->GetSession() || rewardPlayer->GetSession()->IsBot())
                return;

            if (rewardPlayer->AddItem(EMBLEM_OF_CONQUEST, 1))
                ChatHandler(rewardPlayer->GetSession()).SendSysMessage(
                    "[Titan Rune] Defense Protocol Alpha completed: +1 Emblem of Conquest.");
            else
                ChatHandler(rewardPlayer->GetSession()).SendSysMessage(
                    "[Titan Rune] Alpha completion reward could not fit in your bags. Make room before the next run.");
        });
    }
};
}

void AddTitanRuneRewardScripts()
{
    new TitanRuneFrozenHallsPlayerScript();
    new TitanRuneAlphaRewardScript();
}
