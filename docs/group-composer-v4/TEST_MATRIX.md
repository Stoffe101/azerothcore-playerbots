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
- TODO: Recommended Activities reason/readiness stays inside card after the pass-3 layout fix.
- TODO: Raid Templates tabs do not overlap.
- TODO: Diagnostics explains WARN as experimental/partial AI support.
- TODO: existing bot tank appears as current locked Tank slot.
- TODO: existing bot DPS appears as current locked DPS slot.
- TODO: existing real human appears as current locked human slot.
- TODO: Composer fills only remaining role slots.
- PASS: Random WotLK Heroic handoff enters Blizzard RDF role-check/search.
- TODO: Playerbots accept the later RDF dungeon proposal before timeout after deterministic server-side bot auto-agree.
- TODO: human-anchor class icon aligns naturally in the single-icon row after pass-3 repositioning.
- TODO: Unlock Requirements cleanly overlays Activity Browser after pass-3 reparenting.
- TODO: Activity Browser opens on the character-relevant era.
- TODO: Progression opens on the character-relevant era.
- TODO: impossible/inapplicable Heroic/Titan choices are visibly locked and cannot be selected.

## Low-level validation lane

- TODO: `.ap nextstarter vanilla` reports override armed.
- TODO: `.ap nextstarter status` reports armed profile.
- TODO: next newly-created non-DK on same account remains level 1.
- TODO: one-shot override auto-clears after first login.
- TODO: realm remains WotLK.
- TODO: normal global starter profile remains unchanged.
- PASS: low-level character sees level-gated Vanilla dungeon access; user confirmed the low-level level gate behaves correctly.
- TODO: bot level policy uses the lowest real human as reference with a +/-3 peer band, never below dungeon minimum.
- TODO: solo high-level player in trivial legacy content may use high-level peer bots without being treated as a boost run.
- TODO: mixed-level real-player group at **any** levels prepares/selects bots around the lowest real human; 80 + 14 is only one example, not a special case.
- TODO: status/review shows the computed lowest-human peer target and allowed bot level band, matching the actual selected roster.
- TODO: eligible peer-level bots can fill normal dungeon roles.
- TODO: already-grouped overlevel bot blocks with explicit message rather than being kicked.
- TODO: humans remain exempt from bot-only anti-boost rule.

## Era Policy architecture

- TODO: `.ap status` era/level cap/progression values agree with the live realm after EraPolicy migration.
- TODO: manual Vanilla -> TBC -> WotLK release still applies the expected 60/70/80 cap and progression ceiling through EraPolicy.
- STATIC/CI: Adventure Catalog and AdminPanelExpansion share `EraPolicy::Era` and no longer own duplicate era state/cap tables.
- TODO: future-era AdventureStart profile is refused.
- TODO: future-era catch-up package is refused before gear/progression changes.
- TODO: `.playstyle raid unlock` cannot cross the live era boundary.
- TODO: direct `.gctitan queue` is rejected before WotLK.
- TODO: bot progression sync never promotes a bot beyond the live realm era.
- TODO: Playerbots runtime random-bot max reports 60/70/80 with the live era after startup and config reload.
- TODO: Composer refuses ordinary over-cap bot candidates even if stale config/data exposes one.
- TODO: automated RaidRoster gear prep refuses an over-cap bot without stripping gear.
- TODO: stored RNDbot above live cap is skipped without changing its stored level.
- TODO: ungrouped active RNDbot above live cap is logged out/quarantined and becomes eligible again after expansion cap rises.
- TODO: a grouped over-cap RNDbot is not forcibly removed mid-run.
- TODO: Azeroth Control refuses Shattrath before TBC and Dalaran/Argent before WotLK.
- TODO: Azeroth Control goto/saved-location travel refuses a future-era map.
- TODO: Group Composer cannot teleport a reviewed roster into a future-era instance map.

## Admin security / addon launchers

- TODO: normal non-GM account sees no Azeroth Control minimap button after login authorization resolves.
- TODO: normal non-GM account cannot open Azeroth Control with `/ap` or `/adminpanel`.
- TODO: normal non-GM account cannot execute a privileged manual command such as `.ap givegold 1000`.
- TODO: GM account receives Azeroth Control access, sees its minimap button and can open the panel normally.
- TODO: Group Composer minimap button is visible, has the intended stock icon/tooltip and toggles the same dashboard as `/gc`.

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


## Era-fidelity acceptance

These are release-realm acceptance tests. All remain TODO until implemented and observed.

### Vanilla realm

- TODO: declared realm era is Vanilla and effective player cap is 60.
- TODO: no normal random/world/guild/Composer bot above 60 is eligible/visible to players.
- TODO: Composer does not offer Death Knights.
- TODO: Composer defaults to Vanilla activities/templates; TBC/WotLK are locked previews at most.
- TODO: TBC/WotLK activities cannot be assembled or teleported to.
- TODO: AH contains no TBC/WotLK-only items, socket-gem system stock or glyphs.
- TODO: automated bot gear/prep cannot produce TBC/WotLK items.
- TODO: Outland and Northrend access is blocked.
- TODO: profession cap is 300; Jewelcrafting and Inscription are unavailable.
- TODO: future-era vendor/reward/catch-up items are unavailable.

### TBC realm

- TODO: declared realm era is TBC and effective player cap is 70.
- TODO: Vanilla content remains available.
- TODO: no normal bot above 70 is eligible/visible.
- TODO: Death Knights remain unavailable.
- TODO: Composer defaults to TBC endgame and preserves Vanilla under legacy/leveling.
- TODO: TBC 25-player templates optimize 5-player subgroup-local utility.
- TODO: Northrend/WotLK activities remain blocked.
- TODO: AH contains Vanilla + TBC stock but no WotLK-only items or glyphs.
- TODO: profession cap is 375; Jewelcrafting is available; Inscription is unavailable.
- TODO: automated bot gear/prep cannot produce WotLK items.

### WotLK realm

- TODO: declared realm era is WotLK and effective player cap is 80.
- TODO: Vanilla + TBC content remain available.
- TODO: Death Knights become available.
- TODO: profession cap is 450; Inscription/glyph economy becomes available.
- TODO: Composer exposes WotLK 10/25 templates and WotLK recommendations.
- TODO: Titan Rune modes obey their intended WotLK progression/phase gates.
- TODO: Random WotLK Normal/Heroic may use Blizzard RDF handoff where appropriate.

### Additional era-system checks

- TODO: Vanilla does not expose arenas.
- TODO: TBC enables arenas while WotLK-only PvP systems remain unavailable.
- TODO: Wintergrasp remains unavailable before WotLK.
- TODO: automated systems cannot award heirlooms before WotLK.
- TODO: dual spec follows the chosen WotLK-era policy and cannot leak early.
- TODO: era-invalid bot chatter/goals do not reference unreleased endgame as current content.
- TODO: Blood Elf/Draenei release policy matches the TBC transition.
- TODO: Vanilla faction class policy is enforced where the technical implementation supports it.
- TODO: expansion-specific transport/portal/flying routes obey the era gate.
- TODO: holiday/world-event automated rewards pass the future-era item audit.

### Expansion transition integrity

- TODO: opening TBC is forward-only and does not wipe valid Vanilla progress/items/history.
- TODO: opening WotLK is forward-only and does not wipe valid Vanilla/TBC progress/items/history.
- TODO: bot population reconciles to the new cap without replacing the world with instant max-level raid bots.
- TODO: AH keeps older legal stock and adds newly legal expansion stock.
- TODO: Composer refreshes era header/catalog/templates/recommendations immediately after release.
- TODO: Era Integrity audit reports zero future-era leakage after each transition.
