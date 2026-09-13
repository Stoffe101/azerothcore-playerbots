#!/usr/bin/env bash
# Turn on mod-playerbot-chatter on an existing install without re-running full setup.
# Reactive replies now have a small local fallback, so General/party/whisper still answer if
# Ollama is temporarily unavailable; when Ollama is running, normal model replies win.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
AC_DIR="$ROOT/azerothcore-wotlk"
ROOT_ENV="$ROOT/.env"
LIVE_ENV="$AC_DIR/.env"
CHAT_CONF="$AC_DIR/env/dist/etc/modules/mod_playerbot_chatter.conf"
PB_CONF="$AC_DIR/env/dist/etc/modules/mod_playerbots.conf"

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

# Avoid double voices: AI/fallback chatter owns speech; deterministic playerbot command handling
# remains untouched.
set_conf "AiPlayerbot.RandomBotTalk" "0" "$PB_CONF"
set_conf "AiPlayerbot.EnableBroadcasts" "0" "$PB_CONF"
set_conf "AiPlayerbot.RandomBotSayWithoutMaster" "0" "$PB_CONF"

(cd "$AC_DIR" && docker compose restart ac-worldserver)

echo "Bot chatter enabled. General chat now gets one same-zone/faction bot responder when available."
echo "If Ollama is reachable at the configured PlayerbotChatter.Url you get full AI replies;"
echo "if it is down, reactive chat uses the built-in short fallback instead of staying silent."
