#!/usr/bin/env bash
# Restore an AzerothCore backup bundle (.tar from backup.sh). Run ON THE SERVER.
# Restores .env AND the four game databases from ONE file, re-aligns the DB root
# password to the backed-up .env, regenerates confs, and brings the server up.
#
# Assumes ./setup.sh has already run (fork cloned, images built, ac-database up —
# possibly with a throwaway default password on a brand-new box).
#
# Usage: ./restore.sh <backup.tar> [--yes] [--allow-profile-mismatch] [--allow-code-mismatch]
#   --yes / RESTORE_YES=1 : skip the destructive-action confirmation (for automation)
#   --allow-profile-mismatch : explicitly permit cross-profile restore (dangerous)
#   --allow-code-mismatch    : explicitly permit restoring a snapshot against another overlay SHA
#
# Limitation: a DB root password containing a single quote or backslash is not
# supported by the ALTER USER step below.
#
# Note: the four DBs are briefly dropped during the reload — a failed import leaves
# them dropped; just re-run with a good bundle (the bundle is validated before any drop).
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
AC_DIR="$ROOT/azerothcore-wotlk"

# ---- args ----
BUNDLE=""
ASSUME_YES="${RESTORE_YES:-0}"
ALLOW_PROFILE_MISMATCH="${RESTORE_ALLOW_PROFILE_MISMATCH:-0}"
ALLOW_CODE_MISMATCH="${RESTORE_ALLOW_CODE_MISMATCH:-0}"
for arg in "$@"; do
  case "$arg" in
    --yes) ASSUME_YES=1 ;;
    --allow-profile-mismatch) ALLOW_PROFILE_MISMATCH=1 ;;
    --allow-code-mismatch) ALLOW_CODE_MISMATCH=1 ;;
    -*)    echo "Unknown option: $arg" >&2; exit 1 ;;
    *)     BUNDLE="$arg" ;;
  esac
done

if [[ -z "$BUNDLE" ]]; then
  echo "Usage: $0 <backup.tar> [--yes] [--allow-profile-mismatch] [--allow-code-mismatch]" >&2
  exit 1
fi
if [[ ! -f "$BUNDLE" ]]; then
  echo "No such backup file: $BUNDLE" >&2
  exit 1
fi
if [[ ! -d "$AC_DIR/.git" || ! -f "$AC_DIR/.env" ]]; then
  echo "Not installed yet — run ./setup.sh first, then restore." >&2
  exit 1
fi

# ---- validate bundle contents ----
members="$(tar -tf "$BUNDLE")"
if ! grep -qx "database.sql.gz" <<<"$members" || ! grep -qx "env" <<<"$members"; then
  echo "ERROR: $BUNDLE is not a valid backup bundle (needs database.sql.gz + env)." >&2
  echo "Contents were:" >&2; echo "$members" >&2
  exit 1
fi

# ---- snapshot identity guard (before anything destructive) ----
TARGET_PROFILE="$(grep -E '^REALM_PROFILE=' "$AC_DIR/.env" 2>/dev/null | tail -n1 | cut -d= -f2- || true)"
TARGET_PROFILE="${TARGET_PROFILE:-dev}"
SNAPSHOT_PROFILE=""
SNAPSHOT_SHA=""
if grep -qx "snapshot-meta.env" <<<"$members"; then
  SNAPSHOT_PROFILE="$(tar -xOf "$BUNDLE" snapshot-meta.env | grep -E '^REALM_PROFILE=' | tail -n1 | cut -d= -f2- || true)"
  SNAPSHOT_SHA="$(tar -xOf "$BUNDLE" snapshot-meta.env | grep -E '^OVERLAY_SHA=' | tail -n1 | cut -d= -f2- || true)"
fi

if [[ -z "$SNAPSHOT_PROFILE" && "$TARGET_PROFILE" == "friends" && "$ALLOW_PROFILE_MISMATCH" != "1" ]]; then
  echo "ERROR: refusing legacy/unidentified backup on a friends realm." >&2
  echo "       Use an enriched realm snapshot, or explicitly pass --allow-profile-mismatch." >&2
  exit 1
fi
if [[ -n "$SNAPSHOT_PROFILE" && "$SNAPSHOT_PROFILE" != "$TARGET_PROFILE" && "$ALLOW_PROFILE_MISMATCH" != "1" ]]; then
  echo "ERROR: snapshot profile '$SNAPSHOT_PROFILE' does not match target '$TARGET_PROFILE'." >&2
  echo "       Refusing cross-realm restore. Pass --allow-profile-mismatch only deliberately." >&2
  exit 1
fi

CURRENT_OVERLAY_SHA="$(git -C "$ROOT" rev-parse HEAD 2>/dev/null || true)"
if [[ -n "$SNAPSHOT_SHA" && "$CURRENT_OVERLAY_SHA" != "$SNAPSHOT_SHA" && "$ALLOW_CODE_MISMATCH" != "1" ]]; then
  echo "ERROR: snapshot expects overlay SHA $SNAPSHOT_SHA but current checkout is $CURRENT_OVERLAY_SHA." >&2
  echo "       Check out the recorded SHA first, then rerun restore." >&2
  echo "       --allow-code-mismatch exists only for deliberate recovery work." >&2
  exit 1
fi

# ---- current (live) root password = what the DB volume was created with ----
# shellcheck disable=SC1091
set -a; source "$AC_DIR/.env"; set +a
CURRENT_PW="${DOCKER_DB_ROOT_PASSWORD}"

# ---- confirm (destructive) ----
if [[ "$ASSUME_YES" != "1" ]]; then
  echo "This will OVERWRITE $ROOT/.env (propagated to $AC_DIR/.env by setup.sh) and DROP + RELOAD the four acore_* databases"
  echo "from: $BUNDLE"
  [[ -n "$SNAPSHOT_PROFILE" ]] && echo "snapshot profile: $SNAPSHOT_PROFILE"
  [[ -n "$SNAPSHOT_SHA" ]] && echo "snapshot overlay SHA: $SNAPSHOT_SHA"
  read -r -p "Proceed? [y/N] " ans || ans=""   # don't let EOF (no stdin) skip the Aborted message
  [[ "$ans" == "y" || "$ans" == "Y" ]] || { echo "Aborted."; exit 1; }
fi

# ---- extract to a temp dir (always cleaned up) ----
STAGE="$(mktemp -d)"
trap 'rm -rf "$STAGE"' EXIT
tar -xf "$BUNDLE" -C "$STAGE" database.sql.gz env
if grep -qx "configs.tar.gz" <<<"$members"; then
  tar -xf "$BUNDLE" -C "$STAGE" configs.tar.gz
fi

# Backed-up root password — the target the live DB must end up using. By .env
# convention the value is unquoted (same as how `source` populated CURRENT_PW above),
# so this raw grep|cut compares apples-to-apples against CURRENT_PW.
RESTORE_PW="$(grep -E '^DOCKER_DB_ROOT_PASSWORD=' "$STAGE/env" | head -n1 | cut -d= -f2-)"
if [[ -z "$RESTORE_PW" ]]; then
  echo "ERROR: backed-up env has no DOCKER_DB_ROOT_PASSWORD." >&2
  exit 1
fi

cd "$AC_DIR"

# Run SQL as root using the CURRENT live password (no args = read SQL from stdin).
db() { docker compose exec -T ac-database mysql -uroot -p"$CURRENT_PW" "$@"; }

# ---- quiesce so nothing writes to the DB during the load ----
echo "[$(date)] Stopping worldserver/authserver for a clean DB load…"
docker compose stop ac-worldserver ac-authserver

# ---- drop + reload the four databases ----
echo "[$(date)] Dropping and reloading databases…"
if ! db -e "DROP DATABASE IF EXISTS acore_auth; \
            DROP DATABASE IF EXISTS acore_characters; \
            DROP DATABASE IF EXISTS acore_world; \
            DROP DATABASE IF EXISTS acore_playerbots;"; then
  echo "ERROR: could not connect to the database with the password in $AC_DIR/.env." >&2
  echo "       The DB volume was likely initialized with a different root password." >&2
  exit 1
fi
gunzip -c "$STAGE/database.sql.gz" | db   # dump's CREATE DATABASE/USE recreate them

# ---- re-align the live root password to match the backed-up .env ----
# Reloading the game DBs cannot change this (the password lives in the mysql.* system
# DB, which the backup does not include), so set it explicitly here.
if [[ "$RESTORE_PW" != "$CURRENT_PW" ]]; then
  echo "[$(date)] Aligning DB root password with the restored .env…"
  db -e "ALTER USER 'root'@'localhost' IDENTIFIED BY '${RESTORE_PW}'; FLUSH PRIVILEGES;"
  # root@'%' may not exist on every image — ignore if absent.
  db -e "ALTER USER 'root'@'%' IDENTIFIED BY '${RESTORE_PW}'; FLUSH PRIVILEGES;" 2>/dev/null || true
fi

# ---- overlay repo-root .env (the source of truth; setup.sh copies it to the live env) ----
# Snapshot the previous source-of-truth as an undo, then drop the backed-up env in its place.
# The setup.sh re-run below propagates it to azerothcore-wotlk/.env.
if [[ -f "$ROOT/.env" ]]; then
  cp "$ROOT/.env" "$ROOT/.env.pre-restore"
  chmod 600 "$ROOT/.env.pre-restore"   # same plaintext secrets as .env
fi
cp "$STAGE/env" "$ROOT/.env"
echo "[$(date)] Restored ./.env (previous saved to ./.env.pre-restore)."

# ---- regenerate confs from the restored .env and bring the stack up ----
echo "[$(date)] Re-running setup.sh to regenerate confs and start the server…"
"$ROOT/setup.sh"

if [[ -f "$STAGE/configs.tar.gz" ]]; then
  echo "[$(date)] Restoring persistent server/module config snapshot..."
  mkdir -p "$AC_DIR/env/dist/etc"
  tar -xzf "$STAGE/configs.tar.gz" -C "$AC_DIR/env/dist/etc"
  (cd "$AC_DIR" && docker compose restart ac-authserver ac-worldserver)
fi

echo "[$(date)] Restore complete from $(basename "$BUNDLE")."
[[ -n "$SNAPSHOT_SHA" ]] && echo "[$(date)] Snapshot provenance: overlay SHA $SNAPSHOT_SHA, profile $SNAPSHOT_PROFILE."
