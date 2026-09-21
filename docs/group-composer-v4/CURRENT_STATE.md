# Current State

_Last rewritten: 2026-09-20_

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

Latest fully verified green implementation checkpoint: `44adb851e37cd916c1e2ebbb5dd7ece1f2cef0fc`

Exact-head CI: client checks **SUCCESS**, backend staging **SUCCESS**, Group Composer compile **SUCCESS** on `stoffes-pc`, Integration **SUCCESS** on `stoffes-pc`. Both heavy workflows retained the Clang 18 -> GCC 15 libstdc++ workaround.

This head includes runtime pass 3 plus ERA-01 map/travel containment, Playerbots 60/70/80 runtime caps, non-destructive RNDbot quarantine, ERA-02 class/race/profession/AH provenance audit coverage, FEATURE-19 snapshot/rollback foundations, ERA-06 AH profiles, and ERA-07 slice-1 provenance enforcement for new AHBot listings. Current Group Composer version is **0.15.3**.

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

Status: **IN PROGRESS — slice 1 DONE/green; slice 2 IMPLEMENTED and exact-head local CI required**.

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

Do not mark slice 2 green until all four workflows succeed for its exact `[local-ci]` SHA.
