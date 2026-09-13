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
};

PopulationStats GetPopulationStats();
void SetBotTarget(uint32 target, uint32 batch = 10);
void SetBotActivity(float percent);

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
