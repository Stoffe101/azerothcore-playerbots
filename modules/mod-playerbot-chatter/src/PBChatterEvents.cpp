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
    std::unordered_map<uint64_t, Seed> g_seeds;
    std::mutex g_seedsMutex;

    std::unordered_map<uint64, uint32> g_socialTimeMs;
    std::mutex g_socialTimeMutex;
    constexpr uint32 SHARED_TIME_SAMPLE_MS = 60000;

    bool IsBot(Player* p)
    {
        PlayerbotAI* ai = p ? GET_PLAYERBOT_AI(p) : nullptr;
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

    void TouchBotPeers(SocialParty const& party, uint16 familiarity, int16 affinity, uint16 trust,
                       bool sharedRun, PBAIGuildStore::RelationshipSignal signal)
    {
        for (Player* bot : party.guildBots)
        {
            if (!bot)
                continue;
            for (Player* peer : party.guildBots)
            {
                if (!peer || peer == bot || peer->GetGuildId() != bot->GetGuildId())
                    continue;

                uint32 const botGuid = bot->GetGUID().GetCounter();
                uint32 const peerGuid = peer->GetGUID().GetCounter();
                PBAIGuildStore::TouchRelationship(botGuid, 1, peerGuid, familiarity, affinity, trust, sharedRun);
                PBAIGuildStore::NoteRelationshipSignal(botGuid, 1, peerGuid, signal);
            }
        }
    }

    void RememberSharedTime(SocialParty const& party, uint32 minutes)
    {
        if (!party.anchorHuman || !minutes)
            return;

        for (Player* bot : party.guildBots)
        {
            uint32 const botGuid = bot->GetGUID().GetCounter();
            for (Player* human : party.humans)
                PBAIGuildStore::NoteRelationshipSignal(
                    botGuid, 0, human->GetGUID().GetCounter(), PBAIGuildStore::RelationshipSignal::SharedMinute, minutes);
        }

        for (uint32 i = 0; i < minutes; ++i)
            TouchBotPeers(party, 0, 0, 0, false, PBAIGuildStore::RelationshipSignal::SharedMinute);
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
            {
                uint32 const humanGuid = human->GetGUID().GetCounter();
                PBAIGuildStore::TouchRelationship(botGuid, 0, humanGuid, 4, 1, 2, true);
                PBAIGuildStore::NoteRelationshipSignal(
                    botGuid, 0, humanGuid, PBAIGuildStore::RelationshipSignal::BossKill);
            }
        }

        TouchBotPeers(party, 4, 1, 2, true, PBAIGuildStore::RelationshipSignal::BossKill);
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
                uint32 const botGuid = bot->GetGUID().GetCounter();
                PBAIGuildStore::AddMemory(
                    botGuid, eventId, "group_wipe", 75, 2, killer->GetEntry(), summary);
                for (Player* human : party.humans)
                {
                    uint32 const humanGuid = human->GetGUID().GetCounter();
                    PBAIGuildStore::TouchRelationship(botGuid, 0, humanGuid, 2, 0, 1, false);
                    PBAIGuildStore::NoteRelationshipSignal(
                        botGuid, 0, humanGuid, PBAIGuildStore::RelationshipSignal::Wipe);
                }
            }
            TouchBotPeers(party, 2, 0, 1, false, PBAIGuildStore::RelationshipSignal::Wipe);
            return;
        }

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
            uint32 const botGuid = bot->GetGUID().GetCounter();
            uint32 const killedGuid = killed->GetGUID().GetCounter();
            PBAIGuildStore::AddMemory(
                botGuid, eventId, "player_death", 30, 0, killedGuid, summary);
            PBAIGuildStore::TouchRelationship(botGuid, 0, killedGuid, 1, 0, 0, false);
            PBAIGuildStore::NoteRelationshipSignal(
                botGuid, 0, killedGuid, PBAIGuildStore::RelationshipSignal::SharedDeath);
        }
    }

    void RememberLootMoment(Player* winner, Item* item, uint32 count)
    {
        if (!winner || !item || !item->GetTemplate() || !IsRealPlayer(winner))
            return;

        SocialParty party;
        if (!BuildSocialParty(winner, party))
            return;

        ItemTemplate const* proto = item->GetTemplate();
        std::string summary = Acore::StringFormat(
            "{} won {}x {} while grouped with the guild.",
            winner->GetName(), count, proto->Name1);
        uint64 const eventId = PBAIGuildStore::RecordEvent(
            "loot_moment", winner->GetGUID().GetCounter(), 0, winner->GetMapId(), proto->ItemId, summary);
        uint8 const importance = proto->Quality >= ITEM_QUALITY_EPIC ? 70 :
            (proto->Quality >= ITEM_QUALITY_RARE ? 45 : 25);

        for (Player* bot : party.guildBots)
        {
            uint32 const botGuid = bot->GetGUID().GetCounter();
            uint32 const winnerGuid = winner->GetGUID().GetCounter();
            PBAIGuildStore::AddMemory(botGuid, eventId, "loot_moment", importance, 0, winnerGuid, summary);
            PBAIGuildStore::NoteRelationshipSignal(
                botGuid, 0, winnerGuid, PBAIGuildStore::RelationshipSignal::LootMoment);
        }
    }

    void RememberDuel(Player* winner, Player* loser, DuelCompleteType type)
    {
        if (!winner || !loser || type != DUEL_WON)
            return;

        bool const winnerBot = IsBot(winner);
        bool const loserBot = IsBot(loser);
        bool const winnerHuman = IsRealPlayer(winner);
        bool const loserHuman = IsRealPlayer(loser);
        if ((!winnerBot && !loserBot) || (!winnerHuman && !loserHuman && winner->GetGuildId() != loser->GetGuildId()))
            return;

        std::string summary = Acore::StringFormat("{} defeated {} in a duel.", winner->GetName(), loser->GetName());
        uint64 const eventId = PBAIGuildStore::RecordEvent(
            "duel", winner->GetGUID().GetCounter(), loser->GetGUID().GetCounter(), winner->GetMapId(), 0, summary);

        auto rememberForBot = [&](Player* bot, Player* other, uint8 relatedType)
        {
            if (!bot || !other || !IsBot(bot))
                return;
            uint32 const botGuid = bot->GetGUID().GetCounter();
            uint32 const otherGuid = other->GetGUID().GetCounter();
            PBAIGuildStore::AddMemory(botGuid, eventId, "duel", 35, relatedType, otherGuid, summary);
            PBAIGuildStore::TouchRelationship(botGuid, relatedType, otherGuid, 2, 0, 0, false);
            PBAIGuildStore::NoteRelationshipSignal(
                botGuid, relatedType, otherGuid, PBAIGuildStore::RelationshipSignal::Duel);
        };

        if (winnerBot && loserHuman)
            rememberForBot(winner, loser, 0);
        if (loserBot && winnerHuman)
            rememberForBot(loser, winner, 0);
        if (winnerBot && loserBot && winner->GetGuildId() && winner->GetGuildId() == loser->GetGuildId())
        {
            rememberForBot(winner, loser, 1);
            rememberForBot(loser, winner, 1);
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
        PBChatterEventScript() : PlayerScript("PBChatterEventScript") {}

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

        void OnPlayerGroupRollRewardItem(Player* player, Item* item, uint32 count, RollVote /*voteType*/, Roll* /*roll*/) override
        {
            if (!g_PBChatEnable)
                return;
            RememberLootMoment(player, item, count);
        }

        void OnPlayerDuelEnd(Player* winner, Player* loser, DuelCompleteType type) override
        {
            if (!g_PBChatEnable)
                return;
            RememberDuel(winner, loser, type);
        }

        void OnPlayerUpdate(Player* player, uint32 diff) override
        {
            if (!g_PBChatEnable || !IsRealPlayer(player) || !player->GetGroup())
                return;

            SocialParty party;
            if (!BuildSocialParty(player, party) || party.anchorHuman != player || !party.group)
                return;

            uint64 const groupKey = party.group->GetGUID().GetRawValue();
            uint32 minutes = 0;
            {
                std::lock_guard<std::mutex> lock(g_socialTimeMutex);
                uint32& elapsed = g_socialTimeMs[groupKey];
                elapsed += diff;
                if (elapsed >= SHARED_TIME_SAMPLE_MS)
                {
                    minutes = elapsed / SHARED_TIME_SAMPLE_MS;
                    elapsed %= SHARED_TIME_SAMPLE_MS;
                }
            }

            if (minutes)
                RememberSharedTime(party, minutes);
        }
    };
}

PlayerScript* PBChatterMakeEventScript()
{
    return new PBChatterEventScript();
}
