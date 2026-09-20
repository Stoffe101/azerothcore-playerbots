# Runtime Test Matrix

Status vocabulary:
- **TODO** = implemented but not yet proven in-game.
- **PASS** = observed working in-game.
- **FAIL** = observed broken; create/fix a pass and link it from `PASS_LOG.md`.
- **BLOCKED** = test environment currently prevents the test.

## Current immediate retest

- TODO: Dungeon/Raid activity cards become selectable instead of CHECKING ACCESS.
- TODO: locked activity opens exact unlock details.
- TODO: Progression/Recommended/Diagnostics do not overlay Composer workspace.
- TODO: uncleared raids do not display CLEARED.
- TODO: Favorites renders with client-safe text.
- TODO: Utility Coverage Details shows counts + present/missing buff families.
- TODO: Build Selector long class/spec text stays inside cards.
- TODO: Recommended Activities reason/readiness stays inside card.
- TODO: Raid Templates tabs do not overlap.
- TODO: Diagnostics explains WARN as experimental/partial AI support.
- TODO: existing bot tank appears as current locked Tank slot.
- TODO: existing bot DPS appears as current locked DPS slot.
- TODO: existing real human appears as current locked human slot.
- TODO: Composer fills only remaining role slots.
- TODO: Random WotLK Heroic handoff enters Blizzard RDF role-check/search.

## Low-level validation lane

- TODO: `.ap nextstarter vanilla` reports override armed.
- TODO: `.ap nextstarter status` reports armed profile.
- TODO: next newly-created non-DK on same account remains level 1.
- TODO: one-shot override auto-clears after first login.
- TODO: realm remains WotLK.
- TODO: normal global starter profile remains unchanged.
- TODO: low-level character sees expected Vanilla dungeon access.
- TODO: non-grouped bot > player+2 effective levels is rejected.
- TODO: eligible peer-level bots can fill normal dungeon roles.
- TODO: already-grouped overlevel bot blocks with explicit message rather than being kicked.
- TODO: humans remain exempt from bot-only anti-boost rule.

## Group lifecycle

- TODO: automatic 5-player composition.
- TODO: exact class/spec requirement + Auto remainder.
- TODO: contradictory/impossible request returns useful error.
- TODO: Assemble matches reviewed roster.
- TODO: explicit Teleport enters selected activity.
- TODO: Rebuild/Repair preserves valid existing members and fills only missing.
- TODO: Leave Instance Together returns group safely.
- TODO: safe disband refuses to remove an unreviewed changed group.

## Recommendations / journey

- TODO: recommendations are sensible for actual gear/progression.
- TODO: locked recommendation opens View Unlocks.
- TODO: online eligible friend contributes to recommendation reason/weight.
- TODO: friend already busy in another group is excluded.
- TODO: active saved raid gets Resume active lockout context.

## Progression history

- TODO: first tracked final-boss kill creates personal clear.
- TODO: second fresh-instance kill increments count.
- TODO: guild clear is recorded.
- TODO: first guild-clear participant snapshot names actual humans/bots present.
- TODO: recent guild-clear timeline gains another dated row.
- TODO: Playerbot-only ownership does not create fake real-player history.

## Era release

- TODO: Vanilla cap/progression and TBC/WotLK locks.
- TODO: manual TBC release.
- TODO: TBC cap 70, WotLK remains locked.
- TODO: manual WotLK release.
- TODO: WotLK cap 80 and Titan Rune availability.
