#!/usr/bin/env bash
# Build the complete WoW 3.3.5a client pack used by this project.
#
# This wrapper stages the pinned UI/combat addons (ElvUI, ThreatPlates, RestedXP,
# WeakAuras and DBM), then delegates to fetch-client-addons.sh which adds the
# server-specific addons, maps/data patches and produces client-addons.zip.
set -euo pipefail
shopt -s nullglob

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEST="$ROOT/client-addons"
EXPECTED_INTERFACE=30300
mkdir -p "$DEST"

command -v curl  >/dev/null || { echo "ERROR: 'curl' is required (e.g. sudo apt install curl)"; exit 1; }
command -v unzip >/dev/null || { echo "ERROR: 'unzip' is required (e.g. sudo apt install unzip)"; exit 1; }

fail() {
  echo "ERROR: $*" >&2
  exit 1
}

archive_root() {
  local extract="$1"
  local roots=()
  local candidate
  for candidate in "$extract"/*; do
    [[ -d "$candidate" ]] && roots+=("$candidate")
  done
  [[ ${#roots[@]} -eq 1 ]] || fail "Expected exactly one repository root in $extract, found ${#roots[@]}."
  printf '%s\n' "${roots[0]}"
}

validate_addon_root() {
  local dir="$1"
  local name="$2"
  local tocs=("$dir"/*.toc)
  [[ ${#tocs[@]} -gt 0 ]] || fail "$name has no top-level .toc file at '$dir'."

  local toc line interface_ok=0
  for toc in "${tocs[@]}"; do
    while IFS= read -r line || [[ -n "$line" ]]; do
      line="${line//$'\r'/}"
      if [[ "$line" =~ ^[[:space:]]*##[[:space:]]*Interface:[[:space:]]*${EXPECTED_INTERFACE}([[:space:]]|$) ]]; then
        interface_ok=1
        break 2
      fi
    done < "$toc"
  done

  [[ $interface_ok -eq 1 ]] || fail "$name does not declare WoW interface $EXPECTED_INTERFACE in a top-level .toc file."
}

fetch_archive() {
  local repo="$1"
  local sha="$2"
  local work="$3"
  local zip="$work/repo.zip"
  local extract="$work/extract"

  mkdir -p "$extract"
  curl -fsSL "$repo/archive/$sha.zip" -o "$zip"
  unzip -q "$zip" -d "$extract"
  archive_root "$extract"
}

stage_pinned_folders() {
  local stage_name="$1"
  local repo="$2"
  local sha="$3"
  shift 3

  [[ "$sha" =~ ^[0-9a-fA-F]{40}$ ]] || fail "$stage_name is not pinned to a full Git commit SHA."

  local tmp root folder source stage="$DEST/$stage_name"
  tmp="$(mktemp -d)"
  echo "==> Staging pinned $stage_name"
  echo "    $repo @ $sha"
  root="$(fetch_archive "$repo" "$sha" "$tmp")"

  rm -rf "$stage"
  mkdir -p "$stage"
  for folder in "$@"; do
    source="$root/$folder"
    [[ -d "$source" ]] || { rm -rf "$tmp"; fail "$stage_name expected addon folder '$folder' at commit $sha."; }
    validate_addon_root "$source" "$folder"
    cp -a "$source" "$stage/$folder"
    echo "    + $folder"
  done
  rm -rf "$tmp"
}

stage_pinned_root_addon() {
  local addon_name="$1"
  local repo="$2"
  local sha="$3"

  [[ "$sha" =~ ^[0-9a-fA-F]{40}$ ]] || fail "$addon_name is not pinned to a full Git commit SHA."

  local tmp root stage="$DEST/$addon_name"
  tmp="$(mktemp -d)"
  echo "==> Staging pinned $addon_name"
  echo "    $repo @ $sha"
  root="$(fetch_archive "$repo" "$sha" "$tmp")"

  validate_addon_root "$root" "$addon_name"
  rm -rf "$stage"
  mkdir -p "$stage"
  cp -a "$root"/. "$stage"/
  validate_addon_root "$stage" "$addon_name"
  rm -rf "$tmp"
}

# UI foundation. These are the exact pins from the earlier client-ui-pack work,
# now folded into the same bundle as our custom server addons instead of living on
# a disconnected draft branch.
stage_pinned_folders \
  "ElvUI-Pack" \
  "https://github.com/ElvUI-WotLK/ElvUI" \
  "58ea24f7979740221389ce09685eb445723a6346" \
  ElvUI ElvUI_OptionsUI

stage_pinned_folders \
  "TidyPlates-Pack" \
  "https://github.com/hypopheria2k/TidyPlates_3.3.5a" \
  "02956c68068b2c01bfdc3972345eb59a357447d7" \
  TidyPlates TidyPlates_ThreatPlates

stage_pinned_root_addon \
  "RXPGuides" \
  "https://github.com/PottedSalame/RestedXP_RXPGuides-WotLK_3.3.5a" \
  "fb3e0b1e77c589ea58e28fa53d8c17ed0661cef9"

stage_pinned_folders \
  "WeakAuras-Pack" \
  "https://github.com/NoM0Re/WeakAuras-WotLK" \
  "39c2aca9043082c0e3219220f17b98eb69a8e43e" \
  WeakAuras WeakAurasArchive WeakAurasModelPaths WeakAurasOptions WeakAurasStopMotion WeakAurasTemplates

stage_pinned_folders \
  "DBM-Pack" \
  "https://github.com/locus313/WoW-3.3.5a-Addons" \
  "a47dd619de2a87ab26adc31bd23c407a0d06e28b" \
  DBM-Core DBM-GUI DBM-Karazhan DBM-ZulAman DBM-BurningCrusade DBM-BlackTemple \
  DBM-Hyjal DBM-Serpentshrine DBM-TheEye DBM-Sunwell DBM-Outlands DBM-Party-BC \
  DBM-Naxx DBM-Onyxia DBM-VoA DBM-EyeOfEternity DBM-Ulduar DBM-Coliseum \
  DBM-ChamberOfAspects DBM-Icecrown DBM-Party-WotLK

echo
echo "==> Adding project/server addons and client data patches"
bash "$ROOT/fetch-client-addons.sh"

echo
cat <<EOF
==================================================================
 COMPLETE CLIENT PACK READY

 File:
   $ROOT/client-addons.zip

 The zip now contains BOTH the server-specific client pieces and the UI stack:
   - ElvUI + ElvUI Options
   - TidyPlates + ThreatPlates
   - RestedXP Guides
   - WeakAuras
   - DBM (Vanilla/TBC/WotLK modules included by the pinned addon pack)
   - MultiBot + PlayerBotManager
   - Questie, Atlas, AtlasLoot, Grid2, World Dungeon Maps
   - EraTalents + this fork's local addons
   - required WDM / Individual Progression / EraTalents client data patches

 Install by extracting client-addons.zip DIRECTLY into the root of the WoW 3.3.5a
 client. It is pre-structured with Interface/AddOns/ and Data/ paths.

 At character select, open AddOns and enable the installed addons. If the client
 labels a known 3.3.5a addon as out-of-date, enable "Load out of date AddOns".

 No SavedVariables/UI-layout profile is forced yet. That is deliberate: the
 addons are installed reproducibly first, and the 3440x1440 layout can then be
 visually tuned without risking a broken guessed ElvUI profile.
==================================================================
EOF
