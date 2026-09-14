#include "PBChatterRelationships.h"

#include "Creature.h"
#include "DatabaseEnv.h"
#include "Field.h"
#include "Group.h"
#include "Item.h"
#include "ItemTemplate.h"
#include "ObjectAccessor.h"
#include "Player.h"
#include "Playerbots.h"
#include "QueryResult.h"
#include "StringFormat.h"
#include "WorldSession.h"
#include "WorldSessionMgr.h"

#include <algorithm>
#include <deque>
#include <mutex>
#include <string>
#include <unordered_map>
#include <unordered_set>
#include <utility>
#include <vector>

namespace
{
    struct PairKey
    {
        uint64_t bot = 0;
        uint64_t subject = 0;

        bool operator==(PairKey const& rhs) const
        {
            return bot == rhs.bot && subject == rhs.subject;
        }
    };

    struct PairHash
    {
        std::size_t operator()(PairKey const& k) const noexcept
        {
            return std::hash<uint64_t>{}(k.bot) ^ (std::hash<uint64_t>{}(k.subject) << 1);
        }
    };

    struct Relation
    {
        int32_t affinity = 0;
        int32_t trust = 0;
        int32_t rivalry = 0;
        int32_t guildLoyalty = 0;
        uint32_t sharedMinutes = 0;
        uint32_t bossKills = 0;
        uint32_t deathsTogether = 0;
        uint32_t lootMoments = 0;
        uint32_t duels = 0;
        bool subjectIsBot = false;
        std::string lastEvent;
        bool dirty = false;
    };

    struct MemoryLine
    {
        std::string kind;
        uint8_t importance = 1;
        std::string text;
    };

    struct PendingMemory
    {
        PairKey key;
        MemoryLine line;
    };

    std::unordered_map<PairKey, Relation, PairHash> g_relations;
    std::unordered_map<PairKey, std::deque<MemoryLine>, PairHash> g_memories;
    std::vector<PendingMemory> g_pendingMemories;
    std::mutex g_mutex;
    uint32_t g_groupSampleTimer = 0;

    constexpr std::size_t kMemoriesPerPair = 12;

    bool IsBot(Player* player)
    {
        if (!player)
            return false;
        PlayerbotAI* ai = GET_PLAYERBOT_AI(player);
        return ai && !IsSelfBot(player);
    }

    int32_t ClampScore(int32_t value)
    {
        return std::max<int32_t>(-1000, std::min<int32_t>(1000, value));
    }

    std::vector<Player*> OnlineMembers(Player* anchor)
    {
        std::vector<Player*> out;
        if (!anchor)
            return out;

        Group* group = anchor->GetGroup();
        if (!group)
        {
            out.push_back(anchor);
            return out;
        }

        out.reserve(group->GetMembersCount());
        for (auto const& slot : group->GetMemberSlots())
            if (Player* member = ObjectAccessor::FindPlayer(slot.guid))
                if (member->IsInWorld())
                    out.push_back(member);
        return out;
    }

    void AppendMemoryLocked(PairKey key, std::string kind, uint8_t importance, std::string text)
    {
        if (text.empty())
            return;

        MemoryLine line{std::move(kind), importance, std::move(text)};
        auto& dq = g_memories[key];
        dq.push_back(line);
        while (dq.size() > kMemoriesPerPair)
            dq.pop_front();
        g_pendingMemories.push_back(PendingMemory{key, std::move(line)});
    }

    void ApplyOne(Player* bot, Player* subject,
                  int32_t affinity, int32_t trust, int32_t rivalry, int32_t loyalty,
                  uint32_t sharedMinutes, uint32_t bossKills, uint32_t deaths,
                  uint32_t lootMoments, uint32_t duels,
                  std::string const& eventText = {}, std::string const& memoryKind = {},
                  uint8_t importance = 0)
    {
        if (!bot || !subject || bot == subject || !IsBot(bot))
            return;

        PairKey key{bot->GetGUID().GetCounter(), subject->GetGUID().GetCounter()};
        std::lock_guard<std::mutex> lock(g_mutex);
        Relation& rel = g_relations[key];
        rel.subjectIsBot = IsBot(subject);
        rel.affinity = ClampScore(rel.affinity + affinity);
        rel.trust = ClampScore(rel.trust + trust);
        rel.rivalry = ClampScore(rel.rivalry + rivalry);
        rel.guildLoyalty = ClampScore(rel.guildLoyalty + loyalty);
        rel.sharedMinutes += sharedMinutes;
        rel.bossKills += bossKills;
        rel.deathsTogether += deaths;
        rel.lootMoments += lootMoments;
        rel.duels += duels;
        if (!eventText.empty())
            rel.lastEvent = eventText;
        rel.dirty = true;

        // Semantic memories are reserved for meaningful events. Bot↔bot pairs still build full
        // relationship statistics, but we avoid writing thousands of near-identical raid-memory
        // rows for a 40-player roster. A bot always remembers important moments involving a human.
        if (importance && !rel.subjectIsBot)
            AppendMemoryLocked(key, memoryKind, importance, eventText);
    }

    void ApplyPair(Player* a, Player* b,
                   int32_t affinity, int32_t trust, int32_t rivalry, int32_t loyalty,
                   uint32_t sharedMinutes, uint32_t bossKills, uint32_t deaths,
                   uint32_t lootMoments, uint32_t duels,
                   std::string const& eventForA = {}, std::string const& eventForB = {},
                   std::string const& memoryKind = {}, uint8_t importance = 0)
    {
        ApplyOne(a, b, affinity, trust, rivalry, loyalty, sharedMinutes, bossKills, deaths,
                 lootMoments, duels, eventForA, memoryKind, importance);
        ApplyOne(b, a, affinity, trust, rivalry, loyalty, sharedMinutes, bossKills, deaths,
                 lootMoments, duels, eventForB, memoryKind, importance);
    }

    void SampleGroup(Player* realAnchor)
    {
        std::vector<Player*> members = OnlineMembers(realAnchor);
        if (members.size() < 2)
            return;

        // Only pairs involving at least one bot need records. Group time is the quiet backbone of
        // a relationship: every 30 minutes together adds a tiny amount of affinity/trust, while
        // the raw shared-minute counter preserves the actual history (40 hours stays 40 hours).
        for (std::size_t i = 0; i < members.size(); ++i)
        {
            for (std::size_t j = i + 1; j < members.size(); ++j)
            {
                Player* a = members[i];
                Player* b = members[j];
                if (!IsBot(a) && !IsBot(b))
                    continue;

                bool sameGuild = a->GetGuildId() && a->GetGuildId() == b->GetGuildId();

                auto applyMinute = [sameGuild](Player* bot, Player* subject)
                {
                    if (!IsBot(bot))
                        return;
                    PairKey key{bot->GetGUID().GetCounter(), subject->GetGUID().GetCounter()};
                    std::lock_guard<std::mutex> lock(g_mutex);
                    Relation& rel = g_relations[key];
                    rel.subjectIsBot = IsBot(subject);
                    ++rel.sharedMinutes;
                    if ((rel.sharedMinutes % 30u) == 0u)
                    {
                        rel.affinity = ClampScore(rel.affinity + 1);
                        rel.trust = ClampScore(rel.trust + 1);
                        if (sameGuild)
                            rel.guildLoyalty = ClampScore(rel.guildLoyalty + 1);
                    }
                    rel.dirty = true;
                };

                applyMinute(a, b);
                applyMinute(b, a);
            }
        }
    }

    char const* RelationshipWord(Relation const& r)
    {
        if (r.rivalry >= 120 && r.affinity < 80) return "a serious rival";
        if (r.affinity >= 250 && r.trust >= 180) return "one of your closest long-time companions";
        if (r.affinity >= 120 && r.trust >= 80)  return "a trusted friend and regular companion";
        if (r.affinity >= 45)                    return "a familiar player you genuinely like";
        if (r.affinity <= -120)                  return "someone you strongly dislike and hold a grudge against";
        if (r.affinity <= -40)                   return "someone you are wary of and don't particularly trust";
        if (r.sharedMinutes >= 180)              return "a familiar long-running companion";
        if (r.sharedMinutes >= 30)               return "someone you've adventured with several times";
        return "someone you've met before";
    }
}

void PBChatterRelationships::LoadAllFromDB()
{
    std::lock_guard<std::mutex> lock(g_mutex);
    g_relations.clear();
    g_memories.clear();
    g_pendingMemories.clear();

    if (QueryResult result = CharacterDatabase.Query(
        "SELECT bot_guid, subject_guid, subject_is_bot, affinity, trust, rivalry, guild_loyalty, "
        "shared_minutes, boss_kills, deaths_together, loot_moments, duels, last_event "
        "FROM mod_playerbot_chatter_relationship"))
    {
        do
        {
            Field* f = result->Fetch();
            PairKey key{f[0].Get<uint64>(), f[1].Get<uint64>()};
            Relation rel;
            rel.subjectIsBot = f[2].Get<uint8>() != 0;
            rel.affinity = f[3].Get<int32>();
            rel.trust = f[4].Get<int32>();
            rel.rivalry = f[5].Get<int32>();
            rel.guildLoyalty = f[6].Get<int32>();
            rel.sharedMinutes = f[7].Get<uint32>();
            rel.bossKills = f[8].Get<uint32>();
            rel.deathsTogether = f[9].Get<uint32>();
            rel.lootMoments = f[10].Get<uint32>();
            rel.duels = f[11].Get<uint32>();
            rel.lastEvent = f[12].Get<std::string>();
            rel.dirty = false;
            g_relations.emplace(key, std::move(rel));
        } while (result->NextRow());
    }

    if (QueryResult result = CharacterDatabase.Query(
        "SELECT bot_guid, subject_guid, kind, importance, memory_text "
        "FROM mod_playerbot_chatter_memories ORDER BY ts ASC, id ASC"))
    {
        do
        {
            Field* f = result->Fetch();
            PairKey key{f[0].Get<uint64>(), f[1].Get<uint64>()};
            auto& dq = g_memories[key];
            dq.push_back(MemoryLine{f[2].Get<std::string>(), f[3].Get<uint8>(), f[4].Get<std::string>()});
            while (dq.size() > kMemoriesPerPair)
                dq.pop_front();
        } while (result->NextRow());
    }
}

void PBChatterRelationships::Tick(uint32_t diff)
{
    g_groupSampleTimer += diff;
    if (g_groupSampleTimer < 60000u)
        return;
    g_groupSampleTimer %= 60000u;

    std::unordered_set<Group*> sampledGroups;
    for (auto const& [accountId, session] : sWorldSessionMgr->GetAllSessions())
    {
        (void)accountId;
        if (!session)
            continue;
        Player* player = session->GetPlayer();
        if (!player || !player->IsInWorld() || IsBot(player))
            continue;

        Group* group = player->GetGroup();
        if (!group)
            continue;
        if (!sampledGroups.insert(group).second)
            continue;
        SampleGroup(player);
    }
}

void PBChatterRelationships::FlushToDB()
{
    std::vector<std::pair<PairKey, Relation>> dirty;
    std::vector<PendingMemory> pending;
    {
        std::lock_guard<std::mutex> lock(g_mutex);
        dirty.reserve(g_relations.size());
        for (auto& [key, rel] : g_relations)
        {
            if (!rel.dirty)
                continue;
            rel.dirty = false;
            dirty.emplace_back(key, rel);
        }
        pending.swap(g_pendingMemories);
    }

    for (auto& [key, rel] : dirty)
    {
        std::string eventText = rel.lastEvent;
        CharacterDatabase.EscapeString(eventText);
        CharacterDatabase.Execute(Acore::StringFormat(
            "INSERT INTO mod_playerbot_chatter_relationship "
            "(bot_guid,subject_guid,subject_is_bot,affinity,trust,rivalry,guild_loyalty,shared_minutes," 
            "boss_kills,deaths_together,loot_moments,duels,last_event,updated_at) "
            "VALUES ({},{},{},{},{},{},{},{},{},{},{},{},'{}',NOW()) "
            "ON DUPLICATE KEY UPDATE subject_is_bot=VALUES(subject_is_bot), affinity=VALUES(affinity), "
            "trust=VALUES(trust), rivalry=VALUES(rivalry), guild_loyalty=VALUES(guild_loyalty), "
            "shared_minutes=VALUES(shared_minutes), boss_kills=VALUES(boss_kills), "
            "deaths_together=VALUES(deaths_together), loot_moments=VALUES(loot_moments), "
            "duels=VALUES(duels), last_event=VALUES(last_event), updated_at=NOW()",
            key.bot, key.subject, rel.subjectIsBot ? 1 : 0, rel.affinity, rel.trust, rel.rivalry,
            rel.guildLoyalty, rel.sharedMinutes, rel.bossKills, rel.deathsTogether,
            rel.lootMoments, rel.duels, eventText));
    }

    for (PendingMemory& mem : pending)
    {
        std::string kind = mem.line.kind;
        std::string text = mem.line.text;
        CharacterDatabase.EscapeString(kind);
        CharacterDatabase.EscapeString(text);
        CharacterDatabase.Execute(Acore::StringFormat(
            "INSERT INTO mod_playerbot_chatter_memories "
            "(bot_guid,subject_guid,kind,importance,ts,memory_text) "
            "VALUES ({},{},'{}',{},NOW(),'{}')",
            mem.key.bot, mem.key.subject, kind, mem.line.importance, text));
    }

    // Bound persistent semantic memory. Relationship counters remain forever; only the verbose
    // prose is trimmed so a years-old guild does not grow an unbounded prompt/database tail.
    CharacterDatabase.Execute(Acore::StringFormat(
        "DELETE m FROM mod_playerbot_chatter_memories m "
        "JOIN (SELECT id, ROW_NUMBER() OVER (PARTITION BY bot_guid,subject_guid "
        "ORDER BY importance DESC, ts DESC, id DESC) rn FROM mod_playerbot_chatter_memories) r "
        "ON r.id=m.id WHERE r.rn > {}",
        static_cast<uint32_t>(kMemoriesPerPair)));
}

void PBChatterRelationships::RecordBossKill(Player* creditedPlayer, Creature* killed)
{
    if (!creditedPlayer || !killed || !killed->IsDungeonBoss())
        return;

    std::vector<Player*> members = OnlineMembers(creditedPlayer);
    bool raid = creditedPlayer->GetGroup() && creditedPlayer->GetGroup()->isRaidGroup();
    std::string boss = killed->GetName();

    for (std::size_t i = 0; i < members.size(); ++i)
    {
        for (std::size_t j = i + 1; j < members.size(); ++j)
        {
            Player* a = members[i];
            Player* b = members[j];
            if (!IsBot(a) && !IsBot(b))
                continue;
            std::string forA = Acore::StringFormat("You defeated {} together with {}.", boss, b->GetName());
            std::string forB = Acore::StringFormat("You defeated {} together with {}.", boss, a->GetName());
            ApplyPair(a, b, 4, 3, 0, raid ? 2 : 1, 0, 1, 0, 0, 0,
                      forA, forB, raid ? "raid_boss" : "dungeon_boss", raid ? 4 : 3);
        }
    }
}

void PBChatterRelationships::RecordDeath(Player* player)
{
    if (!player)
        return;
    std::vector<Player*> members = OnlineMembers(player);
    for (Player* other : members)
    {
        if (other == player || (!IsBot(player) && !IsBot(other)))
            continue;
        std::string forPlayer = Acore::StringFormat("You died while adventuring with {}.", other->GetName());
        std::string forOther = Acore::StringFormat("You saw {} fall while you were adventuring together.", player->GetName());
        ApplyPair(player, other, 1, 1, 0, 0, 0, 0, 1, 0, 0,
                  forPlayer, forOther, "shared_death", 2);
    }
}

void PBChatterRelationships::RecordDuel(Player* winner, Player* loser)
{
    if (!winner || !loser || (!IsBot(winner) && !IsBot(loser)))
        return;
    std::string forWinner = Acore::StringFormat("You beat {} in a duel.", loser->GetName());
    std::string forLoser = Acore::StringFormat("{} beat you in a duel.", winner->GetName());
    ApplyPair(winner, loser, 1, 0, 4, 0, 0, 0, 0, 0, 1,
              forWinner, forLoser, "duel", 2);
}

void PBChatterRelationships::RecordLoot(Player* winner, Item* item, uint32_t count)
{
    if (!winner || !item || !item->GetTemplate())
        return;
    ItemTemplate const* tpl = item->GetTemplate();
    if (tpl->Quality < ITEM_QUALITY_RARE)
        return;

    std::vector<Player*> members = OnlineMembers(winner);
    for (Player* other : members)
    {
        if (other == winner || (!IsBot(winner) && !IsBot(other)))
            continue;
        std::string qty = count > 1 ? Acore::StringFormat(" x{}", count) : "";
        std::string forWinner = Acore::StringFormat("You won {}{} while grouped with {}.", tpl->Name1, qty, other->GetName());
        std::string forOther = Acore::StringFormat("{} won {}{} while you were grouped together.", winner->GetName(), tpl->Name1, qty);
        uint8_t importance = tpl->Quality >= ITEM_QUALITY_EPIC ? 4 : 2;
        ApplyPair(winner, other, 1, 0, 0, 0, 0, 0, 0, 1, 0,
                  forWinner, forOther, "loot", importance);
    }
}

std::string PBChatterRelationships::PromptContext(uint64_t botGuid, uint64_t subjectGuid,
                                                   std::string const& subjectName)
{
    PairKey key{botGuid, subjectGuid};
    std::lock_guard<std::mutex> lock(g_mutex);
    auto it = g_relations.find(key);
    if (it == g_relations.end())
        return "";

    Relation const& r = it->second;
    std::string out = Acore::StringFormat(
        "\n\nPersistent relationship with {}: {}. You've spent about {} hours adventuring together, "
        "shared {} dungeon/raid boss kills, lived through {} deaths, and seen {} memorable loot moments. "
        "Your trust is {} and your rivalry is {}. Treat this as real shared history and let it subtly "
        "affect your tone; NEVER recite these numbers or call them relationship stats.",
        subjectName, RelationshipWord(r), r.sharedMinutes / 60u, r.bossKills,
        r.deathsTogether, r.lootMoments,
        r.trust >= 120 ? "high" : (r.trust <= -40 ? "low" : "developing"),
        r.rivalry >= 120 ? "strong" : (r.rivalry >= 30 ? "noticeable" : "low"));

    auto memIt = g_memories.find(key);
    if (memIt != g_memories.end() && !memIt->second.empty())
    {
        out += "\nA few things you genuinely remember about your history together:";
        int shown = 0;
        for (auto rit = memIt->second.rbegin(); rit != memIt->second.rend() && shown < 4; ++rit, ++shown)
            out += Acore::StringFormat("\n- {}", rit->text);
        out += "\nUse these only when relevant; don't force a callback into every reply.";
    }
    return out;
}
