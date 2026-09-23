#!/usr/bin/env python3
"""Syntax-check this slice against an already configured build of the exact base SHA."""

import argparse
import json
import shlex
import subprocess
from pathlib import Path


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("build", type=Path, help="configured build directory at the pinned base")
    parser.add_argument("transformed", type=Path, help="temporary transformed Playerbots source tree")
    parser.add_argument(
        "--expected-source-sha",
        help="optional exact source SHA guard for the configured checkout used to produce compile_commands.json",
    )
    args = parser.parse_args()
    root = Path(__file__).resolve().parents[1]
    if args.expected_source_sha:
        base = subprocess.check_output(
            ["git", "-C", str(args.build.parent), "rev-parse", "HEAD"], text=True
        ).strip()
        if base != args.expected_source_sha:
            raise SystemExit(
                f"configured build source is {base}, expected {args.expected_source_sha}"
            )
    commands = json.loads((args.build / "compile_commands.json").read_text())
    sources = {
        "EraPolicy.cpp": root / "modules/mod-raid-roster/src/EraPolicy.cpp",
        "EraAuditCommand.cpp": root / "modules/mod-raid-roster/src/EraAuditCommand.cpp",
        "RaidRosterLoader.cpp": root / "modules/mod-raid-roster/src/RaidRosterLoader.cpp",
        "PBAIGuildServices.cpp": root / "modules/mod-playerbot-chatter/src/PBAIGuildServices.cpp",
        "CastCustomSpellAction.cpp": args.transformed / "modules/mod-playerbots/src/Ai/Base/Actions/CastCustomSpellAction.cpp",
        "PlayerbotFactory.cpp": args.transformed / "modules/mod-playerbots/src/Bot/Factory/PlayerbotFactory.cpp",
    }
    include_dirs = [
        root / "modules/mod-raid-roster/src",
        root / "modules/mod-playerbot-chatter/src",
        args.transformed / "modules/mod-playerbots/src/Bot/Factory",
    ]
    for name, source in sources.items():
        matches = [entry for entry in commands if Path(entry["file"]).name == name]
        if len(matches) != 1:
            raise SystemExit(f"{name}: expected one compile command, found {len(matches)}")
        command = shlex.split(matches[0]["command"])
        output = command.index("-o")
        del command[output:output + 2]
        command.remove("-c")
        command[-1] = str(source)
        command[1:1] = [f"-I{directory}" for directory in include_dirs]
        command.insert(1, "-fsyntax-only")
        print(f"Checking {name}", flush=True)
        subprocess.run(command, cwd=args.build, check=True)


if __name__ == "__main__":
    main()
