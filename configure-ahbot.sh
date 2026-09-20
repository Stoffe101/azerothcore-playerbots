#!/usr/bin/env bash
# Configure mod-ah-bot-plus around a dedicated normal character with an era-specific market.
# Usage: bash configure-ahbot.sh Auctioneer [vanilla|tbc|wotlk]
# Existing installs without AHBOT_ERA_PROFILE default to wotlk for backward compatibility.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
AC_DIR="$ROOT/azerothcore-wotlk"
ENV_ROOT="$ROOT/.env"
ENV_LIVE="$AC_DIR/.env"
AH_CONF="$AC_DIR/env/dist/etc/modules/mod_ahbot.conf"

name="${1:-}"
if [[ ! "$name" =~ ^[A-Za-z][A-Za-z]{1,11}$ ]]; then
  echo "Usage: bash configure-ahbot.sh <character-name> [vanilla|tbc|wotlk]" >&2
  echo "Use a normal throwaway character (not an rndbot), e.g. Auctioneer." >&2
  exit 2
fi

[[ -f "$ENV_LIVE" ]] || { echo "Missing $ENV_LIVE; run setup.sh/update.sh first." >&2; exit 1; }
set -a
# shellcheck disable=SC1090
source "$ENV_LIVE"
set +a

profile="${2:-${AHBOT_ERA_PROFILE:-wotlk}}"
profile="$(printf '%s' "$profile" | tr '[:upper:]' '[:lower:]')"
case "$profile" in
  vanilla) era_cap=60 ;;
  tbc)     era_cap=70 ;;
  wotlk)   era_cap=80 ;;
  *)
    echo "Unknown AH era profile '$profile'. Use vanilla, tbc, or wotlk." >&2
    exit 2
    ;;
esac

if [[ -x "$ROOT/sync-module-configs.sh" ]]; then
  "$ROOT/sync-module-configs.sh" >/dev/null
fi
[[ -f "$AH_CONF" ]] || { echo "Missing $AH_CONF; mod-ah-bot-plus config was not staged." >&2; exit 1; }

mysql_q() {
  (cd "$AC_DIR" && docker compose exec -T ac-database \
    mysql -uroot -p"${DOCKER_DB_ROOT_PASSWORD}" -Nse "$1") 2>/dev/null
}

row="$(mysql_q "SELECT guid,account FROM acore_characters.characters WHERE LOWER(name)=LOWER('${name}') LIMIT 1;")"
[[ -n "$row" ]] || { echo "Character '$name' was not found. Create it in the WoW client, log in once, log out, then rerun this script." >&2; exit 1; }
read -r guid account_id <<<"$row"
username="$(mysql_q "SELECT username FROM acore_auth.account WHERE id=${account_id} LIMIT 1;")"
[[ -n "$username" ]] || { echo "Could not resolve account for '$name'." >&2; exit 1; }

prefix="rndbot"
PB_CONF="$AC_DIR/env/dist/etc/modules/mod_playerbots.conf"
if [[ -f "$PB_CONF" ]]; then
  parsed="$(awk -F= '/^[[:space:]]*AiPlayerbot.RandomBotAccountPrefix[[:space:]]*=/{v=$2; gsub(/[[:space:]\r\"]/,"",v); print v; exit}' "$PB_CONF")"
  [[ -n "$parsed" ]] && prefix="$parsed"
fi
shopt -s nocasematch
if [[ "$username" == "$prefix"* ]]; then
  echo "Refusing '$name': account '$username' is a playerbot account. Use a normal character." >&2
  exit 1
fi
shopt -u nocasematch

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

persist_env() {
  local key="$1" value="$2" file
  for file in "$ENV_ROOT" "$ENV_LIVE"; do
    [[ -f "$file" ]] || continue
    if grep -q "^${key}=" "$file"; then
      sed -i "s|^${key}=.*|${key}=${value}|" "$file"
    else
      printf '\n%s=%s\n' "$key" "$value" >> "$file"
    fi
  done
}

persist_env AHBOT_GUIDS "$guid"
persist_env AHBOT_ERA_PROFILE "$profile"

set_conf "AuctionHouseBot.GUIDs" "$guid" "$AH_CONF"
set_conf "AuctionHouseBot.EraProfile" "$profile" "$AH_CONF"
set_conf "AuctionHouseBot.EraLevelCap" "$era_cap" "$AH_CONF"
set_conf "AuctionHouseBot.EnableSeller" "true" "$AH_CONF"
set_conf "AuctionHouseBot.Buyer.Enabled" "true" "$AH_CONF"
set_conf "AuctionHouseBot.Buyer.AcceptablePriceModifier" "1" "$AH_CONF"
set_conf "AuctionHouseBot.ItemsPerCycle" "500" "$AH_CONF"

# Coarse era containment for new seller listings. ERA-07 still owns true item provenance.
set_conf "AuctionHouseBot.EquipItemUseOrEquipLevelRestrict.Enabled" "true" "$AH_CONF"
set_conf "AuctionHouseBot.EquipItemUseOrEquipLevelRestrict.MinLevel" "0" "$AH_CONF"
set_conf "AuctionHouseBot.EquipItemUseOrEquipLevelRestrict.MaxLevel" "$era_cap" "$AH_CONF"

# Keep all three markets deep. 25k is enough variety for a solo/friends realm without turning
# every search into the same handful of armor auctions.
for faction in Alliance Horde Neutral; do
  set_conf "AuctionHouseBot.${faction}.MinItems" "25000" "$AH_CONF"
  set_conf "AuctionHouseBot.${faction}.MaxItems" "25000" "$AH_CONF"
done

# Bias the random listing mix toward things players repeatedly consume/craft.
set_conf "AuctionHouseBot.ListProportion.CategoryConsumable.QualityNormal" "160" "$AH_CONF"
set_conf "AuctionHouseBot.ListProportion.CategoryConsumable.QualityUncommon" "35" "$AH_CONF"
set_conf "AuctionHouseBot.ListProportion.CategoryConsumable.QualityRare" "12" "$AH_CONF"
set_conf "AuctionHouseBot.ListProportion.CategoryTradeGood.QualityNormal" "160" "$AH_CONF"
set_conf "AuctionHouseBot.ListProportion.CategoryTradeGood.QualityUncommon" "40" "$AH_CONF"
set_conf "AuctionHouseBot.ListProportion.CategoryTradeGood.QualityRare" "20" "$AH_CONF"
set_conf "AuctionHouseBot.ListProportion.CategoryReagent.QualityNormal" "30" "$AH_CONF"
# Reset expansion-only categories completely before applying the selected profile. Zero is a real
# seller proportion in mod-ah-bot-plus, so this removes the category from new-listing selection.
for quality in Poor Normal Uncommon Rare Epic Legendary Artifact Heirloom; do
  set_conf "AuctionHouseBot.ListProportion.CategoryGem.Quality${quality}" "0" "$AH_CONF"
  set_conf "AuctionHouseBot.ListProportion.CategoryGlyph.Quality${quality}" "0" "$AH_CONF"
done

case "$profile" in
  vanilla)
    ;;
  tbc)
    set_conf "AuctionHouseBot.ListProportion.CategoryGem.QualityUncommon" "100" "$AH_CONF"
    set_conf "AuctionHouseBot.ListProportion.CategoryGem.QualityRare" "70" "$AH_CONF"
    set_conf "AuctionHouseBot.ListProportion.CategoryGem.QualityEpic" "45" "$AH_CONF"
    ;;
  wotlk)
    set_conf "AuctionHouseBot.ListProportion.CategoryGem.QualityUncommon" "100" "$AH_CONF"
    set_conf "AuctionHouseBot.ListProportion.CategoryGem.QualityRare" "70" "$AH_CONF"
    set_conf "AuctionHouseBot.ListProportion.CategoryGem.QualityEpic" "45" "$AH_CONF"
    set_conf "AuctionHouseBot.ListProportion.CategoryGlyph.QualityNormal" "80" "$AH_CONF"
    ;;
esac

# Remove the WotLK-only boosts owned by this script before conditionally adding them back.
# This makes profile application idempotent, including backwards simulation on the dirty dev realm.
mult_key="AuctionHouseBot.ListProportion.ListMultipliedItemIDs"
current="$(awk -F= -v k="$mult_key" '{lhs=$1; gsub(/^[ \t]+|[ \t]+$/,"",lhs); if(lhs==k){sub(/^[^=]*=/,""); gsub(/^[ \t]+|[ \t]+$/,"",$0); print; exit}}' "$AH_CONF")"
wotlk_ids="33447 33448 40093 40211 40212 46376 46377 46378 46379 43015"
current="$(awk -v raw="$current" -v banned="$wotlk_ids" '
  BEGIN {
    split(banned,b," "); for (i in b) blocked[b[i]]=1
    n=split(raw,p,","); out=""
    for (i=1;i<=n;i++) {
      split(p[i],kv,":")
      if (p[i] != "" && !blocked[kv[1]]) out = out (out ? "," : "") p[i]
    }
    print out
  }')"

if [[ "$profile" == "wotlk" ]]; then
  for pair in \
    33447:12 33448:12 \
    40093:20 40211:20 40212:20 \
    46376:25 46377:25 46378:18 46379:25 \
    43015:25; do
    current="${current:+$current,}$pair"
  done
fi
set_conf "$mult_key" "$current" "$AH_CONF"

# Config is read at startup. Restart only worldserver; no rebuild/database import is needed.
echo "Configured AH bot character '$name' (guid=$guid, account=$username)."
echo "Restarting worldserver so the new market settings load..."
(cd "$AC_DIR" && docker compose restart ac-worldserver)

echo
echo "AH BOT READY"
echo "  Seller/buyer: enabled"
echo "  Stock target: 25,000 per auction house"
echo "  Refill: 500 listings/cycle"
echo "  Era profile: $profile (equip/use ceiling $era_cap)"
case "$profile" in
  vanilla) echo "  Expansion categories: gems OFF, glyphs OFF" ;;
  tbc)     echo "  Expansion categories: gems ON, glyphs OFF" ;;
  wotlk)   echo "  Expansion categories: gems ON, glyphs ON; Wrath raid staples boosted" ;;
esac
echo
echo "IMPORTANT: this only constrains NEW seller listings by category/use level."
echo "ERA-07 item provenance is still required for future-era items with low/no use level."
echo "Changing profiles does not delete existing auctions."
echo
echo "After you log back in as your PLAYING character, run '.ahbot update' a few times to seed immediately."
