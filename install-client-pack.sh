#!/usr/bin/env bash
# Build the complete 3.3.5a client pack and install it directly into the Windows WoW client.
# Designed for this project's WSL2/Windows setup so addon installation is no longer a manual zip step.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WOW_PATH="${1:-}"

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

echo "==> Installing pack into the Windows WoW client"
if [[ -n "$WOW_PATH" ]]; then
  powershell.exe -NoProfile -ExecutionPolicy Bypass -File "$PS_WIN" -PackZip "$ZIP_WIN" -WowPath "$WOW_PATH"
else
  powershell.exe -NoProfile -ExecutionPolicy Bypass -File "$PS_WIN" -PackZip "$ZIP_WIN"
fi
