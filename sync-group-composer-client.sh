#!/usr/bin/env bash
# Development sync for the Group Composer client addon.
#
# The server and the WoW client live on the same Windows/WSL development PC. Server updates alone
# cannot update Interface/AddOns, so keep the explicitly selected private 3.3.5a client in lockstep
# with client-addons-src/GroupComposer. This script never auto-discovers other WoW installations.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC="$ROOT/client-addons-src/GroupComposer"
DEFAULT_WIN_WOW='D:\wow private server\TheraWoW wotlk'
WOW_WIN="${GROUP_COMPOSER_WOW_PATH:-${WOW_CLIENT_PATH:-$DEFAULT_WIN_WOW}}"
OPTIONAL=0

if [[ "${1:-}" == "--if-present" ]]; then
  OPTIONAL=1
elif [[ -n "${1:-}" ]]; then
  WOW_WIN="$1"
fi

skip_or_fail() {
  if [[ "$OPTIONAL" == "1" ]]; then
    echo "==> Group Composer client sync skipped: $*"
    exit 0
  fi
  echo "ERROR: $*" >&2
  exit 1
}

[[ -f "$SRC/GroupComposer.toc" && -f "$SRC/GroupComposerModernUI.lua" ]] \
  || skip_or_fail "generated Group Composer addon is missing from $SRC"

grep -Fxq 'GroupComposerModernUI.lua' "$SRC/GroupComposer.toc" \
  || skip_or_fail "GroupComposer.toc is not loading GroupComposerModernUI.lua"

command -v wslpath >/dev/null 2>&1 \
  || skip_or_fail "wslpath is unavailable; this host is not the Windows/WSL development PC"

if ! WOW_WSL="$(wslpath -u "$WOW_WIN" 2>/dev/null)" || [[ -z "$WOW_WSL" ]]; then
  skip_or_fail "could not translate configured WoW path: $WOW_WIN"
fi

[[ -f "$WOW_WSL/Wow.exe" && -d "$WOW_WSL/Data" ]] \
  || skip_or_fail "private WoW 3.3.5a client is not present at: $WOW_WIN"

ADDONS="$WOW_WSL/Interface/AddOns"
DEST="$ADDONS/GroupComposer"
TMP="$ADDONS/.GroupComposer.incoming.$$"
OLD="$ADDONS/.GroupComposer.previous"

mkdir -p "$ADDONS"
rm -rf "$TMP" "$OLD"
cp -a "$SRC" "$TMP"
rm -rf "$TMP/tests"

SHA="$(git -C "$ROOT" rev-parse HEAD 2>/dev/null || printf 'unknown')"
VERSION="$(awk -F': ' '/^## Version:/ {print $2; exit}' "$TMP/GroupComposer.toc")"
printf '%s\n' "$SHA" > "$TMP/.group-composer-git-sha"
printf '%s\n' "$VERSION" > "$TMP/.group-composer-version"

# Replace the addon as a directory so deleted/renamed files from older UI revisions cannot linger.
# Keep one short-lived fallback until the new directory is in place.
if [[ -e "$DEST" ]]; then
  mv "$DEST" "$OLD"
fi
if ! mv "$TMP" "$DEST"; then
  [[ -e "$OLD" ]] && mv "$OLD" "$DEST"
  echo "ERROR: failed to install GroupComposer into $DEST" >&2
  exit 1
fi
rm -rf "$OLD"

# The current premium shell has these source markers. Their absence is a very useful signal that a
# stale generated bundle was accidentally packaged.
grep -Fq '"COMPOSE"' "$DEST/GroupComposerModernUI.lua" \
  || { echo "ERROR: installed bundle is missing the current COMPOSE navigation marker." >&2; exit 1; }
grep -Fq '"TOOLS"' "$DEST/GroupComposerModernUI.lua" \
  || { echo "ERROR: installed bundle is missing the current TOOLS navigation marker." >&2; exit 1; }

echo "==> Group Composer client addon synced"
echo "    Client : $WOW_WIN"
echo "    Addon  : Interface/AddOns/GroupComposer"
echo "    Version: ${VERSION:-unknown}"
echo "    Commit : $SHA"
echo "    Reload : restart WoW, or /reload if the client is already open"
