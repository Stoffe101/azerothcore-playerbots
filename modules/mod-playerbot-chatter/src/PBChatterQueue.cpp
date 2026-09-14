#include "PBChatterQueue.h"
#include "PBChatterConfig.h"
#include "PBChatterOllama.h"
#include "PBChatterLore.h"
#include "PBChatterMemory.h"
#include "Log.h"
#include "Random.h"
#include <algorithm>
#include <cctype>
#include <mutex>
#include <queue>
#include <thread>
#include <unordered_set>
#include <vector>

namespace
{
    std::mutex g_mutex;
    int g_running = 0;
    std::queue<PBChatJob> g_pending;

    std::mutex g_resultMutex;
    std::vector<PBChatResult> g_results;

    void RunJob(PBChatJob job);

    std::string Lower(std::string value)
    {
        std::transform(value.begin(), value.end(), value.begin(), [](unsigned char c) { return static_cast<char>(std::tolower(c)); });
        return value;
    }

    std::string Pick(std::vector<std::string> const& lines)
    {
        if (lines.empty())
            return "";
        return lines[urand(0, static_cast<uint32>(lines.size() - 1))];
    }

    std::unordered_set<std::string> TokenSet(std::string const& value)
    {
        static std::unordered_set<std::string> const ignored = {
            "this", "that", "with", "from", "into", "onto", "than", "then", "when", "while",
            "your", "ours", "their", "they", "them", "have", "has", "will", "would", "should",
            "could", "must", "need", "just", "keep", "make", "before", "after", "during", "through",
            "over", "under", "around", "there", "here", "where", "what", "which", "were", "been",
            "being", "only", "also", "more", "most", "very", "some", "each", "everyone", "anyone",
            "raid", "pull", "retry", "plan", "boss", "team", "guys", "okay", "alright", "please",
            "lets", "dont", "doesnt", "again"
        };

        std::unordered_set<std::string> tokens;
        std::string word;
        auto flush = [&]()
        {
            if (word.size() >= 4 && ignored.find(word) == ignored.end())
                tokens.insert(word);
            word.clear();
        };

        for (unsigned char c : value)
        {
            if (std::isalnum(c))
                word.push_back(static_cast<char>(std::tolower(c)));
            else
                flush();
        }
        flush();
        return tokens;
    }

    // Safety gate for grounded system speech. Ollama is allowed to smooth phrasing, but it cannot
    // introduce a new content word that does not occur in the validated fallback, and it must retain
    // most of the fallback's meaningful vocabulary. A rejected rewrite silently becomes the exact
    // deterministic fallback. This gives the raid leader local-model personality without allowing
    // the model to manufacture mechanics, assignments or spell names.
    bool GroundedReplyAllowed(std::string const& reply, std::string const& fallback)
    {
        if (reply.empty() || fallback.empty())
            return false;

        std::unordered_set<std::string> const allowed = TokenSet(fallback);
        std::unordered_set<std::string> const proposed = TokenSet(reply);
        if (allowed.empty())
            return reply.size() <= fallback.size() + 24;

        for (std::string const& token : proposed)
            if (allowed.find(token) == allowed.end())
                return false;

        uint32 kept = 0;
        for (std::string const& token : allowed)
            if (proposed.find(token) != proposed.end())
                ++kept;

        // Require 60% content-word coverage. For very short plans require at least one grounded
        // content word so an empty/generic acknowledgement can never replace the actual brief.
        uint32 const required = std::max<uint32>(1, (uint32(allowed.size()) * 3u + 4u) / 5u);
        return kept >= required;
    }

    // Never leave a real player talking into a void merely because Ollama is restarting/offline.
    // This is intentionally tiny and only used for ordinary REACTIVE jobs after any caller-owned
    // deterministic fallback has had first refusal. Ambient chatter still requires the model so
    // fallback lines cannot become background spam.
    std::string FallbackReply(PBChatJob const& job)
    {
        std::string const m = Lower(job.playerMessage);
        if (m.find("hello") != std::string::npos || m.find("hey") != std::string::npos ||
            m == "hi" || m.rfind("hi ", 0) == 0 || m.find("yo") != std::string::npos)
            return Pick({"yo", "hey :) ", "sup", "hey hey"});

        if (m.find("lfg") != std::string::npos || m.find("dungeon") != std::string::npos ||
            m.find("heroic") != std::string::npos || m.find("raid") != std::string::npos)
            return Pick({"i'm down if you still need one", "yeah i can come", "what role do you need?", "sure, inv me"});

        if (m.find("gz") != std::string::npos || m.find("grats") != std::string::npos ||
            m.find("congrats") != std::string::npos)
            return Pick({"ty!", "cheers", "haha finally, ty"});

        if (m.find('?') != std::string::npos)
            return Pick({"not 100% sure tbh", "i think so yeah", "depends what you're doing", "maybe, haven't tested it yet"});

        return Pick({"yeah lol", "fair", "same tbh", "true", "haha yep"});
    }

    void StartNext()
    {
        // assumes g_mutex held
        if (g_pending.empty())
            return;
        if (g_PBChatMaxConcurrent != 0 && g_running >= (int)g_PBChatMaxConcurrent)
            return;
        PBChatJob job = std::move(g_pending.front());
        g_pending.pop();
        ++g_running;
        std::thread(RunJob, std::move(job)).detach();
    }

    void RunJob(PBChatJob job)
    {
        std::string reply;
        if (job.lore)
            reply = PBChatterLore::Ask(job.lorePayload);   // sidecar first
        if (reply.empty())                                  // disabled/miss/timeout -> reactive LLM fallback
            reply = PBChatterOllama::Ask(job.systemPrompt, job.prompt);

        if (job.groundedAgainstFallback && !job.fallbackReply.empty() &&
            !GroundedReplyAllowed(reply, job.fallbackReply))
        {
            if (g_PBChatDebug && !reply.empty())
                LOG_INFO("server.loading", "[PlayerbotChatter] Rejected ungrounded system rewrite for bot {}; using deterministic fallback.", job.botGuid);
            reply = job.fallbackReply;
        }

        // Safety-critical producers may provide their own grounded text. This must win over the
        // generic conversational fallback, which is intentionally casual and therefore unsuitable
        // for mechanics/assignment announcements.
        if (reply.empty() && !job.fallbackReply.empty())
            reply = job.fallbackReply;
        if (reply.empty() && !job.ambient)
            reply = FallbackReply(job);                     // model unavailable -> tiny local safety net

        if (!reply.empty())
        {
            if (!job.ambient && job.storeMemory)
                PBChatterMemory::Append(job.botGuid, job.playerGuid, job.playerMessage, reply);
            std::lock_guard<std::mutex> lock(g_resultMutex);
            PBChatResult r;
            r.botGuid           = job.botGuid;
            r.playerGuid        = job.playerGuid;
            r.playerName        = job.playerName;
            r.channel           = job.channel;
            r.reply             = reply;
            r.ambient           = job.ambient;
            r.ambientKind       = job.ambientKind;
            r.ambientIdent      = job.ambientIdent;
            r.anchorPlayerGuid  = job.anchorPlayerGuid;
            g_results.push_back(std::move(r));
        }
        else if (g_PBChatDebug)
        {
            // Empty after a successful POST usually means the model returned no text.
            // Drop silently in normal operation; surface it when debugging.
            LOG_INFO("server.loading", "[PlayerbotChatter] Empty reply for bot {} -> no message sent.", job.botGuid);
        }
        std::lock_guard<std::mutex> lock(g_mutex);
        --g_running;
        StartNext();
    }
}

void PBChatterQueue::Submit(PBChatJob job)
{
    std::lock_guard<std::mutex> lock(g_mutex);
    g_pending.push(std::move(job));
    StartNext();
}

std::vector<PBChatResult> PBChatterQueue::DrainResults()
{
    std::lock_guard<std::mutex> lock(g_resultMutex);
    std::vector<PBChatResult> out;
    out.swap(g_results);
    return out;
}

bool PBChatterQueue::TrySubmitAmbient(PBChatJob job)
{
    std::lock_guard<std::mutex> lock(g_mutex);
    // Reactive-first: only run ambient when there is idle headroom and no backlog.
    if (!g_pending.empty())
        return false;
    if (g_PBChatMaxConcurrent != 0 && g_running >= (int)g_PBChatMaxConcurrent)
        return false;
    g_pending.push(std::move(job));
    StartNext();
    return true;
}
