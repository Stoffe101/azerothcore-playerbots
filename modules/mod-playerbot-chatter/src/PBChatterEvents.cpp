#include "PBChatterEvents.h"
#include "PBChatterAmbient.h"
#include "PBChatterConfig.h"
#include "PBChatterRelationships.h"
#include "ScriptMgr.h"
#include "Player.h"
#include "Creature.h"
#include "Group.h"
#include "Item.h"
#include "ItemTemplate.h"
#include "QuestDef.h"
#include "Playerbots.h"
#include "SharedDefines.h"
#include <mutex>
#include <string>
#include <unordered_map>

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
        // via gdb: GetUInt32Value <- Item::GetTemplate <- OnPlayerLootItem).
        //
        // Group-roll rewards are different: PLAYERHOOK_ON_GROUP_ROLL_REWARD_ITEM fires after the
        // reward item exists in the winner's inventory, so it is safe for relationship memory.
        PBChatterEventScript() : PlayerScript("PBChatterEventScript", {
            PLAYERHOOK_ON_LEVEL_CHANGED,
            PLAYERHOOK_ON_PLAYER_COMPLETE_QUEST,
            PLAYERHOOK_ON_CREATURE_KILL,
            PLAYERHOOK_ON_PLAYER_JUST_DIED,
            PLAYERHOOK_ON_DUEL_END,
            PLAYERHOOK_ON_GROUP_ROLL_REWARD_ITEM,
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
            if (!g_PBChatEnable || !killed)
                return;

            // Persistent relationship history is not merely ambient flavor. A boss kill should
            // still count even if spontaneous chatter is disabled.
            PBChatterRelationships::RecordBossKill(killer, killed);

            if (!g_PBChatAmbientEnable)
                return;
            if (!killed->isElite() && !killed->isWorldBoss())
                return; // only notable kills become immediate flavor
            Stamp(killer, "you just took down " + killed->GetName());
        }

        void OnPlayerJustDied(Player* player) override
        {
            if (!g_PBChatEnable)
                return;
            PBChatterRelationships::RecordDeath(player);
            if (g_PBChatAmbientEnable)
                Stamp(player, "you just died during the run");
        }

        void OnPlayerDuelEnd(Player* winner, Player* loser, DuelCompleteType /*type*/) override
        {
            if (g_PBChatEnable)
                PBChatterRelationships::RecordDuel(winner, loser);
        }

        void OnPlayerGroupRollRewardItem(Player* player, Item* item, uint32 count,
                                         RollVote /*voteType*/, Roll* /*roll*/) override
        {
            if (g_PBChatEnable)
                PBChatterRelationships::RecordLoot(player, item, count);
        }
    };
}

PlayerScript* PBChatterMakeEventScript()
{
    return new PBChatterEventScript();
}
