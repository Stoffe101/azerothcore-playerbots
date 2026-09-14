#include "Chat.h"
#include "Config.h"
#include "DatabaseEnv.h"
#include "Event.h"
#include "Field.h"
#include "Guild.h"
#include "GuildMgr.h"
#include "ObjectAccessor.h"
#include "ObjectGuid.h"
#include "Player.h"
#include "PlayerbotAI.h"
#include "Playerbots.h"
#include "PlayerbotGuildMgr.h"
#include "QueryResult.h"
#include "Random.h"
#include "ScriptMgr.h"
#include "SharedDefines.h"
#include "StringFormat.h"

#include <algorithm>
#include <ctime>
#include <set>
#include <sstream>
#include <string>
#include <unordered_map>
#include <vector>

namespace
{
    bool g_enable = true;
    uint32 g_tickMs = 300000;
    uint32 g_offlineCapHours = 48;

    bool IsManagedBot(Player* player)
    {
        if (!player)
            return false;
        PlayerbotAI* ai = GET_PLAYERBOT_AI(player);
        return ai && !IsSelfBot(player);
    }

    struct GuildSnapshot
    {
        uint32 guildId = 0;
        std::string name;
        std::vector<Player*> onlineBots;
        std::vector<Player*> onlineHumans;
    };

    void Journal(uint32 guildId, uint32 actorGuid, std::string type, std::string summary)
    {
        CharacterDatabase.EscapeString(type);
        CharacterDatabase.EscapeString(summary);
        CharacterDatabase.Execute(Acore::StringFormat(
            "INSERT INTO mod_living_world_guild_activity (guild_id,actor_guid,activity_type,summary) "
            "VALUES ({},{},'{}','{}')", guildId, actorGuid, type, summary));
    }

    void BumpMember(Player* bot, uint32 guildId, uint32 attendance, uint32 helpful, uint32 economy)
    {
        if (!bot)
            return;
        CharacterDatabase.Execute(
            "INSERT INTO mod_living_world_member (guid,guild_id,attendance_points,helpfulness_points,economy_points,last_active) "
            "VALUES ({},{},{},{},{},NOW()) ON DUPLICATE KEY UPDATE guild_id=VALUES(guild_id), "
            "attendance_points=attendance_points+VALUES(attendance_points), helpfulness_points=helpfulness_points+VALUES(helpfulness_points), "
            "economy_points=economy_points+VALUES(economy_points), last_active=NOW()",
            bot->GetGUID().GetCounter(), guildId, attendance, helpful, economy);
    }

    void GuildSay(Player* bot, std::string const& text)
    {
        if (!bot)
            return;
        if (PlayerbotAI* ai = GET_PLAYERBOT_AI(bot))
            ai->SayToGuild(text);
    }

    std::vector<GuildSnapshot> Snapshots()
    {
        std::vector<GuildSnapshot> out;
        QueryResult result = CharacterDatabase.Query("SELECT guildid,name FROM guild ORDER BY guildid");
        if (!result)
            return out;
        do
        {
            Field* f = result->Fetch();
            uint32 gid = f[0].Get<uint32>();
            if (!PlayerbotGuildMgr::instance().IsRealGuild(gid))
                continue; // autonomous director belongs to player-led guilds, not synthetic bot guilds

            GuildSnapshot snap;
            snap.guildId = gid;
            snap.name = f[1].Get<std::string>();
            QueryResult members = CharacterDatabase.Query("SELECT guid FROM guild_member WHERE guildid={}", gid);
            if (members)
            {
                do
                {
                    ObjectGuid guid = ObjectGuid::Create<HighGuid::Player>(members->Fetch()[0].Get<uint32>());
                    Player* p = ObjectAccessor::FindPlayer(guid);
                    if (!p || !p->IsInWorld())
                        continue;
                    if (IsManagedBot(p)) snap.onlineBots.push_back(p);
                    else snap.onlineHumans.push_back(p);
                } while (members->NextRow());
            }
            out.push_back(std::move(snap));
        } while (result->NextRow());
        return out;
    }

    std::string ProfessionLabel(Player* bot)
    {
        if (!bot) return "profession";
        std::vector<std::string> skills;
        if (bot->HasSkill(SKILL_MINING)) skills.push_back("mining");
        if (bot->HasSkill(SKILL_HERBALISM)) skills.push_back("herbalism");
        if (bot->HasSkill(SKILL_SKINNING)) skills.push_back("skinning");
        if (bot->HasSkill(SKILL_BLACKSMITHING)) skills.push_back("blacksmithing");
        if (bot->HasSkill(SKILL_ALCHEMY)) skills.push_back("alchemy");
        if (bot->HasSkill(SKILL_ENCHANTING)) skills.push_back("enchanting");
        if (bot->HasSkill(SKILL_ENGINEERING)) skills.push_back("engineering");
        if (bot->HasSkill(SKILL_JEWELCRAFTING)) skills.push_back("jewelcrafting");
        if (bot->HasSkill(SKILL_LEATHERWORKING)) skills.push_back("leatherworking");
        if (bot->HasSkill(SKILL_TAILORING)) skills.push_back("tailoring");
        if (skills.empty()) return "general supplies";
        return skills[urand(0, skills.size() - 1)];
    }

    bool IsCrafter(Player* bot)
    {
        return bot && (bot->HasSkill(SKILL_BLACKSMITHING) || bot->HasSkill(SKILL_ALCHEMY) ||
            bot->HasSkill(SKILL_ENCHANTING) || bot->HasSkill(SKILL_ENGINEERING) ||
            bot->HasSkill(SKILL_JEWELCRAFTING) || bot->HasSkill(SKILL_LEATHERWORKING) ||
            bot->HasSkill(SKILL_TAILORING));
    }

    bool IsGatherer(Player* bot)
    {
        return bot && (bot->HasSkill(SKILL_MINING) || bot->HasSkill(SKILL_HERBALISM) || bot->HasSkill(SKILL_SKINNING));
    }

    void DoAction(Player* bot, char const* action)
    {
        if (!bot || bot->IsInCombat())
            return;
        if (PlayerbotAI* ai = GET_PLAYERBOT_AI(bot))
            ai->DoSpecificAction(action, Event("living world"), true);
    }

    void ProfessionSession(GuildSnapshot const& g)
    {
        if (g.onlineBots.empty()) return;
        uint32 participants = 0;
        Player* announcer = g.onlineBots[urand(0, g.onlineBots.size() - 1)];
        for (Player* bot : g.onlineBots)
        {
            if (bot->IsInCombat()) continue;
            if (IsCrafter(bot))
            {
                DoAction(bot, "craft random item");
                DoAction(bot, "rpg trade useful");
                BumpMember(bot, g.guildId, 1, 2, 3);
                ++participants;
            }
            else if (IsGatherer(bot))
            {
                DoAction(bot, "choose travel target");
                DoAction(bot, "move to travel target");
                BumpMember(bot, g.guildId, 1, 2, 2);
                ++participants;
            }
        }
        GuildSay(announcer, "doing a guild profession/mats run for a bit, ping if you need anything crafted");
        Journal(g.guildId, announcer->GetGUID().GetCounter(), "profession",
                Acore::StringFormat("{} guild members coordinated gathering, crafting and material hand-offs.", participants));
    }

    void MarketSession(GuildSnapshot const& g)
    {
        if (g.onlineBots.empty()) return;
        Player* announcer = g.onlineBots[urand(0, g.onlineBots.size() - 1)];
        uint32 participants = 0;
        for (Player* bot : g.onlineBots)
        {
            if (bot->IsInCombat() || urand(0, 2) != 0) continue;
            DoAction(bot, "check mail");
            DoAction(bot, "rpg sell");
            DoAction(bot, "rpg trade useful");
            BumpMember(bot, g.guildId, 1, 1, 3);
            ++participants;
        }
        GuildSay(announcer, "sorting mats/mail and putting spare stuff back into circulation");
        Journal(g.guildId, announcer->GetGUID().GetCounter(), "economy",
                Acore::StringFormat("{} members handled mail, useful trades and market/vendor runs.", participants));
    }

    void BankSession(GuildSnapshot const& g)
    {
        if (g.onlineBots.empty()) return;
        Player* announcer = g.onlineBots[urand(0, g.onlineBots.size() - 1)];
        uint32 participants = 0;
        for (Player* bot : g.onlineBots)
        {
            if (bot->IsInCombat() || urand(0, 3) != 0) continue;
            // GuildBankAction acts only when a bot is genuinely at a guild bank. The director
            // also nudges city/RPG travel rather than teleporting inventory through the database.
            DoAction(bot, "choose travel target");
            DoAction(bot, "guild bank");
            BumpMember(bot, g.guildId, 1, 2, 2);
            ++participants;
        }
        GuildSay(announcer, "cleaning up guild supplies, don't vendor useful mats if somebody can use them");
        Journal(g.guildId, announcer->GetGUID().GetCounter(), "guild_bank",
                Acore::StringFormat("{} members made guild-bank and supply runs.", participants));
    }

    void GroupNight(GuildSnapshot const& g, bool raid)
    {
        if (g.onlineBots.size() < (raid ? 8u : 3u)) return;
        std::vector<Player*> free;
        for (Player* bot : g.onlineBots)
            if (!bot->GetGroup() && !bot->IsInCombat()) free.push_back(bot);
        if (free.size() < (raid ? 8u : 3u)) return;

        Player* leader = free.front();
        DoAction(leader, "invite guild");
        DoAction(leader, "choose travel target");
        GuildSay(leader, raid ? "putting a raid group together, join if you're free" : "starting a dungeon group, anyone free can jump in");
        for (Player* bot : free)
            BumpMember(bot, g.guildId, 2, 1, 0);
        Journal(g.guildId, leader->GetGUID().GetCounter(), raid ? "raid_night" : "dungeon_night",
                raid ? "Guild members organized an autonomous raid group." : "Guild members organized an autonomous dungeon group.");
    }

    void SocialManagement(GuildSnapshot const& g)
    {
        if (g.onlineBots.empty()) return;
        Player* bot = g.onlineBots[urand(0, g.onlineBots.size() - 1)];
        DoAction(bot, "guild manage nearby");
        if (urand(0,1)) DoAction(bot, "invite nearby");
        GuildSay(bot, "if you see someone solid while you're out, throw them an invite or bring them along");
        BumpMember(bot, g.guildId, 1, 3, 0);
        Journal(g.guildId, bot->GetGUID().GetCounter(), "guild_life", "Guild members handled recruitment, social grouping and routine guild management.");
    }

    void CreateEconomyDemand(GuildSnapshot const& g)
    {
        if (g.onlineBots.empty()) return;
        Player* requester = g.onlineBots[urand(0, g.onlineBots.size() - 1)];
        uint32 skill = 0;
        char const* note = "general guild supplies";
        switch (urand(0,6))
        {
            case 0: skill=SKILL_MINING; note="ore and bars for guild crafters"; break;
            case 1: skill=SKILL_HERBALISM; note="herbs for alchemy stock"; break;
            case 2: skill=SKILL_ALCHEMY; note="flasks, potions and elixirs"; break;
            case 3: skill=SKILL_BLACKSMITHING; note="plate and weapon crafting materials"; break;
            case 4: skill=SKILL_ENCHANTING; note="enchants and enchanting materials"; break;
            case 5: skill=SKILL_COOKING; note="raid food and cooking materials"; break;
            default: skill=SKILL_ENGINEERING; note="engineering consumables and parts"; break;
        }
        std::string escaped(note); CharacterDatabase.EscapeString(escaped);
        CharacterDatabase.Execute(
            "INSERT INTO mod_living_world_economy_order (guild_id,requester_guid,item_id,profession_skill,quantity,note) "
            "VALUES ({},{},0,{},1,'{}')", g.guildId, requester->GetGUID().GetCounter(), skill, escaped);
        GuildSay(requester, std::string("guild could use some ") + note + " if anyone's farming/crafting");
        Journal(g.guildId, requester->GetGUID().GetCounter(), "economy_demand", std::string("Guild demand created: ") + note + ".");
    }

    void FulfillEconomyDemand(GuildSnapshot const& g)
    {
        QueryResult order = CharacterDatabase.Query(
            "SELECT id,profession_skill,note FROM mod_living_world_economy_order WHERE guild_id={} AND fulfilled=0 ORDER BY created_at LIMIT 1",
            g.guildId);
        if (!order) return;
        Field* f = order->Fetch();
        uint64 id = f[0].Get<uint64>();
        uint32 skill = f[1].Get<uint32>();
        std::string note = f[2].Get<std::string>();
        std::vector<Player*> workers;
        for (Player* bot : g.onlineBots)
            if (!bot->IsInCombat() && (skill == 0 || bot->HasSkill(skill))) workers.push_back(bot);
        if (workers.empty()) return;

        Player* worker = workers[urand(0, workers.size() - 1)];
        if (IsCrafter(worker)) DoAction(worker, "craft random item");
        if (IsGatherer(worker)) { DoAction(worker, "choose travel target"); DoAction(worker, "move to travel target"); }
        DoAction(worker, "rpg trade useful");
        BumpMember(worker, g.guildId, 1, 3, 4);
        CharacterDatabase.Execute("UPDATE mod_living_world_economy_order SET fulfilled=1,fulfilled_at=NOW() WHERE id={}", id);
        GuildSay(worker, std::string("working on the guild request for ") + note);
        Journal(g.guildId, worker->GetGUID().GetCounter(), "economy_fulfilled", std::string("A profession dependency was fulfilled: ") + note + ".");
    }

    void RunGuildTick(GuildSnapshot const& g)
    {
        for (Player* bot : g.onlineBots)
            BumpMember(bot, g.guildId, 1, 0, 0);
        if (g.onlineBots.empty()) return;

        // First satisfy persistent profession demand, then schedule another slice of ordinary
        // guild life. These are real Playerbot actions where possible, not database theater.
        FulfillEconomyDemand(g);
        switch (urand(0, 7))
        {
            case 0: ProfessionSession(g); break;
            case 1: MarketSession(g); break;
            case 2: BankSession(g); break;
            case 3: GroupNight(g, false); break;
            case 4: GroupNight(g, true); break;
            case 5: SocialManagement(g); break;
            case 6: CreateEconomyDemand(g); break;
            default:
                for (Player* bot : g.onlineBots) if (urand(0,2)==0) DoAction(bot, "choose travel target");
                Journal(g.guildId, 0, "free_time", "Guild members spread out for questing, farming and spontaneous world activity.");
                break;
        }
    }

    void SimulateOfflineTime()
    {
        std::time_t now = std::time(nullptr);
        int64 last = 0;
        if (QueryResult q = CharacterDatabase.Query("SELECT value_bigint FROM mod_living_world_meta WHERE key_name='last_world_tick'"))
            last = q->Fetch()[0].Get<int64>();

        if (last > 0 && now > last)
        {
            uint32 hours = static_cast<uint32>(std::min<int64>(g_offlineCapHours, (now - last) / 3600));
            if (hours)
            {
                QueryResult guilds = CharacterDatabase.Query("SELECT guildid,name FROM guild ORDER BY guildid");
                if (guilds)
                {
                    do
                    {
                        Field* f = guilds->Fetch();
                        uint32 gid = f[0].Get<uint32>();
                        if (!PlayerbotGuildMgr::instance().IsRealGuild(gid)) continue;
                        // Offline simulation intentionally records/plans work instead of conjuring
                        // items or fake dungeon completions while no actual Playerbot AI is loaded.
                        uint32 cycles = std::max<uint32>(1, hours / 4);
                        for (uint32 i=0; i<cycles; ++i)
                        {
                            static char const* summaries[] = {
                                "While the server was unattended, guild members planned farming routes and queued profession needs for the next active session.",
                                "While offline, the guild kept a running supply list for consumables, materials and repairs.",
                                "Members informally organized the next dungeon/raid night and marked attendance interest.",
                                "Guild crafters and gatherers updated material requests so hand-offs can resume when bots are online."
                            };
                            Journal(gid, 0, "offline_continuity", summaries[urand(0,3)]);
                        }
                    } while (guilds->NextRow());
                }
            }
        }
        CharacterDatabase.Execute(
            "INSERT INTO mod_living_world_meta (key_name,value_bigint) VALUES ('last_world_tick',{}) "
            "ON DUPLICATE KEY UPDATE value_bigint=VALUES(value_bigint)", static_cast<int64>(now));
    }

    class LivingWorldScript : public WorldScript
    {
    public:
        LivingWorldScript() : WorldScript("LivingWorldScript") { }

        void OnAfterConfigLoad(bool /*reload*/) override
        {
            g_enable = sConfigMgr->GetOption<bool>("LivingWorld.Enable", true);
            g_tickMs = std::max<uint32>(60000, sConfigMgr->GetOption<uint32>("LivingWorld.TickSeconds", 300) * 1000u);
            g_offlineCapHours = std::max<uint32>(1, sConfigMgr->GetOption<uint32>("LivingWorld.OfflineSimulationCapHours", 48));
        }

        void OnStartup() override
        {
            if (g_enable) SimulateOfflineTime();
        }

        void OnUpdate(uint32 diff) override
        {
            if (!g_enable) return;
            _timer += diff;
            if (_timer < g_tickMs) return;
            _timer %= g_tickMs;

            for (GuildSnapshot const& g : Snapshots())
                RunGuildTick(g);
            CharacterDatabase.Execute(
                "INSERT INTO mod_living_world_meta (key_name,value_bigint) VALUES ('last_world_tick',UNIX_TIMESTAMP()) "
                "ON DUPLICATE KEY UPDATE value_bigint=VALUES(value_bigint)");
        }

        void OnShutdown() override
        {
            if (g_enable)
                CharacterDatabase.Execute(
                    "INSERT INTO mod_living_world_meta (key_name,value_bigint) VALUES ('last_world_tick',UNIX_TIMESTAMP()) "
                    "ON DUPLICATE KEY UPDATE value_bigint=VALUES(value_bigint)");
        }

    private:
        uint32 _timer = 0;
    };

    class LivingWorldCommand : public CommandScript
    {
    public:
        LivingWorldCommand() : CommandScript("LivingWorldCommand") { }
        ChatCommandTable GetCommands() const override
        {
            static ChatCommandTable sub = {
                { "status", HandleStatus, SEC_PLAYER, Console::Yes },
                { "recent", HandleRecent, SEC_PLAYER, Console::Yes },
            };
            static ChatCommandTable root = { { "livingworld", sub } };
            return root;
        }

        static bool HandleStatus(ChatHandler* handler)
        {
            Player* player = handler->GetSession() ? handler->GetSession()->GetPlayer() : nullptr;
            if (!player || !player->GetGuildId())
            {
                handler->SendSysMessage("You are not in a guild.");
                return true;
            }
            QueryResult q = CharacterDatabase.Query(
                "SELECT COUNT(*),SUM(fulfilled=0) FROM mod_living_world_economy_order WHERE guild_id={}", player->GetGuildId());
            uint64 orders=0, open=0;
            if (q) { orders=q->Fetch()[0].Get<uint64>(); open=q->Fetch()[1].Get<uint64>(); }
            handler->PSendSysMessage("Living World: {}. Tick={} sec. Economy orders={} ({} open).",
                g_enable ? "enabled" : "disabled", g_tickMs/1000u, orders, open);
            return true;
        }

        static bool HandleRecent(ChatHandler* handler)
        {
            Player* player = handler->GetSession() ? handler->GetSession()->GetPlayer() : nullptr;
            if (!player || !player->GetGuildId()) return true;
            QueryResult q = CharacterDatabase.Query(
                "SELECT activity_type,summary,created_at FROM mod_living_world_guild_activity WHERE guild_id={} ORDER BY id DESC LIMIT 8",
                player->GetGuildId());
            if (!q) { handler->SendSysMessage("No guild-life history yet."); return true; }
            do
            {
                Field* f=q->Fetch();
                handler->PSendSysMessage("[{}] {} - {}", f[2].Get<std::string>(), f[0].Get<std::string>(), f[1].Get<std::string>());
            } while (q->NextRow());
            return true;
        }
    };
}

void Addmod_living_worldScripts()
{
    new LivingWorldScript();
    new LivingWorldCommand();
}
