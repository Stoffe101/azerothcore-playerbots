#!/usr/bin/env bash
# Build the complete 3.3.5a client pack and install it into one explicitly selected private client.
# There is deliberately no auto-discovery fallback: retail/other WoW installs are never searched.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEFAULT_WIN_WOW='D:\wow private server\TheraWoW wotlk'
WOW_WIN=""
ALLOW_UNKNOWN=0

usage() {
  cat <<EOF
Usage: $0 [WINDOWS_WOW_PATH] [--allow-unknown-version]

Examples:
  $0
  $0 'E:\Games\WoW 3.3.5a'
  $0 'E:\Games\WoW 3.3.5a' --allow-unknown-version

The last flag is only for a private 3.3.5a client whose Wow.exe has stripped version metadata.
No WoW installation is auto-discovered.
EOF
}

for arg in "$@"; do
  case "$arg" in
    --allow-unknown-version)
      ALLOW_UNKNOWN=1
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    --*)
      echo "ERROR: Unknown option: $arg" >&2
      usage >&2
      exit 2
      ;;
    *)
      if [[ -n "$WOW_WIN" ]]; then
        echo "ERROR: More than one WoW path was supplied." >&2
        usage >&2
        exit 2
      fi
      WOW_WIN="$arg"
      ;;
  esac
done
WOW_WIN="${WOW_WIN:-$DEFAULT_WIN_WOW}"

command -v powershell.exe >/dev/null 2>&1 || {
  echo "ERROR: powershell.exe is not available from this WSL environment." >&2
  exit 1
}
command -v wslpath >/dev/null 2>&1 || {
  echo "ERROR: wslpath is required to translate the selected Windows WoW path." >&2
  exit 1
}

# Convert exactly the path the operator selected. Do not probe drives, registry keys, Battle.net,
# or standard retail locations. The PowerShell installer performs the authoritative 3.3.5a/build
# 12340 validation before writing anything.
if ! WOW_WSL="$(wslpath -u "$WOW_WIN" 2>/dev/null)" || [[ -z "$WOW_WSL" ]]; then
  echo "ERROR: Could not translate Windows WoW path: $WOW_WIN" >&2
  exit 1
fi

if [[ ! -f "$WOW_WSL/Wow.exe" || ! -d "$WOW_WSL/Data" ]]; then
  echo "ERROR: Selected private WoW client is missing Wow.exe or Data/:" >&2
  echo "       $WOW_WIN" >&2
  echo "No other WoW installation will be searched or modified." >&2
  exit 1
fi

echo "============================================================"
echo " AZEROTH 3.3.5a CLIENT INSTALLER"
echo "============================================================"
echo " WoW root : $WOW_WIN"
echo " Auto-discovery: DISABLED"
echo "============================================================"

echo "==> Building complete client pack"
bash "$ROOT/build-client-pack.sh"

ZIP_WIN="$(wslpath -w "$ROOT/client-addons.zip")"
PS_WIN="$(wslpath -w "$ROOT/windows/Install-Client-Pack.ps1")"

echo "==> Installing pack into the selected private 3.3.5a client"
if [[ "$ALLOW_UNKNOWN" == "1" ]]; then
  powershell.exe -NoProfile -ExecutionPolicy Bypass -File "$PS_WIN" \
    -PackZip "$ZIP_WIN" -WowPath "$WOW_WIN" -AllowUnknownClientVersion
else
  powershell.exe -NoProfile -ExecutionPolicy Bypass -File "$PS_WIN" \
    -PackZip "$ZIP_WIN" -WowPath "$WOW_WIN"
fi
