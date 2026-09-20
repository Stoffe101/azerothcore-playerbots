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

Latest fully verified green checkpoint: `1e3e9d5fa32e52d9abb2b43501e222f812ee6c3a`

Exact-head CI: client checks **SUCCESS**, backend staging **SUCCESS**, Group Composer compile **SUCCESS** on `stoffes-pc`, Integration **SUCCESS** on `stoffes-pc`. Both heavy workflows retained the Clang 18 -> GCC 15 libstdc++ workaround.

This head includes the previously verified runtime-pass-3 implementation, peer-policy observability, Admin Panel authorization hardening and the Group Composer minimap launcher. Current Group Composer version is **0.15.2**.

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

Slice 3 is **IN PROGRESS**: EraPolicy derives map era from Map.dbc expansion metadata; Admin Panel teleports/goto/summon/saved locations and Group Composer instance travel are being moved onto that map gate. The first static check failure was a too-broad contract assertion and has been corrected without changing the travel implementation.

ERA-01 is **not DONE yet**. AH, global bot population/geography, professions, vendors, travel, classes/races, PvP and other systems still need migration/enforcement.

## Era-fidelity architecture pass

Canonical design is now recorded in ERA_FIDELITY.md.

Current assessment:
- **DONE:** three-era progression/level-cap foundation, activity-era catalog gates, manual expansion hold/advance foundation, Era Talents, bot-to-master era synchronization, Composer anti-boost foundation.
- **PARTIAL:** Group Composer era presentation/templates/subgroup logic; global bot-population era ceiling; expansion release orchestration.
- **TODO:** strict AH item provenance, era market profiles, profession/vendor/reward/map/transport gates, race/class release policy, era-integrity audit.
- **Known contamination risk:** configure-ahbot.sh is intentionally WotLK-oriented today and must not be reused unchanged for a fresh Vanilla/TBC realm.

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
