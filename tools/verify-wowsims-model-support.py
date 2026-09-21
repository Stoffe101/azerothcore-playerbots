#!/usr/bin/env python3
"""Verify the pinned WoWSims model catalog is internally consistent with source pins."""

from __future__ import annotations

import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SOURCES = ROOT / "data" / "wowsims" / "sources.json"
CATALOG = ROOT / "data" / "wowsims" / "model-support.json"

VALID_ERAS = {"VANILLA", "TBC", "WOTLK"}
VALID_ROLES = {"DPS", "HEALER", "TANK"}
VALID_STATUSES = {"ENGINE_PRESENT_UNVALIDATED", "SIM_BACKED_VALIDATED"}


def fail(message: str) -> None:
    raise SystemExit(f"ERROR: {message}")


def main() -> None:
    sources = json.loads(SOURCES.read_text(encoding="utf-8"))
    catalog = json.loads(CATALOG.read_text(encoding="utf-8"))

    if catalog.get("schema") != 1:
        fail("model-support schema must be 1")
    eras = catalog.get("eras")
    if not isinstance(eras, dict) or set(eras) != VALID_ERAS:
        fail("model-support eras must be exactly VANILLA/TBC/WOTLK")

    expanded_total = 0
    for era in sorted(VALID_ERAS):
        entry = eras[era]
        source = sources["engines"][era]
        if entry.get("repository") != source.get("repository"):
            fail(f"{era} repository differs from sources.json")
        if entry.get("commit") != source.get("commit"):
            fail(f"{era} commit differs from sources.json")

        proto = entry.get("api_proto")
        if not isinstance(proto, dict) or proto.get("path") != "proto/api.proto" or not proto.get("blob"):
            fail(f"{era} api_proto identity is incomplete")

        fields = entry.get("proto_spec_fields")
        if not isinstance(fields, list) or not fields or len(fields) != len(set(fields)):
            fail(f"{era} proto_spec_fields must be non-empty and unique")
        field_set = set(fields)

        routes = entry.get("routes")
        if not isinstance(routes, list) or not routes:
            fail(f"{era} routes must be non-empty")

        seen = set()
        for route in routes:
            class_id = route.get("classId")
            trees = route.get("trees")
            roles = route.get("roles")
            field = route.get("protoSpecField")
            status = route.get("status")

            if not isinstance(class_id, int) or class_id <= 0:
                fail(f"{era} route has invalid classId")
            if not isinstance(trees, list) or not trees or any(tree not in (0, 1, 2) for tree in trees):
                fail(f"{era} route has invalid trees")
            if not isinstance(roles, list) or not roles or any(role not in VALID_ROLES for role in roles):
                fail(f"{era} route has invalid roles")
            if field not in field_set:
                fail(f"{era} route references missing proto field {field!r}")
            if status not in VALID_STATUSES:
                fail(f"{era} route has invalid status {status!r}")
            if era != "WOTLK" and class_id == 6:
                fail(f"{era} must not route Death Knights")

            for tree in trees:
                for role in roles:
                    key = (class_id, tree, role)
                    if key in seen:
                        fail(f"{era} duplicate expanded route {key}")
                    seen.add(key)
                    expanded_total += 1

    print(
        "WoWSims model support verified: "
        + ", ".join(
            f"{era}={len(catalog['eras'][era]['proto_spec_fields'])} proto models"
            for era in ("VANILLA", "TBC", "WOTLK")
        )
        + f"; {expanded_total} expanded character routes"
    )


if __name__ == "__main__":
    main()
