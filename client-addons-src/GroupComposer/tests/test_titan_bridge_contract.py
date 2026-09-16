#!/usr/bin/env python3
from pathlib import Path

root = Path(__file__).resolve().parents[3]
polish = (root / "client-addons-src/GroupComposer/Polish.lua").read_text()
bridge = (root / "modules/mod-raid-roster/src/GroupComposerTitanRune.cpp").read_text()
loader = (root / "modules/mod-raid-roster/src/RaidRosterLoader.cpp").read_text()
titan_h = (root / "modules/mod-titan-rune/src/TitanRuneSystem.h").read_text()
titan_cpp = (root / "modules/mod-titan-rune/src/TitanRuneSystem.cpp").read_text()

required_client = [
    '.gctitan queue ',
    'ROLE_TOKEN = { TANK = "T", HEALER = "H", DPS = "D" }',
    'GC.pendingCommand = "queue"',
]
for token in required_client:
    assert token in polish, f"missing Titan Rune client handoff contract: {token}"

required_bridge = [
    'TitanRune::SaveSelectedMode(master, mode)',
    'TitanRune::IsSupportedDungeon(mapId, mode)',
    'GetLFGDungeon(mapId, DUNGEON_DIFFICULTY_HEROIC)',
    'sLFGMgr->JoinLfg(master, leaderRole, dungeons, "Group Composer Titan Rune")',
    'sLFGMgr->UpdateRoleCheck',
    'group->SetDungeonDifficulty(DUNGEON_DIFFICULTY_HEROIC)',
    'The live party no longer matches the reviewed Group Composer roster',
]
for token in required_bridge:
    assert token in bridge, f"missing Titan Rune server bridge contract: {token}"

assert 'AddGroupComposerTitanRuneScripts();' in loader
assert 'void SaveSelectedMode(Player* player, TitanRuneMode mode);' in titan_h
assert 'bool IsSupportedDungeon(uint32 mapId, TitanRuneMode mode);' in titan_h
assert 'Group leader selection wins.' in titan_cpp

# The bridge may queue a named supported dungeon or a safe multi-specific "random" set, but it must
# never use the stock Random Heroic category because that can select a dungeon unsupported by the
# chosen Alpha/Beta/Gamma protocol.
assert 'RANDOM_DUNGEON_HEROIC_WOTLK' not in bridge
assert 'TitanCandidateMaps(mode)' in bridge

# Every map the current Titan Rune implementation can support must be in the bridge's candidate
# universe. Mode-specific filtering remains authoritative in TitanRune::IsSupportedDungeon().
for map_id in (574, 575, 576, 578, 595, 599, 600, 601, 602, 604, 608, 619, 650, 632, 658, 668):
    assert str(map_id) in bridge, f"Titan Rune map {map_id} missing from queue candidate universe"

print("Group Composer Titan Rune bridge contract passed")
