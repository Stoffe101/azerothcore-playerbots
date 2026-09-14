#!/usr/bin/env bash
# Canonical AzerothCore + Playerbots LAN bootstrap entry point.
#
# The historical bootstrap is large and battle-tested. Keep that body immutable at the pinned
# commit below, patch the integration changes introduced by the full-adventure stack, then execute
# it from this repository directory. The pinned raw file is immutable and setup already requires
# GitHub/network access to clone AzerothCore and its modules.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LEGACY_COMMIT="521c84695c65c7182ce0a27c44deeff8f3dd1939"
LEGACY_URL="https://raw.githubusercontent.com/Stoffe101/azerothcore-playerbots/${LEGACY_COMMIT}/setup.sh"
RUNTIME="$ROOT/.setup-runtime.sh"

cleanup() {
  rm -f "$RUNTIME"
}
trap cleanup EXIT INT TERM

if command -v curl >/dev/null 2>&1; then
  curl -fsSL "$LEGACY_URL" -o "$RUNTIME"
elif command -v wget >/dev/null 2>&1; then
  wget -qO "$RUNTIME" "$LEGACY_URL"
else
  echo "ERROR: setup requires curl or wget to load the pinned bootstrap body from GitHub." >&2
  exit 1
fi

if [[ ! -s "$RUNTIME" ]]; then
  echo "ERROR: failed to download pinned bootstrap body: $LEGACY_URL" >&2
  exit 1
fi

command -v python3 >/dev/null 2>&1 || {
  echo "ERROR: python3 is required for the deterministic bootstrap preflight." >&2
  exit 1
}

python3 - "$RUNTIME" <<'PY'
from pathlib import Path
import sys

path = Path(sys.argv[1])
text = path.read_text(encoding="utf-8")

old_modules = 'LOCAL_MODULES=( "mod-playerbot-chatter" "mod-raid-roster" "mod-ahbot-price" "mod-wintergrasp-bots" "mod-arena-roster" )'
new_modules = 'LOCAL_MODULES=( "mod-playerbot-chatter" "mod-raid-roster" "mod-admin-panel" "mod-ahbot-price" "mod-wintergrasp-bots" "mod-arena-roster" "mod-titan-rune" )'
if old_modules not in text:
    raise SystemExit("ERROR: pinned setup body no longer matches expected LOCAL_MODULES line")
text = text.replace(old_modules, new_modules, 1)

# Every patch in this overlay is rooted at the AzerothCore checkout. Some patches edit files under
# modules/mod-individual-progression or modules/mod-playerbots, but their diff paths deliberately
# include that modules/... prefix. Applying those patches with `git -C` inside the nested module
# repository breaks fresh installs because the prefixed path no longer exists relative to that
# repository. Keep the historical, proven root-relative apply loop and merely verify it is still
# present in the pinned bootstrap body.
old_apply = r'''apply_patches () {
  local pdir="$ROOT/patches"
  [[ -d "$pdir" && -d "$AC_DIR/.git" ]] || return 0
  local patch name
  for patch in "$pdir"/*.patch; do
    [[ -e "$patch" ]] || continue
    name="$(basename "$patch")"
    if git -C "$AC_DIR" apply --reverse --check "$patch" >/dev/null 2>&1; then
      echo "    Patch already applied: $name"
    elif git -C "$AC_DIR" apply --check "$patch" >/dev/null 2>&1; then
      git -C "$AC_DIR" apply "$patch"
      echo "    Applied patch: $name"
    else
      echo "    ERROR: $name no longer applies (upstream moved?). Regenerate it against the" >&2
      echo "           current fork or remove it from patches/. Refusing to build without it." >&2
      exit 1
    fi
  done
  # mod-era-talents ships its own patch tree (core + IP always; playerbots/bridge when present).
  # Runs AFTER ours so 0012's Unit.cpp hunk lands before its Shatter/Wand/Molten Fury hunks —
  # the order every one of its Unit.cpp patches was cut against.
  if [[ -x "$AC_DIR/modules/mod-era-talents/apply-patches.sh" ]]; then
    "$AC_DIR/modules/mod-era-talents/apply-patches.sh" "$AC_DIR"
  fi
}
'''

if old_apply not in text:
    raise SystemExit("ERROR: pinned setup body no longer matches expected apply_patches block")

# This integration branch treats the persistent roster/director as core gameplay. Older templates
# still carry RAIDROSTER_ENABLE=0, so deliberately promote the generated runtime config to enabled.
# Once this branch becomes the canonical installer the template can be simplified separately.
old_roster = '  set_conf "RaidRoster.Enable" "${RAIDROSTER_ENABLE:-0}" "$RAID_CONF"'
new_roster = '  set_conf "RaidRoster.Enable" "1" "$RAID_CONF"'
if old_roster not in text:
    raise SystemExit("ERROR: pinned setup body no longer matches expected RaidRoster.Enable line")
text = text.replace(old_roster, new_roster, 1)

# The historical bootstrap predates the Docker-safe Ollama default. Inside ac-worldserver,
# localhost is the container itself. Match .env.example and the lore sidecar by defaulting to
# Docker Desktop's host gateway unless the operator explicitly supplies CHATTER_URL/OLLAMA_IP.
old_chatter_url = '${CHATTER_URL:-http://${OLLAMA_IP:-localhost}:11434/api/generate}'
new_chatter_url = '${CHATTER_URL:-http://${OLLAMA_IP:-host.docker.internal}:11434/api/generate}'
if old_chatter_url not in text:
    raise SystemExit("ERROR: pinned setup body no longer matches expected chatter URL default")
text = text.replace(old_chatter_url, new_chatter_url, 1)

# Upstream 7da03710 fixes addon downloads by mounting the containing directory instead of a
# single zip file. A file bind mount pins the old inode, so fetch-client-addons.sh replacing the
# archive could leave webreg serving stale data (or /dev/null forever). Keep our pinned bootstrap
# body, but apply the upstream fix deterministically to the generated runtime.
old_webreg = r'''      WEBREG_ADDONS_ZIP_PATH: "/data/addons.zip"
      WEBREG_ADDONS_ZIP_LABEL: "\${ADDONS_ZIP_LABEL:-Download bot addons}"
      WEBREG_BOT_PREFIX: "\${WEBREG_BOT_PREFIX:-rndbot}"
    ports:
      - "\${WEBREG_LAN_PORT:-8090}:8090"
    volumes:
      - "\${CLIENT_ZIP_PATH:-/dev/null}:/data/client.zip:ro"
      - "\${ADDONS_ZIP_PATH:-/dev/null}:/data/addons.zip:ro"
YAML
  # The main `docker compose up` (above) ran before this service was appended and
  # before its secrets existed, so it must be built + started now. Idempotent:
  # re-running reconciles the container with the regenerated override.
  # If fetch-client-addons.sh has produced the bundle, mount it by default so the
  # "Download bot addons" button works without editing .env. An explicit
  # ADDONS_ZIP_PATH still wins; absent, the compose default (/dev/null) applies.
  if [[ -z "${ADDONS_ZIP_PATH:-}" && -f "$ROOT/client-addons.zip" ]]; then
    export ADDONS_ZIP_PATH="$ROOT/client-addons.zip"
  fi
'''
new_webreg = r'''      WEBREG_ADDONS_ZIP_PATH: "/data/dist/client-addons.zip"
      WEBREG_ADDONS_ZIP_LABEL: "\${ADDONS_ZIP_LABEL:-Download bot addons}"
      WEBREG_BOT_PREFIX: "\${WEBREG_BOT_PREFIX:-rndbot}"
    ports:
      - "\${WEBREG_LAN_PORT:-8090}:8090"
    volumes:
      - "\${CLIENT_ZIP_PATH:-/dev/null}:/data/client.zip:ro"
      # DIRECTORY mount, not a file mount: replacing client-addons.zip must be visible live.
      - "$ROOT/client-dist:/data/dist:ro"
YAML
  # The main `docker compose up` (above) ran before this service was appended and
  # before its secrets existed, so it must be built + started now. Idempotent:
  # re-running reconciles the container with the regenerated override.
  # fetch-client-addons.sh writes client-dist/client-addons.zip atomically. Create the
  # directory here so Docker never creates it as root and webreg sees rebuilt zips live.
  mkdir -p "$ROOT/client-dist"
'''
if old_webreg not in text:
    raise SystemExit("ERROR: pinned setup body no longer matches expected webreg addon mount block")
text = text.replace(old_webreg, new_webreg, 1)

path.write_text(text, encoding="utf-8")
PY

# CI and maintainers can validate the pinned bootstrap transformation without cloning/building the
# server or touching an existing installation. This catches stale string replacements and shell
# syntax regressions in the exact generated runtime that a fresh install would execute.
if [[ "${SETUP_PREFLIGHT_ONLY:-0}" == "1" ]]; then
  bash -n "$RUNTIME"
  grep -Fq 'mod-admin-panel' "$RUNTIME"
  grep -Fq 'mod-titan-rune' "$RUNTIME"
  grep -Fq 'RaidRoster.Enable" "1"' "$RUNTIME"
  grep -Fq 'host.docker.internal' "$RUNTIME"
  grep -Fq 'git -C "$AC_DIR" apply --check "$patch"' "$RUNTIME"
  grep -Fq 'WEBREG_ADDONS_ZIP_PATH: "/data/dist/client-addons.zip"' "$RUNTIME"
  grep -Fq '$ROOT/client-dist:/data/dist:ro' "$RUNTIME"
  echo "Setup bootstrap preflight passed."
  exit 0
fi

chmod +x "$RUNTIME"
set +e
bash "$RUNTIME" "$@"
rc=$?
set -e
exit "$rc"
