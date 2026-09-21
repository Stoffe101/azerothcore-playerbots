#!/usr/bin/env python3
"""Private HTTP wrapper for the pinned Skrra WoWSims CLI engines."""

from __future__ import annotations

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


def validate_character_snapshot(payload: dict[str, Any]) -> dict[str, Any]:
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

    if class_id == 11 and spec == "feral":
        semantic_model = "feral_tank_druid" if role == "TANK" else "feral_druid"
    elif class_id == 6:
        semantic_model = "tank_deathknight" if role == "TANK" else "deathknight"
    elif class_id == 1 and spec == "protection":
        semantic_model = "protection_warrior"
    elif class_id == 2:
        semantic_model = {
            "holy": "holy_paladin",
            "protection": "protection_paladin",
            "retribution": "retribution_paladin",
        }[spec]
    elif class_id == 5:
        semantic_model = "shadow_priest" if spec == "shadow" else "healing_priest"
    elif class_id == 7:
        semantic_model = f"{spec}_shaman"
    else:
        semantic_model = class_name.lower()

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
        "support": {
            "status": "AVAILABLE_UNVALIDATED",
            "modelKey": f"{era.lower()}:{semantic_model}:{spec}:{role.lower()}",
            "reason": "Snapshot structure is valid, but this era/spec model is not authoritative until Skrra mechanics/preset validation is completed.",
        },
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
        }

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
        if self.path != "/health":
            self._send_json(HTTPStatus.NOT_FOUND, {"error": "not found"})
            return
        health = self.runner.health()
        status = HTTPStatus.OK if health["ready"] else HTTPStatus.SERVICE_UNAVAILABLE
        self._send_json(status, health)

    def do_POST(self) -> None:
        try:
            payload = self._read_json()
            if self.path == "/v1/snapshot/validate":
                response = validate_character_snapshot(payload)
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
