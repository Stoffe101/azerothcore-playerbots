#include "PBChatterOllama.h"
#include "PBChatterConfig.h"
#include "PBChatterHttp.h"
#include "PBChatterJson.h"
#include "Log.h"
#include <nlohmann/json.hpp>
#include <atomic>
#include <chrono>
#include <regex>

namespace
{
    constexpr int64_t OLLAMA_FAILURE_BACKOFF_MS = 15000;
    std::atomic<int64_t> g_ollamaBackoffUntilMs{0};

    int64_t SteadyNowMs()
    {
        return std::chrono::duration_cast<std::chrono::milliseconds>(
            std::chrono::steady_clock::now().time_since_epoch()).count();
    }

    std::string Sanitize(std::string s)
    {
        // 1. Strip any <think>...</think> (defensive; reasoning despite think=false).
        s = std::regex_replace(s, std::regex(R"(<think>[\s\S]*?</think>)", std::regex::icase), "");
        s = std::regex_replace(s, std::regex(R"(</?think>)", std::regex::icase), "");
        // 2. Strip markdown emphasis / asterisk-actions / backticks.
        s = std::regex_replace(s, std::regex(R"(\*+)"), "");
        s = std::regex_replace(s, std::regex("`+"), "");
        // 3. Trim whitespace.
        size_t a = s.find_first_not_of(" \t\r\n");
        size_t b = s.find_last_not_of(" \t\r\n");
        if (a == std::string::npos)
            return "";
        s = s.substr(a, b - a + 1);
        // 4. Strip a single pair of wrapping quotes.
        if (s.size() >= 2 && s.front() == '"' && s.back() == '"')
            s = s.substr(1, s.size() - 2);
        // 5. Length cap (cut at a word boundary if possible).
        if (s.size() > g_PBChatReplyMaxLen)
        {
            s = s.substr(0, g_PBChatReplyMaxLen);
            size_t sp = s.find_last_of(' ');
            if (sp != std::string::npos && sp > g_PBChatReplyMaxLen / 2)
                s = s.substr(0, sp);
        }
        return s;
    }
}

std::string PBChatterOllama::Ask(std::string const& systemPrompt, std::string const& prompt)
{
    int64_t const nowMs = SteadyNowMs();
    if (nowMs < g_ollamaBackoffUntilMs.load(std::memory_order_relaxed))
        return "";

    std::string body =
        std::string("{") +
        "\"model\":\""  + PBJsonEscape(g_PBChatModel)  + "\"," +
        "\"system\":\"" + PBJsonEscape(systemPrompt)   + "\"," +
        "\"prompt\":\"" + PBJsonEscape(prompt)         + "\"," +
        "\"stream\":false," +
        "\"think\":" + (g_PBChatThink ? "true" : "false") +
        "}";

    if (g_PBChatDebug)
        LOG_INFO("server.loading", "[PlayerbotChatter] -> Ollama: {}", body);

    std::string raw = PBChatterHttp::Post(g_PBChatUrl, body);
    if (raw.empty())
    {
        // One unreachable Ollama endpoint previously made every queued reactive/ambient job spend
        // its own connection timeout, producing a log storm and delaying the local reactive
        // fallback. Back off briefly after the first failed probe; reactive jobs then fall through
        // immediately to the local fallback while one new model probe is allowed every 15 seconds.
        g_ollamaBackoffUntilMs.store(nowMs + OLLAMA_FAILURE_BACKOFF_MS, std::memory_order_relaxed);
        return "";
    }

    g_ollamaBackoffUntilMs.store(0, std::memory_order_relaxed);

    std::string reply;
    try
    {
        nlohmann::json j = nlohmann::json::parse(raw);
        if (j.contains("response") && j["response"].is_string())
            reply = j["response"].get<std::string>();
    }
    catch (std::exception const& e)
    {
        LOG_WARN("server.loading", "[PlayerbotChatter] JSON parse failed: {}", e.what());
        return "";
    }

    reply = Sanitize(reply);
    if (g_PBChatDebug)
        LOG_INFO("server.loading", "[PlayerbotChatter] <- reply: {}", reply);
    return reply;
}
