#!/usr/bin/env python3
"""Generate deterministic Vanilla/TBC/WotLK item provenance from pinned CMaNGOS DB snapshots.

The generator intentionally does not guess from item id, required level, or item level.
For each live AzerothCore item_template entry it assigns the earliest era whose pinned
CMaNGOS full database contains that item id. IDs absent from all three snapshots are
UNKNOWN unless explicitly classified in overrides.csv.

Outputs are deterministic and are intended for automated systems such as AHBot.
UNKNOWN is fail-closed: it is disabled from automated listing in every era until reviewed.
"""

from __future__ import annotations

import argparse
import csv
import gzip
import hashlib
import json
import re
import sys
import tempfile
import urllib.request
from dataclasses import dataclass
from pathlib import Path
from typing import Iterable, Iterator

ERAS = ("vanilla", "tbc", "wotlk")
ERA_RANK = {"vanilla": 0, "tbc": 1, "wotlk": 2, "unknown": 99}
INSERT_RE = re.compile(r"^\s*INSERT\s+INTO\s+`?item_template`?\s+VALUES\s*", re.IGNORECASE)


@dataclass(frozen=True)
class Override:
    era: str
    note: str


def git_blob_sha(data: bytes) -> str:
    header = f"blob {len(data)}\0".encode("ascii")
    return hashlib.sha1(header + data).hexdigest()


def verify_source_bytes(data: bytes, meta: dict, label: str) -> None:
    expected_size = int(meta["size"])
    if len(data) != expected_size:
        raise ValueError(f"{label}: size mismatch: got {len(data)}, expected {expected_size}")
    actual_blob = git_blob_sha(data)
    expected_blob = meta["git_blob_sha"]
    if actual_blob != expected_blob:
        raise ValueError(f"{label}: git blob mismatch: got {actual_blob}, expected {expected_blob}")


def fetch_source(label: str, meta: dict, cache_dir: Path) -> Path:
    cache_dir.mkdir(parents=True, exist_ok=True)
    path = cache_dir / f"{label}-{meta['git_blob_sha']}.sql.gz"
    if path.exists():
        data = path.read_bytes()
        verify_source_bytes(data, meta, label)
        return path

    request = urllib.request.Request(
        meta["url"],
        headers={"User-Agent": "azerothcore-playerbots-era-provenance/1"},
    )
    with urllib.request.urlopen(request, timeout=120) as response:
        data = response.read()
    verify_source_bytes(data, meta, label)
    path.write_bytes(data)
    return path


def iter_insert_entry_ids(statement: str) -> Iterator[int]:
    match = INSERT_RE.match(statement)
    if not match:
        return

    payload = statement[match.end():]
    in_quote = False
    escaped = False
    depth = 0
    i = 0
    size = len(payload)

    while i < size:
        ch = payload[i]

        if in_quote:
            if escaped:
                escaped = False
            elif ch == "\\":
                escaped = True
            elif ch == "'":
                if i + 1 < size and payload[i + 1] == "'":
                    i += 1
                else:
                    in_quote = False
            i += 1
            continue

        if ch == "'":
            in_quote = True
            i += 1
            continue

        if ch == "(":
            if depth == 0:
                j = i + 1
                while j < size and payload[j].isspace():
                    j += 1
                start = j
                while j < size and payload[j].isdigit():
                    j += 1
                if j == start:
                    raise ValueError("item_template row does not start with a numeric entry")
                k = j
                while k < size and payload[k].isspace():
                    k += 1
                if k >= size or payload[k] != ",":
                    raise ValueError("item_template entry is not followed by a comma")
                yield int(payload[start:j])
            depth += 1
        elif ch == ")" and depth:
            depth -= 1

        i += 1


def load_item_ids_from_dump(path: Path) -> set[int]:
    ids: set[int] = set()
    collecting: list[str] | None = None

    with gzip.open(path, "rt", encoding="utf-8", errors="replace", newline="") as handle:
        for line in handle:
            if collecting is None:
                if not INSERT_RE.match(line):
                    continue
                collecting = [line]
            else:
                collecting.append(line)

            if collecting and line.rstrip().endswith(";"):
                statement = "".join(collecting)
                ids.update(iter_insert_entry_ids(statement))
                collecting = None

    if collecting:
        raise ValueError(f"{path}: unterminated item_template INSERT statement")
    if not ids:
        raise ValueError(f"{path}: no item_template entries found")
    return ids


def load_world_ids(path: Path) -> set[int]:
    ids: set[int] = set()
    with path.open("r", encoding="utf-8", newline="") as handle:
        for raw in handle:
            raw = raw.strip()
            if not raw or raw.startswith("#"):
                continue
            first = raw.split(",", 1)[0].strip()
            if first.lower() in {"entry", "item_id", "itemid"}:
                continue
            if not first.isdigit():
                raise ValueError(f"{path}: expected numeric item id, got {first!r}")
            ids.add(int(first))
    if not ids:
        raise ValueError(f"{path}: no world item ids found")
    return ids


def expand_id_spec(spec: str) -> Iterator[int]:
    spec = spec.strip()
    if not spec:
        return
    if "-" not in spec:
        if not spec.isdigit():
            raise ValueError(f"invalid item id {spec!r}")
        yield int(spec)
        return
    left, right = (part.strip() for part in spec.split("-", 1))
    if not left.isdigit() or not right.isdigit():
        raise ValueError(f"invalid item id range {spec!r}")
    start, end = int(left), int(right)
    if end < start:
        raise ValueError(f"descending item id range {spec!r}")
    yield from range(start, end + 1)


def load_overrides(path: Path) -> dict[int, Override]:
    overrides: dict[int, Override] = {}
    if not path.exists():
        return overrides

    with path.open("r", encoding="utf-8", newline="") as handle:
        reader = csv.DictReader(handle)
        expected = {"item_id", "earliest_era", "note"}
        if not reader.fieldnames or not expected.issubset(reader.fieldnames):
            raise ValueError(f"{path}: expected columns item_id,earliest_era,note")
        for row in reader:
            spec = (row.get("item_id") or "").strip()
            if not spec or spec.startswith("#"):
                continue
            era = (row.get("earliest_era") or "").strip().lower()
            if era not in ERA_RANK:
                raise ValueError(f"{path}: invalid era {era!r} for {spec}")
            override = Override(era=era, note=(row.get("note") or "").strip())
            for item_id in expand_id_spec(spec):
                if item_id in overrides:
                    raise ValueError(f"{path}: duplicate override for item {item_id}")
                overrides[item_id] = override
    return overrides


def compact_ranges(ids: Iterable[int]) -> str:
    values = sorted(set(ids))
    if not values:
        return ""
    parts: list[str] = []
    start = prev = values[0]
    for value in values[1:]:
        if value == prev + 1:
            prev = value
            continue
        parts.append(str(start) if start == prev else f"{start}-{prev}")
        start = prev = value
    parts.append(str(start) if start == prev else f"{start}-{prev}")
    return ",".join(parts)


def world_item_fingerprint(ids: Iterable[int]) -> str:
    """Stable FNV-1a/64 fingerprint over sorted uint32 item IDs (little-endian bytes)."""
    value = 14695981039346656037
    prime = 1099511628211
    for item_id in sorted(set(ids)):
        if item_id < 0 or item_id > 0xFFFFFFFF:
            raise ValueError(f"item id out of uint32 range: {item_id}")
        for shift in (0, 8, 16, 24):
            value ^= (item_id >> shift) & 0xFF
            value = (value * prime) & 0xFFFFFFFFFFFFFFFF
    return f"{value:016x}"


def classify(
    world_ids: set[int],
    source_ids: dict[str, set[int]],
    overrides: dict[int, Override],
) -> dict[int, tuple[str, bool, str]]:
    out: dict[int, tuple[str, bool, str]] = {}
    for item_id in sorted(world_ids):
        if item_id in overrides:
            override = overrides[item_id]
            out[item_id] = (override.era, True, override.note)
            continue
        if item_id in source_ids["vanilla"]:
            era = "vanilla"
        elif item_id in source_ids["tbc"]:
            era = "tbc"
        elif item_id in source_ids["wotlk"]:
            era = "wotlk"
        else:
            era = "unknown"
        out[item_id] = (era, False, "")
    return out


def disabled_for(profile: str, classified: dict[int, tuple[str, bool, str]]) -> set[int]:
    allowed_rank = ERA_RANK[profile]
    return {
        item_id
        for item_id, (era, _override, _note) in classified.items()
        if era == "unknown" or ERA_RANK[era] > allowed_rank
    }


def write_outputs(
    out_dir: Path,
    sources: dict,
    world_ids: set[int],
    source_ids: dict[str, set[int]],
    classified: dict[int, tuple[str, bool, str]],
) -> None:
    out_dir.mkdir(parents=True, exist_ok=True)

    manifest = out_dir / "item-era.csv"
    with manifest.open("w", encoding="utf-8", newline="") as handle:
        writer = csv.writer(handle, lineterminator="\n")
        writer.writerow(
            ["item_id", "earliest_era", "classic_source", "tbc_source", "wotlk_source", "override", "note"]
        )
        for item_id in sorted(world_ids):
            era, overridden, note = classified[item_id]
            writer.writerow(
                [
                    item_id,
                    era,
                    int(item_id in source_ids["vanilla"]),
                    int(item_id in source_ids["tbc"]),
                    int(item_id in source_ids["wotlk"]),
                    int(overridden),
                    note,
                ]
            )

    disabled_counts: dict[str, int] = {}
    for profile in ERAS:
        blocked = disabled_for(profile, classified)
        disabled_counts[profile] = len(blocked)
        (out_dir / f"ah-disabled-{profile}.txt").write_text(
            compact_ranges(blocked) + "\n",
            encoding="utf-8",
        )

    era_counts = {era: 0 for era in (*ERAS, "unknown")}
    override_count = 0
    for era, overridden, _note in classified.values():
        era_counts[era] += 1
        override_count += int(overridden)

    metadata = {
        "schema": 1,
        "source_set": sources.get("source_set", "unknown"),
        "sources": {
            era: {
                "repository": sources["sources"][era]["repository"],
                "commit": sources["sources"][era]["commit"],
                "git_blob_sha": sources["sources"][era]["git_blob_sha"],
                "item_count": len(source_ids[era]),
            }
            for era in ERAS
        },
        "world_item_count": len(world_ids),
        "world_item_fingerprint": world_item_fingerprint(world_ids),
        "classified_counts": era_counts,
        "override_count": override_count,
        "disabled_counts": disabled_counts,
        "unknown_policy": "fail-closed-for-automated-listing",
    }
    (out_dir / "metadata.json").write_text(
        json.dumps(metadata, indent=2, sort_keys=True) + "\n",
        encoding="utf-8",
    )


def generate(args: argparse.Namespace) -> None:
    sources = json.loads(args.sources.read_text(encoding="utf-8"))
    if sources.get("schema") != 1:
        raise ValueError(f"{args.sources}: unsupported schema")
    for era in ERAS:
        if era not in sources.get("sources", {}):
            raise ValueError(f"{args.sources}: missing {era} source")

    source_ids: dict[str, set[int]] = {}
    for era in ERAS:
        dump = fetch_source(era, sources["sources"][era], args.cache_dir)
        source_ids[era] = load_item_ids_from_dump(dump)

    world_ids = load_world_ids(args.world_item_ids)
    overrides = load_overrides(args.overrides)
    classified = classify(world_ids, source_ids, overrides)
    write_outputs(args.out_dir, sources, world_ids, source_ids, classified)

    unknown = sum(1 for era, _override, _note in classified.values() if era == "unknown")
    print(
        "ERA item provenance generated: "
        f"world={len(world_ids)} vanilla={sum(1 for x in classified.values() if x[0] == 'vanilla')} "
        f"tbc={sum(1 for x in classified.values() if x[0] == 'tbc')} "
        f"wotlk={sum(1 for x in classified.values() if x[0] == 'wotlk')} unknown={unknown}"
    )


def self_test() -> None:
    def make_dump(path: Path, ids: list[int]) -> None:
        rows = []
        for item_id in ids:
            name = "text ),( 123, with quote '' and slash \\\\"
            rows.append(f"({item_id},'{name}',0)")
        sql = (
            "-- fixture\n"
            "INSERT INTO `other_table` VALUES (999,'ignore');\n"
            "INSERT INTO `item_template` VALUES " + ",".join(rows) + ";\n"
        )
        with gzip.open(path, "wt", encoding="utf-8") as handle:
            handle.write(sql)

    with tempfile.TemporaryDirectory() as raw:
        root = Path(raw)
        classic = root / "classic.sql.gz"
        tbc = root / "tbc.sql.gz"
        wotlk = root / "wotlk.sql.gz"
        make_dump(classic, [1, 2])
        make_dump(tbc, [1, 2, 3])
        make_dump(wotlk, [1, 2, 3, 4])

        source_ids = {
            "vanilla": load_item_ids_from_dump(classic),
            "tbc": load_item_ids_from_dump(tbc),
            "wotlk": load_item_ids_from_dump(wotlk),
        }
        assert source_ids == {"vanilla": {1, 2}, "tbc": {1, 2, 3}, "wotlk": {1, 2, 3, 4}}

        overrides_path = root / "overrides.csv"
        overrides_path.write_text(
            "item_id,earliest_era,note\n5,vanilla,fixture override\n7-8,tbc,fixture range\n",
            encoding="utf-8",
        )
        overrides = load_overrides(overrides_path)
        world = set(range(1, 9))
        classified = classify(world, source_ids, overrides)
        expected = {
            1: "vanilla",
            2: "vanilla",
            3: "tbc",
            4: "wotlk",
            5: "vanilla",
            6: "unknown",
            7: "tbc",
            8: "tbc",
        }
        assert {item: value[0] for item, value in classified.items()} == expected
        assert disabled_for("vanilla", classified) == {3, 4, 6, 7, 8}
        assert disabled_for("tbc", classified) == {4, 6}
        assert disabled_for("wotlk", classified) == {6}
        assert compact_ranges({1, 2, 3, 5, 7, 8}) == "1-3,5,7-8"
        assert world_item_fingerprint(world) == world_item_fingerprint(reversed(sorted(world)))
        assert world_item_fingerprint(world) == "6489bd86fccf7bad"

    print("ERA item provenance self-test passed.")


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser()
    parser.add_argument("--self-test", action="store_true")
    parser.add_argument("--sources", type=Path)
    parser.add_argument("--overrides", type=Path)
    parser.add_argument("--world-item-ids", type=Path)
    parser.add_argument("--cache-dir", type=Path)
    parser.add_argument("--out-dir", type=Path)
    return parser


def main() -> int:
    parser = build_parser()
    args = parser.parse_args()
    if args.self_test:
        self_test()
        return 0

    required = ("sources", "overrides", "world_item_ids", "cache_dir", "out_dir")
    missing = [name for name in required if getattr(args, name) is None]
    if missing:
        parser.error("missing required arguments: " + ", ".join("--" + name.replace("_", "-") for name in missing))
    generate(args)
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except (OSError, ValueError, json.JSONDecodeError) as exc:
        print(f"ERROR: {exc}", file=sys.stderr)
        raise SystemExit(1)
