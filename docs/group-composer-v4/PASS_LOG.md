# Development / Runtime Pass Log

Newest entries belong at the top of the dated section.

## 2026-09-20 — Runtime pass 3: RDF proposals, peer levels and player-aware UI

Status: **IMPLEMENTATION PUSHED; exact-head local CI + runtime retest required**.

Observed:
- low-level level gating works;
- RDF role-check and initial queue now work;
- later RDF proposal acceptance still times out on a Playerbot;
- Recommendations clip text;
- human-anchor class icon placement is awkward;
- nested unlock/browser layers overlap;
- browser/progression open at WotLK for low-level characters;
- difficulty choices need locked states;
- legacy-content anti-boost needs to follow the lowest real human rather than the activity era.

Implemented:
- deterministic Playerbot RDF proposal auto-agree while real humans retain normal Accept/Decline;
- taller structured Recommendation cards;
- nested unlock modal layering;
- corrected one-icon human-anchor placement;
- player-relevant Activity Browser/Progression default era;
- visible disabled difficulty rows and automatic Normal reset after choosing a dungeon incompatible with the previous difficulty;
- difficulty validity based on selected activity era;
- lowest-real-human bot target with +/-3 peer band, dungeon-floor clamp and live-realm-cap clamp.

CI:
- Initial implementation SHA `264c25919fff945d4f11b399966674e21d3d137a` exposed two static bookkeeping failures: Data.lua still reported 0.14.0 and one contract assertion still expected the old activity-peer wording.
- Group Composer typed UI itself compiled/smoke-tested and published generated bundle commit `1385e4f8e3eab3f30a94cadb8965aaac5bab39c4`.
- The next staging run exposed one more stale pre-pass assertion that still required the old master+2/activity-era-cap formula. The implementation correctly uses lowest-real-human+3/live-realm-cap, so this assertion is updated rather than reverting behavior.
- A final stale version contract still expected addon 0.14.0 after the runtime pass bumped both TOC/Data to 0.15.0; the assertion is updated to the new package version.
- The final runtime-pass assertions also exposed a pre-existing test-variable shadow: `TYPES` was reassigned from `GroupComposerTypes.h` to the WoW TypeScript declaration file. It is renamed to `WOW_TYPES` so backend type checks inspect the intended source.
- Exact-head local Compile/Integration on `f5a44696...` then caught a malformed hunk count in the new `0041-playerbot-lfg-proposal-autoaccept.patch` before compilation. The patch is corrected from `+446,17` to `+446,16`; staging/client checks were already green on that SHA.
- This follow-up uses `[local-ci]`; do not mark the pass green until its exact final SHA completes all relevant workflows.

## 2026-09-20 — All era + broader feature proposals approved

Status: **ROADMAP ACCEPTED + EXACT-HEAD LOCAL CI VERIFIED**.

Verified checkpoint: `b1d1d896c9b1b4f249532de0d6b5244e40615798`.

Exact-head workflows:
- Group Composer client checks: SUCCESS
- Stage Group Composer V4 backend: SUCCESS
- Group Composer V4 compile: SUCCESS on `stoffes-pc`
- Integration build: SUCCESS on `stoffes-pc`

User decision:
- Approved all 20 era-relevance improvements.
- Approved all 20 broader server features.
- Requested durable GitHub tracking and that items be crossed off as they are completed.

Work:
- Added `MASTER_ROADMAP.md` with stable IDs ERA-01..ERA-20 and FEATURE-01..FEATURE-20.
- Classified existing foundations honestly as PARTIAL instead of pretending they are either untouched or complete.
- Added strict cross-off semantics: only DONE items receive `[x]`, with CI/runtime evidence required where applicable.
- Added phased dependency order so future sessions always know what comes next.
- Kept the current Group Composer runtime validation as NOW-01.
- Set the first new architecture work after validation to ERA-01 Central Era Policy + ERA-02 Era Integrity Scanner.
- Added FEATURE-19 snapshot/rollback early in the dependency chain before expansion-transition work.

CI:
- Exact-SHA local CI completed successfully.
- Both heavy workflows ran on `stoffes-pc`.
- Local Ubuntu 26.04 Clang 18 → GCC 15 libstdc++ workaround remained active.


## 2026-09-20 — Era-relevance + feature idea-bank pass

Status: **DOCUMENTED + EXACT-HEAD LOCAL CI VERIFIED; ideas are not implementation claims**.

Verified checkpoint: `402ce7c3c1acfbf8a85ef5b6f3d0d1f8282b13f8`.

Exact-head workflows:
- Group Composer client checks: SUCCESS
- Stage Group Composer V4 backend: SUCCESS
- Group Composer V4 compile: SUCCESS on `stoffes-pc`
- Integration build: SUCCESS on `stoffes-pc`

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
