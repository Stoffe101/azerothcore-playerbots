#ifndef MOD_PLAYERBOT_CHATTER_AI_GUILD_SERVICES_H
#define MOD_PLAYERBOT_CHATTER_AI_GUILD_SERVICES_H

#include "Define.h"

#include <string>

class Guild;
class Player;

namespace PBAIGuildServices
{
// Poll completion of queued character-DB transactions on the world thread.
void UpdateAsyncTransactions();

// Returns true when the line is a service command handled by the persistent AI-guild backend.
bool HandleGuildMessage(Player* player, Guild* guild, std::string const& message);

// Process queued guild requests using conserved guild stock and real auction-house listings only.
// No item is synthesized by these helpers.
uint32 ProcessQueuedGuild(uint32 guildId);

// Move a real, tradeable bag stack from a guild bot into the persistent guild stock when that
// exact item is currently requested. The bot loses the physical stack before stock is credited.
bool SupplyQueuedFromBot(Player* bot);

// Ask a guild bot to cast a learned recipe for a queued craft request. AzerothCore's normal spell
// system performs reagent checks/consumption and creates the item; this does not mint materials.
bool TryCraftQueuedFromBot(Player* bot);

// Cast one learned crafting spell only after every direct result and any item-taught recipe have
// passed central item provenance. Opaque runtime-loot recipe results fail closed.
bool TryCraftAllowedFromBot(Player* bot);

// Move one real surplus consumable/material/gem stack from the bot into persistent guild stock.
bool ContributeSurplusFromBot(Player* bot);

// List one real surplus stack from the bot's bags on the actual AzerothCore auction house.
// The physical item leaves the bot's inventory and the bot pays the normal auction deposit.
bool ListSurplusOnAuction(Player* bot);
}

#endif
