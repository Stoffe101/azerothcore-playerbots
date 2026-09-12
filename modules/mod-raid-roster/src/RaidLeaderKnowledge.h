#ifndef MOD_RAID_ROSTER_RAID_LEADER_KNOWLEDGE_H
#define MOD_RAID_ROSTER_RAID_LEADER_KNOWLEDGE_H

#include <string>
#include <vector>

namespace RaidLeaderKnowledge
{
enum class Readiness
{
    GuildReady,
    Playable,
    NotReady,
};

struct Encounter
{
    std::string raid;
    std::string boss;
    std::vector<std::string> aliases;
    Readiness readiness = Readiness::NotReady;
    std::string playerbotStrategy;
    std::string overview;
    std::string tankJob;
    std::string healerJob;
    std::string dpsJob;
    std::string botAutomation;
    std::string caveat;
};

std::vector<Encounter> const& Encounters();
Encounter const* Find(std::string const& text);
char const* ReadinessName(Readiness readiness);
}

#endif
