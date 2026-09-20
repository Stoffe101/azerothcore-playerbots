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
- Anti-boost bot-level rule: ordinary non-grouped bots above player+2 effective-era levels are excluded.
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

Implementation checkpoint: `86ce6c8dc8bd6faddbe0ae1cbd98c082424e21d4`

Exact-head CI: client checks **SUCCESS**, backend staging **SUCCESS**, Group Composer compile **SUCCESS** on `stoffes-pc`, Integration **SUCCESS** on `stoffes-pc`.

### Low-level validation lane on a WotLK dev realm

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

## Era-fidelity architecture pass

Canonical design is now recorded in ERA_FIDELITY.md.

Current assessment:
- **DONE:** three-era progression/level-cap foundation, activity-era catalog gates, manual expansion hold/advance foundation, Era Talents, bot-to-master era synchronization, Composer anti-boost foundation.
- **PARTIAL:** Group Composer era presentation/templates/subgroup logic; global bot-population era ceiling; expansion release orchestration.
- **TODO:** strict AH item provenance, era market profiles, profession/vendor/reward/map/transport gates, race/class release policy, era-integrity audit.
- **Known contamination risk:** configure-ahbot.sh is intentionally WotLK-oriented today and must not be reused unchanged for a fresh Vanilla/TBC realm.

The friends-realm rule is additive and forward-only: TBC keeps legitimate Vanilla content; WotLK keeps legitimate Vanilla + TBC content. Future-era content may never leak backward.

## Known current runtime state

The newest code after `3b548b3d` still needs in-game verification for:

- live party recognition with an existing bot tank/DPS and only missing roles filled;
- Random WotLK Heroic handoff into Blizzard RDF after the LFG cache refresh;
- Build Selector clipping fix;
- Recommended card layout;
- Raid Template tab spacing;
- clearer Diagnostics labels.

Do not mark those runtime behaviors proven merely because CI is green.

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
