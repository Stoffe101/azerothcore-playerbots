#!/usr/bin/env python3
"""Harvest engine-native WoWSims RaidSimRequest presets from pinned upstream test suites.

This tool runs only inside the WoWSims Docker builder against an exact pinned
checkout. It instruments the upstream Go test harness, runs spec tests that call
core.RunTestSuite, and captures the already-constructed Average RaidSimRequest
without executing the simulation itself.
"""
from __future__ import annotations

import argparse
import copy
import hashlib
import json
import os
from pathlib import Path
import re
import subprocess
import tempfile
from typing import Any

SIGNATURES = {
    "WOTLK": "func RunTestSuite(t *testing.T, suiteName string, generator TestGenerator) {",
    "VANILLA": "func RunTestSuite(t *testing.T, suiteName string, generators []TestGenerator) {",
    "TBC": "func RunTestSuite(t *testing.T, suiteName string, generators []TestGenerator) {",
}

INJECTIONS = {
    "WOTLK": """func RunTestSuite(t *testing.T, suiteName string, generator TestGenerator) {
\tif dumpDir := os.Getenv("SKRRA_WOWSIM_DUMP_DIR"); dumpDir != "" {
\t\tif err := skrraDumpPresetGenerator(suiteName, generator, dumpDir); err != nil {
\t\t\tt.Fatal(err)
\t\t}
\t\treturn
\t}
""",
    "VANILLA": """func RunTestSuite(t *testing.T, suiteName string, generators []TestGenerator) {
\tif dumpDir := os.Getenv("SKRRA_WOWSIM_DUMP_DIR"); dumpDir != "" {
\t\tif err := skrraDumpPresetGenerators(suiteName, generators, dumpDir); err != nil {
\t\t\tt.Fatal(err)
\t\t}
\t\treturn
\t}
""",
    "TBC": """func RunTestSuite(t *testing.T, suiteName string, generators []TestGenerator) {
\tif dumpDir := os.Getenv("SKRRA_WOWSIM_DUMP_DIR"); dumpDir != "" {
\t\tif err := skrraDumpPresetGenerators(suiteName, generators, dumpDir); err != nil {
\t\t\tt.Fatal(err)
\t\t}
\t\treturn
\t}
""",
}

HELPER_COMMON = r'''package core

import (
    "fmt"
    "os"
    "path/filepath"
    "regexp"
    "strings"

    "google.golang.org/protobuf/encoding/protojson"
)

var skrraPresetSafeName = regexp.MustCompile(`[^A-Za-z0-9_.-]+`)

func skrraPresetName(value string) string {
    value = strings.Trim(skrraPresetSafeName.ReplaceAllString(value, "_"), "_")
    if value == "" {
        return "preset"
    }
    return value
}

func skrraDumpCombinedPreset(suiteName string, ordinal int, generator TestGenerator, outDir string) error {
    combined, ok := generator.(*CombinedTestGenerator)
    if !ok {
        return nil
    }

    for _, child := range combined.subgenerators {
        if !strings.Contains(strings.ToLower(child.name), "average") {
            continue
        }
        if child.generator.NumTests() == 0 {
            continue
        }
        childName, _, _, request := child.generator.GetTest(0)
        if request == nil {
            continue
        }
        body, err := (protojson.MarshalOptions{Indent: "  "}).Marshal(request)
        if err != nil {
            return fmt.Errorf("marshal %s/%s: %w", suiteName, child.name, err)
        }
        filename := fmt.Sprintf(
            "%s__g%02d__%s__%s.json",
            skrraPresetName(suiteName), ordinal,
            skrraPresetName(child.name), skrraPresetName(childName),
        )
        if err := os.MkdirAll(outDir, 0o755); err != nil {
            return err
        }
        if err := os.WriteFile(filepath.Join(outDir, filename), append(body, '\n'), 0o644); err != nil {
            return err
        }
    }
    return nil
}
'''

HELPER_SINGLE = HELPER_COMMON + r'''
func skrraDumpPresetGenerator(suiteName string, generator TestGenerator, outDir string) error {
    return skrraDumpCombinedPreset(suiteName, 0, generator, outDir)
}
'''

HELPER_SLICE = HELPER_COMMON + r'''
func skrraDumpPresetGenerators(suiteName string, generators []TestGenerator, outDir string) error {
    for ordinal, generator := range generators {
        if err := skrraDumpCombinedPreset(suiteName, ordinal, generator, outDir); err != nil {
            return err
        }
    }
    return nil
}
'''

TEST_FUNC_RE = re.compile(r"(?m)^func\s+(Test[A-Za-z0-9_]+)\s*\(\s*t\s+\*testing\.T\s*\)\s*\{")


def sanitize(value: str) -> str:
    value = re.sub(r"[^A-Za-z0-9_.-]+", "_", value).strip("_")
    return value or "preset"


def snake_to_camel(value: str) -> str:
    parts = value.split("_")
    return parts[0] + "".join(part[:1].upper() + part[1:] for part in parts[1:])


def dominant_tree(talents: str) -> tuple[int, list[int]]:
    parts = (talents.split("-") + ["", ""])[:3]
    points = [sum(int(char) for char in part if char.isdigit()) for part in parts]
    tree = max(range(3), key=lambda idx: points[idx])
    return tree, points


def find_function_body(text: str, start: int) -> str:
    brace = text.find("{", start)
    if brace < 0:
        return ""
    depth = 0
    state = "code"
    quote = ""
    i = brace
    while i < len(text):
        ch = text[i]
        nxt = text[i + 1] if i + 1 < len(text) else ""
        if state == "line_comment":
            if ch == "\n":
                state = "code"
        elif state == "block_comment":
            if ch == "*" and nxt == "/":
                state = "code"
                i += 1
        elif state == "string":
            if ch == "\\":
                i += 1
            elif ch == quote:
                state = "code"
        elif state == "raw_string":
            if ch == "`":
                state = "code"
        else:
            if ch == "/" and nxt == "/":
                state = "line_comment"
                i += 1
            elif ch == "/" and nxt == "*":
                state = "block_comment"
                i += 1
            elif ch in ('"', "'"):
                state = "string"
                quote = ch
            elif ch == "`":
                state = "raw_string"
            elif ch == "{":
                depth += 1
            elif ch == "}":
                depth -= 1
                if depth == 0:
                    return text[brace : i + 1]
        i += 1
    return ""


def discover_suite_tests(source: Path) -> dict[Path, list[str]]:
    grouped: dict[Path, list[str]] = {}
    sim_root = source / "sim"
    for path in sorted(sim_root.rglob("*_test.go")):
        relative = path.relative_to(sim_root)
        # Match Go package traversal: directories beginning '_' or '.' are ignored.
        # WoWSims keeps some intentionally disabled/stale spec implementations there.
        if any(part.startswith(("_", ".")) for part in relative.parts[:-1]):
            continue
        text = path.read_text(encoding="utf-8")
        names: list[str] = []
        for match in TEST_FUNC_RE.finditer(text):
            body = find_function_body(text, match.start())
            if "RunTestSuite(" in body:
                names.append(match.group(1))
        if names:
            grouped.setdefault(path.parent, []).extend(names)
    return grouped


def instrument_source(source: Path, era: str) -> None:
    suite = source / "sim" / "core" / "test_suite.go"
    text = suite.read_text(encoding="utf-8")
    if "SKRRA_WOWSIM_DUMP_DIR" not in text:
        signature = SIGNATURES[era]
        if text.count(signature) != 1:
            raise RuntimeError(f"expected exactly one RunTestSuite signature for {era}")
        text = text.replace(signature, INJECTIONS[era], 1)
        suite.write_text(text, encoding="utf-8")

    helper = source / "sim" / "core" / "skrra_preset_dump.go"
    helper.write_text(HELPER_SINGLE if era == "WOTLK" else HELPER_SLICE, encoding="utf-8")


def run_suite_tests(source: Path, raw_output: Path) -> int:
    groups = discover_suite_tests(source)
    if not groups:
        raise RuntimeError("no RunTestSuite spec tests discovered")
    total = 0
    for package_dir, test_names in groups.items():
        rel = package_dir.relative_to(source).as_posix()
        package_output = raw_output / sanitize(rel)
        package_output.mkdir(parents=True, exist_ok=True)
        pattern = "^(" + "|".join(re.escape(name) for name in sorted(set(test_names))) + ")$"
        env = dict(os.environ)
        env["SKRRA_WOWSIM_DUMP_DIR"] = str(package_output)
        env.setdefault("GOMAXPROCS", "4")
        proc = subprocess.run(
            ["go", "test", "./" + rel, "-run", pattern, "-count=1"],
            cwd=source,
            env=env,
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            timeout=300,
        )
        if proc.returncode != 0:
            raise RuntimeError(f"preset harvest failed for {rel}:\n{proc.stdout[-6000:]}")
        total += len(set(test_names))
    return total


def find_player(request: dict[str, Any]) -> tuple[dict[str, Any], dict[str, Any]]:
    raid = request.get("raid")
    if not isinstance(raid, dict):
        raise ValueError("request has no raid object")
    parties = raid.get("parties")
    if not isinstance(parties, list) or not parties:
        raise ValueError("request has no raid parties")
    players = parties[0].get("players") if isinstance(parties[0], dict) else None
    if not isinstance(players, list) or not players or not isinstance(players[0], dict):
        raise ValueError("request has no first player")
    return raid, players[0]


AUTHORITATIVE_OVERLAY_PLAYER_FIELDS = frozenset({
    "name", "race", "class", "equipment", "talentsString",
    "profession1", "profession2", "glyphs",
})


def preset_assumptions_sha256(request: dict[str, Any]) -> str:
    """Fingerprint only preset-owned assumptions that survive server overlay."""
    normalized = copy.deepcopy(request)
    _, player = find_player(normalized)
    for field in AUTHORITATIVE_OVERLAY_PLAYER_FIELDS:
        player.pop(field, None)
    canonical = json.dumps(normalized, sort_keys=True, separators=(",", ":")).encode("utf-8")
    return hashlib.sha256(canonical).hexdigest()


def assign_canonical_presets(routes: dict[str, list[dict[str, Any]]], era: str) -> None:
    """Choose a canonical request only when upstream candidates are safely equivalent."""
    unresolved: dict[str, list[dict[str, str]]] = {}
    for route_key, entries in routes.items():
        for entry in entries:
            entry["canonical"] = False

        if len(entries) == 1:
            entries[0]["canonical"] = True
            entries[0]["selectionMethod"] = "single-engine-native-preset"
            continue

        assumption_hashes = {str(entry.get("assumptionsSha256", "")) for entry in entries}
        if len(assumption_hashes) != 1:
            unresolved[route_key] = [
                {
                    "source": str(entry.get("source", "")),
                    "sha256": str(entry.get("sha256", "")),
                    "assumptionsSha256": str(entry.get("assumptionsSha256", "")),
                }
                for entry in entries
            ]
            continue

        selected = min(entries, key=lambda entry: str(entry["sha256"]))
        selected["canonical"] = True
        selected["selectionMethod"] = "equivalent-after-authoritative-overlay"

    if unresolved:
        raise RuntimeError(
            f"{era} has non-equivalent preset candidates requiring explicit policy: "
            + json.dumps(unresolved, sort_keys=True)
        )


def resolve_route(catalog: dict[str, Any], era: str, request: dict[str, Any]) -> dict[str, Any]:
    raid, player = find_player(request)
    talents = player.get("talentsString", "")
    if not isinstance(talents, str) or not talents:
        raise ValueError("request player has no talentsString")
    tree, points = dominant_tree(talents)

    entry = catalog["eras"][era]
    field = None
    for candidate in entry["proto_spec_fields"]:
        if snake_to_camel(candidate) in player:
            field = candidate
            break
    if not field:
        raise ValueError("request player has no catalogued spec field")

    candidates = [
        route
        for route in entry["routes"]
        if route["protoSpecField"] == field and tree in route["trees"]
    ]
    if not candidates:
        raise ValueError(f"no catalog route for {field} tree {tree}")

    roles = {role for route in candidates for role in route["roles"]}
    if "TANK" in roles and raid.get("tanks"):
        role = "TANK"
    elif "HEALER" in roles and int(raid.get("targetDummies", 0) or 0) > 0:
        role = "HEALER"
    elif "DPS" in roles:
        role = "DPS"
    elif len(roles) == 1:
        role = next(iter(roles))
    else:
        raise ValueError(f"ambiguous role for {field} tree {tree}: {sorted(roles)}")

    matches = [route for route in candidates if role in route["roles"]]
    if len(matches) != 1:
        raise ValueError(f"ambiguous catalog route for {field} tree {tree} role {role}")
    route = matches[0]
    return {
        "classId": route["classId"],
        "tree": tree,
        "treePoints": points,
        "role": role,
        "protoSpecField": field,
    }


def build_index(
    raw_output: Path,
    output: Path,
    catalog: dict[str, Any],
    era: str,
    commit: str,
) -> dict[str, Any]:
    requests_dir = output / "requests"
    requests_dir.mkdir(parents=True, exist_ok=True)
    routes: dict[str, list[dict[str, Any]]] = {}
    unclassified: list[dict[str, str]] = []
    seen_hashes: set[tuple[str, str]] = set()

    for source_file in sorted(raw_output.rglob("*.json")):
        request = json.loads(source_file.read_text(encoding="utf-8"))
        try:
            route = resolve_route(catalog, era, request)
        except Exception as exc:
            unclassified.append(
                {"source": str(source_file.relative_to(raw_output)), "error": str(exc)}
            )
            continue

        canonical = json.dumps(request, sort_keys=True, separators=(",", ":")).encode("utf-8")
        digest = hashlib.sha256(canonical).hexdigest()
        route_key = f'{route["classId"]}:{route["tree"]}:{route["role"]}'
        if (route_key, digest) in seen_hashes:
            continue
        seen_hashes.add((route_key, digest))

        dest_name = f'{sanitize(route_key)}__{digest[:16]}.json'
        dest = requests_dir / dest_name
        dest.write_text(
            json.dumps(request, indent=2, sort_keys=True) + "\n",
            encoding="utf-8",
        )
        routes.setdefault(route_key, []).append(
            {
                **route,
                "file": f"requests/{dest_name}",
                "sha256": digest,
                "assumptionsSha256": preset_assumptions_sha256(request),
                "source": str(source_file.relative_to(raw_output)),
            }
        )

    if not routes:
        raise RuntimeError(f"no {era} presets could be classified")
    if unclassified:
        raise RuntimeError(
            f"{era} produced {len(unclassified)} unclassified presets: {unclassified[:5]}"
        )

    assign_canonical_presets(routes, era)

    index = {
        "schema": 1,
        "era": era,
        "engineCommit": commit,
        "source": "pinned upstream FullCharacterTestSuiteGenerator Average RaidSimRequest",
        "canonicalPolicy": "authoritative-overlay-equivalence-v1",
        "canonicalRouteCount": len(routes),
        "routes": {key: routes[key] for key in sorted(routes)},
        "routeCount": len(routes),
        "requestCount": sum(len(values) for values in routes.values()),
    }
    (output / "preset-index.json").write_text(
        json.dumps(index, indent=2, sort_keys=True) + "\n",
        encoding="utf-8",
    )
    return index


def harvest(source: Path, era: str, output: Path, model_support: Path, commit: str) -> None:
    era = era.upper()
    if era not in SIGNATURES:
        raise RuntimeError("era must be VANILLA, TBC or WOTLK")
    if not (source / "go.mod").is_file():
        raise RuntimeError(f"{source} does not look like a WoWSims checkout")
    catalog = json.loads(model_support.read_text(encoding="utf-8"))
    entry = catalog["eras"].get(era)
    if not entry or entry.get("commit") != commit:
        raise RuntimeError(f"model catalog commit mismatch for {era}")

    output.mkdir(parents=True, exist_ok=True)
    with tempfile.TemporaryDirectory(prefix=f"skrra-{era.lower()}-presets-") as tmp:
        raw_output = Path(tmp)
        instrument_source(source, era)
        tests = run_suite_tests(source, raw_output)
        index = build_index(raw_output, output, catalog, era, commit)
    print(
        f"{era}: harvested {index['requestCount']} unique preset requests "
        f"across {index['routeCount']} routes from {tests} upstream test functions"
    )


def self_test() -> None:
    assert snake_to_camel("feral_tank_druid") == "feralTankDruid"
    assert dominant_tree("23000513310033015032310250532-03-023303001")[0] == 0
    synthetic = """package mage

import "testing"
func TestArcane(t *testing.T) { core.RunTestSuite(t, t.Name(), thing) }
func TestOther(t *testing.T) { if true { t.Log("x") } }
"""
    with tempfile.TemporaryDirectory() as tmp:
        root = Path(tmp)
        test_file = root / "sim" / "mage" / "mage_test.go"
        test_file.parent.mkdir(parents=True)
        test_file.write_text(synthetic, encoding="utf-8")
        disabled = root / "sim" / "_disabled" / "disabled_test.go"
        disabled.parent.mkdir(parents=True)
        disabled.write_text(
            'package disabled\nimport "testing"\nfunc TestDisabled(t *testing.T) { core.RunTestSuite(t, t.Name(), thing) }\n',
            encoding="utf-8",
        )
        found = discover_suite_tests(root)
        assert list(found.values()) == [["TestArcane"]]

    catalog = {
        "eras": {
            "WOTLK": {
                "proto_spec_fields": ["mage"],
                "routes": [
                    {
                        "classId": 8,
                        "trees": [0, 1, 2],
                        "roles": ["DPS"],
                        "protoSpecField": "mage",
                    }
                ],
            }
        }
    }
    request = {
        "raid": {
            "parties": [
                {
                    "players": [
                        {
                            "talentsString": "23000513310033015032310250532-03-023303001",
                            "mage": {},
                        }
                    ]
                }
            ]
        },
        "encounter": {},
        "simOptions": {},
    }
    route = resolve_route(catalog, "WOTLK", request)
    assert route["classId"] == 8 and route["tree"] == 0 and route["role"] == "DPS"

    equivalent = copy.deepcopy(request)
    _, equivalent_player = find_player(equivalent)
    equivalent_player["name"] = "Different upstream fixture"
    equivalent_player["race"] = "RaceGnome"
    equivalent_player["equipment"] = {"items": [{"id": 12345}]}
    equivalent_player["talentsString"] = "different-talents-that-server-overwrites"
    assert preset_assumptions_sha256(equivalent) == preset_assumptions_sha256(request)

    distinct = copy.deepcopy(request)
    distinct["encounter"] = {"duration": 240}
    assert preset_assumptions_sha256(distinct) != preset_assumptions_sha256(request)

    same = preset_assumptions_sha256(request)
    canonical_routes = {"8:0:DPS": [
        {"sha256": "b" * 64, "source": "b", "assumptionsSha256": same},
        {"sha256": "a" * 64, "source": "a", "assumptionsSha256": same},
    ]}
    assign_canonical_presets(canonical_routes, "WOTLK")
    assert canonical_routes["8:0:DPS"][1]["canonical"] is True
    assert canonical_routes["8:0:DPS"][1]["selectionMethod"] == "equivalent-after-authoritative-overlay"

    try:
        assign_canonical_presets({"8:0:DPS": [
            {"sha256": "a" * 64, "source": "a", "assumptionsSha256": "1" * 64},
            {"sha256": "b" * 64, "source": "b", "assumptionsSha256": "2" * 64},
        ]}, "WOTLK")
    except RuntimeError as exc:
        assert "non-equivalent preset candidates" in str(exc)
    else:
        raise AssertionError("non-equivalent presets must fail closed")

    print("WoWSims preset harvester self-test passed.")


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--source", type=Path)
    parser.add_argument("--era")
    parser.add_argument("--output", type=Path)
    parser.add_argument("--model-support", type=Path)
    parser.add_argument("--commit")
    parser.add_argument("--self-test", action="store_true")
    args = parser.parse_args()
    if args.self_test:
        self_test()
        return
    required = [args.source, args.era, args.output, args.model_support, args.commit]
    if any(value is None for value in required):
        parser.error(
            "--source, --era, --output, --model-support and --commit are required"
        )
    harvest(args.source, args.era, args.output, args.model_support, args.commit)


if __name__ == "__main__":
    main()
