#include "TitanRuneSystem.h"

#include "Group.h"
#include "ObjectAccessor.h"
#include "Player.h"
#include "ScriptMgr.h"
#include "WorldSession.h"

#include <unordered_map>

namespace
{
std::unordered_map<uint32, TitanRuneMode> g_restoreSelections;

Player* RealGroupLeader(Player* player)
{
    if (!player)
        return nullptr;

    Group* group = player->GetGroup();
    if (!group)
        return nullptr;

    Player* leader = ObjectAccessor::FindPlayer(group->GetLeaderGUID());
    if (!leader || !leader->GetSession() || leader->GetSession()->IsBot())
        return nullptr;

    return leader;
}

class TitanRuneSelectionGuardPlayerScript final : public PlayerScript
{
public:
    TitanRuneSelectionGuardPlayerScript() : PlayerScript("TitanRuneSelectionGuardPlayerScript") { }

    void OnPlayerMapChanged(Player* player) override
    {
        if (!player || !player->IsInWorld())
            return;

        Player* leader = RealGroupLeader(player);
        if (!leader || leader == player)
            return;

        // A real group leader's selection is authoritative, including an explicit Off. The core
        // activator historically fell back to a member's personal choice whenever the leader was
        // Off, which could accidentally enable a protocol the leader deliberately disabled.
        if (TitanRune::LoadSelectedMode(leader) != TitanRuneMode::Off)
            return;

        TitanRuneMode const memberSelection = TitanRune::LoadSelectedMode(player);
        if (memberSelection == TitanRuneMode::Off)
            return;

        uint32 const guid = player->GetGUID().GetCounter();
        g_restoreSelections[guid] = memberSelection;
        TitanRune::SaveSelectedMode(player, TitanRuneMode::Off);
    }

    void OnPlayerUpdate(Player* player, uint32 /*diff*/) override
    {
        if (!player)
            return;

        uint32 const guid = player->GetGUID().GetCounter();
        auto itr = g_restoreSelections.find(guid);
        if (itr == g_restoreSelections.end())
            return;

        // By the first update after the map-change hook, all PlayerScript map-change handlers have
        // finished. Restore the member's personal next-dungeon preference without affecting the
        // current instance, which is already locked to the leader's explicit Off selection.
        TitanRune::SaveSelectedMode(player, itr->second);
        g_restoreSelections.erase(itr);
    }

    void OnPlayerLogout(Player* player) override
    {
        if (!player)
            return;

        uint32 const guid = player->GetGUID().GetCounter();
        auto itr = g_restoreSelections.find(guid);
        if (itr == g_restoreSelections.end())
            return;

        TitanRune::SaveSelectedMode(player, itr->second);
        g_restoreSelections.erase(itr);
    }
};
}

void AddTitanRuneSelectionGuardScripts()
{
    new TitanRuneSelectionGuardPlayerScript();
}
