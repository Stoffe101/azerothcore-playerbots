#!/usr/bin/env bash
# Diagnose the exact network path the worldserver uses for Ollama without rebuilding anything.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
AC_DIR="$ROOT/azerothcore-wotlk"
ROOT_ENV="$ROOT/.env"
CHAT_CONF="$AC_DIR/env/dist/etc/modules/mod_playerbot_chatter.conf"

[[ -d "$AC_DIR" ]] || { echo "ERROR: $AC_DIR does not exist." >&2; exit 1; }
[[ -f "$CHAT_CONF" ]] || { echo "ERROR: $CHAT_CONF does not exist. Run ./update.sh first." >&2; exit 1; }

if [[ -f "$ROOT_ENV" ]]; then
  set -a
  # shellcheck disable=SC1090
  source "$ROOT_ENV"
  set +a
fi

conf_value() {
  local key="$1"
  awk -F= -v wanted="$key" '
    {
      lhs=$1; gsub(/^[ \t]+|[ \t]+$/, "", lhs)
      if (lhs == wanted) {
        value=substr($0, index($0, "=") + 1)
        gsub(/^[ \t]+|[ \t]+$/, "", value)
        print value
        exit
      }
    }
  ' "$CHAT_CONF"
}

URL="$(conf_value PlayerbotChatter.Url)"
MODEL="$(conf_value PlayerbotChatter.Model)"
ENABLED="$(conf_value PlayerbotChatter.Enable)"
[[ -n "$URL" ]] || URL="${CHATTER_URL:-http://${OLLAMA_IP:-host.docker.internal}:11434/api/generate}"
[[ -n "$MODEL" ]] || MODEL="${CHATTER_MODEL:-llama3.1:8b}"

if [[ ! "$URL" =~ ^http://([^/:]+)(:([0-9]+))?(/.*)?$ ]]; then
  echo "ERROR: unsupported PlayerbotChatter.Url: $URL" >&2
  exit 1
fi
HOST="${BASH_REMATCH[1]}"
PORT="${BASH_REMATCH[3]:-80}"

cd "$AC_DIR"
WORLD_ID="$(docker compose ps -q ac-worldserver)"
[[ -n "$WORLD_ID" ]] || { echo "ERROR: ac-worldserver is not running." >&2; exit 1; }

echo "============================================================"
echo " BOT CHATTER / OLLAMA DIAGNOSTIC"
echo "============================================================"
echo " enabled  : ${ENABLED:-?}"
echo " endpoint : $URL"
echo " model    : $MODEL"
echo " host:port: $HOST:$PORT"
echo

if [[ "$HOST" == "localhost" || "$HOST" == "127.0.0.1" ]]; then
  echo "[FAIL] The configured Ollama host is container-local $HOST."
  echo "       For Docker Desktop + Windows-hosted Ollama, use OLLAMA_IP=host.docker.internal"
  echo "       in $ROOT_ENV, then run ./enable-bot-chatter.sh again."
  exit 2
fi

echo "==> Resolving Ollama host from INSIDE ac-worldserver"
if docker compose exec -T ac-worldserver sh -lc "getent hosts '$HOST' 2>/dev/null || grep -F '$HOST' /etc/hosts 2>/dev/null || true" | sed 's/^/    /'; then
  :
fi

echo "==> Opening TCP $HOST:$PORT from INSIDE ac-worldserver"
if ! docker compose exec -T ac-worldserver bash -lc "timeout 4 bash -lc '</dev/tcp/$HOST/$PORT'" >/dev/null 2>&1; then
  cat <<EOF
[FAIL] The worldserver container cannot open TCP $HOST:$PORT.

For this project's Windows + Docker Desktop layout, the intended endpoint is:
  http://host.docker.internal:11434/api/generate

If that is already configured, Ollama is probably only listening on Windows localhost.
Ollama's Windows setting OLLAMA_HOST controls its bind address. Do NOT expose port 11434 to
untrusted networks: the local Ollama API has no normal LAN authentication layer.

First verify Ollama itself in Windows PowerShell:
  ollama list
  Invoke-WebRequest http://localhost:11434/api/tags

Then fix the Windows/Docker reachability before enabling full AI chatter. The in-game reactive
fallback remains safe and will still answer while Ollama is unavailable.
EOF
  exit 3
fi

echo "    [OK] TCP connection succeeded."

echo "==> Querying /api/tags through the SAME worldserver network namespace"
# Use bash /dev/tcp so the diagnostic does not depend on curl/wget being installed in the
# worldserver image. HTTP/1.0 + Connection: close makes the response easy to collect.
HTTP_RESPONSE="$(docker compose exec -T ac-worldserver bash -lc "
  exec 3<>/dev/tcp/$HOST/$PORT
  printf 'GET /api/tags HTTP/1.0\r\nHost: $HOST\r\nConnection: close\r\n\r\n' >&3
  cat <&3
" 2>/dev/null || true)"

if ! grep -qE '^HTTP/[0-9.]+ 200' <<<"$HTTP_RESPONSE"; then
  echo "[FAIL] TCP works, but Ollama did not return HTTP 200 for /api/tags."
  printf '%s\n' "$HTTP_RESPONSE" | head -12 | sed 's/^/    /'
  exit 4
fi

echo "    [OK] Ollama HTTP API answered."

if grep -Fq "\"name\":\"$MODEL\"" <<<"$HTTP_RESPONSE" || grep -Fq "\"model\":\"$MODEL\"" <<<"$HTTP_RESPONSE"; then
  echo "    [OK] Configured model '$MODEL' is installed."
else
  echo "[WARN] Ollama is reachable, but '$MODEL' was not found in /api/tags."
  echo "       In Windows PowerShell run: ollama pull $MODEL"
  exit 5
fi

cat <<EOF

CHATTER READY
The exact worldserver -> Ollama network path works and the configured model exists.
If replies still fail after this, inspect:
  docker compose logs --since 5m --no-color ac-worldserver | grep -F '[PlayerbotChatter]'
============================================================
EOF
