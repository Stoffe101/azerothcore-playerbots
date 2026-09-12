#include "PBChatterEvents.h"
#include "PBChatterAmbient.h"
#include "PBChatterConfig.h"
#include "PBAIGuildStore.h"
#include "ScriptMgr.h"
#include "Player.h"
#include "Creature.h"
#include "Group.h"
#include "KillRewarder.h"
#include "Item.h"
#include "ItemTemplate.h"
#include "QuestDef.h"
#include "Playerbots.h"
#include "SharedDefines.h"
#include "StringFormat.h"

#include <algorithm>
#include <mutex>
#include <string>
#include <unordered_map>
#include <vector>

namespace
{
    struct Seed { uint32_t ms; std::string hint; };
    std::unordered_map<uint64_t, Seed> g_seeds; // bot GUID counter -> last event

    // The event hooks below fire from Unit kill/level/quest handling inside Map::Update, which
    // AzerothCore runs on MapUpdater WORKER THREADS (AiPlayerbot drives ~2000 bots across many
    // maps in parallel). Take() runs on the world thread. So g_seeds is touched concurrently
    // from multiple threads and MUST be serialized — an unlocked std::unordered_map mutated
    // from two map threads at once corrupts the heap and crashes the server, even with no
    // players online. This mutex is the single guard for every g_seeds access.
    std::mutex g_seedsMutex;

    bool IsBot(Player* p)
    {
        // upstream 17214b3 renamed PlayerbotAI::IsRealPlayer() (which meant "selfbot") to the
        // free IsSelfBot(Player*); the free IsRealPlayer(Player*) now means "no bot AI at all".
        PlayerbotAI* ai = GET_PLAYERBOT_AI(p);
        return ai && !IsSelfBot(p);
    }

    void Stamp(Player* p, std::string hint)
    {
        if (!g_PBChatEnable || !g_PBChatAmbientEnable)
            return;
        if (!p || !IsBot(p))
            return;
        uint64_t key = p->GetGUID().GetCounter();
        uint32_t now = PBChatterAmbient::NowMs();
        std::lock_guard<std::mutex> lock(g_seedsMutex);
        g_seeds[key] = Seed{ now, std::move(hint) };
    }

    struct SocialParty
    {
        Group* group = nullptr;
        Player* anchorHuman = nullptr;
        std::vector<Player*> humans;
        std::vector<Player*> guildBots;
    };

    bool BuildSocialParty(Player* participant, SocialParty& out)
    {
        if (!participant)
            return false;

        Group* group = participant->GetGroup();
        if (!group)
            return false;

        out.group = group;
        group->DoForAllMembers([&](Player* member)
        {
            if (member && IsRealPlayer(member))
                out.humans.push_back(member);
        });

        if (out.humans.empty())
            return false;

        out.anchorHuman = *std::min_element(out.humans.begin(), out.humans.end(), [](Player* a, Player* b)
        {
            return a->GetGUID().GetCounter() < b->GetGUID().GetCounter();
        });

        // A persistent family memory belongs to the guild, not every random bot that happened
        // to be in a group. A bot qualifies if it shares a non-zero guild with any real player.
        group->DoForAllMembers([&](Player* member)
        {
            if (!member || !IsBot(member) || !member->GetGuildId())
                return;

            for (Player* human : out.humans)
            {
                if (human->GetGuildId() && human->GetGuildId() == member->GetGuildId())
                {
                    out.guildBots.push_back(member);
                    break;
                }
            }
        });

        return !out.guildBots.empty();
    }

    bool PartyIsFullyDead(Group* group)
    {
        if (!group)
            return false;

        uint32 onlineMembers = 0;
        bool anyoneAlive = false;
        group->DoForAllMembers([&](Player* member)
        {
            if (!member)
                return;
            ++onlineMembers;
            if (member->IsAlive())
                anyoneAlive = true;
        });

        return onlineMembers > 0 && !anyoneAlive;
    }

    void RememberBossKill(SocialParty const& party, Creature* boss)
    {
        if (!party.anchorHuman || !boss)
            return;

        bool raid = party.group && party.group->isRaidGroup();
        std::string type = raid ? "raid_boss_kill" : "dungeon_boss_kill";
        std::string summary = Acore::StringFormat(
            "The guild defeated {} together with {}.",
            boss->GetName(),
            party.anchorHuman->GetName());

        uint64 eventId = PBAIGuildStore::RecordEvent(
            type,
            party.anchorHuman->GetGUID().GetCounter(),
            boss->GetGUID().GetCounter(),
            boss->GetMapId(),
            boss->GetEntry(),
            summary);

        for (Player* bot : party.guildBots)
        {
            uint32 botGuid = bot->GetGUID().GetCounter();
            PBAIGuildStore::AddMemory(
                botGuid,
                eventId,
                type,
                raid ? 85 : 65,
                2,
                boss->GetEntry(),
                summary);

            for (Player* human : party.humans)
                PBAIGuildStore::TouchRelationship(
                    botGuid, 0, human->GetGUID().GetCounter(), 4, 1, 2, false);
        }
    }

    void RememberDeathOrWipe(SocialParty const& party, Creature* killer, Player* killed)
    {
        if (!party.anchorHuman || !party.group || !killer || !killed)
            return;

        if (PartyIsFullyDead(party.group))
        {
            std::string summary = Acore::StringFormat(
                "The group wiped to {} while adventuring with {}.",
                killer->GetName(),
                party.anchorHuman->GetName());
            uint64 eventId = PBAIGuildStore::RecordEvent(
                "group_wipe",
                party.anchorHuman->GetGUID().GetCounter(),
                killer->GetGUID().GetCounter(),
                killer->GetMapId(),
                killer->GetEntry(),
                summary);

            for (Player* bot : party.guildBots)
            {
                PBAIGuildStore::AddMemory(
                    bot->GetGUID().GetCounter(), eventId, "group_wipe", 75, 2, killer->GetEntry(), summary);
                for (Player* human : party.humans)
                    PBAIGuildStore::TouchRelationship(
                        bot->GetGUID().GetCounter(), 0, human->GetGUID().GetCounter(), 2, 0, 1, false);
            }
            return;
        }

        // Individual bot deaths are too noisy to keep forever. Human deaths are useful social
        // texture because they support grounded teasing / callbacks without inventing history.
        if (!IsRealPlayer(killed))
            return;

        std::string summary = Acore::StringFormat(
            "{} died to {} while grouped with the guild.",
            killed->GetName(),
            killer->GetName());
        uint64 eventId = PBAIGuildStore::RecordEvent(
            "player_death",
            killed->GetGUID().GetCounter(),
            killer->GetGUID().GetCounter(),
            killed->GetMapId(),
            killer->GetEntry(),
            summary);

        for (Player* bot : party.guildBots)
        {
            PBAIGuildStore::AddMemory(
                bot->GetGUID().GetCounter(), eventId, "player_death", 30, 0,
                killed->GetGUID().GetCounter(), summary);
            PBAIGuildStore::TouchRelationship(
                bot->GetGUID().GetCounter(), 0, killed->GetGUID().GetCounter(), 1, 0, 0, false);
        }
    }
}

bool PBChatterEvents::Take(uint64_t botGuidCounter, uint32_t nowMs, std::string& outHint)
{
    std::lock_guard<std::mutex> lock(g_seedsMutex);
    auto it = g_seeds.find(botGuidCounter);
    if (it == g_seeds.end())
        return false;
    bool fresh = (nowMs - it->second.ms) <= 120000u;
    if (fresh)
        outHint = it->second.hint;
    g_seeds.erase(it);
    return fresh;
}

namespace
{
    class PBChatterEventScript : public PlayerScript
    {
    public:
        // NOTE: deliberately NO PLAYERHOOK_ON_LOOT_ITEM. OnPlayerLootItem fired on the
        // playerbots bot-loot path (PlayerbotHolder::HandleBotPackets -> StoreLootItem) with an
        // Item* that is NOT safe to dereference there — item->GetTemplate() segfaulted the world
        // thread under heavy bot loot ~90s after start, even with the module disabled (confirmed
        // via gdb: GetUInt32Value <- Item::GetTemplate <- OnPlayerLootItem). Loot riffs are an
        // optional flavor; the remaining hooks dereference objects that are valid for the hook.
        PBChatterEventScript() : PlayerScript("PBChatterEventScript", {
            PLAYERHOOK_ON_LEVEL_CHANGED,
            PLAYERHOOK_ON_PLAYER_COMPLETE_QUEST,
            PLAYERHOOK_ON_CREATURE_KILL,
            PLAYERHOOK_ON_PLAYER_KILLED_BY_CREATURE,
            PLAYERHOOK_ON_REWARD_KILL_REWARDER,
        }) {}

        void OnPlayerLevelChanged(Player* player, uint8 /*oldLevel*/) override
        {
            if (!g_PBChatEnable || !g_PBChatAmbientEnable)
                return;
            Stamp(player, "you just dinged level " + std::to_string(player->GetLevel()));
        }

        void OnPlayerCompleteQuest(Player* player, Quest const* quest) override
        {
            if (!g_PBChatEnable || !g_PBChatAmbientEnable)
                return;
            std::string title = quest ? quest->GetTitle() : "";
            Stamp(player, title.empty() ? "you just finished a quest"
                                        : ("you just finished the quest \"" + title + "\""));
        }

        void OnPlayerCreatureKill(Player* killer, Creature* killed) override
        {
            if (!g_PBChatEnable || !g_PBChatAmbientEnable)
                return;
            if (!killed)
                return;
            if (!killed->isElite() && !killed->isWorldBoss())
                return;
            Stamp(killer, "you just took down " + killed->GetName());
        }

        void OnPlayerRewardKillRewarder(Player* player, KillRewarder* rewarder, bool /*isDungeon*/, float& /*rate*/) override
        {
            if (!g_PBChatEnable || !player || !rewarder || !IsRealPlayer(player))
                return;

            Creature* killed = rewarder->GetVictim() ? rewarder->GetVictim()->ToCreature() : nullptr;
            if (!killed || !killed->IsDungeonBoss())
                return;

            SocialParty party;
            if (!BuildSocialParty(player, party))
                return;

            // KillRewarder invokes this once for each credited real player. Only the canonical
            // human writes the shared event so a two-human party does not duplicate memories.
            if (party.anchorHuman != player)
                return;

            RememberBossKill(party, killed);
        }

        void OnPlayerKilledByCreature(Creature* killer, Player* killed) override
        {
            if (!g_PBChatEnable || !killer || !killed)
                return;

            SocialParty party;
            if (!BuildSocialParty(killed, party))
                return;

            RememberDeathOrWipe(party, killer, killed);
        }
    };
}

PlayerScript* PBChatterMakeEventScript()
{
    return new PBChatterEventScript();
}
