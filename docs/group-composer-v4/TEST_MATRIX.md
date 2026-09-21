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
- TODO: `.era audit` is GM-only and does not mutate state.
- TODO: `.era audit` reports central cap drift as FAIL.
- TODO: `.era audit` reports stored over-cap RNDbots as WARN/quarantined with examples.
- TODO: `.era audit` reports Outland/Northrend map policy correctly for Vanilla/TBC/WotLK.
- TODO: Composer Build Selector hides Death Knight before WotLK and shows it after WotLK release; backend also rejects it before release.
- TODO: Composer/RaidRoster excludes Blood Elf/Draenei before TBC.
- TODO: RaidRoster sync from a dirty level-80 master clamps bots to 60 in Vanilla and 70 in TBC.
- TODO: `.era audit` FAILs on active future-era bot class/race.
- TODO: `.era audit` FAILs on active Jewelcrafting before TBC, Inscription before WotLK, or profession skill above 300/375/450.
- TODO: Azeroth Control refuses Shattrath before TBC and Dalaran/Argent before WotLK.
- TODO: Azeroth Control goto/saved-location travel refuses a future-era map.
- TODO: Group Composer cannot teleport a reviewed roster into a future-era instance map.

## GearAdvisor / WoWSims integration

- PASS (CI `1f5ef71c`): GearAdvisor v0.2.1 narrow-screen anchoring/layout static contracts and both local heavy builds.
- STATIC/CI: WoWSimsBridge parses as Lua 5.1 / Interface 30300.
- TODO exact-head repair: client workflow itself parses/runs exactly once after `97178c40` malformed-workflow failure.
- STATIC/CI: source manifest pins Classic, TBC, WotLK and exporter upstream commits.
- STATIC/CI: GearAdvisor no longer calls `priorityText:SetText(profile.priority)`.
- STATIC/CI: WoWSimsBridge exposes Classic/TBC/WotLK URLs plus character and bag export functions.
- TODO: Vanilla server era produces a Classic-family export accepted by WoWSims.
- TODO: TBC server era produces a TBC-family export accepted by WoWSims.
- TODO: WotLK server era produces a WotLK-family export accepted by WoWSims, including gems/glyphs.
- TODO: equipped item IDs, enchants, talents and professions match the live character.
- TODO: bag export is accepted by WoWSims batch/top-gear import.
- TODO: unsupported sim model is labeled UNSUPPORTED rather than receiving a static-weight winner.
- TODO: automatic backend runs same-settings baseline and candidate simulations.
- TODO: candidate explanation quantifies cap/stat trade, e.g. hit lost vs agility/crit gained, and cites the actual simulated metric delta.
- TODO: special proc/set/weapon effects are labeled simulation-sensitive and not explained as raw-stat arithmetic only.

## ERA-07 starter/catch-up / PlayerbotFactory provenance

- PASS (CI `e990dff5`): post-patch transformer Python-compiles and inserts readiness + item-allowed callback contracts after EraTalents.
- PASS (CI `e990dff5`): setup, update, Integration and Group Composer compile use the transformer after the full patch stack.
- PASS (CI `e990dff5`): static 0044/deferred-patch machinery is retired.
- PASS (CI `e990dff5`): RaidRoster registers `EraPolicy::ItemProvenanceReady` and `EraPolicy::IsItemAllowed` with PlayerbotFactory.
- PASS (CI `e990dff5`) / runtime TODO: AdventureStart and catch-up fail before destructive/one-time state mutation when provenance is unavailable.
- TODO: Vanilla starter/factory generation never creates TBC/WotLK/UNKNOWN items.
- TODO: TBC starter/factory generation never creates WotLK/UNKNOWN items.
- TODO: WotLK factory generation still blocks UNKNOWN items.
- TODO: catch-up package with provenance disabled/stale leaves progression and claim bit untouched.
- TODO: catch-up package after provenance repair can be retried successfully.
- TODO: raid-ready AdventureStart with stale provenance does not level/progress/mark starter state or strip existing gear.
- TODO: factory-generated ammo/potions/food/reagents/gems used by protected flows obey central item provenance.
- TODO: audit remaining legacy factory heuristics separately; they may restrict more than provenance but must never be treated as chronology proof.

## ERA-07 Adventure Cache reward provenance

- PASS (CI `e1a2e6fa`): cache open checks provenance readiness before consuming the pending cache.
- PASS (CI `e1a2e6fa`): cache gear candidates and direct item storage call `EraPolicy::IsItemAllowed`.
- TODO: with provenance unavailable, `.cache open` leaves pending cache unchanged.
- TODO: after provenance repair, the same pending cache can be opened.
- TODO: Vanilla/TBC/WotLK cache rewards never create future/UNKNOWN gear or potions.

## Auction House era profiles / ERA-07 provenance

- STATIC/CI: `configure-era-item-provenance.sh` and `configure-ahbot.sh` parse with `bash -n`.
- STATIC/CI: setup/update both invoke the central provenance generator, and server contracts require EraPolicy + gear/audit consumers.
- PASS (CI `44adb851`): ERA-07 generator self-test passes and the pinned source manifest parses as JSON.
- PASS (CI `44adb851`): AHBot wrapper patch consumes `AuctionHouseBot.EraProvenanceDisabledItemIDs` separately from operator custom IDs.
- TODO: first provenance generation downloads/verifies the three exact pinned Git blobs and later runs use the verified cache.
- TODO: generated manifest covers every live `acore_world.item_template` entry as Vanilla/TBC/WotLK/UNKNOWN.
- TODO: UNKNOWN items are present in every generated AH blocklist until explicitly overridden.
- TODO: Vanilla AHBot never creates a TBC/WotLK/UNKNOWN listing after provenance profile application.
- TODO: TBC AHBot never creates a WotLK/UNKNOWN listing after provenance profile application.
- TODO: `.era audit` AUCTION_PROVENANCE profile/source/world-item counts agree with the active generated profile and WARN on blocked UNKNOWNs.
- TODO: Vanilla profile persists marker `vanilla`, cap 60, Gems OFF, Glyphs OFF.
- TODO: TBC profile uses cap 70, Gems ON, Glyphs OFF.
- TODO: WotLK profile uses cap 80, Gems ON, Glyphs ON and Wrath boost IDs.
- TODO: applying Vanilla/TBC after WotLK removes script-owned Wrath boost IDs.
- TODO: `.era audit` FAILs when enabled AH profile disagrees with live era and PASSes when aligned.
- PASS (CI `e96d009`) / runtime TODO: `.era audit` scans existing auction stock and FAILs on future-era or UNKNOWN listings.
- PASS (CI `e96d009`) / runtime TODO: `.era audit` scans stored RNDbot equipment slots and FAILs on future-era or UNKNOWN gear.
- PASS (CI `e96d009`) / runtime TODO: deterministic RaidRoster/Group Composer gear preparation never selects a future-era/UNKNOWN item and refuses to strip a bot when central provenance is unavailable.
- TODO: central provenance generation reports the live item count/fingerprint and survives a normal `./update.sh` restart with `AUCTION_PROVENANCE` ready.

## Snapshot / rollback safety

- STATIC/CI: backup, restore and realm-snapshot shell syntax passes `bash -n`.
- TODO: manual dev snapshot produces DB/env/config/Git/pin/migration metadata.
- TODO: `--purpose release-transition` is refused on the dirty dev realm.
- TODO: friends-profile snapshot is refused when `RELEASE_OPERATIONS` is disabled.
- TODO: restore refuses profile mismatch.
- TODO: restore refuses overlay SHA mismatch.
- TODO: dev snapshot can be restored end-to-end and services return healthy without losing captured config.

## Client addon bundle / GearAdvisor

- PASS (CI `de842ba8`): `fetch-client-addons.sh` parses and contains exact pins for NoM0Re WeakAuras + maintained Details.
- PASS (CI `de842ba8`): no Bunny67 WeakAuras fallback is packaged.
- PASS (CI `de842ba8`): GearAdvisor parses under Lua 5.1 and includes all class/spec profile families.
- PASS (CI `6d472bc0`): v0.2.0 widened 390px panel, screen clamping, cap tooltips/two-column rows, seven key-stat rows, WotLK-reference warning and Arms 1260 ArP baseline are asserted by client CI.
- STATIC/CI v0.2.1: side selection compares right/left usable space before choosing an anchor; exact-head local CI required.
- TODO: generated client zip contains Details, WeakAuras/Options/model folders and GearAdvisor, but not ExtendedCharacterStats.
- TODO: GearAdvisor opens beside CharacterFrame without covering paper-doll/header controls; test wide, ~800px and 768px-class layouts/UI scales to confirm it chooses the side with more usable space and remains on-screen.
- TODO: switching dual spec refreshes the detected spec/profile immediately.
- TODO: MM Hunter shows ranged-hit target/shortfall, equipped ilvl and the MM priority profile.
- TODO: Feral Cat/Bear mode toggle changes guidance without changing the player's talents; Cat key stats include melee hit and the row layout remains aligned.
- TODO: DK DPS/Tank role toggle changes the same tree's guidance safely.
- TODO: WotLK level-80 rating targets match the live client's combat-rating conversions.
- TODO: when Group Composer has a server era snapshot, GearAdvisor displays that era rather than relying on level fallback.
- TODO: hover each populated cap row and verify the target explanation/current-target tooltip is readable and does not cover the panel unusably.
- TODO: long hit/rating/ArP values stay in the right column without clipping into the cap label.
- TODO: Vanilla/TBC display the visible WotLK-reference warning for detailed priorities.
- TODO: close-button + `/ga` hide/restore state behaves consistently across CharacterFrame reopen.

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


## WoWSims automatic backend

- PASS (CI `c420b300`): repaired WoWSimsBridge/GearAdvisor client checkpoint passed all four exact-SHA workflows.
- STATIC/UNIT: `wowsims-service/app.py` parses and unit tests cover era allowlisting, metric extraction, two-run comparison, fixed-binary invocation and readiness failure.
- STATIC: image-local `wowsims-service/sources.json` must be byte-identical to canonical `data/wowsims/sources.json`.
- STATIC: Dockerfile pins must exactly match Classic/TBC/WotLK canonical commits.
- STATIC: generated Compose block must contain `expose` and must not publish `ports`.
- TODO runtime: build `ac-wowsims` on the server PC and require `GET /health` ready=true for all three engines.
- TODO runtime: execute one valid RaidSimRequest per era.
- TODO integration: worldserver builds equivalent baseline/candidate requests and GearAdvisor receives the returned result/explanation.


### Authoritative WoWSims snapshot

- PASS (CI `aba336fd`): simulator-service foundation passed all four exact-SHA workflows.
- STATIC/CI: worldserver snapshot contains exactly 17 WoWSims equipment positions.
- STATIC/CI: permanent enchants come from live Item state and socket enchantments resolve through `sSpellItemEnchantmentStore` to gem item IDs.
- STATIC/CI: talent string is reconstructed from live Player talent state rather than trusting the addon export.
- STATIC/UNIT: service rejects malformed gear count, future-era Death Knight snapshots and era level-cap violations.
- STATIC/UNIT: accepted structural models return `AVAILABLE_UNVALIDATED`, never SIM-BACKED.
- TODO runtime: `.wowsims snapshot` reports expected era/class/tree on a real character.
- TODO runtime: `.wowsims validate` reaches `ac-wowsims` and returns the pinned engine/model route.
- TODO integration: validated preset construction, asynchronous sim queue and GearAdvisor result transport.


### Pinned WoWSims model catalog

- PASS (CI `0e4fadb2`): authoritative worldserver snapshot + structural validation passed all four exact-SHA workflows.
- STATIC: model catalog repo/commit pins must equal `data/wowsims/sources.json`.
- STATIC: catalog stores the exact pinned `proto/api.proto` Git blob for each era.
- STATIC: every route's `protoSpecField` must exist in that era's catalogued proto field set.
- STATIC: expanded class/tree/role routes must be unique.
- STATIC: no Death Knight route may exist before WotLK.
- UNIT: Vanilla Enhancement Tank resolves only to the Classic `warden_shaman` engine model.
- UNIT: TBC Protection Warrior resolves to `protection_warrior`.
- UNIT: an uncatalogued role/spec combination returns `UNSUPPORTED`, never a substituted model.
- TODO: preset validation must promote individual routes from ENGINE_PRESENT_UNVALIDATED before automatic sim authority is enabled.


### Engine-native WoWSims preset harvesting

- STATIC/UNIT: `harvest_presets.py --self-test` covers Go test-function discovery and model-route classification.
- STATIC/UNIT: discovery ignores underscore-prefixed/dot-prefixed package directories, matching Go traversal and excluding upstream disabled legacy specs.
- STATIC: WotLK single-generator and Vanilla/TBC generator-slice `RunTestSuite` signatures are instrumented separately.
- CONTRACT: pristine pinned `wowsimcli` binaries are compiled before upstream test-harness instrumentation.
- CONTRACT: only upstream full-character `Average` RaidSimRequests are harvested.
- CONTRACT: every harvested request must classify to an exact model-catalog class/tree/role route; unclassified requests fail the image build.
- CONTRACT: stats-only upstream suites produce no automatic sim preset. No rotation is synthesized.
- CONTRACT: each generated request is SHA-256 identified inside the era `preset-index.json`.
- RUNTIME-BUILD: when simulator inputs change, Stage backend must build the real `wowsims-service` image and require preset readiness for VANILLA, TBC and WOTLK.
- TODO integration: replace template character fields with authoritative worldserver snapshot state and produce a baseline RaidSimRequest.
- TODO integration: mutate one candidate equipment slot, run baseline/candidate through the same preset and return the exact delta.


### Addon layout-safety follow-up

- PASS (CI base `998d297a`): WoWSims preset image harvest is exact-head green for all three eras.
- STATIC: GearAdvisor v0.3.1 uses a 638px panel, a 34px era notice region and a 72px explanation/result region.
- STATIC: no-icon Group Composer buttons anchor labels to both left and right insets.
- STATIC: Activity Browser cards use 88px card height / 96px row stride and a 28px two-line status region.
- STATIC: Recommendations use 228px cards / 236px stride and keep reason/readiness copy narrower than the action column.
- STATIC: equivalent geometry exists in checked-in `GroupComposerModernUI.lua`.
- TODO runtime: GearAdvisor class/spec, mode toggle, close button and top info line do not overlap at normal and narrow UI scales.
- TODO runtime: long era warnings and sim explanations stay inside GearAdvisor without touching stats/footer/WoWSims button.
- TODO runtime: Activity Browser locked reasons/support labels remain inside their cards and never overlap Favorites or the next row.
- TODO runtime: Recommended Activity reason/readiness copy never overlaps Configure/View Unlocks or adjacent cards.


### WoWSims baseline request-construction slice

- PASS: addon layout/source contracts are exact-head green at `c9690919ab40c8d40c3af20fdb2e5847ca59bbf3`.
- STATIC: `POST /v1/snapshot/request` exists and returns `REQUEST_BUILT_UNVALIDATED`.
- UNIT: authoritative character fields replace preset character fields while rotation/spec options/consumes/buffs/encounter/simOptions remain unchanged.
- UNIT: preset canonical SHA-256 is reverified before overlay.
- UNIT: an ambiguous route with multiple presets requires explicit `presetSha256`.
- UNIT: WotLK glyph spell IDs map to glyph item IDs and unknown mappings fail closed.
- UNIT: Vanilla profession/race restrictions and pre-WotLK DK restrictions remain enforced.
- UNIT: negative AzerothCore random-property ID maps to Classic/TBC randomSuffix; positive random-property IDs fail closed.
- STATIC: service image copies the WotLK glyph map from the exact pinned engine checkout and requires it at startup.
- STATIC: `.wowsims request` calls the private request-builder endpoint but does not simulate.
- TODO runtime: build a request for a real single-preset route and inspect gear/talents/race/professions/glyphs against the live character.
- TODO runtime: choose explicit preset IDs for ambiguous routes before automatic simulation.
- TODO: meta-gem enabled/disabled semantics must be verified for TBC/WotLK before affected routes become authoritative.


### Candidate request isolation + GearAdvisor v0.3.2

- PASS: baseline authoritative request builder exact-head green at `f3e17eb7dec14e5dcb272c77c981bef798aa320d`.
- UNIT: candidate builder accepts only slotIndex 0-16.
- UNIT: baseline/candidate pair must have at least one difference.
- UNIT: every recursive diff path must live under the selected `raid.parties.0.players.0.equipment.items.<slot>` subtree.
- UNIT: replacing only that selected-slot object makes the full requests structurally equivalent.
- UNIT: nonzero WotLK random-property state is rejected because pinned WotLK ItemSpec has no suffix/property field.
- STATIC: GearAdvisor v0.3.2 anchors both key-stat labels and values at `-370 - (i - 1) * 18`.
- TODO runtime: verify all seven key-stat rows visually align on 3.3.5a at normal/narrow UI scale.
- TODO next: server-authoritative inventory enumeration must feed candidate objects without trusting client-exported item state.
