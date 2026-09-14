#include "PBAIGuildLife.h"

#include "Chat.h"
#include "DatabaseEnv.h"
#include "Field.h"
#include "Log.h"
#include "PBAIGuildStore.h"
#include "Player.h"
#include "Playerbots.h"
#include "QueryResult.h"
#include "ScriptMgr.h"
#include "WorldSession.h"
#include "WorldSessionMgr.h"

#include <algorithm>
#include <ctime>
#include <string>
#include <unordered_map>
#include <vector>

namespace
{
constexpr uint32 TICK_MS = 60000;
constexpr uint64 COPPER_PER_GOLD = 10000;
constexpr uint64 MAX_DAILY_PROFESSION_COPPER = 50 * COPPER_PER_GOLD;
uint32 g_tick = 0;

struct DailyFocus
{
    std::string type;
    std::string title;
    std::string summary;
};

struct ProfessionDay
{
    uint32 bots = 0;
    uint32 kinds = 0;
    uint64 copper = 0;
};

DailyFocus MakeFocus(uint32 guildId)
{
    uint64 day = static_cast<uint64>(std::time(nullptr)) / 86400u;
    switch ((guildId * 2654435761u + static_cast<uint32>(day)) % 5u)
    {
        case 0:
            return { "dungeon", "Dungeon night",
                "Form balanced five-player groups, help guildmates with progression, and turn wipes into shared stories." };
        case 1:
            return { "raid", "Raid practice",
                "Review grounded encounter briefs, repair and restock, then practice the next unlocked raid without skipping progression." };
        case 2:
            return { "profession", "Profession drive",
                "Crafters and gatherers are the focus today. Use the guild vault and work-order services to keep useful supplies moving." };
        case 3:
            return { "pvp", "Battleground patrol",
                "Queue some PvP with guildmates, keep groups social, and treat wins and losses as part of the guild history." };
        default:
            return { "exploration", "Adventure day",
                "Help with quests, hunt achievements and rares, or revisit an unlocked zone together instead of idling in town." };
    }
}

DailyFocus EnsureFocus(uint32 guildId)
{
    if (QueryResult result = CharacterDatabase.Query(
        "SELECT focus_type, title, summary FROM mod_ai_guild_life_day "
        "WHERE guild_id = {} AND activity_date = CURDATE() LIMIT 1",
        guildId))
    {
        Field* f = result->Fetch();
        return { f[0].Get<std::string>(), f[1].Get<std::string>(), f[2].Get<std::string>() };
    }

    DailyFocus focus = MakeFocus(guildId);
    std::string type = focus.type;
    std::string title = focus.title;
    std::string summary = focus.summary;
    CharacterDatabase.EscapeString(type);
    CharacterDatabase.EscapeString(title);
    CharacterDatabase.EscapeString(summary);
    CharacterDatabase.DirectExecute(
        "INSERT IGNORE INTO mod_ai_guild_life_day "
        "(guild_id, activity_date, focus_type, title, summary) VALUES ({}, CURDATE(), '{}', '{}', '{}')",
        guildId, type, title, summary);

    PBAIGuildStore::RecordEvent("guild_focus", 0, guildId, 0, 0,
        "Guild focus: " + focus.title + ". " + focus.summary);
    return focus;
}

ProfessionDay ReadProfessionDay(uint32 guildId)
{
    ProfessionDay day;
    if (QueryResult result = CharacterDatabase.Query(
        "SELECT contributing_bots, profession_kinds, contribution_copper FROM mod_ai_guild_profession_day "
        "WHERE guild_id = {} AND activity_date = CURDATE() LIMIT 1",
        guildId))
    {
        Field* f = result->Fetch();
        day.bots = f[0].Get<uint32>();
        day.kinds = f[1].Get<uint32>();
        day.copper = f[2].Get<uint64>();
    }
    return day;
}

ProfessionDay EnsureProfessionDay(uint32 guildId)
{
    if (QueryResult existing = CharacterDatabase.Query(
        "SELECT contributing_bots, profession_kinds, contribution_copper, credited "
        "FROM mod_ai_guild_profession_day WHERE guild_id = {} AND activity_date = CURDATE() LIMIT 1",
        guildId))
    {
        Field* f = existing->Fetch();
        ProfessionDay day{ f[0].Get<uint32>(), f[1].Get<uint32>(), f[2].Get<uint64>() };
        if (f[3].Get<uint8>() != 0 || !day.copper)
            return day;

        CharacterDatabase.DirectExecute("INSERT IGNORE INTO mod_ai_guild_economy (guild_id) VALUES ({})", guildId);
        CharacterDatabase.DirectExecute(
            "UPDATE mod_ai_guild_economy SET money_copper = money_copper + {}, earned_copper = earned_copper + {}, "
            "updated_at = CURRENT_TIMESTAMP WHERE guild_id = {}",
            day.copper, day.copper, guildId);
        CharacterDatabase.DirectExecute(
            "UPDATE mod_ai_guild_profession_day SET credited = 1 WHERE guild_id = {} AND activity_date = CURDATE()",
            guildId);
        return day;
    }

    uint32 skilledBots = 0;
    uint32 professionKinds = 0;
    if (QueryResult result = CharacterDatabase.Query(
        "SELECT COUNT(DISTINCT rr.bot_guid), COUNT(DISTINCT cs.skill) "
        "FROM guild_member gm "
        "INNER JOIN mod_raid_roster rr ON rr.bot_guid = gm.guid "
        "INNER JOIN character_skills cs ON cs.guid = gm.guid "
        "WHERE gm.guildid = {} AND cs.value > 0 AND cs.skill IN (129,164,165,171,182,185,186,197,202,333,356,393,755,773)",
        guildId))
    {
        Field* f = result->Fetch();
        skilledBots = f[0].Get<uint32>();
        professionKinds = f[1].Get<uint32>();
    }

    uint64 contribution = std::min<uint64>(
        MAX_DAILY_PROFESSION_COPPER,
        uint64(skilledBots) * 2500u + uint64(professionKinds) * COPPER_PER_GOLD);

    CharacterDatabase.DirectExecute(
        "INSERT IGNORE INTO mod_ai_guild_profession_day "
        "(guild_id, activity_date, contributing_bots, profession_kinds, contribution_copper, credited) "
        "VALUES ({}, CURDATE(), {}, {}, {}, 0)",
        guildId, skilledBots, professionKinds, contribution);

    ProfessionDay day = ReadProfessionDay(guildId);
    if (day.copper)
    {
        CharacterDatabase.DirectExecute("INSERT IGNORE INTO mod_ai_guild_economy (guild_id) VALUES ({})", guildId);
        CharacterDatabase.DirectExecute(
            "UPDATE mod_ai_guild_economy SET money_copper = money_copper + {}, earned_copper = earned_copper + {}, "
            "updated_at = CURRENT_TIMESTAMP WHERE guild_id = {}",
            day.copper, day.copper, guildId);
        CharacterDatabase.DirectExecute(
            "UPDATE mod_ai_guild_profession_day SET credited = 1 WHERE guild_id = {} AND activity_date = CURDATE()",
            guildId);
    }
    return day;
}

std::string MoneyText(uint64 copper)
{
    uint64 gold = copper / COPPER_PER_GOLD;
    copper %= COPPER_PER_GOLD;
    uint64 silver = copper / 100;
    return std::to_string(gold) + "g " + std::to_string(silver) + "s";
}

void UpdateAttendance(Player* player, DailyFocus const& focus, ProfessionDay const& professionDay)
{
    if (!player || !player->GetGuildId())
        return;

    uint32 guildId = player->GetGuildId();
    uint32 guid = player->GetGUID().GetCounter();
    CharacterDatabase.DirectExecute(
        "INSERT INTO mod_ai_guild_life_member "
        "(guild_id, player_guid, activity_date, online_minutes, recognition_level, noticed) "
        "VALUES ({}, {}, CURDATE(), 1, 0, 0) "
        "ON DUPLICATE KEY UPDATE online_minutes = LEAST(1440, online_minutes + 1), updated_at = CURRENT_TIMESTAMP",
        guildId, guid);

    QueryResult state = CharacterDatabase.Query(
        "SELECT online_minutes, recognition_level, noticed FROM mod_ai_guild_life_member "
        "WHERE guild_id = {} AND player_guid = {} AND activity_date = CURDATE() LIMIT 1",
        guildId, guid);
    if (!state)
        return;

    Field* f = state->Fetch();
    uint32 minutes = f[0].Get<uint32>();
    uint8 recognition = f[1].Get<uint8>();
    bool noticed = f[2].Get<uint8>() != 0;

    if (!noticed && player->GetSession())
    {
        ChatHandler handler(player->GetSession());
        handler.PSendSysMessage("[Guild Life] {}: {}", focus.title, focus.summary);
        if (professionDay.copper)
            handler.PSendSysMessage(
                "[Guild Economy] {} persistent roster crafter(s), covering {} profession type(s), contributed {} to the treasury today.",
                professionDay.bots, professionDay.kinds, MoneyText(professionDay.copper));
        CharacterDatabase.DirectExecute(
            "UPDATE mod_ai_guild_life_member SET noticed = 1 WHERE guild_id = {} AND player_guid = {} AND activity_date = CURDATE()",
            guildId, guid);
    }

    if (minutes >= 180 && recognition < 2 && player->GetSession())
    {
        ChatHandler(player->GetSession()).SendSysMessage(
            "[Guild Life] You have been around the guild for three hours today. The guild remembers regulars, not just raid slots.");
        CharacterDatabase.DirectExecute(
            "UPDATE mod_ai_guild_life_member SET recognition_level = 2 WHERE guild_id = {} AND player_guid = {} AND activity_date = CURDATE()",
            guildId, guid);
    }
    else if (minutes >= 60 && recognition < 1 && player->GetSession())
    {
        ChatHandler(player->GetSession()).SendSysMessage(
            "[Guild Life] One hour together today. Your attendance is now part of the persistent guild record.");
        CharacterDatabase.DirectExecute(
            "UPDATE mod_ai_guild_life_member SET recognition_level = 1 WHERE guild_id = {} AND player_guid = {} AND activity_date = CURDATE()",
            guildId, guid);
    }
}

class PBAIGuildLifeWorldScript : public WorldScript
{
public:
    PBAIGuildLifeWorldScript() : WorldScript("PBAIGuildLifeWorldScript") { }

    void OnUpdate(uint32 diff) override
    {
        g_tick += diff;
        if (g_tick < TICK_MS)
            return;
        g_tick = 0;

        std::unordered_map<uint32, std::vector<Player*>> guildPlayers;
        WorldSessionMgr::SessionMap const& sessions = sWorldSessionMgr->GetAllSessions();
        for (auto const& [accountId, session] : sessions)
        {
            (void)accountId;
            Player* player = session ? session->GetPlayer() : nullptr;
            if (!player || !player->IsInWorld() || !IsRealPlayer(player) || !player->GetGuildId())
                continue;
            guildPlayers[player->GetGuildId()].push_back(player);
        }

        for (auto const& [guildId, players] : guildPlayers)
        {
            DailyFocus focus = EnsureFocus(guildId);
            ProfessionDay professionDay = EnsureProfessionDay(guildId);
            for (Player* player : players)
                UpdateAttendance(player, focus, professionDay);
        }
    }
};
}

void AddPBAIGuildLifeScripts()
{
    LOG_INFO("server.loading", "[GuildLife] Registering persistent guild-life and profession economy director.");
    new PBAIGuildLifeWorldScript();
}
