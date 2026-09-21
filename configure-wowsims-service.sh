#!/usr/bin/env bash
# Add the private WoWSims simulator container to the generated AzerothCore compose override.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
AC_DIR="${AC_DIR:-$ROOT/azerothcore-wotlk}"
OVERRIDE="${WOWSIMS_COMPOSE_FILE:-$AC_DIR/docker-compose.override.yml}"
BEGIN_MARKER="# BEGIN SKRRA WOWSIMS SERVICE"
END_MARKER="# END SKRRA WOWSIMS SERVICE"

render_block() {
  cat <<'YAML'
  # BEGIN SKRRA WOWSIMS SERVICE
  ac-wowsims:
    build: ./../wowsims-service
    restart: unless-stopped
    networks:
      - ac-network
    expose:
      - "8092"
    environment:
      WOWSIMS_LISTEN: "0.0.0.0:8092"
      WOWSIMS_TIMEOUT_SECONDS: "${WOWSIMS_TIMEOUT_SECONDS:-45}"
      WOWSIMS_GOMAXPROCS: "${WOWSIMS_GOMAXPROCS:-2}"
      WOWSIMS_MAX_CONCURRENT: "${WOWSIMS_MAX_CONCURRENT:-2}"
      WOWSIMS_HTTP_LOG: "${WOWSIMS_HTTP_LOG:-0}"
  # END SKRRA WOWSIMS SERVICE
YAML
}

if [[ "${1:-}" == "--render" ]]; then
  render_block
  exit 0
fi

read_live_env() {
  local key="$1" fallback="$2"
  local env_file="$AC_DIR/.env"
  local value="${!key:-}"
  if [[ -z "$value" && -f "$env_file" ]]; then
    value="$(awk -F= -v wanted="$key" '
      $0 !~ /^[[:space:]]*#/ {
        lhs=$1
        gsub(/^[ \t]+|[ \t]+$/, "", lhs)
        if (lhs == wanted) {
          sub(/^[^=]*=/, "", $0)
          print $0
          exit
        }
      }
    ' "$env_file")"
    value="${value%\"}"; value="${value#\"}"
    value="${value%\'}"; value="${value#\'}"
  fi
  printf '%s' "${value:-$fallback}"
}

enable="$(read_live_env WOWSIMS_ENABLE 1)"

if [[ ! -f "$OVERRIDE" ]]; then
  echo "ERROR: WoWSims compose configuration expected $OVERRIDE. Run setup.sh first." >&2
  exit 1
fi

python3 - "$OVERRIDE" "$BEGIN_MARKER" "$END_MARKER" <<'PY'
from pathlib import Path
import sys

path = Path(sys.argv[1])
begin = sys.argv[2]
end = sys.argv[3]
text = path.read_text(encoding="utf-8")

while begin in text:
    start = text.index(begin)
    line_start = text.rfind("\n", 0, start) + 1
    end_pos = text.find(end, start)
    if end_pos < 0:
        raise SystemExit(f"ERROR: found {begin!r} without matching {end!r}")
    line_end = text.find("\n", end_pos)
    if line_end < 0:
        line_end = len(text)
    else:
        line_end += 1
    text = text[:line_start] + text[line_end:]

path.write_text(text.rstrip() + "\n", encoding="utf-8")
PY

if [[ "$enable" == "1" ]]; then
  render_block >> "$OVERRIDE"
  echo "==> WoWSims service enabled in docker-compose.override.yml (private Docker network only)."
else
  echo "==> WoWSims service disabled (WOWSIMS_ENABLE=$enable)."
fi

if [[ "${1:-}" == "--start" ]]; then
  cd "$AC_DIR"
  if [[ "$enable" == "1" ]]; then
    docker compose up -d --build ac-wowsims
  else
    docker rm -f ac-wowsims >/dev/null 2>&1 || true
  fi
fi
