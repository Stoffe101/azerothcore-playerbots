#include "../../azerothcore-wotlk/modules/mod-dungeon-clear/src/Ai/Dungeon/DungeonClear/Util/DcHumanNavigatorPolicy.h"

#include <cassert>

int main()
{
    using DcHumanNavigator::SuppressRouteAction;
    assert(SuppressRouteAction("dungeon clear engage", false));
    assert(SuppressRouteAction("dungeon clear pull maneuver", false));
    assert(SuppressRouteAction("attack anything", false));
    assert(!SuppressRouteAction("dungeon clear advance", false));
    assert(!SuppressRouteAction("dungeon clear loot", false));
    assert(SuppressRouteAction("dungeon clear advance", true));
    assert(SuppressRouteAction("dungeon clear pull maneuver", true));
    assert(!SuppressRouteAction("heal party", true));
    assert(!SuppressRouteAction("dps assist", true));
    assert(!SuppressRouteAction("dungeon clear hor stay ahead", true));
    assert(!SuppressRouteAction("dungeon clear oc rider", true));
    assert(!SuppressRouteAction("dungeon clear hold fire", true));
    assert(!SuppressRouteAction("dungeon clear run event combat", true));
}
