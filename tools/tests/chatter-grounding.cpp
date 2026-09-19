#include "../../modules/mod-playerbot-chatter/src/PBChatterGrounding.h"

#include <cassert>

int main()
{
    using PBChatterGrounding::GroundedReplyAllowed;
    char const* brief = "Tank: Alice. Healer: Bob. Do not dispel. Stack 3 players.";
    assert(GroundedReplyAllowed(brief, brief));
    assert(GroundedReplyAllowed("  TANK: Alice.\nHealer: Bob. Do not dispel. Stack 3 players.  ", brief));
    assert(!GroundedReplyAllowed("Tank: Bob. Healer: Alice. Do not dispel. Stack 3 players.", brief));
    assert(!GroundedReplyAllowed("Tank: Alice. Healer: Bob. Do dispel. Stack 3 players.", brief));
    assert(!GroundedReplyAllowed("Tank: Alice. Healer: Bob. Do not dispel. Stack 5 players.", brief));
    assert(!GroundedReplyAllowed("Tank: Alice. Healer: Bob. Do not dispel. Stack 3 players. Interrupt Frostbolt.", brief));
    assert(!GroundedReplyAllowed("", brief));
    assert(!GroundedReplyAllowed("", ""));
    assert(!GroundedReplyAllowed(" \n", ""));
}
