#!/usr/bin/env bash
# Seed missing module configs and append newly introduced config keys without rebuilding the server.
# Existing values are never overwritten.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
AC_DIR="$ROOT/azerothcore-wotlk"
DEST_DIR="$AC_DIR/env/dist/etc/modules"

[[ -d "$AC_DIR/modules" ]] || {
  echo "ERROR: AzerothCore modules directory not found at $AC_DIR/modules" >&2
  exit 1
}

mkdir -p "$DEST_DIR"

added_files=0
added_keys=0

while IFS= read -r -d '' dist; do
  base="$(basename "$dist")"
  dest="$DEST_DIR/${base%.dist}"

  if [[ ! -f "$dest" ]]; then
    cp "$dist" "$dest"
    echo "Created: $(basename "$dest")"
    added_files=$((added_files + 1))
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
      echo "Added: $(basename "$dest") -> $key"
      added_keys=$((added_keys + 1))
    fi
  done < "$dist"
done < <(find "$AC_DIR/modules" -type f -path '*/conf/*.conf.dist' -print0)

echo ""
echo "Module config sync complete: ${added_files} new file(s), ${added_keys} new key(s)."
echo "Existing config values were preserved."
