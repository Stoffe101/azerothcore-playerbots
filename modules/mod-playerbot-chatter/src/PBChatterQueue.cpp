#include "PBChatterQueue.h"
#include "PBChatterGrounding.h"
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
            !PBChatterGrounding::GroundedReplyAllowed(reply, job.fallbackReply))
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
            r.briefGroupGuid    = job.briefGroupGuid;
            r.briefMapId        = job.briefMapId;
            r.briefInstanceId   = job.briefInstanceId;
            r.briefCreatedMs    = job.briefCreatedMs;
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
