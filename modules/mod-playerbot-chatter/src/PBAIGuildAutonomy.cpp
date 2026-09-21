#include "PBAIGuildAutonomy.h"

#include "Config.h"
#include "DatabaseEnv.h"
#include "Event.h"
#include "Field.h"
#include "Log.h"
#include "ObjectAccessor.h"
#include "ObjectGuid.h"
#include "PBAIGuildServices.h"
#include "PBAIGuildStore.h"
#include "Player.h"
#include "PlayerbotAI.h"
#include "PlayerbotGuildMgr.h"
#include "Playerbots.h"
#include "QueryResult.h"
#include "Random.h"
#include "ScriptMgr.h"
#include "SharedDefines.h"
#include "WorldSession.h"

#include <algorithm>
#include <cstdint>
#include <string>
#include <unordered_map>
#include <vector>

namespace
{
bool g_enable = true;
bool g_economyEnable = true;
bool g_auctionEnable = true;
uint32 g_tickMs = 60000;
uint32 g_minActivityMinutes = 5;
uint32 g_maxActivityMinutes = 12;
std::unordered_map<uint32, uint32> g_nextGuildActivityMs;

struct GuildSnapshot
{
    uint32 guildId = 0;
    std::string name;
    std::vector<Player*> bots;
    std::vector<Player*> humans;
};

bool IsManagedBot(Player* player)
{
    if (!player || !player->IsInWorld())
        return false;

    PlayerbotAI* ai = GET_PLAYERBOT_AI(player);
    if (!ai)
        return false;

    WorldSession* session = player->GetSession();
    return !session || session->IsBot();
}

bool IsHuman(Player* player)
{
    return player && player->IsInWorld() && player->GetSession() && !player->GetSession()->IsBot();
}

bool DoAction(Player* bot, char const* action, std::string const& param = {})
{
    if (!bot || bot->IsInCombat())
        return false;

    PlayerbotAI* ai = GET_PLAYERBOT_AI(bot);
    if (!ai)
        return false;

    return ai->DoSpecificAction(action, Event("ai guild autonomy", param), true);
}

void GuildSay(Player* bot, std::string const& text)
{
    if (!bot)
        return;
    if (PlayerbotAI* ai = GET_PLAYERBOT_AI(bot))
        ai->SayToGuild(text);
}

void Remember(Player* bot, GuildSnapshot const& guild, std::string const& type,
              std::string const& summary, uint8 importance = 45)
{
    if (!bot)
        return;

    uint32 const botGuid = bot->GetGUID().GetCounter();
    uint64 const eventId = PBAIGuildStore::RecordEvent(type, botGuid, 0, bot->GetMapId(), 0, summary);
    PBAIGuildStore::AddMemory(botGuid, eventId, type, importance, 0, 0, summary);

    for (Player* human : guild.humans)
    {
        if (!human)
            continue;
        PBAIGuildStore::TouchRelationship(botGuid, 0, human->GetGUID().GetCounter(), 1, 0, 1, false);
    }
}

std::vector<GuildSnapshot> BuildSnapshots()
{
    std::vector<GuildSnapshot> snapshots;
    QueryResult guilds = CharacterDatabase.Query("SELECT guildid,name FROM guild ORDER BY guildid");
    if (!guilds)
        return snapshots;

    do
    {
        Field* guildFields = guilds->Fetch();
        uint32 const guildId = guildFields[0].Get<uint32>();
        if (!PlayerbotGuildMgr::instance().IsRealGuild(guildId))
            continue;

        GuildSnapshot snapshot;
        snapshot.guildId = guildId;
        snapshot.name = guildFields[1].Get<std::string>();

        QueryResult members = CharacterDatabase.Query("SELECT guid FROM guild_member WHERE guildid={}", guildId);
        if (members)
        {
            do
            {
                ObjectGuid const guid = ObjectGuid::Create<HighGuid::Player>(members->Fetch()[0].Get<uint32>());
                Player* player = ObjectAccessor::FindPlayer(guid);
                if (!player || !player->IsInWorld())
                    continue;

                if (IsManagedBot(player))
                    snapshot.bots.push_back(player);
                else if (IsHuman(player))
                    snapshot.humans.push_back(player);
            } while (members->NextRow());
        }

        snapshots.push_back(std::move(snapshot));
    } while (guilds->NextRow());

    return snapshots;
}

bool IsCrafter(Player* bot)
{
    return bot && (bot->HasSkill(SKILL_ALCHEMY) || bot->HasSkill(SKILL_BLACKSMITHING) ||
        bot->HasSkill(SKILL_ENCHANTING) || bot->HasSkill(SKILL_ENGINEERING) ||
        bot->HasSkill(SKILL_JEWELCRAFTING) || bot->HasSkill(SKILL_LEATHERWORKING) ||
        bot->HasSkill(SKILL_TAILORING) || bot->HasSkill(SKILL_COOKING));
}

bool IsGatherer(Player* bot)
{
    return bot && (bot->HasSkill(SKILL_MINING) || bot->HasSkill(SKILL_HERBALISM) ||
        bot->HasSkill(SKILL_SKINNING) || bot->HasSkill(SKILL_FISHING));
}

Player* RandomAvailable(std::vector<Player*> const& bots)
{
    std::vector<Player*> candidates;
    candidates.reserve(bots.size());
    for (Player* bot : bots)
        if (bot && !bot->IsInCombat())
            candidates.push_back(bot);

    if (candidates.empty())
        return nullptr;
    return candidates[urand(0, uint32(candidates.size() - 1))];
}

void RunProfessionSession(GuildSnapshot const& guild)
{
    std::vector<Player*> workers;
    for (Player* bot : guild.bots)
        if (bot && !bot->IsInCombat() && (IsCrafter(bot) || IsGatherer(bot)))
            workers.push_back(bot);

    if (workers.empty())
        return;

    Player* announcer = workers[urand(0, uint32(workers.size() - 1))];
    uint32 actions = 0;
    uint32 economyActions = 0;
    for (Player* bot : workers)
    {
        bool acted = false;

        if (g_economyEnable)
        {
            if (PBAIGuildServices::SupplyQueuedFromBot(bot))
            {
                acted = true;
                ++economyActions;
            }

            if (IsCrafter(bot) && PBAIGuildServices::TryCraftQueuedFromBot(bot))
            {
                acted = true;
                ++economyActions;
            }
        }

        if (IsCrafter(bot))
        {
            acted |= PBAIGuildServices::TryCraftAllowedFromBot(bot);
            acted |= DoAction(bot, "rpg trade useful");
        }
        if (IsGatherer(bot))
        {
            acted |= DoAction(bot, "choose travel target");
            acted |= DoAction(bot, "move to travel target");
        }

        if (g_economyEnable && urand(0, 3) == 0 && PBAIGuildServices::ContributeSurplusFromBot(bot))
        {
            acted = true;
            ++economyActions;
        }

        if (acted)
            ++actions;
    }

    if (!actions)
        return;

    if (g_economyEnable)
        PBAIGuildServices::ProcessQueuedGuild(guild.guildId);

    GuildSay(announcer, "doing a profession and mats run for the guild, shout if you need something crafted");
    Remember(announcer, guild, "guild_profession",
        std::to_string(actions) + " guild bots performed real crafting, gathering or material-trade actions; " +
        std::to_string(economyActions) + " conserved-stock/craft request actions were completed.", 55);
}

void RunSupplySession(GuildSnapshot const& guild)
{
    Player* bot = RandomAvailable(guild.bots);
    if (!bot)
        return;

    bool acted = false;
    if (g_economyEnable)
        acted |= PBAIGuildServices::SupplyQueuedFromBot(bot);

    acted |= DoAction(bot, "check mail");
    acted |= DoAction(bot, "rpg trade useful");
    acted |= DoAction(bot, "rpg sell");
    // Playerbots' GuildBankAction requires an item-selection payload. "materials" resolves the
    // bot's actual trade-material stacks and moves them through the real guild-bank API when a
    // guild bank is nearby and the bot rank has deposit rights.
    acted |= DoAction(bot, "guild bank", "materials");

    if (g_auctionEnable)
        acted |= PBAIGuildServices::ListSurplusOnAuction(bot);

    if (!acted)
    {
        acted |= DoAction(bot, "choose travel target");
        acted |= DoAction(bot, "move to travel target");
    }

    if (!acted)
        return;

    if (g_economyEnable)
        PBAIGuildServices::ProcessQueuedGuild(guild.guildId);

    GuildSay(bot, "sorting mail, spare mats, market listings and guild supplies for a bit");
    Remember(bot, guild, "guild_supply",
        "Handled real mail, useful-item trades, vendor/guild-bank activity or an actual auction listing for the guild.", 50);
}

void RunMarketSession(GuildSnapshot const& guild)
{
    if (!g_auctionEnable)
        return;

    Player* bot = RandomAvailable(guild.bots);
    if (!bot)
        return;

    if (!PBAIGuildServices::ListSurplusOnAuction(bot))
        return;

    GuildSay(bot, "put a spare stack on the auction house instead of vendoring it");
    Remember(bot, guild, "guild_market",
        "Listed a real inventory stack on the AzerothCore auction house and paid the normal deposit.", 45);
}

void RunSocialSession(GuildSnapshot const& guild)
{
    Player* bot = RandomAvailable(guild.bots);
    if (!bot)
        return;

    bool acted = DoAction(bot, "guild manage nearby");
    if (urand(0, 1) == 1)
        acted |= DoAction(bot, "invite nearby");

    if (!acted)
        return;

    GuildSay(bot, "if you meet someone solid out there, bring them along rather than leaving them solo");
    Remember(bot, guild, "guild_social",
        "Handled real nearby guild-management, promotion/demotion, recruitment or spontaneous grouping actions.", 45);
}

void RunGroupSession(GuildSnapshot const& guild, bool raid)
{
    std::vector<Player*> freeBots;
    for (Player* bot : guild.bots)
        if (bot && !bot->IsInCombat() && !bot->GetGroup())
            freeBots.push_back(bot);

    uint32 const minimum = raid ? 8u : 3u;
    if (freeBots.size() < minimum)
        return;

    Player* leader = freeBots.front();
    if (!DoAction(leader, "invite guild"))
        return;

    DoAction(leader, "choose travel target");
    DoAction(leader, "move to travel target");
    GuildSay(leader, raid ? "putting a raid group together, hop in if you're free" :
                           "starting a dungeon group, anyone free can jump in");
    Remember(leader, guild, raid ? "guild_raid_group" : "guild_dungeon_group",
        raid ? "Started a real autonomous guild raid-group formation attempt."
             : "Started a real autonomous guild dungeon-group formation attempt.", 65);
}

void StrengthenSharedGuildHistory(GuildSnapshot const& guild)
{
    for (Player* bot : guild.bots)
    {
        if (!bot || !bot->GetGroup())
            continue;

        uint32 const botGuid = bot->GetGUID().GetCounter();
        for (Player* human : guild.humans)
        {
            if (!human || human->GetGroup() != bot->GetGroup())
                continue;
            PBAIGuildStore::TouchRelationship(botGuid, 0, human->GetGUID().GetCounter(), 2, 1, 1, false);
        }
    }
}

void RunGuildActivity(GuildSnapshot const& guild)
{
    if (guild.bots.empty())
        return;

    StrengthenSharedGuildHistory(guild);
    if (g_economyEnable)
        PBAIGuildServices::ProcessQueuedGuild(guild.guildId);

    switch (urand(0, 7))
    {
        case 0: RunProfessionSession(guild); break;
        case 1: RunSupplySession(guild); break;
        case 2: RunSocialSession(guild); break;
        case 3: RunGroupSession(guild, false); break;
        case 4: RunGroupSession(guild, true); break;
        case 5: RunMarketSession(guild); break;
        default:
        {
            Player* bot = RandomAvailable(guild.bots);
            if (!bot)
                break;
            bool acted = DoAction(bot, "choose travel target");
            acted |= DoAction(bot, "move to travel target");
            if (acted)
                Remember(bot, guild, "guild_free_time",
                    "Went out into the world for ordinary questing, farming or travel instead of idling in town.", 35);
            break;
        }
    }
}

class PBAIGuildAutonomyWorldScript final : public WorldScript
{
public:
    PBAIGuildAutonomyWorldScript() : WorldScript("PBAIGuildAutonomyWorldScript") { }

    void OnAfterConfigLoad(bool /*reload*/) override
    {
        g_enable = sConfigMgr->GetOption<bool>("PlayerbotChatter.GuildAutonomyEnable", true);
        g_economyEnable = sConfigMgr->GetOption<bool>("PlayerbotChatter.GuildEconomyEnable", true);
        g_auctionEnable = sConfigMgr->GetOption<bool>("PlayerbotChatter.GuildAuctionEnable", true);
        g_tickMs = std::max<uint32>(30000, sConfigMgr->GetOption<uint32>("PlayerbotChatter.GuildAutonomyTickSeconds", 60) * 1000u);
        g_minActivityMinutes = std::max<uint32>(1, sConfigMgr->GetOption<uint32>("PlayerbotChatter.GuildAutonomyMinMinutes", 5));
        g_maxActivityMinutes = std::max<uint32>(g_minActivityMinutes,
            sConfigMgr->GetOption<uint32>("PlayerbotChatter.GuildAutonomyMaxMinutes", 12));
    }

    void OnUpdate(uint32 diff) override
    {
        PBAIGuildServices::UpdateAsyncTransactions();

        if (!g_enable)
            return;

        _tick += diff;
        if (_tick < g_tickMs)
            return;
        _tick %= g_tickMs;

        for (GuildSnapshot const& guild : BuildSnapshots())
        {
            if (g_economyEnable)
                PBAIGuildServices::ProcessQueuedGuild(guild.guildId);

            uint32& remaining = g_nextGuildActivityMs[guild.guildId];
            if (remaining > g_tickMs)
            {
                remaining -= g_tickMs;
                StrengthenSharedGuildHistory(guild);
                continue;
            }

            RunGuildActivity(guild);
            remaining = urand(g_minActivityMinutes, g_maxActivityMinutes) * 60u * 1000u;
        }
    }

private:
    uint32 _tick = 0;
};
}

void AddPBAIGuildAutonomyScripts()
{
    LOG_INFO("server.loading", "[GuildAutonomy] Registering real Playerbot guild-life, profession and auction actions.");
    new PBAIGuildAutonomyWorldScript();
}
