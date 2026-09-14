#ifndef MOD_PLAYERBOT_CHATTER_AI_GUILD_SERVICES_H
#define MOD_PLAYERBOT_CHATTER_AI_GUILD_SERVICES_H

#include <string>

class Guild;
class Player;

namespace PBAIGuildServices
{
// Returns true when the line is a service command handled by the persistent AI-guild backend.
bool HandleGuildMessage(Player* player, Guild* guild, std::string const& message);
}

#endif
