#!/usr/bin/env bash
# Build/stage the current client addon pack and install GroupComposer into a WotLK client from WSL.
# Usage:
#   ./install-group-composer-wsl.sh
#   ./install-group-composer-wsl.sh "/mnt/d/path/to/WoW/Interface/AddOns"
#
# The default below matches this project's local test client. Override it with the first argument or
# WOW_ADDONS_DIR if the client moves.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEFAULT_ADDONS='/mnt/d/wow private server/TheraWoW wotlk/Interface/AddOns'
ADDONS_DIR="${1:-${WOW_ADDONS_DIR:-$DEFAULT_ADDONS}}"

[[ -d "$ADDONS_DIR" ]] || {
  echo "ERROR: WoW AddOns directory does not exist: $ADDONS_DIR" >&2
  echo "Pass the correct WSL path as the first argument or set WOW_ADDONS_DIR." >&2
  exit 1
}

echo "==> Staging current client addon pack"
"$ROOT/fetch-client-addons.sh"

SRC="$ROOT/client-addons/GroupComposer"
DST="$ADDONS_DIR/GroupComposer"

[[ -f "$SRC/GroupComposer.toc" ]] || {
  echo "ERROR: staged GroupComposer addon is missing." >&2
  exit 1
}
[[ -f "$SRC/GroupComposerModernUI.lua" ]] || {
  echo "ERROR: staged GroupComposer is missing the modern generated UI bundle." >&2
  exit 1
}
grep -q '^## X-UI-Shell: ModernTypedV1$' "$SRC/GroupComposer.toc" || {
  echo "ERROR: staged GroupComposer is not the modern UI shell." >&2
  exit 1
}
grep -Fxq 'GroupComposerModernUI.lua' "$SRC/GroupComposer.toc" || {
  echo "ERROR: staged GroupComposer TOC does not load the modern generated UI." >&2
  exit 1
}

echo "==> Replacing installed GroupComposer"
rm -rf "$DST"
cp -a "$SRC" "$DST"

echo
echo "Installed Group Composer:"
grep -E '^## (Version|X-UI-Shell):' "$DST/GroupComposer.toc"
grep -Fxq 'GroupComposerModernUI.lua' "$DST/GroupComposer.toc"
echo "Modern UI bundle: $DST/GroupComposerModernUI.lua"
echo
echo "Done. Fully restart WoW before testing the new UI."
