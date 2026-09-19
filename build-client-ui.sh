#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
UI="$ROOT/client-ui"
SYNC=0
[[ "${1:-}" == "--sync" ]] && SYNC=1

command -v node >/dev/null || { echo "ERROR: Node.js is required to build the typed Group Composer UI." >&2; exit 1; }
command -v npm  >/dev/null || { echo "ERROR: npm is required to build the typed Group Composer UI." >&2; exit 1; }

cd "$UI"
if [[ ! -x node_modules/.bin/tstl ]]; then
  echo "==> Installing pinned Group Composer UI build dependencies"
  npm install --package-lock=false --ignore-scripts --no-audit --no-fund
fi

echo "==> Compiling Group Composer TypeScript -> Lua 5.1"
npm run build

OUT="$UI/dist/GroupComposerModernUI.lua"
[[ -f "$OUT" ]] || { echo "ERROR: expected generated bundle missing: $OUT" >&2; exit 1; }

if command -v luac5.1 >/dev/null; then
  luac5.1 -p "$OUT"
elif command -v luac >/dev/null; then
  luac -p "$OUT"
else
  echo "NOTE: luac not installed; TypeScriptToLua compile succeeded but Lua syntax was not independently parsed."
fi

if [[ "$SYNC" == "1" ]]; then
  bash "$UI/scripts/sync-generated.sh"
fi

echo "    Generated $OUT"
