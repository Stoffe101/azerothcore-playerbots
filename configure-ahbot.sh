#!/usr/bin/env bash
# Configure mod-ah-bot-plus around a dedicated normal character and bias the market toward
# useful WotLK consumables/crafting goods. Usage: bash configure-ahbot.sh Auctioneer
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
AC_DIR="$ROOT/azerothcore-wotlk"
ENV_ROOT="$ROOT/.env"
ENV_LIVE="$AC_DIR/.env"
AH_CONF="$AC_DIR/env/dist/etc/modules/mod_ahbot.conf"

name="${1:-}"
if [[ ! "$name" =~ ^[A-Za-z][A-Za-z]{1,11}$ ]]; then
  echo "Usage: bash configure-ahbot.sh <character-name>" >&2
  echo "Use a normal throwaway character (not an rndbot), e.g. Auctioneer." >&2
  exit 2
fi

[[ -f "$ENV_LIVE" ]] || { echo "Missing $ENV_LIVE; run setup.sh/update.sh first." >&2; exit 1; }
set -a
# shellcheck disable=SC1090
source "$ENV_LIVE"
set +a

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

set_conf "AuctionHouseBot.GUIDs" "$guid" "$AH_CONF"
set_conf "AuctionHouseBot.EnableSeller" "true" "$AH_CONF"
set_conf "AuctionHouseBot.Buyer.Enabled" "true" "$AH_CONF"
set_conf "AuctionHouseBot.Buyer.AcceptablePriceModifier" "1" "$AH_CONF"
set_conf "AuctionHouseBot.ItemsPerCycle" "500" "$AH_CONF"

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
set_conf "AuctionHouseBot.ListProportion.CategoryGem.QualityUncommon" "100" "$AH_CONF"
set_conf "AuctionHouseBot.ListProportion.CategoryGem.QualityRare" "70" "$AH_CONF"
set_conf "AuctionHouseBot.ListProportion.CategoryGem.QualityEpic" "45" "$AH_CONF"
set_conf "AuctionHouseBot.ListProportion.CategoryTradeGood.QualityNormal" "160" "$AH_CONF"
set_conf "AuctionHouseBot.ListProportion.CategoryTradeGood.QualityUncommon" "40" "$AH_CONF"
set_conf "AuctionHouseBot.ListProportion.CategoryTradeGood.QualityRare" "20" "$AH_CONF"
set_conf "AuctionHouseBot.ListProportion.CategoryReagent.QualityNormal" "30" "$AH_CONF"
set_conf "AuctionHouseBot.ListProportion.CategoryGlyph.QualityNormal" "80" "$AH_CONF"

# The upstream default already multiplies cloth/ore/herbs/raw gems and healing/mana potions.
# Append the WotLK raid staples it does NOT emphasize by default: tank/caster/melee flasks,
# combat potions and Fish Feast. Multipliers affect selection frequency, not item stats/prices.
mult_key="AuctionHouseBot.ListProportion.ListMultipliedItemIDs"
current="$(awk -F= -v k="$mult_key" '{lhs=$1; gsub(/^[ \t]+|[ \t]+$/,"",lhs); if(lhs==k){sub(/^[^=]*=/,""); gsub(/^[ \t]+|[ \t]+$/,"",$0); print; exit}}' "$AH_CONF")"
for pair in \
  33447:12 33448:12 \
  40093:20 40211:20 40212:20 \
  46376:25 46377:25 46378:18 46379:25 \
  43015:25; do
  id="${pair%%:*}"
  if [[ ! ",$current," =~ ,${id}:[0-9]+, ]]; then
    current="${current:+$current,}$pair"
  fi
done
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
echo "  Priority: WotLK gems, flasks, combat/health/mana potions, Fish Feast, glyphs and trade goods"
echo
echo "After you log back in as your PLAYING character, run '.ahbot update' a few times to seed immediately."
