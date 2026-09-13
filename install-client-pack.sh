#!/usr/bin/env bash
# Build the complete 3.3.5a client pack and install it ONLY into the verified TheraWoW client.
# There is deliberately no auto-discovery fallback: retail WoW must never be touched by this script.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FIXED_WSL_WOW="/mnt/d/wow private server/TheraWoW wotlk"
FIXED_WIN_WOW='D:\wow private server\TheraWoW wotlk'
FIXED_ADDONS="$FIXED_WSL_WOW/Interface/AddOns"

if [[ $# -gt 0 && "$1" != "$FIXED_WIN_WOW" ]]; then
  echo "ERROR: This installer is hard-locked to the private-server client:" >&2
  echo "       $FIXED_WIN_WOW" >&2
  echo "Refusing requested path: $1" >&2
  exit 1
fi

if [[ ! -f "$FIXED_WSL_WOW/Wow.exe" ]]; then
  echo "ERROR: Private WoW client not found at:" >&2
  echo "       $FIXED_WSL_WOW" >&2
  echo "No other WoW installation will be searched or modified." >&2
  exit 1
fi

mkdir -p "$FIXED_ADDONS"

echo "============================================================"
echo " AZEROTH CLIENT INSTALLER - HARD LOCKED TARGET"
echo "============================================================"
echo " WoW root : $FIXED_WIN_WOW"
echo " AddOns   : D:\wow private server\TheraWoW wotlk\Interface\AddOns"
echo " Retail WoW auto-discovery: DISABLED"
echo "============================================================"

echo "==> Building complete client pack"
bash "$ROOT/build-client-pack.sh"

command -v powershell.exe >/dev/null 2>&1 || {
  echo "ERROR: powershell.exe is not available from this WSL environment." >&2
  exit 1
}
command -v wslpath >/dev/null 2>&1 || {
  echo "ERROR: wslpath is required to hand the generated zip to Windows." >&2
  exit 1
}

ZIP_WIN="$(wslpath -w "$ROOT/client-addons.zip")"
PS_WIN="$(wslpath -w "$ROOT/windows/Install-Client-Pack.ps1")"

echo "==> Installing pack into the fixed TheraWoW client"
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "$PS_WIN" -PackZip "$ZIP_WIN" -WowPath "$FIXED_WIN_WOW"
