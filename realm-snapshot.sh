#!/usr/bin/env bash
# Create an enriched, restorable realm snapshot around the existing backup.sh bundle.
# This is the canonical pre-transition safety primitive. It never changes realm state.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
AC_DIR="$ROOT/azerothcore-wotlk"
BACKUP_DIR="$ROOT/backups"
PURPOSE="manual"

usage() {
  cat <<'EOF'
Usage: ./realm-snapshot.sh [--purpose manual|release-transition]

release-transition is intentionally guarded:
  REALM_PROFILE must be friends
  RELEASE_OPERATIONS must be 1
  the overlay git worktree must be clean
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --purpose) PURPOSE="${2:-}"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown argument: $1" >&2; usage >&2; exit 1 ;;
  esac
done

case "$PURPOSE" in
  manual|release-transition) ;;
  *) echo "ERROR: --purpose must be manual or release-transition." >&2; exit 1 ;;
esac

if [[ ! -d "$ROOT/.git" || ! -f "$AC_DIR/.env" ]]; then
  echo "ERROR: run this from an installed overlay checkout with azerothcore-wotlk/.env." >&2
  exit 1
fi

profile="$(grep -E '^REALM_PROFILE=' "$AC_DIR/.env" 2>/dev/null | tail -n1 | cut -d= -f2- || true)"
profile="${profile:-dev}"
release_enabled="$(grep -E '^RELEASE_OPERATIONS=' "$AC_DIR/.env" 2>/dev/null | tail -n1 | cut -d= -f2- || true)"
release_enabled="${release_enabled:-0}"
if [[ ! "$profile" =~ ^[a-z0-9_-]+$ ]]; then
  echo "ERROR: invalid REALM_PROFILE '$profile'." >&2
  exit 1
fi

overlay_sha="$(git -C "$ROOT" rev-parse HEAD)"
overlay_branch="$(git -C "$ROOT" rev-parse --abbrev-ref HEAD)"
dirty=0
[[ -n "$(git -C "$ROOT" status --porcelain)" ]] && dirty=1

if [[ "$PURPOSE" == "release-transition" ]]; then
  if [[ "$profile" != "friends" || "$release_enabled" != "1" ]]; then
    echo "ERROR: release-transition snapshot refused." >&2
    echo "       Required: REALM_PROFILE=friends and RELEASE_OPERATIONS=1." >&2
    echo "       Current: REALM_PROFILE=$profile RELEASE_OPERATIONS=$release_enabled" >&2
    exit 1
  fi
  if [[ "$dirty" != "0" ]]; then
    echo "ERROR: release-transition snapshot requires a clean overlay git worktree." >&2
    exit 1
  fi
fi

result_file="$(mktemp)"
stage="$(mktemp -d)"
trap 'rm -f "$result_file"; rm -rf "$stage"' EXIT

BACKUP_RESULT_FILE="$result_file" "$ROOT/backup.sh"
bundle="$(cat "$result_file")"
if [[ ! -s "$bundle" ]]; then
  echo "ERROR: backup.sh did not produce a usable bundle." >&2
  exit 1
fi

base="$(basename "$bundle" .tar)"
stamp="${base#acore-}"
migration_list="$stage/migrations.txt"
find "$ROOT/modules" -type f -path '*/data/sql/*' -print 2>/dev/null   | sed "s|^$ROOT/||" | sort > "$migration_list"
migration_count="$(wc -l < "$migration_list" | tr -d ' ')"

cat > "$stage/snapshot-meta.env" <<EOF
SNAPSHOT_FORMAT=1
SNAPSHOT_PURPOSE=$PURPOSE
REALM_PROFILE=$profile
OVERLAY_SHA=$overlay_sha
OVERLAY_BRANCH=$overlay_branch
OVERLAY_DIRTY=$dirty
MIGRATION_COUNT=$migration_count
CREATED_UTC=$(date -u +%Y-%m-%dT%H:%M:%SZ)
EOF

cp "$ROOT/repo-pins.txt" "$stage/repo-pins.snapshot"
{
  printf 'overlay %s %s\n' "$overlay_branch" "$overlay_sha"
  [[ -d "$AC_DIR/.git" ]] && printf 'azerothcore-wotlk %s\n' "$(git -C "$AC_DIR" rev-parse HEAD)"
  for module in "$AC_DIR"/modules/*; do
    [[ -d "$module/.git" ]] || continue
    printf '%s %s\n' "$(basename "$module")" "$(git -C "$module" rev-parse HEAD)"
  done
} > "$stage/git-state.txt"

mkdir -p "$stage/empty-config"
if [[ -d "$AC_DIR/env/dist/etc" ]]; then
  tar -czf "$stage/configs.tar.gz" -C "$AC_DIR/env/dist/etc" .
else
  tar -czf "$stage/configs.tar.gz" -C "$stage/empty-config" .
fi

tar -rf "$bundle" -C "$stage" snapshot-meta.env repo-pins.snapshot git-state.txt migrations.txt configs.tar.gz
final="$BACKUP_DIR/snapshot-$profile-$PURPOSE-$stamp-${overlay_sha:0:12}.tar"
mv "$bundle" "$final"
chmod 600 "$final"

echo "[$(date)] Realm snapshot OK: $final"
echo "    profile=$profile purpose=$PURPOSE sha=$overlay_sha dirty=$dirty migrations=$migration_count"
