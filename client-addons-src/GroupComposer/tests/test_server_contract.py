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
SERVER = (ROOT / "modules/mod-raid-roster/src/GroupComposerCommand.cpp").read_text(encoding="utf-8")


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

print("Group Composer client/server contract tests passed")
