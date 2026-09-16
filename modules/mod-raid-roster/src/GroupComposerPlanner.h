#ifndef MOD_RAID_ROSTER_GROUP_COMPOSER_PLANNER_H
#define MOD_RAID_ROSTER_GROUP_COMPOSER_PLANNER_H

#include "GroupComposerTypes.h"

#include <string>

class Player;

namespace GroupComposer
{
class Planner
{
public:
    // Build is deterministic for a snapshot of currently available candidates. It never invites,
    // logs in, removes or mutates a player. All destructive/action work belongs to assembly.
    static bool Build(Player* master, Config const& config, Plan& out, std::string& error);

    // Rearrange an already-selected roster. Membership and active roles never change here.
    static void Arrange(Plan& plan);

    // Manual subgroup move. Full destination groups perform a same-role swap when possible.
    static bool Move(Plan& plan, std::string const& name, uint8 subgroup, std::string& detail);

    static uint8 InferRole(Player* player);
    static uint8 InferSpec(Player* player);
    static bool CanClassFillRole(uint8 cls, uint8 role);
    static uint32 UtilityMask(uint8 cls, uint8 spec, uint8 role);
    static bool IsRangedDps(uint8 cls, uint8 spec, uint8 role);

    static std::string CoverageSummary(Plan const& plan);
    static std::string Diagnostics(Plan const& plan);
};
}

#endif
