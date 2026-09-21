#!/usr/bin/env bash
# Generate the central ERA-07 item provenance policy from the live AzerothCore world item set.
# This is independent of whether AHBot is enabled: every automated item consumer reads the same
# Vanilla/TBC/WotLK chronology through EraPolicy.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
AC_DIR="$ROOT/azerothcore-wotlk"
ENV_LIVE="$AC_DIR/.env"
RAID_CONF="$AC_DIR/env/dist/etc/modules/mod_raid_roster.conf"
PROVENANCE_TOOL="$ROOT/tools/generate-era-item-provenance.py"
PROVENANCE_SOURCES="$ROOT/data/era-item-provenance/sources.json"
PROVENANCE_OVERRIDES="$ROOT/data/era-item-provenance/overrides.csv"
PROVENANCE_CACHE="$ROOT/.cache/era-item-provenance"
PROVENANCE_OUT="$PROVENANCE_CACHE/generated"

[[ -f "$ENV_LIVE" ]] || { echo "Missing $ENV_LIVE; run setup.sh/update.sh first." >&2; exit 1; }
set -a
# shellcheck disable=SC1090
source "$ENV_LIVE"
set +a

if [[ -x "$ROOT/sync-module-configs.sh" ]]; then
  "$ROOT/sync-module-configs.sh" >/dev/null
fi

[[ -f "$RAID_CONF" ]] || { echo "Missing $RAID_CONF; mod-raid-roster config was not staged." >&2; exit 1; }
[[ -f "$PROVENANCE_TOOL" ]] || { echo "Missing $PROVENANCE_TOOL." >&2; exit 1; }
[[ -f "$PROVENANCE_SOURCES" ]] || { echo "Missing $PROVENANCE_SOURCES." >&2; exit 1; }
[[ -f "$PROVENANCE_OVERRIDES" ]] || { echo "Missing $PROVENANCE_OVERRIDES." >&2; exit 1; }
command -v python3 >/dev/null 2>&1 || { echo "python3 is required for ERA-07 item provenance." >&2; exit 1; }

mysql_q() {
  (cd "$AC_DIR" && docker compose exec -T ac-database     mysql -uroot -p"${DOCKER_DB_ROOT_PASSWORD}" -Nse "$1") 2>/dev/null
}

for attempt in {1..30}; do
  if mysql_q "SELECT 1;" >/dev/null 2>&1; then
    break
  fi
  if [[ "$attempt" -eq 30 ]]; then
    echo "Database did not become ready for ERA-07 provenance generation." >&2
    exit 1
  fi
  sleep 2
done

set_conf() {
  local key="$1" value="$2" file="$3"
  if grep -Eq "^[[:space:]]*${key//./\.}[[:space:]]*=" "$file"; then
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
  else
    printf '\n%s = %s\n' "$key" "$value" >> "$file"
  fi
}

mkdir -p "$PROVENANCE_CACHE" "$PROVENANCE_OUT"
world_item_ids="$(mktemp)"
cleanup_world_item_ids() { rm -f "$world_item_ids"; }
trap cleanup_world_item_ids EXIT
mysql_q "SELECT entry FROM acore_world.item_template ORDER BY entry;" > "$world_item_ids"
[[ -s "$world_item_ids" ]] || { echo "Could not read acore_world.item_template for provenance generation." >&2; exit 1; }

python3 "$PROVENANCE_TOOL"   --sources "$PROVENANCE_SOURCES"   --overrides "$PROVENANCE_OVERRIDES"   --world-item-ids "$world_item_ids"   --cache-dir "$PROVENANCE_CACHE/sources"   --out-dir "$PROVENANCE_OUT"

cleanup_world_item_ids
trap - EXIT

disabled_vanilla="$(tr -d '\r\n' < "$PROVENANCE_OUT/ah-disabled-vanilla.txt")"
disabled_tbc="$(tr -d '\r\n' < "$PROVENANCE_OUT/ah-disabled-tbc.txt")"
disabled_wotlk="$(tr -d '\r\n' < "$PROVENANCE_OUT/ah-disabled-wotlk.txt")"

read -r source_set world_count world_fingerprint unknown_count vanilla_count tbc_count wotlk_count < <(
  python3 - "$PROVENANCE_OUT/metadata.json" <<'PY'
import json
import sys
meta = json.load(open(sys.argv[1], encoding="utf-8"))
print(
    meta["source_set"],
    meta["world_item_count"],
    meta["world_item_fingerprint"],
    meta["classified_counts"]["unknown"],
    meta["disabled_counts"]["vanilla"],
    meta["disabled_counts"]["tbc"],
    meta["disabled_counts"]["wotlk"],
)
PY
)

set_conf "EraPolicy.ItemProvenance.Enable" "1" "$RAID_CONF"
set_conf "EraPolicy.ItemProvenance.SourceSet" "$source_set" "$RAID_CONF"
set_conf "EraPolicy.ItemProvenance.WorldItemCount" "$world_count" "$RAID_CONF"
set_conf "EraPolicy.ItemProvenance.WorldItemFingerprint" "$world_fingerprint" "$RAID_CONF"
set_conf "EraPolicy.ItemProvenance.UnknownCount" "$unknown_count" "$RAID_CONF"
set_conf "EraPolicy.ItemProvenance.DisabledVanillaCount" "$vanilla_count" "$RAID_CONF"
set_conf "EraPolicy.ItemProvenance.DisabledTbcCount" "$tbc_count" "$RAID_CONF"
set_conf "EraPolicy.ItemProvenance.DisabledWotlkCount" "$wotlk_count" "$RAID_CONF"
set_conf "EraPolicy.ItemProvenance.DisabledVanillaItemIDs" "$disabled_vanilla" "$RAID_CONF"
set_conf "EraPolicy.ItemProvenance.DisabledTbcItemIDs" "$disabled_tbc" "$RAID_CONF"
set_conf "EraPolicy.ItemProvenance.DisabledWotlkItemIDs" "$disabled_wotlk" "$RAID_CONF"

echo "ERA-07 ITEM PROVENANCE READY"
echo "  Source set: $source_set"
echo "  Live world items: $world_count (fingerprint $world_fingerprint)"
echo "  Blocked in Vanilla: $vanilla_count"
echo "  Blocked in TBC: $tbc_count"
echo "  Blocked in WotLK/UNKNOWN: $wotlk_count"
echo "  Unknown chronology: $unknown_count (fail-closed)"
