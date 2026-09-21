# Current State

_Last rewritten: 2026-09-21_


## Current integrated ERA-07 vendor/reward candidate

Status: **DONE + exact-head local-CI green at `66c13cb1638fcb64fa66c3f96ab79c4490a072db`**.

Codex implemented the bounded automated vendor/reward-helper slice at source SHA `9499939ed190af2d68989d69a99f7a58468be042`; it was integrated onto the newer WoWSims line by merge `304aee8d759e52aa231705a91cc92417e43c206c`, then documented and proven through all four required workflows at `66c13cb1...`.

Covered boundaries:
- Titan Rune Sidereal/Scourgestone scripted vendor visibility and purchases;
- Scourgestone -> Sidereal exchange;
- durable pending Titan Rune encounter rewards;
- automatic Gamma signet grants;
- AI Guild conserved-stock mail, stock conservation, automated real-AH buying and surplus listing;
- player-facing AI Guild deposit/withdraw/mail/buy helpers;
- central provenance overrides for custom Titan Rune currencies/signets;
- new `.era audit` sections for vendor catalogs, pending rewards, AI Guild stock and queued automated purchases.

All covered paths fail closed before spending currency or mutating protected item/stock/treasury/request/delivery state when provenance is unavailable or the item is future/UNKNOWN. Codex's focused Python/codestyle/self-tests passed before integration; no full C++ build was performed on that source commit.

Still outside this slice: `TitanRuneLoot.cpp` protocol loot injection, AI Guild recipe discovery / `TryCraftQueuedFromBot`, ordinary loot/crafting/recipes, ArenaRoster PvP gear generation, core-wide quest/NPC/vendor cleanup, and broader Titan Rune spawn/map lifecycle containment. ERA-07 and ERA-13 therefore remain PARTIAL/IN PROGRESS.


## Product status

Group Composer V4 is a **feature-complete candidate under real in-game validation**. Core product work is already present; current development is driven by observed runtime failures, usability problems and validation gaps rather than speculative feature expansion.

### Implemented Group Composer capabilities

- Modern TypeScriptToLua UI shell for the 3.3.5a client.
- Dungeon and Raid composition from 5-player groups through legacy 40-player raids.
- WotLK 10/25 Normal/Heroic support plus Titan Rune Alpha/Beta/Gamma where appropriate.
- Configure → Build & Prepare → Review → Assemble → explicit Teleport lifecycle.
- Existing group members are sticky. Composer does not silently prune them.
- Human anchors, pinned bots, guild-bot preference, world-bot fallback and managed/disposable capacity.
- Role/class/spec requirements with Auto filling remaining slots.
- Subgroup preferences/stability.
- Vanilla/TBC/WotLK era browser, Favorites, Recent.
- Saved dungeon and raid templates.
- Exact unlock modal for level/progression/quest/item/achievement/ilvl/human blockers.
- Ordered prerequisite chains with an explicit NEXT STEP.
- Three-era server gate, caps, progression ceilings and manual TBC/WotLK release.
- Anti-boost bot-level rule: the lowest real human in the planned group defines a +/-3 bot peer band, clamped by the selected activity's minimum level and the live realm cap; managed capacity can be prepared toward that human peer target.
- Co-op whole-human access preflight.
- Multi-human raid lockout conflict detection.
- Persistent real-player raid clear history, stable activity IDs, first guild-clear roster and recent guild-clear timeline.
- Active raid-lockout awareness and Resume active lockout recommendations.
- Recommended Activities using progression, gear, planner feasibility, guild context, lockouts and eligible online WoW friends.
- Encounter-readiness warnings from the curated raid leader ledger.
- Human gear floor/target advisories.
- Why This Bot explanations.
- Group Actions: Rebuild/Repair, Leave Instance Together, safe Composer disband.
- Activity Diagnostics page.
- Utility Coverage details with numeric provider counts and present/missing major raid-buff families.

### First runtime pass, fixed

User testing exposed and we fixed:

- ACTIVITY protocol format mismatch that spammed `Wrong format occurred` and left activities on CHECKING ACCESS.
- Progression/Recommended/Diagnostics overlapping the main Composer workspace.
- False raid CLEARED state caused by treating progression stage as proof of a boss kill.
- Broken star glyphs in Favorites on the Wrath client.
- Locked activity cards being dead instead of opening Unlock Requirements.
- Utility Coverage being too vague.

Verified green checkpoint after this pass: `a7f583b9...`.

### Second runtime pass, fixed

User testing then exposed and we fixed:

- Existing Playerbots were preserved by the backend planner but hidden from the client anchor snapshot.
- Composer UI now treats existing humans and existing Playerbots as locked current-group members and fills only missing roles.
- Newly prepared bots could enter stock RDF with stale Dungeon Finder lock caches.
- Composer now refreshes LFG lock state after preparation and again immediately before handoff.
- RDF handoff verifies that Blizzard Dungeon Finder actually enters role-check instead of reporting success blindly.
- Build Selector class/spec text clipped outside cards.
- Recommended Activities cards overflowed vertically.
- Raid Template tabs could retain stale positions and overlap.
- Diagnostics wording did not explain that WARN means experimental/partial Playerbots support rather than structural failure.

Verified green checkpoint after this pass: `3b548b3d29539a1ae0816d10db0e943546d3626c`.

## Latest green development pass

Latest fully verified green implementation checkpoint: `e96d009552b01a84d7e70f4a8956b33b34900843`

Exact-head CI: client checks **SUCCESS**, backend staging **SUCCESS**, Group Composer compile **SUCCESS** on `stoffes-pc`, Integration **SUCCESS** on `stoffes-pc`. Documentation head `253c2288` is also fully green.

This head includes runtime pass 3 plus ERA-01/ERA-02 containment, ERA-06 AH profiles, and ERA-07 slices 1-2 including central item provenance, existing-auction/stored-bot audits and deterministic RaidRoster/Composer gear gating. Current Group Composer version is **0.15.3**.

### Client addon bundle / GearAdvisor pass

Status: **DONE + exact-head GitHub-hosted CI green at `de842ba842721f32d588ba5d9818b872f9a6c805`**.

- `fetch-client-addons.sh` adds NoM0Re/WeakAuras-WotLK release `5.22.0-b3706bd4` with its published SHA-256.
- The old Bunny67 WeakAuras 4.0.0 fallback is deliberately not used.
- Details uses the maintained `5Buttons/Details-WotLK` fork pinned to `a2372618...`.
- New local `GearAdvisor` addon anchors to the right side of the Character frame and shows detected class/spec/role, equipped average item level, boss-oriented caps/targets, current key stats and a stat-priority explanation.
- GearAdvisor covers every WotLK talent tree. Feral can switch Cat/Bear and Death Knight trees can switch DPS/Tank modes.
- Hard-cap rows are distinct from priority guidance. Hit targets account for relevant self-talents when detectable; expertise/defense/ArP targets are shown only where they make sense.
- GearAdvisor reads the server-reported realm era from Group Composer when available and uses era-aware baseline hit/defense rules. Advanced priority prose is presently WotLK-oriented; full Vanilla/TBC priority profiles remain future polish.
- The superseded `ExtendedCharacterStats` source is retained for history but skipped by the distributed bundle, preventing duplicate character-side panels.

GearAdvisor v0.2.0 polish status: **DONE + exact-head GitHub-hosted CI green at `6d472bc0b594e401816925c7f9552a3e60b1d848`**.
- Panel grows from 352x506 to 390x574 and uses a cleaner native tooltip-style border/background with section dividers.
- Detected talent-tree icon appears in the header; class/spec/role identity is class-colored.
- Cap rows are true two-column rows rather than one long FontString, preventing rating/shortfall text from colliding with the cap label.
- Hovering a cap explains what the target means and shows the full current/target detail.
- Key-stat capacity increases from six to seven; Feral Cat now visibly includes melee hit, and several haste-sensitive melee profiles expose haste instead of silently omitting it.
- The side panel flips to CharacterFrame's left when the right side would exceed the screen width and is clamped on-screen.
- The potentially overlapping CharacterFrame `Advisor` text button is removed; the panel owns a normal close button and `/ga` remains the reopen/toggle path.
- Vanilla/TBC visibly mark the detailed priority as a **WotLK reference** while their cap math remains era-aware.
- Arms Armor Penetration uses 1260 rating as its Battle Stance baseline reference; the tooltip notes weapon specialization/proc soft-cap caveats.
- Runtime visual acceptance remains TODO until the 3.3.5a client is available.

### Runtime pass 3 implementation

Code/CI status: **DONE**. Runtime acceptance status: **TODO**.

Implemented in addon/server version 0.15.0:

- Playerbot Dungeon Finder proposals auto-agree deterministically at proposal construction; real players keep normal Accept/Decline control.
- Activity Browser and Progression default to the highest released era relevant to the character rather than blindly opening WotLK.
- Dungeon difficulty rows can be visible-but-locked with reasons; impossible/inapplicable Heroic and Titan Rune choices cannot be selected.
- Changing to a dungeon incompatible with the previous difficulty resets the configuration to Normal.
- Difficulty validity follows the **selected activity's era**, so a WotLK realm never turns a Vanilla dungeon such as Ragefire Chasm into a valid Heroic/Titan activity.
- Recommendation cards have larger structured reason/readiness space.
- Unlock Requirements is layered as a child of Activity Browser instead of fighting it as a sibling dialog.
- Human-anchor rows use a proper one-icon class position.
- Bot level/preparation policy follows the **lowest real human** in the reviewed group with a +/-3 band, dungeon-floor clamp and live-realm-cap clamp.
- The policy is generic: **whatever the lowest real-human level is** becomes the peer target. A level-80 + level-14 group was only an illustrative example; level 80 + 23 targets 23, and 47 + 44 + 31 targets 31.
- Review/status now exposes the computed peer target and allowed bot band directly so arbitrary mixed-level cases can be verified in game.
- Solo high-level characters may run trivial legacy content with high-level peer bots without being treated as boosting a lower human.

### Earlier low-level validation lane on a WotLK dev realm

Problem: the dev realm's normal AdventureStart default can intentionally boost brand-new characters to TBC/WotLK starter profiles, which makes true level-1/low-level Group Composer validation impossible.

Implemented solution:

- GM-only `.ap nextstarter vanilla`.
- Account-scoped, in-memory, one-shot override.
- Consumed only by the next eligible newly-created non-DK character first logged in on that account.
- That character receives `VanillaFresh`, which leaves it at a genuine level 1 with no raid-ready boost.
- Realm era is unchanged.
- Normal realm starter default is unchanged.
- Override auto-clears after consumption.
- `.ap nextstarter status` shows whether it is armed.
- `.ap nextstarter clear` cancels it.
- Server restart also clears it by design.

This is test tooling, not a friends-realm gameplay feature. It is compiled and CI-verified; its in-game one-shot behavior is still a runtime test.

## ERA-01 central era policy

Status: **IN PROGRESS**.

Slice 1 is exact-head local-CI green at `943d70b7`.

First implementation slice:
- added `EraPolicy.h/.cpp` as the server-authoritative policy API for realm era identity, 60/70/80 caps, progression ceilings/minimums, release comparisons, display/key parsing and applying the active era to Individual Progression;
- removed the duplicate `AdventureEra` enum by aliasing Adventure Catalog to `EraPolicy::Era`;
- Adventure Catalog era/cap/release helpers now delegate to EraPolicy rather than re-deriving policy;
- removed AdminPanelExpansion's separate `g_currentEra`, duplicate 60/70/80 table and duplicate Vanilla/TBC progression ceilings;
- AdminPanelExpansion is now a compatibility facade over EraPolicy, preserving existing Admin Panel call sites while establishing one source of truth;
- the active era is derived from Individual Progression's live progression ceiling, so startup cannot disagree merely because module initialization order differs.

Slice 2 is exact-head local-CI green at `1e3e9d5f`: starter/catch-up availability, player progression shortcuts, direct Composer Titan Rune access and bot progression synchronization now consume EraPolicy.

Slices 3, 4a and 4b are cumulatively **DONE + exact-head local-CI green at `1e6f01f`**:
- Map.dbc-backed era policy gates Admin Panel teleport/goto/summon/saved-location travel and Group Composer instance travel.
- Playerbots runtime random-bot maximum + bracket snapshot follow the live 60/70/80 cap; Composer and automated RaidRoster preparation hard-fence over-cap bots.
- Stored/ungrouped RNDbots above the cap are quarantined non-destructively rather than downlevelled/deleted; grouped bots are not yanked mid-run.
- The final wrapper-patch hunk-count repair was compile-verified on `stoffes-pc`.

ERA-01 is **not DONE yet**. AH, global bot population/geography, professions, vendors, travel, classes/races, PvP and other systems still need migration/enforcement.

## ERA-02 integrity scanner

Status: **IN PROGRESS**.

GM-only `.era audit` is read-only and now covers central cap drift, online/stored RNDbot quarantine, Outland/Northrend map gates, future Composer-map leakage, active bot class/race/profession leaks and ERA-06 AH profile drift. ERA-07 slice 1 adds a generated provenance-profile/coverage section. Existing-auction item scans, equipped-item provenance, vendors/rewards, PvP and broader world enforcement remain TODO.

Group Composer 0.15.3 also hides Death Knight from the Build Selector before WotLK and clears a stale preselected DK build when the selector opens on an earlier-era realm.

## Era-fidelity architecture pass

Canonical design is now recorded in ERA_FIDELITY.md.

Current assessment:
- **DONE foundations:** three-era progression/level-cap spine, activity-era catalog gates, manual expansion hold/advance foundation, Era Talents, bot-to-master era synchronization and Composer anti-boost foundation.
- **PARTIAL:** global bot population containment, Group Composer era presentation/templates/subgroup logic, AH profiles, class/race/profession policy, map/travel gates, integrity scanning, snapshot/rollback and expansion orchestration.
- **IN PROGRESS:** ERA-07 reproducible item chronology. AH automated listings are the first consumer; bot gear/starter/catch-up/vendors/rewards and live-auction scans still need the same policy.
- **TODO:** remaining profession trainers/recipes, vendor/currency/reward gates, transport/flying/PvP/convenience/Guild Bank lifecycle and deeper old-world leakage auditing.

The friends-realm rule is additive and forward-only: TBC keeps legitimate Vanilla content; WotLK keeps legitimate Vanilla + TBC content. Future-era content may never leak backward.

## Planning / idea-bank state

Verified accepted-roadmap checkpoint: `b1d1d896c9b1b4f249532de0d6b5244e40615798`.

Exact-head CI for that checkpoint: client checks **SUCCESS**, backend staging **SUCCESS**, Group Composer compile **SUCCESS** on `stoffes-pc`, Integration **SUCCESS** on `stoffes-pc`.

The user has now explicitly approved the full set of 20 era-relevance improvements and 20 broader server features. `MASTER_ROADMAP.md` is the canonical execution board with stable IDs, statuses, dependencies and cross-off rules. `FEATURE_IDEAS.md` remains the longer design/rationale bank. Approval does **not** mean implementation; individual roadmap items remain TODO/PARTIAL until completed and proven.

Immediate execution remains the already-built P0 runtime validation. Once that is stable, the first new architecture pass is ERA-01 Central Era Policy + ERA-02 Era Integrity Scanner because the other era features depend on one source of truth and measurable leak detection.

## Known current runtime state

The pass-3 implementation is now exact-head CI green at `91f8cff1beeb6d09875c60a1b1aee7fab662c20f`.

Already observed in game before this fix:
- low-level activity level gating works;
- WotLK Random Heroic reaches Blizzard RDF role-check and QUEUED.

Still requiring in-game retest after deployment:
- Playerbots accept the later RDF dungeon proposal and the party proceeds instead of timing out;
- Recommendation text remains inside cards;
- human-anchor class icon placement is correct;
- Unlock Requirements cleanly overlays Activity Browser;
- low-level Activity Browser and Progression open on Vanilla/relevant character era;
- impossible Heroic/Alpha/Beta/Gamma choices are visibly locked;
- lowest-real-human +/-3 peer policy behaves correctly for solo and mixed-level human groups.

Do not convert those TODOs to PASS from CI alone.

## P0.5 security / addon launcher pass

Implementation status: **DONE + exact-head local CI verified at `8dc94defe9e2a213250017635fc20a219006f237`; runtime validation pending**.

- Azeroth Control already had GM-only server command registrations for privileged actions. This pass adds a harmless server authorization probe so the addon can know whether the current session is actually GM-authorized.
- Non-GM clients keep the Azeroth Control minimap button hidden, cannot keep the panel frame shown, and `/ap` / `/adminpanel` will not open privileged UI.
- The client-side gate is defense-in-depth only; privileged `.ap` commands remain `SEC_GAMEMASTER` server-side, so a modified addon cannot grant itself authority.
- Group Composer addon version 0.15.2 adds a stock-texture minimap launcher. Clicking it toggles the same modern dashboard as `/gc`; slash commands remain available as fallback.

## Realm / server direction

- Current realm remains permanent development/test realm.
- Future friends realm starts clean at Vanilla with fresh character/guild/progression state.
- Manual release gates open TBC and later WotLK.
- Public layout target:
  - `skrra.dev`: existing portfolio.
  - `wow.skrra.dev`: WoW realm hostname.
  - `join.skrra.dev`: optional registration/download/instructions site.
- Expose only TCP 3724 and 8085 for WoW.
- Keep MySQL 3306, SOAP 7878, raw webreg 8090, lore 8091 and Ollama 11434 private.

## FEATURE-19 safe snapshot / rollback foundation

Status: **PARTIAL / IN PROGRESS**.

- New `realm-snapshot.sh` wraps the existing DB backup and enriches it with realm profile, overlay Git SHA/branch/dirty state, actual core/module Git SHAs, repo pins, SQL migration inventory and the persistent server/module config tree.
- `--purpose release-transition` fails closed unless the installed realm explicitly has `REALM_PROFILE=friends`, `RELEASE_OPERATIONS=1` and a clean overlay worktree. Existing installs with no marker are treated as `dev`.
- `restore.sh` recognizes enriched snapshots and refuses profile mismatch or overlay-SHA mismatch unless an explicit dangerous override is supplied.
- A friends realm refuses legacy/unidentified backups by default.
- Enriched restore reapplies the saved persistent config tree after setup regeneration and restarts auth/world services.
- This is the safety primitive for future expansion transitions. It does not yet provide the Admin Panel/Command Center release button or automatically checkout an old Git SHA.

## ERA-06 Auction House profiles

Status: **PARTIAL / IN PROGRESS**.

- `configure-ahbot.sh` now has explicit `vanilla`, `tbc`, and `wotlk` seller profiles.
- New listings use an equip/use-level ceiling of 60/70/80.
- Vanilla zeros every Gem and Glyph listing proportion; TBC enables Gems but keeps Glyphs off; WotLK enables both.
- WotLK-specific custom boost IDs are scrubbed before every profile and re-added only by the WotLK profile.
- Fresh installs default `AHBOT_ERA_PROFILE=vanilla`; unmarked existing installs remain WotLK-compatible until explicitly changed.
- `.era audit` checks enabled AH profile name, seller level ceiling and Gem/Glyph gates against live EraPolicy.
- Category/use-level containment is now being paired with ERA-07 provenance rather than pretending level proves chronology.
- Profile changes do not delete existing auctions; friends-realm progression is forward-only.

## ERA-07 item expansion provenance

Status: **IN PROGRESS — slices 1 and 2 DONE; slice 2 exact-head local-CI green at `e96d009552b01a84d7e70f4a8956b33b34900843`**.

- A deterministic generator compares exact pinned CMaNGOS Classic/TBC/WotLK `item_template` identities and classifies the live AzerothCore world item IDs by earliest database era.
- Source commits, compressed dump byte sizes and Git blob SHAs are pinned in `data/era-item-provenance/sources.json`; downloaded dumps live only in the ignored cache.
- No required-level, item-level or item-ID threshold is used as provenance.
- IDs absent from all three source snapshots are **UNKNOWN** and fail closed for automated AH listings until reviewed in `overrides.csv`.
- `configure-ahbot.sh` generates a profile-specific compact blocklist and publishes provenance metadata into AHBot config.
- Patch `0043-ahbot-era-provenance-filter.patch` makes the pinned AH bot consume the dedicated provenance blocklist without overwriting operator `DisabledCustomItemIDs`.
- `.era audit` reports provenance profile/source/live-item coverage and WARNs when UNKNOWN IDs remain blocked.
- This slice protects **new automated AH listings only**. Existing auctions, bot gear/prep, starter/catch-up, vendors/rewards and other item-producing systems remain later ERA-07/ERA-02 work.
- Exact-SHA CI evidence for slice 1: client checks **SUCCESS**, backend staging **SUCCESS**, Integration **SUCCESS** on `stoffes-pc`, Group Composer V4 compile **SUCCESS** on `stoffes-pc`.

Slice 2 implementation:
- new `configure-era-item-provenance.sh` owns generation independently of AHBot and writes **all three** Vanilla/TBC/WotLK blocklists into the persistent RaidRoster config;
- setup/update regenerate the central snapshot from the live `item_template` set and restart/recreate worldserver so every consumer sees the same chronology;
- the generator now fingerprints the exact live world item-ID set; EraPolicy verifies count + fingerprint before trusting any blocklist;
- EraPolicy exposes central item provenance readiness, earliest-era lookup and `IsItemAllowed(itemId)`; UNKNOWN or stale/unavailable provenance fails closed;
- automated `RaidRosterGear::EquipForSpec`, including Group Composer full preparation, refuses to strip/regear when provenance is unavailable and dynamically excludes future/UNKNOWN candidates;
- `.era audit` now scans **existing auction stock** and stored RNDbot equipped items against the same central policy;
- `EquipCatchup`, starter/catch-up packages, vendors/rewards and other item-producing paths are intentionally still outside this slice and remain TODO.

Slice 2 exact-SHA CI: client checks **SUCCESS**, backend staging **SUCCESS**, Integration **SUCCESS** on `stoffes-pc`, Group Composer V4 compile **SUCCESS** on `stoffes-pc`.

Slice 3 implementation status: **DONE + exact-head GitHub-hosted CI green at `e990dff5cd6e8c7fa317d4b94840320eb6b73adb`**.

- PlayerbotFactory receives narrow external item-policy callbacks without a direct dependency on mod-raid-roster.
- RaidRoster registers `EraPolicy::ItemProvenanceReady` + `EraPolicy::IsItemAllowed` as those callbacks.
- `tools/apply-playerbot-era-item-policy.py` runs after all wrapper patches and EraTalents in fresh setup, update, Integration CI and Group Composer compile CI.
- The transformer uses strict semantic markers and aborts if the fully assembled PlayerbotFactory shape drifts; static patch `0044` is retired.
- AutoGear/InitEquipment fails before second-chance equipment destruction when provenance is unavailable/stale.
- Start-outfit candidates, PvP trinkets, normal equipment candidates, bags, ammo, potions, food, generic factory-stored items and gem-item candidates are vetoed by central item provenance.
- Existing EraTalents/Playerbots item-ID or RequiredLevel heuristics are not chronology truth. They remain only as extra conservative restrictions where present.
- AdventureStart refuses item-producing profiles before progression/level/starter-state mutation when central provenance is unavailable.
- Explicit AdventureStart supply grants call `EraPolicy::IsItemAllowed`.
- `.catchup` refuses before progression unlock or one-time claim mutation when provenance is unavailable, and `EquipCatchup` has a defensive readiness guard.
- Item provenance does not yet prove enchant-spell chronology.

Exact-head `e990dff5` CI: client checks **SUCCESS**, backend staging **SUCCESS**, Integration **SUCCESS**, Group Composer V4 compile **SUCCESS**, all using GitHub-hosted CI while `stoffes-pc` is offline.

### ERA-07 slice 4 — Adventure Cache direct rewards

Status: **DONE + exact-head GitHub-hosted CI green at `e1a2e6fa89e375290247b42099c12dca8203c414`**.

- Adventure Cache is a custom item-producing reward path outside PlayerbotFactory.
- Cache opening checks `EraPolicy::ItemProvenanceReady()` before consuming the pending one-shot reward.
- Spec-aware cache gear candidates and direct potion/gear storage call `EraPolicy::IsItemAllowed`.
- If provenance is stale/unavailable, the pending cache remains intact for retry after repair.
- Exact-head CI: client checks SUCCESS, backend staging SUCCESS, Group Composer V4 compile SUCCESS, Integration SUCCESS.
- Ordinary vendors/rewards, loot/crafting/recipes and other non-PlayerbotFactory item sources remain later work.


GearAdvisor v0.2.1 follow-up: **DONE + exact-head local-CI green at `1f5ef71cef6d1d18dc33e25a876f6e50b7d1caa5`**.
- narrow-resolution anchoring measures usable space on both sides of CharacterFrame;
- when neither side fully fits the 390px panel, it chooses the side with more space and relies on screen clamping only for the small remainder;
- runtime visual acceptance remains TODO.

GearAdvisor v0.3 / WoWSims integration: **IMPLEMENTED FOR FIRST BRIDGE SLICE / exact-head local CI required**.
- `WoWSimsBridge` is a new Interface 30300 addon packaged from `client-addons-src/`.
- server-reported era routes exports to Vanilla `wowsims/classic`, TBC `wowsims/tbc-new`, or WotLK `wowsims/wotlk`; level fallback is labeled.
- character export includes gear IDs/enchants, TBC/WotLK gems, Vanilla/TBC random suffix, talents, professions and WotLK glyphs.
- bag export supports WoWSims batch/top-gear workflows.
- GearAdvisor no longer displays `profile.priority` as upgrade authority; it keeps era-valid mechanical caps/current stats and links directly to WoWSims Bridge.
- the future automatic backend will run pinned `wowsimcli` baseline/candidate requests and return sim-backed trade explanations.
- Pawn/static weights are explicitly not the final upgrade decision path.
- unsupported/unvalidated era/spec models must return UNSUPPORTED/LIMITED rather than fabricated percentages.
- canonical integration design: `docs/group-composer-v4/WOWSIMS_INTEGRATION.md`.


### WoWSims bridge CI repair

Exact head `97178c406f5a009b945b6950af3fd40d605990fc` is **FAILED / superseded** because the client-check workflow file was malformed during repository editing and GitHub could not create the validation job. Backend staging succeeded; heavy jobs from that SHA do not make it a valid checkpoint because the required client workflow failed before execution.

Repair: rebuild `.github/workflows/stage-group-composer-v4-client.yml` from exact green parent `1f5ef71c`, reapply only the intended WoWSims assertions, and rerun via `[local-ci]`.


### WoWSims automatic simulation backend foundation

The repaired WoWSimsBridge/GearAdvisor checkpoint `c420b300cf41455c7f20630b37fdbe37e4b744b4` is now **fully green**: Group Composer client checks, Stage Group Composer V4 backend, Group Composer V4 compile and Integration build all completed successfully for that exact SHA. The two heavy jobs used the intended local-CI route.

Current implementation adds the first server-side simulator service foundation:

- `wowsims-service/Dockerfile` builds the exact pinned Classic, TBC and WotLK `wowsimcli` revisions;
- `/health`, `/v1/sim` and `/v1/compare` provide a private internal contract;
- compare returns baseline/candidate DPS or HPS plus absolute/percent delta;
- simulator execution is era-allowlisted, timeout-bounded and concurrency-bounded;
- `configure-wowsims-service.sh` inserts `ac-wowsims` into the generated Compose override using Docker `expose` only, never a host-published port;
- setup/update are wired to configure/build the service.

This is **not yet the final automatic GearAdvisor path**. The remaining adapter must construct a validated WoWSims request from authoritative server character state, perform the candidate-slot swap, call the service and send the result/explanation back to the 3.3.5a addon.


### Authoritative WoWSims character snapshot

The simulator-service foundation checkpoint `aba336fd00fae61ac1b2e12af070eba1359b0917` is **fully green on all four exact-SHA workflows**, including both heavy builds on `stoffes-pc`.

The next integration slice is now implemented for CI validation:

- worldserver builds the 17-slot WoWSims equipment snapshot from live server item instances, not client guesses;
- permanent enchant IDs and socket enchantments are resolved back to gem item IDs through `SpellItemEnchantment.dbc`;
- active talent ranks are reconstructed from the live Player talent map in DBC row/column order;
- active role, dominant tree, glyph properties/spells, professions, race/class, level and live EraPolicy are included;
- `.wowsims snapshot` provides a cheap in-game serialization diagnostic;
- `.wowsims validate` posts the snapshot to the private `ac-wowsims` service;
- the service rejects future-era classes, level-cap drift, malformed talents and non-17-slot gear payloads;
- accepted models remain explicitly `AVAILABLE_UNVALIDATED`, so structural routing cannot accidentally become a fabricated upgrade verdict.

This is still a diagnostic validation path. Full item simulation will use an asynchronous request path rather than blocking the world thread.


### Pinned WoWSims model coverage catalog

The authoritative worldserver snapshot checkpoint `0e4fadb25c06462fb485831bb0875b07979b0ff4` is **fully green** on all four exact-SHA workflows:

- Group Composer client checks: SUCCESS;
- Stage Group Composer V4 backend: SUCCESS;
- Group Composer V4 compile: SUCCESS on `stoffes-pc`;
- Integration build: SUCCESS on `stoffes-pc`.

Current implementation makes model routing data-driven:

- `data/wowsims/model-support.json` records the exact pinned repo/commit and `proto/api.proto` Git blob for Classic, TBC and WotLK;
- the catalog records every proto spec field exposed by those pinned engines and the class/tree/role routes we may use;
- `tools/verify-wowsims-model-support.py` rejects pin drift, unknown proto fields, duplicate expanded routes and pre-WotLK Death Knight routes;
- the private service exposes `GET /v1/models` for diagnostics;
- snapshot validation now returns `UNSUPPORTED` when no catalog route exists instead of inventing a nearby model;
- catalogued routes return `ENGINE_PRESENT_UNVALIDATED`, deliberately weaker than SIM-BACKED.

The next step is a pinned preset contract for buffs/debuffs/consumes/rotation/encounter defaults, followed by actual RaidSimRequest construction and candidate slot mutation.


### Engine-native preset harvesting

`7c9591511ff25839812bfc99e78cf8cec4f5e9bd` is fully green: client checks SUCCESS, backend staging SUCCESS, Integration SUCCESS on `stoffes-pc`, and Group Composer V4 compile SUCCESS on `stoffes-pc`.

The next WoWSims slice is staged around a fail-closed preset harvester:

- the harvester temporarily instruments the exact pinned upstream test harness only inside the Docker builder;
- it discovers spec tests that call `core.RunTestSuite` and extracts only the already-built **Average** `RaidSimRequest`;
- it does **not** run those simulations during extraction;
- it classifies every harvested request against `model-support.json` by real proto spec field, dominant talent tree and tank/healer/DPS role;
- an unclassified harvested request fails the image build rather than being ignored;
- stats-only upstream models naturally produce no RaidSimRequest preset. For example, the pinned TBC healer-priest suite is stats-only, so no healing rotation is invented;
- each era receives a generated `preset-index.json` with request SHA-256s and route coverage;
- the service exposes preset readiness/coverage through health and `GET /v1/presets`;
- the runtime image requires the three generated preset indexes;
- the backend workflow performs a real Docker image build only when simulator runtime inputs changed, avoiding three-engine rebuilds on unrelated Group Composer commits.

This still does not promote any route to SIM-BACKED. The next slice must apply authoritative character state to a harvested preset and validate baseline/candidate request construction.


### WoWSims real-image build prerequisite repair

The first engine-native preset SHA `2027a2d2` intentionally failed the new real Docker gate before harvesting. A pristine pinned Classic checkout does not contain generated Go protobuf files, so direct `go build` is invalid. The repair now generates protobufs from the pinned source and builds each CLI with upstream `with_db` release semantics; TBC keeps its explicit descriptor.proto mapping. No model has been promoted to SIM-BACKED from this failure.


WoWSims preset harvester follow-up: `dcbc4201` proved protobuf generation + pristine Classic CLI build are correct, then failed because discovery included underscore-prefixed disabled legacy packages that normal Go traversal ignores. The harvester now mirrors Go directory-ignore rules instead of maintaining a spec blacklist.


Preset-harvester progress: `365c194e` successfully completed the Vanilla engine build and harvested 24 unique Classic requests across 15 routes. TBC stopped before build because distro `protoc` needed `/usr/include` added explicitly for `google/protobuf/descriptor.proto`; the repair preserves the upstream descriptor mapping and only adds the missing include path.


Preset-harvester dependency follow-up: `72062c78` reconfirmed the Classic 24-request/15-route harvest, then proved the missing TBC descriptor was a package-content issue rather than an include-path issue. Debian Bookworm ships the standard proto definitions in `libprotobuf-dev`; the builder now installs it explicitly because `--no-install-recommends` suppresses that recommended dependency.


### WoWSims preset harvesting green + addon layout safety

Exact SHA `998d297a7f38e941740c41bdc972842157de0e97` is fully green on all four workflows. Its real Docker build harvested 24 Vanilla requests across 15 routes, 15 TBC requests across 15 routes, and 37 WotLK requests across 33 routes. All three preset catalogs report ready.

Current client layout-safety work:
- GearAdvisor is bumped to v0.3.1 and gains extra vertical space for simulation guidance, realm-era warnings and returned explanations;
- the header separates class/spec from role/ilvl/era so variant controls do not compete with long spec labels;
- generic no-icon Group Composer buttons now bind labels between left/right insets rather than using a single unbounded center anchor;
- Activity Browser cards gain taller bounded title/detail/status regions and a two-line support/status area;
- Recommended Activities gains bounded title/meta/reason/readiness areas and a reserved right-side action column;
- the TypeScript source and checked-in `GroupComposerModernUI.lua` contain the same geometry changes.

This pass is exact-head CI green at `c9690919ab40c8d40c3af20fdb2e5847ca59bbf3`. Real-client screenshot/runtime acceptance is still required before the visual acceptance rows become PASS.


### Current WoWSims request-construction slice

The next bounded slice constructs a real baseline RaidSimRequest from the authoritative worldserver snapshot without running the simulator yet.

Implemented in the current candidate:
- new `POST /v1/snapshot/request` endpoint;
- validates the snapshot/model route, loads one exact harvested preset and verifies its canonical SHA-256;
- preserves preset-owned rotation/APL, spec options, consumes, individual/party/raid buffs, debuffs, encounter and sim options;
- overlays server-owned name, race, class, exact 17-slot gear, permanent enchant effect IDs, gem item IDs, talent string and professions;
- WotLK glyph spell IDs are translated to WoWSims glyph item IDs using the pinned engine's own `assets/db_inputs/glyph_id_map.json`;
- Vanilla rejects Blood Elf/Draenei and pre-WotLK rejects Death Knight;
- profession availability is era-gated;
- Classic/TBC random suffixes map only from AzerothCore's negative random-property ID convention; positive random-property IDs fail closed instead of being guessed;
- routes with multiple engine-native preset candidates require explicit `presetSha256` instead of arbitrary selection;
- returned status is `REQUEST_BUILT_UNVALIDATED`. It does not run WoWSims and does not grant SIM-BACKED authority;
- `.wowsims request` provides an in-game diagnostic for single-preset routes.

Known follow-up:
- select/validate canonical presets for ambiguous routes;
- validate meta-gem activation semantics where needed;
- add candidate-slot mutation and prove baseline/candidate differ only in the intended slot;
- move actual simulator execution/result delivery to the asynchronous queue path.


### Exact-green baseline request checkpoint

`f3e17eb7dec14e5dcb272c77c981bef798aa320d` is fully green:
- Group Composer client checks: SUCCESS;
- Stage Group Composer V4 backend: SUCCESS, including the real three-engine Docker image and pinned WotLK glyph map;
- Group Composer V4 compile: SUCCESS on `stoffes-pc`;
- Integration build: SUCCESS on `stoffes-pc`.

### Current candidate request + addon alignment slice

The next exact-head candidate:
- builds baseline/candidate RaidSimRequest pairs from one authoritative snapshot and one exact pinned preset;
- changes exactly one caller-selected equipment slot;
- computes recursive request difference paths and rejects any difference outside that slot;
- rejects no-op candidates and slot indexes outside 0-16;
- explicitly rejects nonzero WotLK random-property state because the pinned WotLK ItemSpec cannot encode it;
- remains diagnostic/unvalidated and does not execute WoWSims;
- GearAdvisor advances to v0.3.2 and fixes the seven key-stat values that were still anchored 32px above their labels;
- footer wording changes from “Sim-backed upgrades” to “WoWSims upgrade authority” until automatic result transport is truly live.

Future “Sim Bags” candidate capture should stay server-authoritative: read the actual bag `Item` objects in worldserver and derive candidate state there rather than trusting client-parsed enchant/gem/suffix data.


### Server-authoritative Sim Bags candidate enumeration

Status: **DONE + exact-head local-CI green at `52ac52552ff0a2c0920b391961887f52dd9ee7b6`**.

- `8d3ff2be...` is fully green and is the prerequisite candidate-isolation checkpoint.
- worldserver scans the player's actual backpack and equipped bag contents, not addon-exported item strings;
- every item is filtered through central ERA-07 item provenance and `EraPolicy::IsItemAllowed`;
- each candidate is tested through AzerothCore `Player::CanEquipItem` against the exact 17 WoWSims equipment slots while ignoring temporary combat/death restrictions;
- swaps that would secretly mutate a second slot, notably a non-Titan-Grip 2H main-hand swap that clears an occupied offhand, are excluded from this one-slot pipeline;
- the service endpoint `POST /v1/snapshot/bag-candidates` reuses one authoritative baseline request, validates every proposed slot mutation through the same candidate isolation guard, and returns request fingerprints/counts rather than sim results;
- exact no-op swaps are skipped rather than treated as errors;
- `.wowsims bags` exposes the manifest boundary in game for diagnostics;
- status remains `BAG_CANDIDATES_BUILT_UNVALIDATED`. No `wowsimcli` execution occurs.

Next after this slice is green: canonical preset selection for ambiguous routes, then asynchronous compare execution/result transport. Automatic addon-triggered simulation remains intentionally disabled until those boundaries are proven.


### Canonical WoWSims preset-selection boundary

Current slice: **IMPLEMENTED / exact-head local CI required**.

- each harvested request receives an assumptions fingerprint after removing only the first player's fields that AzerothCore always overwrites: name, race, class, equipment, talents, professions and glyphs;
- a route with one request is canonical by construction;
- a route with multiple requests is auto-resolved only if all surviving simulator assumptions are byte-canonical equivalent;
- equivalent routes choose the lowest pinned request SHA solely as a deterministic representative because the final overlaid request is identical;
- if candidates still disagree on simulator-owned assumptions, harvesting fails closed and prints the source/request/assumption hashes instead of making an arbitrary choice;
- runtime catalog loading requires exactly one canonical request per route and health exposes canonical-route coverage;
- explicit preset SHA remains available as a diagnostic override, but normal request/bag-manifest construction uses the canonical preset automatically;
- model status remains ENGINE_PRESENT_UNVALIDATED. Canonical selection does not promote a route to SIM-BACKED.

Next: asynchronous baseline/candidate simulation execution and result transport, still off the AzerothCore world thread.


### Canonical preset repair — real-image findings

`4ba6b74d8eeef844c53398c6ab3f44a9d089b862` must **not** be called green. Stage Group Composer V4 backend failed while building the real pinned Classic image after focused source/unit checks had passed.

The failure proved that "one canonical request per route by overlay-equivalence only" was too coarse:
- Vanilla Combat Rogue route `4:1:DPS` contains distinct Daggers and Sinister Strike talent/APL builds;
- Vanilla Elemental Shaman route `7:0:DPS` contains phase-specific suites whose consumes change across Classic phases.

Current repair policy:
- harvested entries retain their upstream talent string and parsed phase;
- entries are grouped by talent build inside a class/tree/role route;
- for one talent build with phase-specific differences, the latest upstream phase is the representative because this realm currently gates at expansion level rather than emulating every Classic patch phase;
- multiple distinct talent builds remain selectable variants;
- the service compares the authoritative live talent string to the pinned variant talent strings and requires one unique closest match;
- a distance tie, missing policy, unresolved same-build ambiguity or malformed index fails closed;
- health exposes selectable-route and dynamic-route counts, and real-image CI requires every harvested route to have an explicit selection policy.

No simulator execution or SIM-BACKED promotion is part of this repair.


### Preset-repair syntax checkpoint

`4c79cd6e91596b2aed41e89173f725f54e9fe69e` is **FAILED / superseded**. Backend focused checks caught a malformed duplicate `preset_catalog_summary` fragment before any real-image policy evaluation. The next repair removes that fragment; the talent-variant/latest-phase policy itself still requires exact-head validation.


## Current WoWSims asynchronous comparison slice

Status: **DONE + exact-head local-CI green at `d449136f406a942f4553b7adc54a972ce66837cd`**.

The bounded WoWSims execution layer moves expensive comparison execution completely off the AzerothCore world thread:

- `POST /v1/snapshot/compare-bags` rebuilds the same authoritative baseline/candidate set already proven by Sim Bags;
- DPS routes use raid DPS and healer routes use raid HPS; tank comparison still fails closed because no approved survivability metric exists yet;
- the service simulates the baseline exactly once, then each accepted candidate against that same baseline;
- the response remains `BAG_COMPARE_COMPLETE_UNVALIDATED`; no route is promoted to SIM-BACKED;
- the worldserver captures snapshot + bag Item state on the world thread, then enqueues only immutable JSON/string state;
- the worker thread owns all HTTP/simulator waiting and never dereferences `Player*`, inventory objects or world state;
- completed work is drained by `RaidRosterWorld::OnUpdate` and delivered only after resolving the player again on the world thread;
- one active Sim Bags job per character and a bounded global queue prevent accidental job floods;
- `.wowsims simbags` is the diagnostic entry point for this boundary;
- shutdown joins the worker cleanly and discards queued work.

The next slice after this is green is result/confidence/explanation transport into GearAdvisor plus an explicit client Sim Bags action. Runtime model/mechanics validation remains required before any player-facing result may be called SIM-BACKED.


### WotLK same-talent preset discriminator repair

The first async candidate `4cfc5adb...` forced a real service-image rebuild and exposed a previously unproven WotLK preset ambiguity. Upstream `TestFire` and `TestFrostFire` share the exact same Mage talent string, so talent distance alone is insufficient. The pinned upstream fixtures differ in their major glyph set: Fire uses Glyph of Fireball while Frostfire uses Glyph of Frostfire.

Repair status: **DONE + real-image + exact-head local-CI green at `d449136f406a942f4553b7adc54a972ce66837cd`**.

- harvested entries now retain sorted non-zero glyph item IDs from the pinned request;
- multi-variant routes use `closest-live-character` selection;
- selection score is ordered by live talent distance and then authoritative live glyph-set distance;
- live WotLK glyph spell IDs are translated through the existing pinned WoWSims spell->item map before comparison;
- different same-talent glyph variants remain valid candidates instead of being collapsed;
- ties after both authoritative discriminators still return an error;
- routes that cannot be distinguished from authoritative character state still fail the real image build rather than receiving a guessed default;
- canonical policy version advances to `talent-glyph-variant-latest-phase-v2`.

This is still preset routing only. It does not make Fire/Frostfire mechanics SIM-BACKED.


## GearAdvisor automatic Sim Bags transport

Status: **IMPLEMENTED / exact-head local CI required**.

This slice connects the green async comparison boundary to the existing GearAdvisor result surface without promoting unvalidated models:

- GearAdvisor v0.3.3 adds an explicit `Sim Bags` button beside the manual WoWSims export button;
- the button sends `.wowsims simbags`, which only queues work and returns immediately;
- worldserver completion emits a compact `[GA]` system-message protocol consumed through the same 3.3.5a-compatible chat-filter pattern already proven by Group Composer;
- queue, success, no-positive-candidate, stale-state and error states have separate protocol records;
- the async job retains its queue-time character snapshot and authoritative bag-candidate snapshot;
- before result delivery, the world thread rebuilds both snapshots; if equipped state, talents/spec/professions/glyphs or bag candidates changed, the result is discarded as STALE;
- GearAdvisor persists the latest simulation result/status in its WHY / WHAT NEXT region rather than losing it on normal stat refresh events;
- a positive result is labeled `UNVALIDATED GAIN` while model support remains `ENGINE_PRESENT_UNVALIDATED`; only a future `SIM_BACKED` route may render authoritative UPGRADE/DOWNGRADE wording;
- item ID and canonical equipment slot are shown with the cached item link/name when available;
- manual WoWSims export remains available as a separate `Export` button.

This is result transport and UX plumbing, not mechanics approval. Route-by-route simulator validation remains a separate gate.
