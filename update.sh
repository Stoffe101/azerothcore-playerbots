#!/usr/bin/env bash
# Pull the latest AzerothCore fork + modules and rebuild. Run ON THE SERVER.
# Safe to re-run. Your config (env/dist/etc/*.conf) and database volume are preserved.
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

patch_target_dir () {
  local name="$1"
  case "$name" in
    0014-ip-*)
      echo "$AC_DIR/modules/mod-individual-progression"
      ;;
    *)
      echo "$AC_DIR"
      ;;
  esac
}

apply_patches () {
  local pdir="$ROOT/patches"
  [[ -d "$pdir" && -d "$AC_DIR/.git" ]] || return 0
  local patch name target
  for patch in "$pdir"/*.patch; do
    [[ -e "$patch" ]] || continue
    name="$(basename "$patch")"
    target="$(patch_target_dir "$name")"

    if [[ ! -d "$target/.git" ]]; then
      echo "    ERROR: patch target repo missing for $name: $target" >&2
      exit 1
    fi

    if git -C "$target" apply --reverse --check "$patch" >/dev/null 2>&1; then
      echo "    Patch already applied: $name"
    elif git -C "$target" apply --check "$patch" >/dev/null 2>&1; then
      git -C "$target" apply "$patch"
      echo "    Applied patch: $name"
    else
      echo "    ERROR: $name no longer applies to $(basename "$target") (upstream moved?)." >&2
      echo "           Regenerate it against the pinned repo or remove it from patches/." >&2
      exit 1
    fi
  done
  if [[ -x "$AC_DIR/modules/mod-era-talents/apply-patches.sh" ]]; then
    "$AC_DIR/modules/mod-era-talents/apply-patches.sh" "$AC_DIR"
  fi
}

update_repo "$AC_DIR" "AzerothCore (playerbots fork)"
for moddir in "$AC_DIR"/modules/*/; do
  [[ -d "$moddir/.git" ]] || continue
  update_repo "$moddir" "$(basename "$moddir")"
done
apply_patches

# Re-sync every in-repo module before rebuild. Keep this list in step with setup.sh LOCAL_MODULES.
for lm in mod-playerbot-chatter mod-raid-roster mod-admin-panel mod-ahbot-price mod-wintergrasp-bots mod-arena-roster; do
  if [[ -d "$ROOT/modules/$lm" ]]; then
    echo "==> Syncing local module: $lm"
    rm -rf "$AC_DIR/modules/$lm"
    cp -a "$ROOT/modules/$lm" "$AC_DIR/modules/$lm"
  fi
done

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

echo "==> Pruning Docker build cache older than 7 days"
docker builder prune -f --filter until=168h || echo "    (build-cache prune skipped)"

cat <<EOF

==================================================================
 Update complete.
 Watch the world come back up:  docker compose logs -f ac-worldserver

 Note: new config options added by an update are NOT auto-merged into
 your existing env/dist/etc/*.conf (they keep compiled defaults). To pick
 up brand-new settings, compare against the .conf.dist files in that dir.
==================================================================
EOF
