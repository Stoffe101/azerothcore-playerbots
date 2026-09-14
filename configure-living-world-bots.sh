#!/usr/bin/env bash
# One-time Playerbots defaults for a persistent, populated private MMO world.
# Existing operator choices remain authoritative after the migration marker is written.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
AC_DIR="$ROOT/azerothcore-wotlk"
CONF="$AC_DIR/env/dist/etc/modules/playerbots.conf"
MARKER="$AC_DIR/env/dist/etc/.living_world_playerbots_v1"

[[ -f "$MARKER" ]] && exit 0

if [[ ! -f "$CONF" ]]; then
  DIST="$AC_DIR/modules/mod-playerbots/conf/playerbots.conf.dist"
  if [[ ! -f "$DIST" ]]; then
    echo "ERROR: cannot configure living-world Playerbots defaults; playerbots.conf.dist is missing." >&2
    exit 1
  fi
  mkdir -p "$(dirname "$CONF")"
  cp "$DIST" "$CONF"
fi

command -v python3 >/dev/null 2>&1 || {
  echo "ERROR: python3 is required to migrate Playerbots living-world defaults." >&2
  exit 1
}

python3 - "$CONF" <<'PY'
from pathlib import Path
import re
import sys

path = Path(sys.argv[1])
text = path.read_text(encoding="utf-8")

# Keep important guild characters persistent while making the anonymous world population cycle
# through every level range instead of slowly becoming an all-level-80 retirement village.
settings = {
    "AiPlayerbot.LevelBrackets.Enabled": "1",
    "AiPlayerbot.LevelBrackets.IgnoreGuildBotsWithRealPlayers": "1",
    "AiPlayerbot.ResetBotLevel.Enabled": "1",
    "AiPlayerbot.ResetBotLevel.MaxLevel": "80",
    "AiPlayerbot.ResetBotLevel.ResetToLevel": "1",
    "AiPlayerbot.ResetBotLevel.ResetChance": "100",
    "AiPlayerbot.ResetBotLevel.ScaledChance": "0",
    "AiPlayerbot.ResetBotLevel.RestrictTimePlayed": "1",
    "AiPlayerbot.ResetBotLevel.MinTimePlayed": "86400",
    "AiPlayerbot.ResetBotLevel.IgnoreGuildBotsWithRealPlayers": "1",
    # The newer reset manager is the single owner of max-level recycling. Do not let the legacy
    # downgrade switch compete with it.
    "AiPlayerbot.DowngradeMaxLevelBot": "0",
}

for key, value in settings.items():
    pattern = re.compile(rf"(?m)^[ \t]*{re.escape(key)}[ \t]*=.*$")
    replacement = f"{key} = {value}"
    if pattern.search(text):
        text = pattern.sub(replacement, text, count=1)
    else:
        if not text.endswith("\n"):
            text += "\n"
        text += replacement + "\n"

path.write_text(text, encoding="utf-8")
PY

mkdir -p "$(dirname "$MARKER")"
: > "$MARKER"

echo "==> Living-world Playerbots defaults enabled: level brackets + safe random-bot recycling."
echo "    Bots in guilds with real players are excluded and remain persistent."
