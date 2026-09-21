#!/usr/bin/env bash
# Pull the latest AzerothCore fork + modules and rebuild. Run ON THE SERVER.
# Safe to re-run. Existing config values and the database volume are preserved.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
AC_DIR="$ROOT/azerothcore-wotlk"
PINS_FILE="$ROOT/repo-pins.txt"

if [[ ! -d "$AC_DIR/.git" ]]; then
  echo "Not installed yet — run ./setup.sh first." >&2
  exit 1
fi

pin_for () {
  [[ -f "$PINS_FILE" ]] || return 0
  awk -v r="$1" '!/^[[:space:]]*#/ && NF>=2 && $1==r {print $2; exit}' "$PINS_FILE"
}

update_repo () {
  local dir="$1" label="$2"
  if [[ ! -d "$dir/.git" ]]; then
    echo "    Skipping $label (not present)."
    return
  fi
  local pin; pin="$(pin_for "$(basename "$dir")")"
  if [[ -n "$pin" ]]; then
    echo "==> Pinning $label to $pin (repo-pins.txt)"
    git -C "$dir" cat-file -e "${pin}^{commit}" 2>/dev/null \
      || git -C "$dir" fetch --depth 1 origin "$pin"
    git -C "$dir" reset --hard "$pin"
    git -C "$dir" clean -fd -- src/ 2>/dev/null || true
    return
  fi
  local branch
  branch="$(git -C "$dir" rev-parse --abbrev-ref HEAD)"
  echo "==> Updating $label ($branch)"
  git -C "$dir" fetch --depth 1 origin "$branch"
  git -C "$dir" reset --hard "origin/$branch"
  git -C "$dir" clean -fd -- src/ 2>/dev/null || true
}

ensure_git_module () {
  local name="$1" url="$2"
  local dir="$AC_DIR/modules/$name"
  if [[ -d "$dir/.git" ]]; then
    return
  fi
  if [[ -e "$dir" ]]; then
    echo "==> Replacing stale non-git module copy: $name"
    rm -rf "$dir"
  fi
  echo "==> Installing module: $name"
  git clone "$url" "$dir"
}

apply_patches () {
  local pdir="$ROOT/patches"
  [[ -d "$pdir" && -d "$AC_DIR/.git" ]] || return 0
  local patch name
  local -a apply_args
  for patch in "$pdir"/*.patch; do
    [[ -e "$patch" ]] || continue
    name="$(basename "$patch")"
    apply_args=()

    # Sunwell and AQ40 were authored around nearby upstream PlayerbotAI strategy-list changes.
    # Keep their large feature patches intact, but let the tiny 0014a/0016a compatibility patches
    # own PlayerbotAI.cpp against the exact pinned mod-playerbots revision. This keeps setup,
    # update and CI deterministic without regenerating two large patches for a pair of stale hunks.
    if [[ "$name" == "0014-playerbot-sunwell.patch" || "$name" == "0016-playerbot-aq40-twins.patch" ]]; then
      apply_args+=(--exclude=modules/mod-playerbots/src/Bot/PlayerbotAI.cpp)
    fi

    # All overlay diffs are rooted at the AzerothCore checkout. This includes patches whose
    # paths begin with modules/mod-playerbots/... or modules/mod-individual-progression/....
    # Applying those from inside the nested module repository makes the prefixed path invalid.
    if git -C "$AC_DIR" apply "${apply_args[@]}" --reverse --check "$patch" >/dev/null 2>&1; then
      echo "    Patch already applied: $name"
    elif git -C "$AC_DIR" apply "${apply_args[@]}" --check "$patch" >/dev/null 2>&1; then
      git -C "$AC_DIR" apply "${apply_args[@]}" "$patch"
      echo "    Applied patch: $name"
    else
      echo "    ERROR: $name no longer applies to the pinned integration tree (upstream moved?)." >&2
      echo "           Regenerate it against the pinned repos or remove it from patches/." >&2
      git -C "$AC_DIR" apply "${apply_args[@]}" --check --verbose "$patch" || true
      exit 1
    fi
  done
  if [[ -x "$AC_DIR/modules/mod-era-talents/apply-patches.sh" ]]; then
    "$AC_DIR/modules/mod-era-talents/apply-patches.sh" "$AC_DIR"
  fi
}

# Module .conf.dist files are compiled into Docker images, but an existing install keeps its
# persistent env/dist/etc/modules directory. Seed entirely new module configs and append only
# newly introduced keys to existing configs. Existing operator values are never overwritten.
sync_module_configs () {
  local dest_dir="$AC_DIR/env/dist/etc/modules"
  mkdir -p "$dest_dir"

  local dist base dest line key
  while IFS= read -r -d '' dist; do
    base="$(basename "$dist")"
    dest="$dest_dir/${base%.dist}"

    if [[ ! -f "$dest" ]]; then
      cp "$dist" "$dest"
      echo "==> Created module config: $(basename "$dest")"
      continue
    fi

    while IFS= read -r line || [[ -n "$line" ]]; do
      [[ "$line" =~ ^[[:space:]]*[A-Za-z0-9_.-]+[[:space:]]*= ]] || continue
      key="${line%%=*}"
      key="$(printf '%s' "$key" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')"

      if ! awk -F= -v wanted="$key" '
        {
          lhs=$1
          gsub(/^[ \t]+|[ \t]+$/, "", lhs)
          if (lhs == wanted) found=1
        }
        END { exit(found ? 0 : 1) }
      ' "$dest"; then
        printf '\n%s\n' "$line" >> "$dest"
        echo "    Added config key: $(basename "$dest") -> $key"
      fi
    done < "$dist"
  done < <(find "$AC_DIR/modules" -type f -path '*/conf/*.conf.dist' -print0)
}

# One-time migration for installs created before the Adventure Guide / Guild Director became the
# normal player-facing path. Old installs intentionally shipped RaidRoster.Enable=0, which makes
# the new Form Group / Prepare Raid buttons look broken even though the code is present. Promote
# that legacy value once, then leave the marker behind so a later deliberate operator opt-out is
# respected on every future update.
migrate_full_adventure_config () {
  local marker="$AC_DIR/env/dist/etc/.full_adventure_stack_v1"
  local conf="$AC_DIR/env/dist/etc/modules/mod_raid_roster.conf"
  [[ -f "$marker" ]] && return 0

  if [[ ! -f "$conf" ]]; then
    echo "    ERROR: full-adventure migration expected $conf but it does not exist." >&2
    exit 1
  fi

  if grep -qE '^[[:space:]]*RaidRoster\.Enable[[:space:]]*=' "$conf"; then
    sed -i -E 's|^[[:space:]]*RaidRoster\.Enable[[:space:]]*=.*|RaidRoster.Enable = 1|' "$conf"
  else
    printf '\nRaidRoster.Enable = 1\n' >> "$conf"
  fi

  : > "$marker"
  echo "==> Full adventure migration: RaidRoster enabled for Guild Director / Adventure Guide."
}

update_repo "$AC_DIR" "AzerothCore (playerbots fork)"

# New upstream gameplay extensions must also be installed on an already-existing server. setup.sh
# handles fresh installs through its MODULES list; this is the matching update-path bootstrap.
ensure_git_module "mod-dungeon-clear" "https://github.com/jrad7/mod-dungeon-clear.git"

for moddir in "$AC_DIR"/modules/*/; do
  [[ -d "$moddir/.git" ]] || continue
  update_repo "$moddir" "$(basename "$moddir")"
done
apply_patches

# Re-sync every in-repo module before rebuild. Keep this list in step with setup.sh LOCAL_MODULES.
for lm in mod-playerbot-chatter mod-raid-roster mod-admin-panel mod-ahbot-price mod-wintergrasp-bots mod-arena-roster mod-titan-rune; do
  if [[ -d "$ROOT/modules/$lm" ]]; then
    echo "==> Syncing local module: $lm"
    rm -rf "$AC_DIR/modules/$lm"
    cp -a "$ROOT/modules/$lm" "$AC_DIR/modules/$lm"
  fi
done

# Persistent module configs are outside the image build context's generated reference tree. Keep
# them compatible with newly added modules/options before restarting containers.
sync_module_configs
migrate_full_adventure_config
bash "$ROOT/configure-living-world-bots.sh"

cd "$AC_DIR"

CD_UID="$(grep -E '^DOCKER_USER_ID='  "$AC_DIR/.env" 2>/dev/null | cut -d= -f2)"; CD_UID="${CD_UID:-1000}"
CD_GID="$(grep -E '^DOCKER_GROUP_ID=' "$AC_DIR/.env" 2>/dev/null | cut -d= -f2)"; CD_GID="${CD_GID:-1000}"
DATA_VOL_BASE="${DOCKER_VOL_DATA:-ac-client-data}"
DATA_VOL="$(docker volume ls --format '{{.Name}}' | grep -E "(^|_)${DATA_VOL_BASE}$" | head -1 || true)"
if [[ -n "$DATA_VOL" ]]; then
  echo "==> Ensuring client-data volume ($DATA_VOL) is writable by UID ${CD_UID} (survives client-data version bumps)"
  docker run --rm -v "${DATA_VOL}:/d" alpine chown -R "${CD_UID}:${CD_GID}" /d 2>/dev/null || true
fi

echo "==> Rebuilding & restarting"
echo "    (recompiles only what changed; ac-db-import re-runs to apply new DB migrations)"
docker compose up -d --build

echo "==> Regenerating central ERA-07 item provenance policy"
bash "$ROOT/configure-era-item-provenance.sh"
# The policy is read into EraPolicy on worldserver startup, so recreate the world process after
# regenerating the config. The DB/auth containers stay untouched.
docker compose up -d --no-deps --force-recreate ac-worldserver

echo "==> Pruning Docker build cache older than 7 days"
docker builder prune -f --filter until=168h || echo "    (build-cache prune skipped)"

# Group Composer is a client addon. On the development PC, keep the explicitly configured
# private 3.3.5a client in lockstep with the branch so a normal git pull + ./update.sh cannot
# leave an old UI installed while the server is already on the new backend.
if [[ "${SYNC_GROUP_COMPOSER_CLIENT:-1}" == "1" && -x "$ROOT/sync-group-composer-client.sh" ]]; then
  "$ROOT/sync-group-composer-client.sh" --if-present
fi


cat <<EOF

==================================================================
 Update complete.
 Watch the world come back up:  docker compose logs -f ac-worldserver

 Module configs are now forward-merged automatically: new files/keys are
 added without replacing values you already customized.
==================================================================
EOF
