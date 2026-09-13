#ifndef MOD_ADMIN_PANEL_GAMEPLAY_H
#define MOD_ADMIN_PANEL_GAMEPLAY_H

#include "Define.h"

class Player;

namespace AdminPanelGameplay
{
struct PopulationStats
{
    uint32 sessions = 0;
    uint32 realPlayers = 0;
    uint32 bots = 0;
    uint32 botTarget = 0;
    uint32 botBatch = 0;
    float botActivity = 0.0f;
    uint32 botAccounts = 0;
    uint32 assignedBotAccounts = 0;
    uint32 requiredBotAccounts = 0;
    uint32 managerCandidates = 0;
    uint32 managerRandomAccounts = 0;
    uint32 pendingBotLogins = 0;
    bool botEngineEnabled = false;
    bool botAutologinEnabled = false;
};

PopulationStats GetPopulationStats();
void SetBotTarget(uint32 target, uint32 batch = 10);
void SetBotActivity(float percent);
// Ensures the RNDbot account/character pool has enough capacity, refreshes account assignments,
// rebuilds stale ephemeral add-event state when no random bots are online, and kicks the login
// manager. Safe to call repeatedly; persistent bot characters/progression are never deleted.
void RepairBotPopulation();

bool GiveGold(Player* player, uint32 gold);
void Repair(Player* player);
void Restore(Player* player);
void MaxSkills(Player* player);
// Maxes the skill value/rank of professions the character already knows. It deliberately does
// not learn every profession or every recipe, so it cannot blow past the normal two-primary limit.
uint32 MaxProfessions(Player* player);
void RefreshConsumables(Player* player);
void ResetEraTalents(Player* player);
void RegearTbcPreRaid(Player* player);

uint32 PrepareGroup(Player* leader);
uint32 SummonGroup(Player* leader);
uint32 RaidNight(Player* leader);
}

#endif
