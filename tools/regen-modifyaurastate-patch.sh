#!/usr/bin/env bash
# regen-modifyaurastate-patch.sh — re-cut
# patches/0018-core-modifyaurastate-iterator-safety.patch from the fork working tree at
# azerothcore-wotlk.
#
# CORE-ONLY patch (like 0008/0010/0012, unlike every module patch): it touches
# src/server/game/Entities/Unit/Unit.cpp in the fork itself. A plain `git -C "$AC" diff` with
# NO prefix rewriting is therefore correct — the a/src/... paths already resolve from the fork
# root, which is where setup.sh's apply_patches invokes `git -C "$AC_DIR" apply`. Do NOT copy
# the --src-prefix/--dst-prefix flags from the module regen scripts; they would corrupt the
# paths. The gate below enforces this.
#
# WHAT 0018 IS: Unit::ModifyAuraState walked Unit::GetOwnedAuras() with raw iterators while
# calling Aura::HandleAllEffects(), which can add or remove owned auras. AuraMap is a
# boost::container::flat_multimap (contiguous storage), so any insert/erase invalidates every
# iterator. Production segfaulted ~13x/day at Unit.cpp ModifyAuraState: gdb showed the iterator
# at index 30 of a container whose size had shrunk to 27 (capacity still 35, buffer unmoved),
# so `itr != end()` never became true-to-false and the loop dereferenced a null Aura* out in the
# dead capacity region. 0018 snapshots the aura pointers into a LOCAL std::vector first (local,
# not the m_auraUpdateSnapshot member, because ModifyAuraState can nest) and skips IsRemoved()
# entries. Snapshot pointers stay valid because a removed aura is only deleted later in
# _DeleteRemovedAuras() — the same invariant the fork's _UpdateSpells snapshot relies on.
#
# WHY THIS IS BASELINE-AWARE: Unit.cpp is shared with FOUR other patches, so a naive whole-file
# `git diff` of the full-stack worktree would embed their hunks into 0018 (the regen trap that
# bit the 0004 regen). The baseline we diff against is pristine + every OTHER patch on this
# file:
#   * patches/0012-core-bot-aura-batching.patch  — an OVERLAY patch applied BEFORE 0018.
#   * mod-era-talents' core patches 01 / 05 / 06 — applied AFTER all overlay patches, by that
#     module's own apply-patches.sh.
# Including the era hunks in the baseline does NOT corrupt 0018's hunk line numbers: all three
# era hunks sit at ~8479 / ~8520 / ~9280, i.e. AFTER ModifyAuraState (~7665), so the line
# numbers at our hunk are identical with or without them. 0012's hunk at ~4004 is BEFORE ours
# and genuinely shifts it, which is why 0012 must be in the baseline. The era patches are in
# the baseline purely so their hunks don't leak into 0018's diff.
# The era module is a CLONE (may be absent on a fresh/partial tree), so a missing era patch file
# is skipped, not fatal.
#
# Procedure (the regen-arena-patch.sh index-baseline pattern):
#   1. save the current (0018-bearing) Unit.cpp; trap a restore of worktree + index
#   2. checkout -- Unit.cpp (pristine)
#   3. re-apply ONLY the other patches' Unit.cpp hunks (0012, era 01/05/06)
#   4. `git add` Unit.cpp (index = baseline)
#   5. copy the saved Unit.cpp back (worktree = baseline + 0018)
#   6. `git diff` (index vs worktree) == exactly the 0018 hunk, correct headers
#
# LITERAL PATHS ONLY on every git/cp line — the shell does not word-split an unquoted $var, so
# a `for f in $FILES` loop would cut an empty patch (this trap has bitten twice before).
#
# Re-runnable from the full-stack worktree state; leaves the fork worktree AND index exactly as
# found.

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
AC="$ROOT/azerothcore-wotlk"
OUT="$ROOT/patches/0018-core-modifyaurastate-iterator-safety.patch"
P0012="$ROOT/patches/0012-core-bot-aura-batching.patch"
ERA="$AC/modules/mod-era-talents/patches/core"

[[ -d "$AC/.git" ]] || { echo "ERROR: $AC is not a git clone (run setup.sh first)" >&2; exit 1; }
[[ -f "$P0012" ]]   || { echo "ERROR: missing $P0012 (baseline needs 0012's Unit.cpp hunk)" >&2; exit 1; }

# The 0018 edit must actually be present in the worktree, or we would cut an empty/partial patch
# over a good one and silently drop the crash fix on the next fork reset.
grep -q "snapshot.reserve(GetOwnedAuras().size())" "$AC/src/server/game/Entities/Unit/Unit.cpp" \
  || { echo "ERROR: Unit.cpp has no ModifyAuraState snapshot — 0018 not applied?" >&2; exit 1; }

TMP="$(mktemp -d)"
restore() {
  # Always leave the fork exactly as found: 0018-bearing worktree, pristine index.
  # (`if` not `&&` — under set -e a failing `[[ ]] && cmd` compound aborts the trap.)
  if [[ -f "$TMP/Unit.cpp" ]]; then cp "$TMP/Unit.cpp" "$AC/src/server/game/Entities/Unit/Unit.cpp"; fi
  git -C "$AC" reset -q -- src/server/game/Entities/Unit/Unit.cpp 2>/dev/null || true
  rm -rf "$TMP"
}
trap restore EXIT

# 1. Save the current (0018-bearing) file.
cp "$AC/src/server/game/Entities/Unit/Unit.cpp" "$TMP/Unit.cpp"

# 2. Pristine.
git -C "$AC" checkout -- src/server/game/Entities/Unit/Unit.cpp

# 3. Rebuild the baseline: pristine + every OTHER patch's Unit.cpp hunks.
git -C "$AC" apply --include=src/server/game/Entities/Unit/Unit.cpp "$P0012"
# The era module is a clone — skip any patch that isn't checked out here. Its patches use
# fork-root-relative paths, so they apply from "$AC" like the overlay's.
if [[ -f "$ERA/01-shatter-crit-vs-frozen.patch" ]]; then
  git -C "$AC" apply --include=src/server/game/Entities/Unit/Unit.cpp "$ERA/01-shatter-crit-vs-frozen.patch"
else
  echo "NOTE: mod-era-talents core patch 01 absent — skipped in baseline" >&2
fi
if [[ -f "$ERA/05-wand-spec-era-no-spell-leak.patch" ]]; then
  git -C "$AC" apply --include=src/server/game/Entities/Unit/Unit.cpp "$ERA/05-wand-spec-era-no-spell-leak.patch"
else
  echo "NOTE: mod-era-talents core patch 05 absent — skipped in baseline" >&2
fi
if [[ -f "$ERA/06-molten-fury-era-window.patch" ]]; then
  git -C "$AC" apply --include=src/server/game/Entities/Unit/Unit.cpp "$ERA/06-molten-fury-era-window.patch"
else
  echo "NOTE: mod-era-talents core patch 06 absent — skipped in baseline" >&2
fi

# 4. Stage the baseline (index = pristine + 0012 + era for this path).
git -C "$AC" add -- src/server/game/Entities/Unit/Unit.cpp

# 5. Restore the 0018 worktree state.
cp "$TMP/Unit.cpp" "$AC/src/server/game/Entities/Unit/Unit.cpp"

# 6. Index(baseline) vs worktree(0018) == exactly the 0018 hunk. No prefix rewriting: core patch.
git -C "$AC" diff -- src/server/game/Entities/Unit/Unit.cpp > "$TMP/0018.patch"

# (index/worktree restoration happens in the EXIT trap)

# Gates — a bad patch here plus a setup.sh reset would orphan the crash fix.
[[ -s "$TMP/0018.patch" ]] || { echo "GATE FAIL: generated patch is empty" >&2; exit 1; }
[[ "$(grep -c '^diff --git' "$TMP/0018.patch")" -eq 1 ]] \
  || { echo "GATE FAIL: expected exactly 1 file in the patch" >&2; exit 1; }
grep -q "b/src/server/game/Entities/Unit/Unit.cpp" "$TMP/0018.patch" \
  || { echo "GATE FAIL: patch path is not fork-root relative — did you add --dst-prefix?" >&2; exit 1; }
for needle in "snapshot.reserve" "for (Aura* aura : snapshot)"; do
  grep -qF -- "$needle" "$TMP/0018.patch" \
    || { echo "GATE FAIL: patch missing expected content: $needle" >&2; exit 1; }
done
# The change must be inside ModifyAuraState (hunk header shows the enclosing function).
grep -q "^@@.*ModifyAuraState" "$TMP/0018.patch" \
  || { echo "GATE FAIL: hunk is not inside Unit::ModifyAuraState" >&2; exit 1; }
# CONTAMINATION — fail if the patch absorbed a neighbour's hunks on this shared file.
for canary in "m_botAuraUpdateTimer" "BOT_AURA_UPDATE_INTERVAL" "mod-era-talents" "Molten Fury" "Wand Specialization"; do
  if grep -qF -- "$canary" "$TMP/0018.patch"; then
    echo "GATE FAIL: patch contaminated with another patch's content: $canary" >&2; exit 1
  fi
done

cp "$TMP/0018.patch" "$OUT"
echo "OK: wrote $OUT ($(wc -l < "$OUT") lines)"
git -C "$AC" apply --stat "$OUT" | sed 's/^/    /'
