#include "GroupComposerTitanRune.h"

#include "Chat.h"
#include "CommandScript.h"
#include "DBCStores.h"
#include "EraPolicy.h"
#include "Group.h"
#include "LFG.h"
#include "LFGMgr.h"
#include "ObjectAccessor.h"
#include "Player.h"
#include "RBAC.h"
#include "ScriptMgr.h"
#include "SharedDefines.h"
#include "TitanRuneSystem.h"
#include "WorldSession.h"

#include <algorithm>
#include <array>
#include <cctype>
#include <cstdint>
#include <string>
#include <unordered_map>
#include <unordered_set>
#include <vector>

using namespace Acore::ChatCommands;

namespace
{
std::string Lower(std::string value)
{
    std::transform(value.begin(), value.end(), value.begin(), [](unsigned char c) { return static_cast<char>(std::tolower(c)); });
    return value;
}

std::string Sanitize(std::string value)
{
    std::replace(value.begin(), value.end(), '|', '/');
    std::replace(value.begin(), value.end(), '\n', ' ');
    std::replace(value.begin(), value.end(), '\r', ' ');
    return value;
}

void SendError(ChatHandler* handler, std::string const& text)
{
    if (handler)
        handler->PSendSysMessage("[GC]|ERROR|{}", Sanitize(text));
}

bool ParseMode(std::string value, TitanRuneMode& mode)
{
    value = Lower(value);
    if (value == "alpha") { mode = TitanRuneMode::Alpha; return true; }
    if (value == "beta")  { mode = TitanRuneMode::Beta; return true; }
    if (value == "gamma") { mode = TitanRuneMode::Gamma; return true; }
    return false;
}

uint32 DungeonMapId(std::string const& activity)
{
    static std::unordered_map<std::string, uint32> const maps = {
        { "utgarde_keep", 574 }, { "nexus", 576 }, { "azjol_nerub", 601 }, { "ahnkahet", 619 },
        { "drak_tharon", 600 }, { "violet_hold", 608 }, { "gundrak", 604 }, { "halls_of_stone", 599 },
        { "halls_of_lightning", 602 }, { "oculus", 578 }, { "culling", 595 }, { "utgarde_pinnacle", 575 },
        { "trial_champion", 650 }, { "forge_souls", 632 }, { "pit_saron", 658 }, { "halls_reflection", 668 },
    };
    auto itr = maps.find(Lower(activity));
    return itr == maps.end() ? 0 : itr->second;
}

uint8 RoleMask(char token, bool leader)
{
    uint8 role = 0;
    switch (static_cast<char>(std::toupper(static_cast<unsigned char>(token))))
    {
        case 'T': role = lfg::PLAYER_ROLE_TANK; break;
        case 'H': role = lfg::PLAYER_ROLE_HEALER; break;
        case 'D': role = lfg::PLAYER_ROLE_DAMAGE; break;
        default: return 0;
    }
    if (leader)
        role |= lfg::PLAYER_ROLE_LEADER;
    return role;
}

bool ParseRoster(std::string const& encoded, std::unordered_map<std::string, char>& roles)
{
    roles.clear();
    std::size_t start = 0;
    while (start < encoded.size())
    {
        std::size_t comma = encoded.find(',', start);
        std::string item = encoded.substr(start, comma == std::string::npos ? std::string::npos : comma - start);
        std::size_t colon = item.rfind(':');
        if (colon == std::string::npos || colon == 0 || colon + 2 != item.size())
            return false;

        std::string name = Lower(item.substr(0, colon));
        char role = static_cast<char>(std::toupper(static_cast<unsigned char>(item[colon + 1])));
        if ((role != 'T' && role != 'H' && role != 'D') || !roles.emplace(name, role).second)
            return false;

        if (comma == std::string::npos)
            break;
        start = comma + 1;
    }
    return roles.size() == 5;
}

std::vector<uint32> TitanCandidateMaps(TitanRuneMode mode)
{
    static std::array<uint32, 16> const all = {
        574, 575, 576, 578, 595, 599, 600, 601,
        602, 604, 608, 619, 650, 632, 658, 668,
    };

    std::vector<uint32> maps;
    for (uint32 mapId : all)
        if (TitanRune::IsSupportedDungeon(mapId, mode))
            maps.push_back(mapId);
    return maps;
}

class GroupComposerTitanRuneCommand final : public CommandScript
{
public:
    GroupComposerTitanRuneCommand() : CommandScript("GroupComposerTitanRuneCommand") { }

    ChatCommandTable GetCommands() const override
    {
        static ChatCommandTable sub = {
            { "queue", HandleQueue, SEC_PLAYER, Console::No },
        };
        static ChatCommandTable root = { { "gctitan", sub } };
        return root;
    }

    static bool HandleQueue(ChatHandler* handler, std::string modeText, std::string activity, std::string roster)
    {
        Player* master = handler && handler->GetSession() ? handler->GetSession()->GetPlayer() : nullptr;
        if (!master)
            return true;

        if (!EraPolicy::IsEraReleased(EraPolicy::Era::Wotlk))
        {
            SendError(handler, "Titan Rune protocols are locked until Wrath of the Lich King is released.");
            return true;
        }

        TitanRuneMode mode = TitanRuneMode::Off;
        if (!ParseMode(modeText, mode))
        {
            SendError(handler, "Titan Rune mode must be Alpha, Beta or Gamma.");
            return true;
        }

        Group* group = master->GetGroup();
        if (!group || group->GetMembersCount() != 5)
        {
            SendError(handler, "Titan Rune handoff requires the complete assembled five-player party.");
            return true;
        }
        if (group->isRaidGroup())
        {
            SendError(handler, "Titan Rune Dungeon Finder handoff requires a normal five-player party, not raid format.");
            return true;
        }
        if (!group->IsLeader(master->GetGUID()))
        {
            SendError(handler, "Only the party leader can select the Titan Rune protocol and queue the assembled party.");
            return true;
        }

        std::unordered_map<std::string, char> requestedRoles;
        if (!ParseRoster(roster, requestedRoles))
        {
            SendError(handler, "The reviewed five-player role snapshot could not be decoded. Find Roster again before queueing.");
            return true;
        }

        std::unordered_set<std::string> liveNames;
        std::vector<std::pair<ObjectGuid, uint8>> memberRoles;
        memberRoles.reserve(5);
        uint8 leaderRole = 0;
        for (Group::MemberSlot const& slot : group->GetMemberSlots())
        {
            Player* member = ObjectAccessor::FindConnectedPlayer(slot.guid);
            if (!member)
            {
                SendError(handler, "Every assembled party member must be online before entering Dungeon Finder.");
                return true;
            }

            std::string key = Lower(member->GetName());
            auto roleItr = requestedRoles.find(key);
            if (roleItr == requestedRoles.end() || !liveNames.insert(key).second)
            {
                SendError(handler, "The live party no longer matches the reviewed Group Composer roster. Find Roster again.");
                return true;
            }

            bool isLeader = slot.guid == master->GetGUID();
            uint8 mask = RoleMask(roleItr->second, isLeader);
            if (!mask)
            {
                SendError(handler, "A reviewed party role is invalid. Find Roster again.");
                return true;
            }
            if (isLeader)
                leaderRole = mask;
            memberRoles.emplace_back(slot.guid, mask);
        }

        if (liveNames.size() != requestedRoles.size() || !leaderRole)
        {
            SendError(handler, "The live party changed after the roster was reviewed. Find Roster again.");
            return true;
        }

        lfg::LfgDungeonSet dungeons;
        activity = Lower(activity);
        if (activity == "random")
        {
            for (uint32 mapId : TitanCandidateMaps(mode))
            {
                if (LFGDungeonEntry const* entry = GetLFGDungeon(mapId, DUNGEON_DIFFICULTY_HEROIC))
                    dungeons.insert(entry->ID);
            }
            if (dungeons.empty())
            {
                SendError(handler, "No Heroic Dungeon Finder entries are available for the selected Titan Rune protocol.");
                return true;
            }
        }
        else
        {
            uint32 mapId = DungeonMapId(activity);
            if (!mapId)
            {
                SendError(handler, "Unknown dungeon selection for Titan Rune handoff.");
                return true;
            }
            if (!TitanRune::IsSupportedDungeon(mapId, mode))
            {
                SendError(handler, std::string("Defense Protocol ") + TitanRune::ModeName(mode) + " is not supported by that dungeon on this realm.");
                return true;
            }
            LFGDungeonEntry const* entry = GetLFGDungeon(mapId, DUNGEON_DIFFICULTY_HEROIC);
            if (!entry)
            {
                SendError(handler, "The selected Titan Rune dungeon has no Heroic Dungeon Finder entry on this client/server build.");
                return true;
            }
            dungeons.insert(entry->ID);
        }

        // The Titan Rune module treats the real group leader's persisted selection as authoritative
        // when the Heroic instance is created. Set it only after every membership/role/RDF validation
        // has passed, then queue the same reviewed five-player roster through stock LFG plumbing.
        TitanRune::SaveSelectedMode(master, mode);
        group->SetDungeonDifficulty(DUNGEON_DIFFICULTY_HEROIC);

        sLFGMgr->JoinLfg(master, leaderRole, dungeons, "Group Composer Titan Rune");
        for (auto const& entry : memberRoles)
            sLFGMgr->UpdateRoleCheck(group->GetGUID(), entry.first, entry.second);
        master->UpdateLFGChannel();

        handler->PSendSysMessage("[GC]|DONE|Defense Protocol {} selected; party queued for {} eligible Heroic dungeon{}.",
            TitanRune::ModeName(mode), uint32(dungeons.size()), dungeons.size() == 1 ? "" : "s");
        return true;
    }
};
}

void AddGroupComposerTitanRuneScripts()
{
    new GroupComposerTitanRuneCommand();
}
