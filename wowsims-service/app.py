#!/usr/bin/env python3
"""Private HTTP wrapper for the pinned Skrra WoWSims CLI engines."""

from __future__ import annotations

import copy
import hashlib
import json
import os
from pathlib import Path
import subprocess
import tempfile
import threading
from http import HTTPStatus
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from typing import Any

SCHEMA_VERSION = 1
DEFAULT_LISTEN = "0.0.0.0:8092"
DEFAULT_TIMEOUT_SECONDS = 45.0
DEFAULT_MAX_BODY_BYTES = 4 * 1024 * 1024
DEFAULT_MAX_CONCURRENT = 2

ERA_TO_BINARY = {
    "VANILLA": os.environ.get("WOWSIMS_CLASSIC_BIN", "/usr/local/bin/wowsimcli-classic"),
    "TBC": os.environ.get("WOWSIMS_TBC_BIN", "/usr/local/bin/wowsimcli-tbc"),
    "WOTLK": os.environ.get("WOWSIMS_WOTLK_BIN", "/usr/local/bin/wowsimcli-wotlk"),
}

METRIC_PATHS = {
    "dps": ("raidMetrics", "dps", "avg"),
    "hps": ("raidMetrics", "hps", "avg"),
}


class ServiceError(Exception):
    def __init__(self, message: str, status: int = HTTPStatus.BAD_REQUEST):
        super().__init__(message)
        self.status = int(status)


def _env_float(name: str, default: float) -> float:
    raw = os.environ.get(name)
    if raw is None or raw == "":
        return default
    value = float(raw)
    if value <= 0:
        raise ValueError(f"{name} must be greater than zero")
    return value


def _env_int(name: str, default: int) -> int:
    raw = os.environ.get(name)
    if raw is None or raw == "":
        return default
    value = int(raw)
    if value <= 0:
        raise ValueError(f"{name} must be greater than zero")
    return value


def load_manifest(path: str | os.PathLike[str] | None = None) -> dict[str, Any]:
    manifest_path = Path(path or os.environ.get("WOWSIMS_MANIFEST", "/app/sources.json"))
    try:
        data = json.loads(manifest_path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as exc:
        raise RuntimeError(f"failed to load WoWSims manifest {manifest_path}: {exc}") from exc

    engines = data.get("engines")
    if not isinstance(engines, dict):
        raise RuntimeError("WoWSims manifest is missing engines")
    for era in ERA_TO_BINARY:
        entry = engines.get(era)
        if not isinstance(entry, dict) or not entry.get("repository") or not entry.get("commit"):
            raise RuntimeError(f"WoWSims manifest is missing repository/commit for {era}")
    return data


def load_model_support(
    path: str | os.PathLike[str] | None = None,
    manifest: dict[str, Any] | None = None,
) -> dict[str, Any]:
    catalog_path = Path(
        path
        or os.environ.get("WOWSIMS_MODEL_SUPPORT")
        or Path(__file__).with_name("model-support.json")
    )
    try:
        data = json.loads(catalog_path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as exc:
        raise RuntimeError(f"failed to load WoWSims model catalog {catalog_path}: {exc}") from exc

    eras = data.get("eras")
    if data.get("schema") != SCHEMA_VERSION or not isinstance(eras, dict):
        raise RuntimeError("WoWSims model catalog is invalid")

    for era in ERA_TO_BINARY:
        entry = eras.get(era)
        if not isinstance(entry, dict):
            raise RuntimeError(f"WoWSims model catalog is missing {era}")
        fields = entry.get("proto_spec_fields")
        routes = entry.get("routes")
        if not isinstance(fields, list) or not fields or len(fields) != len(set(fields)):
            raise RuntimeError(f"WoWSims model catalog has invalid proto fields for {era}")
        if not isinstance(routes, list) or not routes:
            raise RuntimeError(f"WoWSims model catalog has no routes for {era}")
        if manifest is not None:
            engine = manifest["engines"][era]
            if entry.get("repository") != engine.get("repository") or entry.get("commit") != engine.get("commit"):
                raise RuntimeError(f"WoWSims model catalog pin mismatch for {era}")

        expanded: set[tuple[int, int, str]] = set()
        field_set = set(fields)
        for route in routes:
            class_id = route.get("classId")
            trees = route.get("trees")
            roles = route.get("roles")
            proto_field = route.get("protoSpecField")
            if not isinstance(class_id, int) or not isinstance(trees, list) or not isinstance(roles, list):
                raise RuntimeError(f"WoWSims model catalog has malformed route for {era}")
            if proto_field not in field_set:
                raise RuntimeError(f"WoWSims model catalog route uses unknown proto field {proto_field!r} for {era}")
            for tree in trees:
                for role in roles:
                    key = (class_id, tree, role)
                    if key in expanded:
                        raise RuntimeError(f"WoWSims model catalog has duplicate route {key!r} for {era}")
                    expanded.add(key)
    return data


def resolve_model(
    catalog: dict[str, Any],
    era: str,
    class_id: int,
    tree: int,
    role: str,
) -> dict[str, Any] | None:
    entry = catalog["eras"][era]
    for route in entry["routes"]:
        if (
            route.get("classId") == class_id
            and tree in route.get("trees", [])
            and role in route.get("roles", [])
        ):
            return route
    return None


def model_catalog_summary(catalog: dict[str, Any]) -> dict[str, Any]:
    eras: dict[str, Any] = {}
    for era, entry in catalog["eras"].items():
        expanded = sum(len(route["trees"]) * len(route["roles"]) for route in entry["routes"])
        eras[era] = {
            "repository": entry["repository"],
            "commit": entry["commit"],
            "apiProto": entry["api_proto"],
            "protoSpecCount": len(entry["proto_spec_fields"]),
            "expandedRouteCount": expanded,
        }
    return {"schema": SCHEMA_VERSION, "eras": eras}


def load_preset_catalog(
    root: str | os.PathLike[str] | None = None,
    manifest: dict[str, Any] | None = None,
    *,
    required: bool | None = None,
) -> dict[str, Any]:
    preset_root = Path(
        root
        or os.environ.get("WOWSIMS_PRESET_ROOT")
        or Path(__file__).with_name("presets")
    )
    if required is None:
        required = os.environ.get("WOWSIMS_REQUIRE_PRESETS", "0") == "1"

    catalog: dict[str, Any] = {
        "root": str(preset_root),
        "required": required,
        "eras": {},
    }
    for era in ERA_TO_BINARY:
        index_path = preset_root / era / "preset-index.json"
        if not index_path.is_file():
            if required:
                raise RuntimeError(f"WoWSims preset index is missing for {era}: {index_path}")
            catalog["eras"][era] = {
                "ready": False,
                "routeCount": 0,
                "canonicalRouteCount": 0,
                "requestCount": 0,
                "canonicalPolicy": None,
                "routes": {},
            }
            continue

        try:
            index = json.loads(index_path.read_text(encoding="utf-8"))
        except (OSError, json.JSONDecodeError) as exc:
            raise RuntimeError(f"failed to load WoWSims preset index {index_path}: {exc}") from exc

        if index.get("schema") != SCHEMA_VERSION or index.get("era") != era:
            raise RuntimeError(f"WoWSims preset index has invalid schema/era for {era}")
        if manifest is not None and index.get("engineCommit") != manifest["engines"][era]["commit"]:
            raise RuntimeError(f"WoWSims preset index pin mismatch for {era}")
        routes = index.get("routes")
        if not isinstance(routes, dict) or not routes:
            raise RuntimeError(f"WoWSims preset index has no routes for {era}")

        request_count = 0
        canonical_route_count = 0
        for route_key, entries in routes.items():
            if not isinstance(route_key, str) or not isinstance(entries, list) or not entries:
                raise RuntimeError(f"WoWSims preset index has malformed route for {era}")
            for entry in entries:
                if not isinstance(entry, dict) or not entry.get("file") or not entry.get("sha256"):
                    raise RuntimeError(f"WoWSims preset index has malformed request metadata for {era}/{route_key}")
                request_file = preset_root / era / entry["file"]
                if required and not request_file.is_file():
                    raise RuntimeError(f"WoWSims preset request is missing: {request_file}")
                request_count += 1

            canonical = [entry for entry in entries if entry.get("canonical") is True]
            if not canonical and len(entries) == 1:
                entries[0]["canonical"] = True
                entries[0].setdefault("selectionMethod", "single-engine-native-preset")
                canonical = [entries[0]]
            if len(canonical) != 1:
                raise RuntimeError(
                    f"WoWSims preset route {era}/{route_key} must have exactly one canonical request"
                )
            canonical[0].setdefault("selectionMethod", "single-engine-native-preset")
            canonical_route_count += 1

        catalog["eras"][era] = {
            "ready": True,
            "routeCount": int(index.get("routeCount", len(routes))),
            "canonicalRouteCount": canonical_route_count,
            "requestCount": int(index.get("requestCount", request_count)),
            "canonicalPolicy": index.get("canonicalPolicy", "singleton-only-v0"),
            "routes": routes,
        }
    return catalog


def preset_catalog_summary(catalog: dict[str, Any]) -> dict[str, Any]:
    return {
        "schema": SCHEMA_VERSION,
        "required": bool(catalog.get("required", False)),
        "eras": {
            era: {
                "ready": bool(entry.get("ready", False)),
                "routeCount": int(entry.get("routeCount", 0)),
                "canonicalRouteCount": int(entry.get("canonicalRouteCount", 0)),
                "requestCount": int(entry.get("requestCount", 0)),
                "canonicalPolicy": entry.get("canonicalPolicy"),
                "routeKeys": sorted(entry.get("routes", {}).keys()),
            }
            for era, entry in catalog["eras"].items()
        },
    }



RACE_ENUMS = {
    "BLOODELF": "RaceBloodElf",
    "DRAENEI": "RaceDraenei",
    "DWARF": "RaceDwarf",
    "GNOME": "RaceGnome",
    "HUMAN": "RaceHuman",
    "NIGHTELF": "RaceNightElf",
    "ORC": "RaceOrc",
    "TAUREN": "RaceTauren",
    "TROLL": "RaceTroll",
    "UNDEAD": "RaceUndead",
}

CLASS_ENUMS = {
    "WARRIOR": "ClassWarrior",
    "PALADIN": "ClassPaladin",
    "HUNTER": "ClassHunter",
    "ROGUE": "ClassRogue",
    "PRIEST": "ClassPriest",
    "DEATHKNIGHT": "ClassDeathknight",
    "SHAMAN": "ClassShaman",
    "MAGE": "ClassMage",
    "WARLOCK": "ClassWarlock",
    "DRUID": "ClassDruid",
}

PROFESSION_ENUMS = {
    "ALCHEMY": "Alchemy",
    "BLACKSMITHING": "Blacksmithing",
    "ENCHANTING": "Enchanting",
    "ENGINEERING": "Engineering",
    "HERBALISM": "Herbalism",
    "INSCRIPTION": "Inscription",
    "JEWELCRAFTING": "Jewelcrafting",
    "LEATHERWORKING": "Leatherworking",
    "MINING": "Mining",
    "SKINNING": "Skinning",
    "TAILORING": "Tailoring",
}

ERA_PROFESSIONS = {
    "VANILLA": {
        "ALCHEMY", "BLACKSMITHING", "ENCHANTING", "ENGINEERING", "HERBALISM",
        "LEATHERWORKING", "MINING", "SKINNING", "TAILORING",
    },
    "TBC": {
        "ALCHEMY", "BLACKSMITHING", "ENCHANTING", "ENGINEERING", "HERBALISM",
        "JEWELCRAFTING", "LEATHERWORKING", "MINING", "SKINNING", "TAILORING",
    },
    "WOTLK": set(PROFESSION_ENUMS),
}


def load_glyph_spell_map(
    path: str | os.PathLike[str] | None = None,
    *,
    required: bool | None = None,
) -> dict[int, int]:
    glyph_path = Path(
        path
        or os.environ.get("WOWSIMS_WOTLK_GLYPH_MAP")
        or Path(__file__).with_name("wotlk-glyph-id-map.json")
    )
    if required is None:
        required = os.environ.get("WOWSIMS_REQUIRE_GLYPH_MAP", "0") == "1"
    if not glyph_path.is_file():
        if required:
            raise RuntimeError(f"WotLK glyph map is missing: {glyph_path}")
        return {}
    try:
        data = json.loads(glyph_path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as exc:
        raise RuntimeError(f"failed to load WotLK glyph map {glyph_path}: {exc}") from exc
    if not isinstance(data, list):
        raise RuntimeError("WotLK glyph map must be an array")
    result: dict[int, int] = {}
    for entry in data:
        if not isinstance(entry, dict):
            raise RuntimeError("WotLK glyph map contains a non-object entry")
        item_id = entry.get("itemId")
        spell_id = entry.get("spellId")
        if not isinstance(item_id, int) or item_id <= 0 or not isinstance(spell_id, int) or spell_id <= 0:
            raise RuntimeError("WotLK glyph map contains an invalid itemId/spellId")
        if spell_id in result and result[spell_id] != item_id:
            raise RuntimeError(f"WotLK glyph spell {spell_id} maps to multiple items")
        result[spell_id] = item_id
    return result


def _canonical_request_sha256(request: dict[str, Any]) -> str:
    body = json.dumps(request, sort_keys=True, separators=(",", ":")).encode("utf-8")
    return hashlib.sha256(body).hexdigest()


def _preset_route_key(snapshot: dict[str, Any]) -> str:
    character = snapshot["character"]
    return f'{character["classId"]}:{character["dominantTree"]}:{character["role"]}'


def _select_preset(
    preset_catalog: dict[str, Any],
    era: str,
    route_key: str,
    preset_sha256: str | None,
) -> tuple[dict[str, Any], dict[str, Any]]:
    era_entry = preset_catalog["eras"].get(era, {})
    entries = era_entry.get("routes", {}).get(route_key, [])
    if not entries:
        raise ServiceError(f"no engine-native preset exists for {era} route {route_key}")
    if preset_sha256 is None:
        canonical = [entry for entry in entries if entry.get("canonical") is True]
        if len(canonical) != 1:
            raise ServiceError(
                f"{era} route {route_key} has no unique canonical preset",
                HTTPStatus.INTERNAL_SERVER_ERROR,
            )
        selected = canonical[0]
    else:
        matches = [entry for entry in entries if entry.get("sha256") == preset_sha256]
        if len(matches) != 1:
            raise ServiceError(f"presetSha256 is not valid for {era} route {route_key}")
        selected = matches[0]

    root = Path(preset_catalog["root"]).resolve()
    era_root = (root / era).resolve()
    request_path = (era_root / str(selected["file"])).resolve()
    if not request_path.is_relative_to(era_root):
        raise ServiceError("preset path escapes the pinned preset root", HTTPStatus.INTERNAL_SERVER_ERROR)
    try:
        request = json.loads(request_path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as exc:
        raise ServiceError(
            f"failed to load pinned preset {selected['file']}",
            HTTPStatus.INTERNAL_SERVER_ERROR,
        ) from exc
    if not isinstance(request, dict):
        raise ServiceError("pinned preset request is not a JSON object", HTTPStatus.INTERNAL_SERVER_ERROR)
    digest = _canonical_request_sha256(request)
    if digest != selected.get("sha256"):
        raise ServiceError(
            f"pinned preset checksum mismatch for {selected['file']}",
            HTTPStatus.INTERNAL_SERVER_ERROR,
        )
    return selected, request


def _request_player(request: dict[str, Any]) -> dict[str, Any]:
    try:
        parties = request["raid"]["parties"]
        players = parties[0]["players"]
        player = players[0]
    except (KeyError, IndexError, TypeError) as exc:
        raise ServiceError("pinned preset has no first raid player", HTTPStatus.INTERNAL_SERVER_ERROR) from exc
    if not isinstance(player, dict):
        raise ServiceError("pinned preset first player is invalid", HTTPStatus.INTERNAL_SERVER_ERROR)
    return player


def _item_spec_from_snapshot(era: str, item: dict[str, Any], label: str) -> dict[str, Any]:
    _require_int(item.get("id"), f"{label}.id", minimum=1)
    enchant = _require_int(item.get("enchant", 0), f"{label}.enchant")
    gems = item.get("gems", [])
    if (
        not isinstance(gems, list)
        or len(gems) != 3
        or any(isinstance(value, bool) or not isinstance(value, int) or value < 0 for value in gems)
    ):
        raise ServiceError(f"{label}.gems must contain exactly three non-negative integers")

    random_property_id = item.get("randomPropertyId", 0)
    if isinstance(random_property_id, bool) or not isinstance(random_property_id, int):
        raise ServiceError(f"{label}.randomPropertyId must be an integer")

    spec: dict[str, Any] = {"id": item["id"]}
    if enchant:
        spec["enchant"] = enchant

    if era in {"TBC", "WOTLK"}:
        sim_gems = list(gems)
        while sim_gems and sim_gems[-1] == 0:
            sim_gems.pop()
        if sim_gems:
            spec["gems"] = sim_gems

    if era in {"VANILLA", "TBC"}:
        if random_property_id > 0:
            raise ServiceError(
                f"{label} uses random property {random_property_id}; "
                "automatic WoWSims mapping currently supports suffix IDs only"
            )
        if random_property_id < 0:
            spec["randomSuffix"] = -random_property_id
    elif random_property_id != 0:
        raise ServiceError(
            f"{label} uses random property {random_property_id}, but the pinned WotLK ItemSpec "
            "does not represent random suffix/property state"
        )

    return spec


def _equipment_from_snapshot(era: str, gear: list[Any]) -> dict[str, Any]:
    items: list[dict[str, Any]] = []
    for index, item in enumerate(gear):
        if item is None:
            items.append({})
            continue
        items.append(_item_spec_from_snapshot(era, item, f"character.gear[{index}]"))
    return {"items": items}


def _professions_from_snapshot(era: str, professions: Any) -> tuple[str, str]:
    if not isinstance(professions, list):
        raise ServiceError("character.professions must be an array")
    values: list[str] = []
    for index, profession in enumerate(professions):
        if not isinstance(profession, dict):
            raise ServiceError(f"character.professions[{index}] must be an object")
        token = profession.get("name")
        if not isinstance(token, str) or token not in PROFESSION_ENUMS:
            raise ServiceError(f"character.professions[{index}].name is unsupported")
        if token not in ERA_PROFESSIONS[era]:
            raise ServiceError(f"{token} is unavailable in {era}")
        enum_value = PROFESSION_ENUMS[token]
        if enum_value not in values:
            values.append(enum_value)
    if len(values) > 2:
        raise ServiceError("WoWSims supports at most two character professions")
    values += ["ProfessionUnknown"] * (2 - len(values))
    return values[0], values[1]


def _glyphs_from_snapshot(glyphs: Any, glyph_spell_map: dict[int, int]) -> dict[str, int]:
    if not isinstance(glyphs, list):
        raise ServiceError("character.glyphs must be an array")
    major: list[tuple[int, int]] = []
    minor: list[tuple[int, int]] = []
    for index, glyph in enumerate(glyphs):
        if not isinstance(glyph, dict):
            raise ServiceError(f"character.glyphs[{index}] must be an object")
        slot = glyph.get("slot")
        spell_id = glyph.get("spellId")
        type_flags = glyph.get("typeFlags")
        if not isinstance(slot, int) or slot < 0 or slot >= 6:
            raise ServiceError(f"character.glyphs[{index}].slot is invalid")
        if not isinstance(spell_id, int) or spell_id <= 0:
            raise ServiceError(f"character.glyphs[{index}].spellId is invalid")
        if type_flags not in (0, 1):
            raise ServiceError(f"character.glyphs[{index}].typeFlags must be 0 (major) or 1 (minor)")
        item_id = glyph_spell_map.get(spell_id)
        if item_id is None:
            raise ServiceError(f"WotLK glyph spell {spell_id} is absent from the pinned WoWSims glyph map")
        (major if type_flags == 0 else minor).append((slot, item_id))
    major.sort()
    minor.sort()
    if len(major) > 3 or len(minor) > 3:
        raise ServiceError("character has more than three major or minor glyphs")
    major_ids = [item for _, item in major] + [0] * (3 - len(major))
    minor_ids = [item for _, item in minor] + [0] * (3 - len(minor))
    return {
        "major1": major_ids[0],
        "major2": major_ids[1],
        "major3": major_ids[2],
        "minor1": minor_ids[0],
        "minor2": minor_ids[1],
        "minor3": minor_ids[2],
    }


def build_baseline_request(
    snapshot: dict[str, Any],
    model_support: dict[str, Any],
    preset_catalog: dict[str, Any],
    glyph_spell_map: dict[int, int],
    *,
    preset_sha256: str | None = None,
) -> dict[str, Any]:
    validation = validate_character_snapshot(snapshot, model_support)
    support = validation["support"]
    if support["status"] == "UNSUPPORTED":
        raise ServiceError(support["reason"])

    era = validation["era"]
    character = snapshot["character"]
    route_key = _preset_route_key(snapshot)
    preset, raw_request = _select_preset(preset_catalog, era, route_key, preset_sha256)
    request = copy.deepcopy(raw_request)
    player = _request_player(request)

    race_token = character.get("race")
    class_token = character.get("class")
    if not isinstance(race_token, str) or race_token not in RACE_ENUMS:
        raise ServiceError(f"unsupported character.race {race_token!r}")
    if era == "VANILLA" and race_token in {"BLOODELF", "DRAENEI"}:
        raise ServiceError(f"{race_token} is unavailable in VANILLA")
    if not isinstance(class_token, str) or class_token not in CLASS_ENUMS:
        raise ServiceError(f"unsupported character.class {class_token!r}")
    if era != "WOTLK" and class_token == "DEATHKNIGHT":
        raise ServiceError("Death Knight is unavailable before WOTLK")

    profession1, profession2 = _professions_from_snapshot(era, character.get("professions", []))

    player["name"] = str(character.get("name") or "SkrraPlayer")
    player["race"] = RACE_ENUMS[race_token]
    player["class"] = CLASS_ENUMS[class_token]
    player["equipment"] = _equipment_from_snapshot(era, character["gear"])
    player["talentsString"] = character["talents"]
    player["profession1"] = profession1
    player["profession2"] = profession2
    if era == "WOTLK":
        player["glyphs"] = _glyphs_from_snapshot(character.get("glyphs", []), glyph_spell_map)
    else:
        player.pop("glyphs", None)

    return {
        "schema": SCHEMA_VERSION,
        "status": "REQUEST_BUILT_UNVALIDATED",
        "era": era,
        "routeKey": route_key,
        "support": support,
        "preset": {
            "file": preset["file"],
            "sha256": preset["sha256"],
            "source": preset.get("source"),
            "protoSpecField": preset.get("protoSpecField"),
            "canonical": bool(preset.get("canonical", False)),
            "selectionMethod": preset.get("selectionMethod"),
            "assumptionsSha256": preset.get("assumptionsSha256"),
            "selection": "explicit" if preset_sha256 is not None else "canonical",
        },
        "request": request,
    }


def _difference_paths(left: Any, right: Any, path: str = "") -> list[str]:
    if type(left) is not type(right):
        return [path or "$"]
    if isinstance(left, dict):
        paths: list[str] = []
        keys = sorted(set(left) | set(right))
        for key in keys:
            child = f"{path}.{key}" if path else str(key)
            if key not in left or key not in right:
                paths.append(child)
            else:
                paths.extend(_difference_paths(left[key], right[key], child))
        return paths
    if isinstance(left, list):
        paths: list[str] = []
        if len(left) != len(right):
            paths.append((path or "$") + ".length")
        for index in range(min(len(left), len(right))):
            child = f"{path}.{index}" if path else str(index)
            paths.extend(_difference_paths(left[index], right[index], child))
        return paths
    return [] if left == right else [path or "$"]


def _candidate_request_from_baseline(
    baseline: dict[str, Any],
    candidate: dict[str, Any],
    slot_index: int,
    *,
    label: str = "candidate",
) -> dict[str, Any]:
    if isinstance(slot_index, bool) or not isinstance(slot_index, int) or not 0 <= slot_index < 17:
        raise ServiceError("slotIndex must be an integer from 0 through 16")
    if not isinstance(candidate, dict):
        raise ServiceError(f"{label} must be an item object")

    era = baseline["era"]
    candidate_item = _item_spec_from_snapshot(era, candidate, label)

    candidate_request = copy.deepcopy(baseline["request"])
    player = _request_player(candidate_request)
    equipment = player.get("equipment")
    if not isinstance(equipment, dict):
        raise ServiceError("baseline preset equipment is invalid", HTTPStatus.INTERNAL_SERVER_ERROR)
    items = equipment.get("items")
    if not isinstance(items, list) or len(items) != 17:
        raise ServiceError(
            "baseline request must contain exactly 17 equipment items",
            HTTPStatus.INTERNAL_SERVER_ERROR,
        )

    items[slot_index] = candidate_item
    diff_paths = _difference_paths(baseline["request"], candidate_request)
    prefix = f"raid.parties.0.players.0.equipment.items.{slot_index}"
    if not diff_paths:
        raise ServiceError("candidate produces no request change")
    if any(path != prefix and not path.startswith(prefix + ".") for path in diff_paths):
        raise ServiceError(
            "candidate mutation changed data outside the intended equipment slot",
            HTTPStatus.INTERNAL_SERVER_ERROR,
        )
    return {
        "slotIndex": slot_index,
        "changedPaths": diff_paths,
        "candidateRequest": candidate_request,
    }


def build_candidate_request(
    snapshot: dict[str, Any],
    candidate: dict[str, Any],
    slot_index: int,
    model_support: dict[str, Any],
    preset_catalog: dict[str, Any],
    glyph_spell_map: dict[int, int],
    *,
    preset_sha256: str | None = None,
) -> dict[str, Any]:
    baseline = build_baseline_request(
        snapshot,
        model_support,
        preset_catalog,
        glyph_spell_map,
        preset_sha256=preset_sha256,
    )
    built = _candidate_request_from_baseline(baseline, candidate, slot_index)

    return {
        "schema": SCHEMA_VERSION,
        "status": "CANDIDATE_REQUEST_BUILT_UNVALIDATED",
        "era": baseline["era"],
        "routeKey": baseline["routeKey"],
        "support": baseline["support"],
        "preset": baseline["preset"],
        "slotIndex": built["slotIndex"],
        "changedPaths": built["changedPaths"],
        "baselineRequest": baseline["request"],
        "candidateRequest": built["candidateRequest"],
    }


def build_bag_candidate_manifest(
    snapshot: dict[str, Any],
    candidates: list[Any],
    model_support: dict[str, Any],
    preset_catalog: dict[str, Any],
    glyph_spell_map: dict[int, int],
    *,
    preset_sha256: str | None = None,
) -> dict[str, Any]:
    if not isinstance(candidates, list):
        raise ServiceError("candidates must be an array")

    baseline = build_baseline_request(
        snapshot,
        model_support,
        preset_catalog,
        glyph_spell_map,
        preset_sha256=preset_sha256,
    )
    baseline_fingerprint = _canonical_request_sha256(baseline["request"])
    swaps: list[dict[str, Any]] = []
    skipped: list[dict[str, Any]] = []

    for index, entry in enumerate(candidates):
        label = f"candidates[{index}]"
        if not isinstance(entry, dict):
            raise ServiceError(f"{label} must be an object")
        bag = _require_int(entry.get("bag"), f"{label}.bag")
        slot = _require_int(entry.get("slot"), f"{label}.slot")
        item = entry.get("item")
        if not isinstance(item, dict):
            raise ServiceError(f"{label}.item must be an object")
        slot_indexes = entry.get("slotIndexes")
        if (
            not isinstance(slot_indexes, list)
            or not slot_indexes
            or any(isinstance(value, bool) or not isinstance(value, int) or not 0 <= value < 17 for value in slot_indexes)
        ):
            raise ServiceError(f"{label}.slotIndexes must contain WoWSims slot indexes 0-16")
        if len(set(slot_indexes)) != len(slot_indexes):
            raise ServiceError(f"{label}.slotIndexes must not contain duplicates")

        for slot_index in slot_indexes:
            try:
                built = _candidate_request_from_baseline(
                    baseline,
                    item,
                    slot_index,
                    label=f"{label}.item",
                )
            except ServiceError as exc:
                if str(exc) == "candidate produces no request change":
                    skipped.append({
                        "bag": bag,
                        "slot": slot,
                        "itemId": item.get("id"),
                        "slotIndex": slot_index,
                        "reason": "NO_CHANGE",
                    })
                    continue
                raise

            swaps.append({
                "bag": bag,
                "slot": slot,
                "itemId": item.get("id"),
                "slotIndex": slot_index,
                "changedPaths": built["changedPaths"],
                "candidateFingerprint": _canonical_request_sha256(built["candidateRequest"]),
            })

    return {
        "schema": SCHEMA_VERSION,
        "status": "BAG_CANDIDATES_BUILT_UNVALIDATED",
        "era": baseline["era"],
        "routeKey": baseline["routeKey"],
        "support": baseline["support"],
        "preset": baseline["preset"],
        "baselineFingerprint": baseline_fingerprint,
        "candidateCount": len(candidates),
        "swapCount": len(swaps),
        "skippedCount": len(skipped),
        "swaps": swaps,
        "skipped": skipped,
    }


def normalize_era(value: Any) -> str:
    if not isinstance(value, str):
        raise ServiceError("era must be one of VANILLA, TBC or WOTLK")
    era = value.strip().upper()
    if era not in ERA_TO_BINARY:
        raise ServiceError("era must be one of VANILLA, TBC or WOTLK")
    return era


def extract_metric(result: dict[str, Any], metric: str) -> float:
    if metric not in METRIC_PATHS:
        raise ServiceError(f"unsupported metric {metric!r}; supported metrics: dps, hps")

    node: Any = result
    try:
        for key in METRIC_PATHS[metric]:
            node = node[key]
        return float(node)
    except (KeyError, TypeError, ValueError) as exc:
        raise ServiceError(
            f"WoWSims result did not contain raid {metric} average",
            HTTPStatus.BAD_GATEWAY,
        ) from exc


ERA_LEVEL_CAPS = {
    "VANILLA": 60,
    "TBC": 70,
    "WOTLK": 80,
}

CLASS_SPECS = {
    1: ("WARRIOR", ("arms", "fury", "protection")),
    2: ("PALADIN", ("holy", "protection", "retribution")),
    3: ("HUNTER", ("beast_mastery", "marksman", "survival")),
    4: ("ROGUE", ("assassination", "combat", "subtlety")),
    5: ("PRIEST", ("discipline", "holy", "shadow")),
    6: ("DEATHKNIGHT", ("blood", "frost", "unholy")),
    7: ("SHAMAN", ("elemental", "enhancement", "restoration")),
    8: ("MAGE", ("arcane", "fire", "frost")),
    9: ("WARLOCK", ("affliction", "demonology", "destruction")),
    11: ("DRUID", ("balance", "feral", "restoration")),
}

VALID_ROLES = {"TANK", "HEALER", "DPS"}


def _require_int(value: Any, name: str, *, minimum: int = 0) -> int:
    if isinstance(value, bool) or not isinstance(value, int) or value < minimum:
        raise ServiceError(f"{name} must be an integer >= {minimum}")
    return value


def validate_character_snapshot(
    payload: dict[str, Any],
    model_support: dict[str, Any] | None = None,
) -> dict[str, Any]:
    if payload.get("schema") != SCHEMA_VERSION:
        raise ServiceError(f"snapshot schema must be {SCHEMA_VERSION}")

    era = normalize_era(payload.get("era"))
    character = payload.get("character")
    if not isinstance(character, dict):
        raise ServiceError("character must be an object")

    level = _require_int(character.get("level"), "character.level", minimum=1)
    cap = ERA_LEVEL_CAPS[era]
    if level > cap:
        raise ServiceError(f"character.level {level} exceeds {era} cap {cap}")

    class_id = _require_int(character.get("classId"), "character.classId", minimum=1)
    class_info = CLASS_SPECS.get(class_id)
    if class_info is None:
        raise ServiceError(f"unsupported classId {class_id}")
    class_name, specs = class_info

    if class_id == 6 and era != "WOTLK":
        raise ServiceError("Death Knight is unavailable before WOTLK")

    tree = _require_int(character.get("dominantTree"), "character.dominantTree")
    if tree >= len(specs):
        raise ServiceError("character.dominantTree must be 0, 1 or 2")
    spec = specs[tree]

    role = character.get("role")
    if role not in VALID_ROLES:
        raise ServiceError("character.role must be TANK, HEALER or DPS")

    points = character.get("treePoints")
    if (
        not isinstance(points, list)
        or len(points) != 3
        or any(isinstance(value, bool) or not isinstance(value, int) or value < 0 for value in points)
    ):
        raise ServiceError("character.treePoints must contain exactly three non-negative integers")

    talents = character.get("talents")
    if not isinstance(talents, str) or len(talents.split("-")) != 3:
        raise ServiceError("character.talents must be a three-tree talent string")
    if any(part and not part.isdigit() for part in talents.split("-")):
        raise ServiceError("character.talents may contain only ranks and '-' separators")

    gear = character.get("gear")
    if not isinstance(gear, list) or len(gear) != 17:
        raise ServiceError("character.gear must contain exactly 17 WoWSims slots")
    for index, item in enumerate(gear):
        if item is None:
            continue
        if not isinstance(item, dict):
            raise ServiceError(f"character.gear[{index}] must be null or an object")
        _require_int(item.get("id"), f"character.gear[{index}].id", minimum=1)
        _require_int(item.get("enchant", 0), f"character.gear[{index}].enchant")
        gems = item.get("gems", [])
        if (
            not isinstance(gems, list)
            or len(gems) != 3
            or any(isinstance(value, bool) or not isinstance(value, int) or value < 0 for value in gems)
        ):
            raise ServiceError(f"character.gear[{index}].gems must contain exactly three non-negative integers")

    catalog = model_support or load_model_support()
    route = resolve_model(catalog, era, class_id, tree, role)
    if route is None:
        support = {
            "status": "UNSUPPORTED",
            "modelKey": f"{era.lower()}:unsupported:{spec}:{role.lower()}",
            "reason": "The pinned WoWSims engine has no catalogued route for this class/tree/role combination.",
        }
    else:
        proto_field = route["protoSpecField"]
        support = {
            "status": route["status"],
            "modelKey": f"{era.lower()}:{proto_field}:{spec}:{role.lower()}",
            "protoSpecField": proto_field,
            "apiProtoBlob": catalog["eras"][era]["api_proto"]["blob"],
            "reason": "Pinned engine model exists, but Skrra mechanics/preset validation is still required before this route is authoritative.",
        }

    return {
        "schema": SCHEMA_VERSION,
        "valid": True,
        "era": era,
        "character": {
            "level": level,
            "classId": class_id,
            "class": class_name,
            "spec": spec,
            "role": role,
        },
        "support": support,
    }


class SimRunner:
    def __init__(
        self,
        manifest: dict[str, Any],
        *,
        timeout_seconds: float | None = None,
        binaries: dict[str, str] | None = None,
    ) -> None:
        self.manifest = manifest
        self.model_support = load_model_support(manifest=manifest)
        self.preset_catalog = load_preset_catalog(manifest=manifest)
        self.glyph_spell_map = load_glyph_spell_map()
        self.timeout_seconds = timeout_seconds or _env_float(
            "WOWSIMS_TIMEOUT_SECONDS", DEFAULT_TIMEOUT_SECONDS
        )
        self.binaries = dict(binaries or ERA_TO_BINARY)
        self._slots = threading.BoundedSemaphore(
            _env_int("WOWSIMS_MAX_CONCURRENT", DEFAULT_MAX_CONCURRENT)
        )

    def engine_info(self, era: str) -> dict[str, Any]:
        engine = self.manifest["engines"][era]
        return {
            "repository": engine["repository"],
            "commit": engine["commit"],
            "binary": self.binaries[era],
        }

    def health(self) -> dict[str, Any]:
        engines: dict[str, Any] = {}
        ready = True
        for era in ERA_TO_BINARY:
            path = Path(self.binaries[era])
            exists = path.is_file() and os.access(path, os.X_OK)
            ready = ready and exists
            engines[era] = {
                **self.engine_info(era),
                "ready": exists,
            }
        return {
            "schema": SCHEMA_VERSION,
            "ready": ready,
            "engines": engines,
            "models": model_catalog_summary(self.model_support),
            "presets": preset_catalog_summary(self.preset_catalog),
        }

    def validate_snapshot(self, payload: dict[str, Any]) -> dict[str, Any]:
        return validate_character_snapshot(payload, self.model_support)

    def build_snapshot_request(
        self,
        snapshot: dict[str, Any],
        *,
        preset_sha256: str | None = None,
    ) -> dict[str, Any]:
        return build_baseline_request(
            snapshot,
            self.model_support,
            self.preset_catalog,
            self.glyph_spell_map,
            preset_sha256=preset_sha256,
        )

    def build_candidate_request(
        self,
        snapshot: dict[str, Any],
        candidate: dict[str, Any],
        slot_index: int,
        *,
        preset_sha256: str | None = None,
    ) -> dict[str, Any]:
        return build_candidate_request(
            snapshot,
            candidate,
            slot_index,
            self.model_support,
            self.preset_catalog,
            self.glyph_spell_map,
            preset_sha256=preset_sha256,
        )

    def build_bag_candidate_manifest(
        self,
        snapshot: dict[str, Any],
        candidates: list[Any],
        *,
        preset_sha256: str | None = None,
    ) -> dict[str, Any]:
        return build_bag_candidate_manifest(
            snapshot,
            candidates,
            self.model_support,
            self.preset_catalog,
            self.glyph_spell_map,
            preset_sha256=preset_sha256,
        )

    def simulate(self, era: str, request: dict[str, Any]) -> dict[str, Any]:
        era = normalize_era(era)
        if not isinstance(request, dict):
            raise ServiceError("request must be a RaidSimRequest JSON object")

        binary = self.binaries[era]
        if not (Path(binary).is_file() and os.access(binary, os.X_OK)):
            raise ServiceError(
                f"{era} WoWSims binary is unavailable",
                HTTPStatus.SERVICE_UNAVAILABLE,
            )

        with tempfile.TemporaryDirectory(prefix="skrra-wowsims-") as tmp:
            infile = Path(tmp) / "request.json"
            infile.write_text(
                json.dumps(request, separators=(",", ":"), ensure_ascii=False),
                encoding="utf-8",
            )
            acquired = self._slots.acquire(timeout=self.timeout_seconds)
            if not acquired:
                raise ServiceError(
                    "WoWSims service is busy",
                    HTTPStatus.SERVICE_UNAVAILABLE,
                )
            try:
                try:
                    completed = subprocess.run(
                        [binary, "sim", "--infile", str(infile)],
                        check=False,
                        capture_output=True,
                        text=True,
                        timeout=self.timeout_seconds,
                        env={
                            **os.environ,
                            "GOMAXPROCS": os.environ.get("WOWSIMS_GOMAXPROCS", "2"),
                        },
                    )
                except subprocess.TimeoutExpired as exc:
                    raise ServiceError(
                        f"{era} WoWSims timed out after {self.timeout_seconds:g}s",
                        HTTPStatus.GATEWAY_TIMEOUT,
                    ) from exc
                except OSError as exc:
                    raise ServiceError(
                        f"failed to launch {era} WoWSims: {exc}",
                        HTTPStatus.SERVICE_UNAVAILABLE,
                    ) from exc
            finally:
                self._slots.release()

        if completed.returncode != 0:
            detail = (completed.stderr or completed.stdout or "unknown simulator error").strip()
            if len(detail) > 800:
                detail = detail[:800] + "..."
            raise ServiceError(
                f"{era} WoWSims failed: {detail}",
                HTTPStatus.UNPROCESSABLE_ENTITY,
            )

        try:
            result = json.loads(completed.stdout)
        except json.JSONDecodeError as exc:
            raise ServiceError(
                f"{era} WoWSims returned invalid JSON",
                HTTPStatus.BAD_GATEWAY,
            ) from exc

        if not isinstance(result, dict):
            raise ServiceError(
                f"{era} WoWSims returned a non-object result",
                HTTPStatus.BAD_GATEWAY,
            )
        if result.get("errorResult"):
            raise ServiceError(
                f"{era} WoWSims error: {result['errorResult']}",
                HTTPStatus.UNPROCESSABLE_ENTITY,
            )
        return result

    def compare(
        self,
        era: str,
        baseline_request: dict[str, Any],
        candidate_request: dict[str, Any],
        *,
        metric: str = "dps",
        include_results: bool = False,
    ) -> dict[str, Any]:
        era = normalize_era(era)
        if metric not in METRIC_PATHS:
            raise ServiceError(f"unsupported metric {metric!r}; supported metrics: dps, hps")

        baseline_result = self.simulate(era, baseline_request)
        candidate_result = self.simulate(era, candidate_request)
        baseline = extract_metric(baseline_result, metric)
        candidate = extract_metric(candidate_result, metric)
        delta = candidate - baseline
        delta_percent = None if baseline == 0 else (delta / baseline) * 100.0

        response: dict[str, Any] = {
            "schema": SCHEMA_VERSION,
            "era": era,
            "engine": self.engine_info(era),
            "metric": metric,
            "baseline": baseline,
            "candidate": candidate,
            "delta": delta,
            "deltaPercent": delta_percent,
        }
        if include_results:
            response["baselineResult"] = baseline_result
            response["candidateResult"] = candidate_result
        return response


class ApiHandler(BaseHTTPRequestHandler):
    server_version = "SkrraWoWSims/0.1"

    @property
    def runner(self) -> SimRunner:
        return self.server.runner  # type: ignore[attr-defined]

    @property
    def max_body_bytes(self) -> int:
        return self.server.max_body_bytes  # type: ignore[attr-defined]

    def log_message(self, format: str, *args: Any) -> None:
        if os.environ.get("WOWSIMS_HTTP_LOG", "0") == "1":
            super().log_message(format, *args)

    def _send_json(self, status: int, payload: dict[str, Any]) -> None:
        body = json.dumps(payload, separators=(",", ":"), ensure_ascii=False).encode("utf-8")
        self.send_response(status)
        self.send_header("Content-Type", "application/json; charset=utf-8")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def _read_json(self) -> dict[str, Any]:
        raw_length = self.headers.get("Content-Length")
        if raw_length is None:
            raise ServiceError("Content-Length is required", HTTPStatus.LENGTH_REQUIRED)
        try:
            length = int(raw_length)
        except ValueError as exc:
            raise ServiceError("invalid Content-Length") from exc
        if length < 0 or length > self.max_body_bytes:
            raise ServiceError(
                "request body is too large",
                HTTPStatus.REQUEST_ENTITY_TOO_LARGE,
            )
        raw = self.rfile.read(length)
        try:
            payload = json.loads(raw)
        except json.JSONDecodeError as exc:
            raise ServiceError("request body must be valid JSON") from exc
        if not isinstance(payload, dict):
            raise ServiceError("request body must be a JSON object")
        return payload

    def do_GET(self) -> None:
        if self.path == "/health":
            health = self.runner.health()
            status = HTTPStatus.OK if health["ready"] else HTTPStatus.SERVICE_UNAVAILABLE
            self._send_json(status, health)
            return
        if self.path == "/v1/models":
            self._send_json(HTTPStatus.OK, model_catalog_summary(self.runner.model_support))
            return
        if self.path == "/v1/presets":
            self._send_json(HTTPStatus.OK, preset_catalog_summary(self.runner.preset_catalog))
            return
        self._send_json(HTTPStatus.NOT_FOUND, {"error": "not found"})

    def do_POST(self) -> None:
        try:
            payload = self._read_json()
            if self.path == "/v1/snapshot/validate":
                response = self.runner.validate_snapshot(payload)
                response["engine"] = self.runner.engine_info(response["era"])
                self._send_json(HTTPStatus.OK, response)
                return

            if self.path == "/v1/snapshot/request":
                snapshot = payload.get("snapshot")
                if not isinstance(snapshot, dict):
                    raise ServiceError("snapshot must be an object")
                preset_sha256 = payload.get("presetSha256")
                if preset_sha256 is not None and not isinstance(preset_sha256, str):
                    raise ServiceError("presetSha256 must be a string")
                response = self.runner.build_snapshot_request(
                    snapshot,
                    preset_sha256=preset_sha256,
                )
                response["engine"] = self.runner.engine_info(response["era"])
                self._send_json(HTTPStatus.OK, response)
                return

            if self.path == "/v1/snapshot/candidate-request":
                snapshot = payload.get("snapshot")
                candidate = payload.get("candidate")
                slot_index = payload.get("slotIndex")
                if not isinstance(snapshot, dict):
                    raise ServiceError("snapshot must be an object")
                if not isinstance(candidate, dict):
                    raise ServiceError("candidate must be an item object")
                preset_sha256 = payload.get("presetSha256")
                if preset_sha256 is not None and not isinstance(preset_sha256, str):
                    raise ServiceError("presetSha256 must be a string")
                response = self.runner.build_candidate_request(
                    snapshot,
                    candidate,
                    slot_index,
                    preset_sha256=preset_sha256,
                )
                response["engine"] = self.runner.engine_info(response["era"])
                self._send_json(HTTPStatus.OK, response)
                return

            if self.path == "/v1/snapshot/bag-candidates":
                snapshot = payload.get("snapshot")
                candidates = payload.get("candidates")
                if not isinstance(snapshot, dict):
                    raise ServiceError("snapshot must be an object")
                if not isinstance(candidates, list):
                    raise ServiceError("candidates must be an array")
                preset_sha256 = payload.get("presetSha256")
                if preset_sha256 is not None and not isinstance(preset_sha256, str):
                    raise ServiceError("presetSha256 must be a string")
                response = self.runner.build_bag_candidate_manifest(
                    snapshot,
                    candidates,
                    preset_sha256=preset_sha256,
                )
                response["engine"] = self.runner.engine_info(response["era"])
                self._send_json(HTTPStatus.OK, response)
                return

            if self.path == "/v1/sim":
                era = normalize_era(payload.get("era"))
                result = self.runner.simulate(era, payload.get("request"))
                self._send_json(
                    HTTPStatus.OK,
                    {
                        "schema": SCHEMA_VERSION,
                        "era": era,
                        "engine": self.runner.engine_info(era),
                        "result": result,
                    },
                )
                return

            if self.path == "/v1/compare":
                response = self.runner.compare(
                    payload.get("era"),
                    payload.get("baselineRequest"),
                    payload.get("candidateRequest"),
                    metric=payload.get("metric", "dps"),
                    include_results=bool(payload.get("includeResults", False)),
                )
                self._send_json(HTTPStatus.OK, response)
                return

            raise ServiceError("not found", HTTPStatus.NOT_FOUND)
        except ServiceError as exc:
            self._send_json(exc.status, {"error": str(exc)})
        except Exception:
            self._send_json(
                HTTPStatus.INTERNAL_SERVER_ERROR,
                {"error": "internal server error"},
            )


class SimHTTPServer(ThreadingHTTPServer):
    daemon_threads = True

    def __init__(
        self,
        address: tuple[str, int],
        runner: SimRunner,
        max_body_bytes: int,
    ):
        super().__init__(address, ApiHandler)
        self.runner = runner
        self.max_body_bytes = max_body_bytes


def parse_listen(value: str) -> tuple[str, int]:
    host, sep, port_text = value.rpartition(":")
    if not sep or not host:
        raise ValueError("WOWSIMS_LISTEN must be HOST:PORT")
    port = int(port_text)
    if not 1 <= port <= 65535:
        raise ValueError("WOWSIMS_LISTEN port must be 1-65535")
    return host, port


def main() -> None:
    manifest = load_manifest()
    runner = SimRunner(manifest)
    address = parse_listen(os.environ.get("WOWSIMS_LISTEN", DEFAULT_LISTEN))
    max_body_bytes = _env_int(
        "WOWSIMS_MAX_BODY_BYTES",
        DEFAULT_MAX_BODY_BYTES,
    )
    server = SimHTTPServer(address, runner, max_body_bytes)
    print(
        f"Skrra WoWSims service listening on {address[0]}:{address[1]} "
        f"(schema {SCHEMA_VERSION})",
        flush=True,
    )
    server.serve_forever()


if __name__ == "__main__":
    main()
