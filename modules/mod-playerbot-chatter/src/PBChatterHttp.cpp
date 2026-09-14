#include "PBChatterHttp.h"
#include "PBChatterConfig.h"
#include "Log.h"
#include "httplib.h"
#include <regex>

std::string PBChatterHttp::Post(std::string const& url, std::string const& jsonBody, int readTimeoutSec)
{
    std::smatch m;
    std::regex re(R"(^(https?)://([^:/]+)(?::(\d+))?(/.*)?$)");
    if (!std::regex_match(url, m, re))
    {
        LOG_ERROR("server.loading", "[PlayerbotChatter] Bad URL: {}", url);
        return "";
    }
    if (m[1] == "https")
    {
        // httplib is built HTTP-only here (no CPPHTTPLIB_OPENSSL_SUPPORT). Refuse rather
        // than silently send cleartext to the https host/port.
        LOG_ERROR("server.loading", "[PlayerbotChatter] HTTPS not supported; use an http:// URL.");
        return "";
    }
    std::string host = m[2];
    int port = m[3].matched ? std::stoi(m[3]) : 80;
    std::string path = m[4].matched ? std::string(m[4]) : "/";

    httplib::Client cli(host, port);
    cli.set_connection_timeout(3, 0);
    cli.set_read_timeout(readTimeoutSec, 0);
    cli.set_write_timeout(10, 0);

    // Use the std::string body overload: Post(path, body, content_type)
    auto res = cli.Post(path, jsonBody, "application/json");
    if (!res)
    {
        // Include the actual destination. The old generic message made a stale container-local
        // localhost URL indistinguishable from a dead model host and cost several debugging loops.
        LOG_WARN(
            "server.loading",
            "[PlayerbotChatter] Ollama POST failed (no response) to http://{}:{}{}.",
            host,
            port,
            path);
        return "";
    }
    if (res->status != 200)
    {
        LOG_WARN(
            "server.loading",
            "[PlayerbotChatter] Ollama HTTP {} from http://{}:{}{}.",
            res->status,
            host,
            port,
            path);
        return "";
    }
    return res->body;
}
