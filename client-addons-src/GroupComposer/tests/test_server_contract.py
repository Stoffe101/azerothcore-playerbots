#!/usr/bin/env python3
"""Static client/server contract tests for Group Composer.

The 3.3.5a addon deliberately owns presentation metadata while the C++ backend owns
validation and runtime actions. These assertions make duplicated activity identifiers and
critical assembly-safety hooks fail CI loudly instead of drifting silently.
"""

from pathlib import Path
import re

ROOT = Path(__file__).resolve().parents[3]
DATA = (ROOT / "client-addons-src/GroupComposer/Data.lua").read_text(encoding="utf-8")
POLISH = (ROOT / "client-addons-src/GroupComposer/Polish.lua").read_text(encoding="utf-8")
SERVER = (ROOT / "modules/mod-raid-roster/src/GroupComposerCommand.cpp").read_text(encoding="utf-8")
PLANNER = (ROOT / "modules/mod-raid-roster/src/GroupComposerPlanner.cpp").read_text(encoding="utf-8")
TYPES = (ROOT / "modules/mod-raid-roster/src/GroupComposerTypes.h").read_text(encoding="utf-8")


def section(text: str, start: str, end: str) -> str:
    a = text.index(start)
    b = text.index(end, a + len(start))
    return text[a:b]


def ids(block: str) -> list[str]:
    return re.findall(r'\bid\s*=\s*"([^"]+)"', block)


dungeon_data = section(DATA, "D.DUNGEONS = {", "D.DUNGEON_DIFFICULTIES = {")
raid_data = section(DATA, "D.RAIDS = {", "D.RAID_DIFFICULTIES = {")
raid_server = section(SERVER, "bool RaidSupports(", "uint32 DungeonMapId(")
dungeon_server = section(SERVER, "uint32 DungeonMapId(", "bool IsBotGuid(")

client_dungeons: dict[str, int] = {}
for entry in re.finditer(r'\{\s*id\s*=\s*"([^"]+)"([^}]*)\}', dungeon_data):
    dungeon_id, body = entry.group(1), entry.group(2)
    map_match = re.search(r'\bmap\s*=\s*(\d+)', body)
    if map_match:
        client_dungeons[dungeon_id] = int(map_match.group(1))

server_dungeons = {
    name: int(map_id)
    for name, map_id in re.findall(r'\{\s*"([^"]+)"\s*,\s*(\d+)\s*\}', dungeon_server)
}
assert client_dungeons, "No addon dungeon map metadata parsed"
assert client_dungeons == server_dungeons, (
    "Dungeon activity/map contract drift:\n"
    f"addon={client_dungeons}\nserver={server_dungeons}"
)

client_dungeon_ids = ids(dungeon_data)
assert "random" in client_dungeon_ids, "Addon lost Random Dungeon"
assert 'plan.config.activity == "random"' in SERVER, "Backend lost Random Dungeon handling"

client_raids = ids(raid_data)
assert client_raids, "No addon raid metadata parsed"
missing_raids = [raid for raid in client_raids if f'"{raid}"' not in raid_server]
assert not missing_raids, f"Raid activity missing from backend validator: {missing_raids}"

difficulty_data = section(DATA, "D.DUNGEON_DIFFICULTIES = {", "D.RAIDS = {")
client_difficulties = ids(difficulty_data)
assert client_difficulties == ["normal", "heroic", "alpha", "beta", "gamma"], client_difficulties
for mode in ("alpha", "beta", "gamma"):
    assert f'difficulty != "{mode}"' in SERVER or f'difficulty == "{mode}"' in SERVER, (
        f"Backend no longer mentions Titan Rune mode {mode}"
    )
assert "Titan Rune queue handoff is not represented by stock 3.3.5a RDF difficulty IDs" in SERVER
assert "GetLFGDungeon(mapId, difficulty)" in SERVER

for command in (
    "begin", "pref", "humanrole", "human", "pin", "arrangepref", "find", "arrange",
    "move", "assemble", "queue", "anchors", "diagnostics", "clear", "status",
):
    assert re.search(r'\{\s*"' + re.escape(command) + r'"\s*,', SERVER), (
        f"Missing server command registration: {command}"
    )

# Client safety contracts. A passive status sync must not leave the whole addon action-locked, and
# Assemble must remain an explicit commit step rather than a one-click destructive operation.
assert 'if GC.pendingCommand == "status" then GC.pendingCommand = nil end' in POLISH, (
    "Passive status synchronization can leave the composer permanently action-locked"
)
assert 'StaticPopupDialogs["GROUPCOMPOSER_CONFIRM_ASSEMBLY"]' in POLISH, (
    "Live roster assembly lost its explicit confirmation boundary"
)
assert 'StaticPopup_Show("GROUPCOMPOSER_CONFIRM_ASSEMBLY"' in POLISH, (
    "Assemble no longer routes through the confirmation popup"
)

# Safety invariants. These are intentionally source-level contracts because removing any one of
# them changes the destructive semantics even if the module still compiles.
assert "ValidateAssemblySnapshot(master, plan, validationError)" in SERVER, "Assemble lost pre-prune revalidation"
assert SERVER.index("ValidateAssemblySnapshot(master, plan, validationError)") < SERVER.index("PruneUnselectedBots(master, plan)"), (
    "Destructive pruning must happen only after snapshot revalidation"
)
assert "group->SwapMembersGroup(member.guid, swap->guid)" in SERVER, "Full raid subgroup swaps are no longer applied atomically"
assert "group->GetMembersCount() == plan.members.size()" in SERVER, "Assembly must require exact reviewed membership"
assert "(void)keepMe; config.keepMe = true" in SERVER, "Local player anchor must remain mandatory server-side"
assert "The group gained a real player after the preview" in SERVER, "Late human joins must force a fresh preview"

# A real player's invite is user-facing state, not a retryable bot operation. One explicit Assemble
# may send a human invite once; a later explicit Assemble is the retry boundary.
assert "std::unordered_set<uint32> humanInvitesSent;" in TYPES, "Plan lost one-shot human invite tracking"
assert "plan.humanInvitesSent.clear();" in SERVER, "Fresh Assemble must reset its human invite attempt set"
assert "plan.humanInvitesSent.count(member.guid.GetCounter())" in SERVER, "Assembly can re-invite a human repeatedly"
assert "plan.humanInvitesSent.insert(member.guid.GetCounter())" in SERVER, "Sent human invites are not remembered"

# Instance conflicts mirror the stock invite rule: different instance IDs are incompatible only
# when both players are in different copies of the same map. Merely being in different instances on
# different maps must not make an otherwise eligible friend/bot disappear from the candidate pool.
planner_instances = section(PLANNER, "bool ConflictingInstances(", "void AddCoverage(")
assert "master->GetMapId() == other->GetMapId()" in planner_instances, (
    "Planner instance-conflict filtering drifted from the stock group-invite rule"
)

# Selection priority is part of correctness. Required pins and Required class/spec rows are hard
# constraints. Preferred pins may be chosen before ordinary score-based filling, but never before a
# hard class/spec requirement that could need the same final role slot.
build = section(PLANNER, "bool Planner::Build(", "void Planner::Arrange(")
required_pin_pos = build.index("if (!pin.required) continue;")
required_pref_pos = build.index("std::unordered_set<uint32> requiredMemberUsed;")
preferred_pin_pos = build.index("if (pin.required) continue;")
assert required_pin_pos < required_pref_pos < preferred_pin_pos, (
    "Preferred pins must not consume slots before all hard requirements are secured"
)
assert "member.pinned = true;" in build, "A hard-selected familiar pin must retain stable/pinned identity"

print("Group Composer client/server contract tests passed")
