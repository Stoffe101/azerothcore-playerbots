# Development / Runtime Pass Log

Newest entries belong at the top of the dated section.

## 2026-09-20 — ERA-01 slice 3: map/travel containment

Status: **IMPLEMENTATION PUSHED; exact-head local CI required**.

Implemented:
- EraPolicy reads Map.dbc `expansionID` through the server DBC store and exposes `TryMapEra` / `IsMapAllowed`;
- removed Admin Panel's duplicated per-destination `requiredEra` table;
- Admin Panel teleport, goto, summon destination and saved-location travel now respect the central map policy;
- Group Composer performs an explicit EraPolicy map check immediately before instance travel;
- unknown map IDs fail closed in the EraPolicy travel paths;
- raw core GM tooling remains the deliberate dev escape hatch; Azeroth Control itself respects the live realm.

Scope: this is map-level containment. Portals/transports/flying mechanics and historically altered old-world content still require later ERA-14/ERA-18 work.

CI: commit uses `[local-ci]`; exact final SHA must pass all required workflows.

## 2026-09-20 — ERA-01 slice 2: progression boundaries

Status: **IMPLEMENTATION DONE + EXACT-HEAD LOCAL CI VERIFIED**.

Implemented:
- EraPolicy adds canonical level/progression band helpers and allow checks;
- AdventureStart rejects future-era starter profiles before level/gear/progression changes;
- Adventure Catch-up rejects future-era progression/gear packages;
- player progression shortcuts cannot jump into an unreleased expansion;
- direct Group Composer Titan Rune queue is server-gated to WotLK;
- bot progression sync clamps level-derived fallback and contaminated future progression to the live realm;
- static contracts cover each migrated boundary.

Still TODO: item provenance, global bot level/gear enforcement, Titan Rune phase timing, AH/vendors/professions/PvP/maps/transports.

CI: exact SHA `1e3e9d5fa32e52d9abb2b43501e222f812ee6c3a` passed client checks, backend staging, Integration and Group Composer compile. Both heavy jobs ran on `stoffes-pc` with the Clang 18 -> GCC 15 workaround intact.

## 2026-09-20 — ERA-01 slice 1: central policy spine

Status: **IMPLEMENTATION DONE + EXACT-HEAD LOCAL CI VERIFIED**.

Goal:
- eliminate competing definitions of Vanilla/TBC/WotLK before migrating more world systems.

Implemented:
- new `EraPolicy::Era` canonical enum;
- one canonical 60/70/80 level-cap table;
- one canonical Vanilla/TBC/WotLK progression-ceiling/minimum table;
- one authoritative `CurrentRealmEra()` derived from the live Individual Progression ceiling;
- one `ApplyRealmEra()` path that updates progression ceiling + `BotAccountsMaxLevel` together;
- canonical name/token/key/parse/release helpers;
- Adventure Catalog now aliases/delegates its era API to EraPolicy;
- AdminPanelExpansion now aliases/delegates to EraPolicy and no longer owns `g_currentEra` or duplicate cap tables;
- static contracts prevent those duplicate policy definitions from silently returning.

Scope note:
- ERA-01 remains IN PROGRESS. This is the policy spine, not a claim that AH/vendors/professions/travel/PvP/global bots are already era-safe.

CI:
- Initial SHA `eb7118d31ced7f5193fd6069c59b3cfe32e13d4c` passed static/client staging but Clang correctly caught one ADL ambiguity: the `AdventureEra` alias associates `EraPolicy`, so an unqualified `IsEraReleased(activity.era)` inside AdventureCatalog matched both the compatibility wrapper and `EraPolicy::IsEraReleased`.
- The call is now explicitly `EraPolicy::IsEraReleased(activity.era)`; no policy behavior changed.
- Follow-up `943d70b78db8215b4e6c92d69ba7afbbc1bbd67a` completed client checks, backend staging, Group Composer compile and Integration successfully on the local-CI route. Slice 1 is green.

## 2026-09-20 — P0.5 Admin security + Group Composer launcher

Status: **IMPLEMENTATION DONE + EXACT-HEAD LOCAL CI VERIFIED; runtime validation required**.

User request:
- normal/non-GM players must not be able to access or use Azeroth Control/Admin Panel;
- Group Composer should have a real clickable addon launcher instead of relying only on `/gc`.

Findings:
- privileged `.ap` commands were already correctly registered as `SEC_GAMEMASTER`, so server execution authority was protected;
- the AdminPanel addon itself still exposed its minimap button and could open its frame for every client;
- Group Composer had no clickable launcher despite having a mature UI shell.

Implemented:
- added `.ap access`, a harmless `SEC_PLAYER` authorization probe that returns only whether the current session meets `SEC_GAMEMASTER`;
- kept every privileged Admin Panel action at `SEC_GAMEMASTER`;
- AdminPanel now requests authorization on login, hides its minimap button until authorized, refuses to remain shown for unauthorized sessions and gates all client Send/SendRaw helpers;
- removed the globally named Admin Panel minimap button; the existing named main frame remains only for ProfessionTools compatibility but now has an OnShow authorization guard;
- bumped Azeroth Control addon to 2.3.0;
- added `GroupComposerMinimapButton` with a stock WoW icon/tooltip and click-to-toggle behavior while preserving `/gc`;
- bumped Group Composer addon to 0.15.2;
- added static contracts proving all privileged Admin Panel commands remain GM-only and the new launch/access guards exist.

CI:
- Exact current branch checkpoint: `8dc94defe9e2a213250017635fc20a219006f237`.
- Group Composer client checks: **SUCCESS**.
- Stage Group Composer V4 backend: **SUCCESS**.
- Integration build: **SUCCESS** on `stoffes-pc`.
- Group Composer V4 compile: **SUCCESS** on `stoffes-pc`.
- Both heavy jobs retained the Clang 18 -> GCC 15 libstdc++ workaround.

## 2026-09-20 — Runtime pass 3.1: peer-policy observability

Status: **IMPLEMENTED + INCLUDED IN EXACT-HEAD LOCAL CI GREEN CHECKPOINT; runtime verification required**.

Clarification:
- The mixed-level anti-boost rule has no special level-14 case.
- The lowest real human at any level is the peer reference. Examples such as 80+14 or 80+23 are illustrative only.

Work:
- Extended the existing META snapshot with bot target/min/max levels.
- Composer status now shows `Lowest-human target Lv X · bots Lv A-B` after a roster is built.
- Bumped addon/runtime package to 0.15.1.
- Added contract coverage for the peer-policy protocol and display.
- Updated canonical runtime docs so examples cannot be mistaken for hard-coded cases.

CI:
- Parent documentation checkpoint `cf8d988c2515a15fddc28767ed1364cc56e073fe` is exact-head green on client checks, backend staging, Group Composer compile and Integration; both heavy jobs ran on `stoffes-pc` with the Clang 18/GCC 15 workaround intact.
- Source commit: `b9ed63e5b82ad360e648bebd624dc85a3000bd94`.
- Group Composer typed UI completed successfully and published generated bundle commit `68adeb52bb1d50e3a4e7ff013f5a538895405837`.
- GitHub Actions bot pushes do not start the required downstream workflows, so this documentation follow-up intentionally uses `[local-ci]` on top of the generated bundle.
- The later combined branch head `8dc94defe9e2a213250017635fc20a219006f237` contains this source + generated bundle and completed all four required workflows successfully on the exact SHA.
- Runtime acceptance remains TODO until arbitrary mixed-level groups confirm the displayed peer target/band and actual roster agree.

## 2026-09-20 — Runtime pass 3: RDF proposals, peer levels and player-aware UI

Status: **IMPLEMENTATION DONE + EXACT-HEAD LOCAL CI VERIFIED; runtime retest required**.

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
- Exact implementation checkpoint: `91f8cff1beeb6d09875c60a1b1aee7fab662c20f`.
- Group Composer client checks: **SUCCESS**.
- Stage Group Composer V4 backend: **SUCCESS**.
- Group Composer V4 compile: **SUCCESS** on `stoffes-pc`.
- Integration build: **SUCCESS** on `stoffes-pc`.
- The local Clang 18 -> GCC 15 libstdc++ workaround remained intact.
- Code/CI is DONE for this pass. Runtime behavior stays TODO until deployed and observed in game.

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
