#ifndef MOD_PB_CHATTER_RELATIONSHIPS_H
#define MOD_PB_CHATTER_RELATIONSHIPS_H

#include <cstdint>
#include <string>

class Player;
class Creature;
class Item;

namespace PBChatterRelationships
{
    // Loads persisted relationship scores + notable memories into the in-memory cache.
    // Call from the world thread during startup.
    void LoadAllFromDB();

    // Samples real-player groups once per minute so time spent adventuring together becomes
    // durable history. This deliberately only follows groups containing a real player; random
    // bot-only groups do not generate an O(N^2) relationship storm across thousands of bots.
    void Tick(uint32_t diff);

    // Flushes dirty relationship rows and queued semantic memories. Call on the world thread.
    void FlushToDB();

    // Significant shared events. These functions only mutate a mutex-protected cache and are
    // safe to call from map/update worker threads.
    void RecordBossKill(Player* creditedPlayer, Creature* killed);
    void RecordDeath(Player* player);
    void RecordDuel(Player* winner, Player* loser);
    void RecordLoot(Player* winner, Item* item, uint32_t count);

    // Natural-language summary injected into Ollama prompts. Scores are intentionally described,
    // not exposed as game mechanics: the model should act like it remembers someone rather than
    // reciting a friendship spreadsheet.
    std::string PromptContext(uint64_t botGuid, uint64_t subjectGuid, std::string const& subjectName);
}

#endif
