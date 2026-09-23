#!/usr/bin/env python3
"""Permanent source contracts for the bounded ERA-13/ERA-18 world slice."""

import argparse
import json
import shlex
import subprocess
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
TITAN = (ROOT / "modules/mod-titan-rune/src/TitanRuneSystem.cpp").read_text()
AUDIT = (ROOT / "modules/mod-raid-roster/src/EraAuditCommand.cpp").read_text()
GATE = "EraPolicy::IsEraReleased(EraPolicy::Era::Wotlk)"


def body(source: str, start: str, end: str) -> str:
    assert start in source and end in source, (start, end)
    return source.split(start, 1)[1].split(end, 1)[0]


def check_contracts() -> None:
    assert GATE in body(TITAN, "bool EnsureDalaranNpcs()", "uint32 CurrencyForVendor")
    assert GATE in body(TITAN, "bool IsEligibleHeroicMap(", "void Notify(")
    assert GATE in body(TITAN, "bool IsSupportedDungeon(", "void ActivateForPlayer(")
    assert GATE in body(TITAN, "void OnUpdate(uint32 diff) override", "class TitanRuneInstanceLifecycleScript")
    for script in ("npc_titan_rune_coordinator", "npc_titan_sidereal_vendor", "npc_titan_scourgestone_vendor"):
        section = body(TITAN, "class " + script, "class " if script != "npc_titan_scourgestone_vendor" else "class TitanRuneCommandScript")
        assert section.count(GATE) >= 2, script
    exchange = body(TITAN, "else if (action == 30001)", "ShowVendorPage(player, creature, VENDOR_SCOURGESTONE, 0)")
    assert "DestroyItemCount" in exchange and "ItemProvenanceReady" in exchange
    assert exchange.index("ItemProvenanceReady") < exchange.index("DestroyItemCount")
    assert "WorldDatabase.DirectExecute" not in AUDIT
    assert "DELETE FROM" not in AUDIT and "UPDATE " not in AUDIT
    for source in (
        "creature", "gameobject", "npc_vendor", "game_event_npc_vendor",
        "npc_trainer", "creature_default_trainer", "creature_template_addon",
        "creature_queststarter", "creature_questender",
        "gameobject_queststarter", "gameobject_questender", "quest_template",
        "mod_titan_rune_vendor_spawns",
    ):
        assert source in AUDIT, source
    assert "examples.size() < 5" in AUDIT
    assert "unknownContentChronology=" in AUDIT
    assert "information_schema.COLUMNS" in AUDIT and "c.id2" in AUDIT and "c.id3" in AUDIT
    assert "EraPolicy::TryMapEra" in AUDIT and "EraPolicy::TryItemEra" in AUDIT
    print("ERA world containment source contracts: PASS")


def compile_sources(build: Path) -> None:
    entries = json.loads((build / "compile_commands.json").read_text())
    sources = {
        "TitanRuneSystem.cpp": ROOT / "modules/mod-titan-rune/src/TitanRuneSystem.cpp",
        "EraAuditCommand.cpp": ROOT / "modules/mod-raid-roster/src/EraAuditCommand.cpp",
    }
    includes = [ROOT / "modules/mod-raid-roster/src", ROOT / "modules/mod-titan-rune/src"]
    for name, source in sources.items():
        matches = [entry for entry in entries if Path(entry["file"]).name == name]
        assert len(matches) == 1, (name, len(matches))
        command = shlex.split(matches[0]["command"])
        output = command.index("-o")
        del command[output:output + 2]
        command.remove("-c")
        command[-1] = str(source)
        command[1:1] = ["-fsyntax-only", "-Werror", *(f"-I{path}" for path in includes)]
        print(f"Focused Clang: {name}", flush=True)
        subprocess.run(command, cwd=build, check=True)


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--compile-build", type=Path)
    args = parser.parse_args()
    check_contracts()
    if args.compile_build:
        compile_sources(args.compile_build)
