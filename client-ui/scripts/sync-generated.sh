#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SRC="$ROOT/client-ui/dist/GroupComposerModernUI.lua"
DEST="$ROOT/client-addons-src/GroupComposer/GroupComposerModernUI.lua"

[[ -f "$SRC" ]] || {
  echo "ERROR: generated UI bundle not found: $SRC" >&2
  exit 1
}

mkdir -p "$(dirname "$DEST")"
cp -f "$SRC" "$DEST"
echo "Synced Group Composer generated UI: $DEST"
