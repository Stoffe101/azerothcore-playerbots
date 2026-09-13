#!/usr/bin/env bash
# Turn on mod-playerbot-chatter on an existing install without re-running full setup.
# Reactive replies have a small local fallback, so General/party/whisper still answer if Ollama is
# temporarily unavailable; when Ollama is reachable, normal model replies win.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
AC_DIR="$ROOT/azerothcore-wotlk"
ROOT_ENV="$ROOT/.env"
LIVE_ENV="$AC_DIR/.env"
CHAT_CONF="$AC_DIR/env/dist/etc/modules/mod_playerbot_chatter.conf"
PB_CONF="$AC_DIR/env/dist/etc/modules/mod_playerbots.conf"

# The repo-root .env is the project's source of truth. Older versions of this helper only toggled
# Enable/AmbientEnable and therefore left a historical localhost URL sitting in the persistent
# module config. localhost from inside ac-worldserver means the container itself, not Windows/WSL's
# Ollama process. Load the current env and refresh the endpoint/model knobs every time we enable it.
if [[ -f "$ROOT_ENV" ]]; then
  set -a
  # shellcheck disable=SC1090
  source "$ROOT_ENV"
  set +a
fi

OLLAMA_HOST="${OLLAMA_IP:-host.docker.internal}"
RESOLVED_CHATTER_URL="${CHATTER_URL:-http://${OLLAMA_HOST}:11434/api/generate}"
RESOLVED_CHATTER_MODEL="${CHATTER_MODEL:-llama3.1:8b}"
RESOLVED_CHATTER_THINK="${CHATTER_THINK:-0}"
RESOLVED_CHATTER_CONCURRENCY="${CHATTER_MAX_CONCURRENT:-3}"

persist_env() {
  local key="$1" value="$2" file
  for file in "$ROOT_ENV" "$LIVE_ENV"; do
    [[ -f "$file" ]] || continue
    if grep -q "^${key}=" "$file"; then
      sed -i "s|^${key}=.*|${key}=${value}|" "$file"
    else
      printf '\n%s=%s\n' "$key" "$value" >> "$file"
    fi
  done
}

set_conf() {
  local key="$1" value="$2" file="$3"
  [[ -f "$file" ]] || return 0
  awk -v k="$key" -v v="$value" '
    BEGIN { done=0 }
    {
      line=$0
      split(line,a,"=")
      lhs=a[1]; gsub(/^[ \t]+|[ \t]+$/,"",lhs)
      if (!done && lhs==k) { print k " = " v; done=1 } else print line
    }
    END { if (!done) print k " = " v }
  ' "$file" > "$file.tmp"
  mv "$file.tmp" "$file"
}

if [[ -x "$ROOT/sync-module-configs.sh" ]]; then
  "$ROOT/sync-module-configs.sh" >/dev/null
fi
[[ -f "$CHAT_CONF" ]] || { echo "Missing $CHAT_CONF. Run ./update.sh first." >&2; exit 1; }

persist_env CHATTER_ENABLE 1
persist_env CHATTER_AMBIENT_ENABLE 1
set_conf "PlayerbotChatter.Enable" "1" "$CHAT_CONF"
set_conf "PlayerbotChatter.AmbientEnable" "1" "$CHAT_CONF"
set_conf "PlayerbotChatter.Url" "$RESOLVED_CHATTER_URL" "$CHAT_CONF"
set_conf "PlayerbotChatter.Model" "$RESOLVED_CHATTER_MODEL" "$CHAT_CONF"
set_conf "PlayerbotChatter.Think" "$RESOLVED_CHATTER_THINK" "$CHAT_CONF"
set_conf "PlayerbotChatter.MaxConcurrent" "$RESOLVED_CHATTER_CONCURRENCY" "$CHAT_CONF"

# Avoid double voices: AI/fallback chatter owns speech; deterministic playerbot command handling
# remains untouched.
set_conf "AiPlayerbot.RandomBotTalk" "0" "$PB_CONF"
set_conf "AiPlayerbot.EnableBroadcasts" "0" "$PB_CONF"
set_conf "AiPlayerbot.RandomBotSayWithoutMaster" "0" "$PB_CONF"

case "$RESOLVED_CHATTER_URL" in
  http://localhost:*|http://127.0.0.1:*)
    echo "WARNING: PlayerbotChatter.Url resolves to $RESOLVED_CHATTER_URL" >&2
    echo "         ac-worldserver runs in Docker, so localhost is the container itself." >&2
    echo "         Unless Ollama is deliberately inside that same container, set:" >&2
    echo "         OLLAMA_IP=host.docker.internal" >&2
    echo "         in $ROOT_ENV and run this helper again." >&2
    ;;
esac

(cd "$AC_DIR" && docker compose restart ac-worldserver)

echo "Bot chatter enabled."
echo "  endpoint : $RESOLVED_CHATTER_URL"
echo "  model    : $RESOLVED_CHATTER_MODEL"
echo "  parallel : $RESOLVED_CHATTER_CONCURRENCY"
echo "General chat gets one same-zone/faction bot responder when available."
echo "If Ollama is unavailable, reactive chat uses the built-in short fallback instead of silence."
