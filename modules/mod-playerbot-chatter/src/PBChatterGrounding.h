#ifndef PB_CHATTER_GROUNDING_H
#define PB_CHATTER_GROUNDING_H

#include <cctype>
#include <string>

namespace PBChatterGrounding
{
    // A vocabulary overlap test cannot validate semantics: swapping tank/healer assignments,
    // dropping "not", or changing a single-digit count can preserve the same word set.
    // Accept presentation-only changes while retaining every ordered token and punctuation mark.
    // Richer narration needs structured, independently validated facts before it can be trusted.
    inline bool GroundedReplyAllowed(std::string const& reply, std::string const& fallback)
    {
        auto normalize = [](std::string const& text)
        {
            std::string result;
            bool space = false;
            for (unsigned char c : text)
            {
                if (std::isspace(c))
                {
                    space = !result.empty();
                    continue;
                }
                if (space)
                    result.push_back(' ');
                space = false;
                result.push_back(static_cast<char>(std::tolower(c)));
            }
            return result;
        };
        return !reply.empty() && !fallback.empty() && normalize(reply) == normalize(fallback);
    }

}

#endif
