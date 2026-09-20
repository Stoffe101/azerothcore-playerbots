# Development / Runtime Pass Log

Newest entries belong at the top of the dated section.

## 2026-09-20 — Era-relevance + feature idea-bank pass

Status: **DOCUMENTED; ideas are not implementation claims**.

Why:
- The project needs a durable place for expansion-authenticity improvements and broader server ideas so future chats do not lose or repeatedly reinvent them.
- The user explicitly wants the server to feel materially Vanilla/TBC/WotLK appropriate while preserving private-server QoL.

Work:
- Added canonical `FEATURE_IDEAS.md`.
- Expanded era-relevance candidates across bots, AH, professions, Composer, vendors/currencies, travel, PvP, world events, races/classes and historical-fidelity polish.
- Added broader candidates including Expansion Command Center, Era Integrity dashboard, Vanilla/TBC LFG Board, raid planner, persistent bot bench, crafting orders, guild-bank steward, population director, attunement assistant, readiness planner, wipe analyzer, loot council, guild chronicle, opening events and safe snapshots.
- Kept speculative ideas out of implemented/current-state claims.
- CI routing for this follow-up pass is explicitly `[local-ci]` so compile/Integration use `stoffes-pc`.

Next:
- Complete exact-head local CI.
- Continue the existing P0 in-game validation before promoting new feature ideas into implementation.

## 2026-09-20 — Expansion-era fidelity architecture

Status: **DESIGN DONE; implementation intentionally tracked as TODO/PARTIAL**.

Why:
- The future realm is meant to progress Vanilla → TBC → WotLK, but a level cap alone does not stop future-era bots, AH items, professions, vendors, travel or preparation systems leaking backward.
- Group Composer needs different composition logic and presentation for 40-player Vanilla, subgroup-sensitive TBC and 10/25-player WotLK.

Findings:
- Existing Individual Progression + AdventureCatalog already provide a strong three-era foundation.
- Existing RaidRosterEra::SyncBotToMaster handles Composer/roster bot era synchronization.
- configure-ahbot.sh is deliberately WotLK-biased today and is therefore a confirmed future-release contamination risk if reused unchanged.
- mod-ah-bot-plus exposes useful item/use-level and custom-disabled-item filters, but level/item-level filters alone are not enough to prove expansion provenance.

Work:
- Added canonical ERA_FIDELITY.md.
- Defined the additive expansion rule: Vanilla; then Vanilla+TBC; then Vanilla+TBC+WotLK.
- Defined server-authoritative era-policy direction and a read-only Era Integrity audit.
- Defined per-era Group Composer browsing, class/spec rules, raid-template strategy and dungeon/RDF behavior.
- Defined bot population/gear constraints and non-destructive dev-realm handling.
- Defined AH market profiles and layered future-item filtering.
- Defined profession/vendor/reward/map/transport requirements and a forward-only expansion release transaction.

Next:
- Finish the already-scheduled runtime validation first.
- Then implement era fidelity in ordered passes from central policy/audit outward.

## 2026-09-20 — Canonical handoff + low-level test lane

Final verified green implementation: `86ce6c8dc8bd6faddbe0ae1cbd98c082424e21d4`

Exact-head workflows:
- Group Composer client checks: SUCCESS
- Stage Group Composer V4 backend: SUCCESS
- Group Composer V4 compile: SUCCESS on `stoffes-pc`
- Integration build: SUCCESS on `stoffes-pc`

Why:
- New chats need one authoritative place to recover exact project state.
- The WotLK dev realm's normal starter profile prevents genuine level-1 testing.

Work:
- Created `docs/group-composer-v4/` as the canonical handoff folder.
- Defined mandatory per-pass documentation updates.
- Added a one-shot, per-account Vanilla-fresh next-character override through Admin Panel.
- Command contract:
  - `.ap nextstarter vanilla`
  - `.ap nextstarter status`
  - `.ap nextstarter clear`
- Override is intentionally in-memory and does not alter the realm-wide starter profile.

Runtime test still required after deploy:
- Arm the override on the GM/main character.
- Create a new non-DK character.
- First login should remain level 1.
- Open Group Composer and validate low-level activity access + anti-boost behavior.

## 2026-09-20 — Runtime pass 2: live groups, RDF and layout

Final verified green: `3b548b3d29539a1ae0816d10db0e943546d3626c`

User findings:
- Existing party bots were not visible/usable as current composition slots.
- Random heroic queue produced "party members do not meet requirements".
- Blizzard RDF did not visibly begin the intended search.
- Build Selector text escaped its cards.
- Recommended text escaped cards.
- Raid Templates My Templates/WotLK tabs overlapped.
- Diagnostics warnings were confusing.

Fixes:
- Backend anchor protocol now exposes Playerbots as well as humans.
- Client keeps `ScanHumans()` for human-only logic and adds `ScanGroupMembers()` for the live group.
- Dungeon UI renders existing bot/human anchors as locked slots.
- Missing-role calculations include live grouped bots.
- Prepared bot selection excludes already-anchored group members from duplicate display.
- LFG lock caches refresh after managed bot preparation and immediately before RDF queueing.
- RDF handoff checks for `LFG_STATE_ROLECHECK`.
- Class selector cards/section made taller.
- Recommended cards made taller with bounded readiness text.
- Template tabs reset to canonical positions before mode-specific hiding.
- Diagnostics explains PASS/WARN/FAIL semantics.

Exact-head workflows:
- Group Composer client checks: SUCCESS
- Stage Group Composer V4 backend: SUCCESS
- Group Composer V4 compile: SUCCESS on `stoffes-pc`
- Integration build: SUCCESS on `stoffes-pc`

## 2026-09-20 — Runtime pass 1: protocol, pages, history truth, Favorites and utility

Final verified green: `a7f583b91217d0a4b1237b35fdf7cf835ad0e6a2`

User findings:
- Yellow `Wrong format occurred (argument not found)` spam.
- All activity cards greyed out / stuck checking access.
- Progression/Recommended/Diagnostics overlaid the Composer page.
- Raids displayed CLEARED when the player had not cleared them.
- Favorites star glyph rendered incorrectly.
- Utility Coverage needed useful counts and missing-buff information.

Fixes:
- Corrected ACTIVITY 12-placeholder / 11-argument mismatch.
- Removed progression-stage-as-clear fallback. Raid clears now come from durable clear history.
- Page visibility now hides/shows the actual Composer workspace/status region.
- Favorites uses client-safe text rather than unsupported star glyphs.
- Locked cards stay clickable for unlock details.
- Added Utility Coverage Details:
  - interrupts;
  - dispels/cleanses;
  - raid-buff-capable members;
  - Heroism/Bloodlust;
  - battle rez;
  - CC;
  - threat support;
  - ranged/melee DPS;
  - present/missing core buff families with provider counts/names.

Exact-head workflows all succeeded.

## 2026-09-20 — Pre-test feature completion

Verified green checkpoint: `7e9658076069c5fad0f107ed8227140f2484cf0f`

This closed the speculative pre-test feature backlog:
- recent durable guild-clear timeline;
- richer first-clear context;
- View Unlocks from recommendations;
- ordered quest NEXT STEP;
- online-friend-aware recommendation weighting;
- existing gear/catch-up/guild/lockout/planner weighting retained.

Decision made here:
**Future changes should be driven by observed runtime behavior.**
