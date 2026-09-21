# Development / Runtime Pass Log

Newest entries belong at the top of the dated section.

## 2026-09-21 — ERA-07 slice 3: PlayerbotFactory + starter/catch-up item provenance

Status: **IMPLEMENTED; exact-head GitHub-hosted CI required**.

Implemented:
- added wrapper patch `0044-playerbot-era-item-policy-hook.patch` against exact pinned mod-playerbots `b6696bdb...`;
- PlayerbotFactory exposes independent readiness/item-allowed callbacks, keeping mod-playerbots decoupled from the realm module while still using central EraPolicy;
- RaidRoster registers the callbacks once during script registration;
- AutoGear/InitEquipment fails closed before second-chance destruction if provenance is unavailable;
- protected factory item paths now gate start outfit, equipment candidates, PvP trinket, bags, ammo, potions, food, generic StoreItem/StoreNewItem and gem-item candidates;
- old item-ID gear/gem expansion heuristics are removed from those protected paths instead of competing with chronology evidence;
- factory bag provisioning picks the largest currently legal bag through the central policy (Portable Hole -> Netherweave -> Mooncloth);
- AdventureStart profiles fail before progression/level/starter-state mutation when their item package cannot be proven safe;
- explicit starter supply IDs are independently checked through EraPolicy;
- catch-up profiles fail before progression/claim mutation when provenance is unavailable, preserving the player's ability to retry;
- defensive `EquipCatchup` readiness check prevents a future caller from bypassing the command guard;
- focused contracts and backend CI assert the policy hook, no-ID-threshold contract and starter/catch-up failure boundaries.

Boundary:
- this is **item** chronology, not spell chronology; generated enchant spells still need an eventual authoritative era policy;
- vendors/rewards, loot, recipes/crafting and item-producing systems outside PlayerbotFactory remain TODO;
- existing contaminated gear/auctions remain audit-only rather than being silently destroyed.

CI routing: `stoffes-pc` remains offline, so the implementation commit uses `[github-ci]`.

## 2026-09-21 — Client addon bundle + GearAdvisor

Status: **DONE + exact-head GitHub-hosted CI verified at `de842ba842721f32d588ba5d9818b872f9a6c805`**.

Implemented:
- added NoM0Re's actively maintained 3.3.5a WeakAuras backport, pinned to release `5.22.0-b3706bd4` and SHA-256 `83f62045...`;
- explicitly rejected the ancient Bunny67 WeakAuras 4.0.0 fallback from the bundle;
- added the maintained `5Buttons/Details-WotLK` damage/healing/threat meter pinned to exact commit `a2372618...`;
- zip inputs can now be SHA-256-pinned and verified before extraction;
- added local `GearAdvisor` addon beside the Character frame;
- GearAdvisor detects class/talent tree, supports Feral Cat/Bear and DK DPS/Tank role variants, calculates equipped average ilvl, shows hard caps separately from stat priorities, and gives "need +X" guidance;
- all ten WotLK classes / every talent tree have a profile;
- realm-era baseline hit/defense targets follow Group Composer's server-reported era when available;
- superseded `ExtendedCharacterStats` is skipped from the distributed pack so only GearAdvisor owns the character-side stat panel;
- client CI now parses GearAdvisor under Lua 5.1 and asserts the exact Details/WeakAuras pins.

Boundary:
- GearAdvisor is guidance, not a simulator/BiS optimizer;
- raid buffs, racials and encounter-specific gearing can change practical hit/haste targets;
- WotLK stat priorities are the detailed profile set in this first version; Vanilla/TBC advanced spec priorities remain future work even though hard-cap baselines are era-aware;
- runtime UI positioning and real-client stat values still need in-game validation.

CI: exact SHA `de842ba842721f32d588ba5d9818b872f9a6c805` passed client checks, backend staging, Integration and Group Composer V4 compile using the explicit `[github-ci]` route while `stoffes-pc` was offline.

## 2026-09-21 — ERA-07 slice 2: central item policy + stock/gear enforcement

Status: **DONE FOR SLICE 2 + exact-head local CI verified at `e96d009552b01a84d7e70f4a8956b33b34900843`; ERA-07 overall remains IN PROGRESS**.

Implemented:
- provenance generation moved behind `configure-era-item-provenance.sh`, independent of whether AHBot is enabled;
- generator metadata now fingerprints the sorted live `item_template` ID set with deterministic FNV-1a/64;
- the persistent RaidRoster config stores source metadata plus all three Vanilla/TBC/WotLK blocked-ID sets simultaneously;
- `setup.sh` and `update.sh` regenerate central provenance against the live world DB and recreate worldserver so EraPolicy reads one immutable snapshot per process;
- `configure-ahbot.sh` reuses the central generator instead of owning duplicate chronology generation;
- EraPolicy validates source metadata, world item count/fingerprint, nested blocklist counts and live item existence before becoming ready;
- `TryItemEra` / `IsItemAllowed` make the central policy reusable by every server-side item consumer;
- RaidRoster/Group Composer synthetic gear preparation fails closed before stripping gear if provenance is unavailable, and excludes future/UNKNOWN items at candidate/equip boundaries;
- `.era audit` scans current auction stock for future/UNKNOWN items and scans stored RNDbot equipped slots for the same leaks;
- static contracts cover central script wiring, setup/update regeneration, policy API and audit/gear consumers.

Boundary:
- the stock/equipment scanner is read-only; it does not delete auctions or mutate contaminated stored gear;
- this slice protects the deterministic RaidRoster/Group Composer gear path, not `EquipCatchup`, starter/catch-up packages, vendors/rewards, loot, crafting or every Playerbots randomization path;
- provenance remains expansion-level chronology, not patch/phase-specific obtainability.

CI: exact SHA `e96d009552b01a84d7e70f4a8956b33b34900843` passed client checks, backend staging, Integration and Group Composer V4 compile. Both heavy workflows completed successfully on `stoffes-pc`.

## 2026-09-21 — ERA-07 slice 1: reproducible item provenance + AH enforcement

Status: **DONE FOR SLICE 1 + exact-head local CI verified at `44adb851e37cd916c1e2ebbb5dd7ece1f2cef0fc`; ERA-07 overall remains IN PROGRESS**.

Implemented:
- new `tools/generate-era-item-provenance.py` with a deterministic self-test;
- exact CMaNGOS Classic/TBC/WotLK database commits + compressed Git blob SHAs pinned as chronology evidence;
- generator intersects those historical item identities with the live AzerothCore `item_template` set;
- earliest historical presence defines Vanilla/TBC/WotLK; no item-ID/required-level/item-level chronology guess is used;
- IDs absent from all three snapshots become UNKNOWN and fail closed for automated AH listings until explicitly reviewed;
- `overrides.csv` is the review ledger for source omissions/anomalies;
- `configure-ahbot.sh` caches verified source dumps, generates compact profile blocklists and publishes provenance metadata;
- new AHBot patch consumes `AuctionHouseBot.EraProvenanceDisabledItemIDs` separately from normal custom disabled IDs;
- `.era audit` gains AUCTION_PROVENANCE PASS/WARN/FAIL coverage;
- focused backend CI runs the provenance self-test, JSON validation and AH script syntax checks.

Boundary:
- this first consumer protects **new AHBot seller listings** only;
- existing auctions are not purged or yet scanned by item provenance;
- bot gearing/prep, starter/catch-up, vendors/rewards and other automated item paths still need the same central provenance policy;
- UNKNOWNs are safe from AH automation but remain review work, therefore ERA-07 stays IN PROGRESS.

CI: exact SHA `44adb851e37cd916c1e2ebbb5dd7ece1f2cef0fc` passed client checks, backend staging, Integration and Group Composer V4 compile. Both heavy workflows completed successfully on `stoffes-pc`.

## 2026-09-21 — RNDbot quarantine patch format repair (final)

Status: **DONE + exact-head local CI verified at `1e6f01f25cd63184618abd202cbd2cd0a677a189`**.

Exact-head compile/Integration on `186b4aa8` stopped during pinned-tree assembly because wrapper patch `0042-playerbot-era-cap-quarantine.patch` still declared the ProcessBot hunk as `+26` lines even though that hunk contains 19 insertions + 6 context lines = 25. Git therefore consumed the following hunk header as patch content and reported `corrupt patch at line 54`.

Fix:
- ProcessBot new-side hunk count corrected from 26 to 25;
- following RandomizeFirst new-side start corrected from 2060 to 2059 to reflect cumulative insertions;
- no RNDbot quarantine logic changed.

CI: `1e6f01f25cd63184618abd202cbd2cd0a677a189` passed client checks, backend staging, Group Composer V4 compile and Integration. Both heavy jobs used `stoffes-pc`.

## 2026-09-21 — ERA-06 slice 1: era-aware AH market profiles

Status: **IMPLEMENTATION PUSHED; exact-head local CI required**.

Implemented:
- `configure-ahbot.sh <character> [vanilla|tbc|wotlk]`;
- seller equip/use-level ceilings 60/70/80;
- Vanilla Gems OFF + Glyphs OFF;
- TBC Gems ON + Glyphs OFF;
- WotLK Gems ON + Glyphs ON;
- script-owned Wrath potion/flask/Fish Feast boost IDs are removed before every profile and only re-added for WotLK;
- fresh installs default to Vanilla while unmarked existing installs keep backward-compatible WotLK behavior;
- `.era audit` checks AH profile/cap/Gem/Glyph drift against the central live era;
- AH script syntax is included in static CI.

Boundary:
- required/equip level cannot prove expansion provenance, so ERA-07 remains mandatory.
- profile changes are non-destructive and do not purge already-listed auctions.

## 2026-09-21 — Playerbots era-quarantine patch format repair

Status: **FIX PUSHED; exact-head local CI required**.

Local Group Composer compile on `5be15b74` stopped during pinned-tree assembly before C++ compilation because `0042-playerbot-era-cap-quarantine.patch` had stale new-side hunk counts. The patch contents/behavior were correct, but its headers under-counted inserted lines. Hunk lengths/offsets are repaired; no quarantine behavior was removed.

## 2026-09-21 — FEATURE-19 slice 1: safe realm snapshot foundation

Status: **IMPLEMENTATION PUSHED; exact-head local CI required**.

Implemented:
- enriched `realm-snapshot.sh` built on the existing DB backup path;
- snapshot provenance includes realm profile, exact overlay/core/module Git state, repo pins, migration inventory and persistent config archive;
- release-transition snapshot is allowed only on an explicitly marked friends realm with release operations enabled and a clean worktree;
- dev/default realms fail closed for release-transition operations;
- restore refuses cross-profile and wrong-code-SHA snapshots by default;
- friends realms refuse legacy unidentified bundles unless the operator explicitly overrides the guard;
- enriched restore reapplies the captured persistent config tree;
- shell syntax is executed in the contract suite with `bash -n`.

Scope:
- FEATURE-19 remains PARTIAL until transition tooling automatically creates these snapshots and the full restore path is runtime-tested.

## 2026-09-21 — Group Composer era class visibility

Status: **IMPLEMENTATION PUSHED; typed UI + exact-head local CI required**.

Implemented:
- Group Composer 0.15.3 Build Selector hides Death Knight unless the live realm is WotLK;
- class tiles are still created at addon load, while live-era filtering happens during refresh so an early default realm snapshot cannot permanently remove the DK tile;
- a stale/persisted Death Knight selection is cleared when opening the selector before WotLK;
- server-side EraPolicy remains authoritative; this client filtering is UX rather than security.

## 2026-09-21 — ERA-01/02 identity and profession policy foundation

Status: **IMPLEMENTATION PUSHED; exact-head local CI required**.

Central policy added:
- Death Knight requires WotLK;
- Blood Elf and Draenei require TBC;
- Jewelcrafting requires TBC and Inscription requires WotLK;
- profession skill caps are 300/375/450 for Vanilla/TBC/WotLK.

Enforcement added:
- Group Composer filters unreleased classes/races from ordinary online, AddClass and offline reserve candidates;
- `CanClassFillRole` refuses an unreleased class, so explicit DK requirements cannot sneak through before WotLK;
- RaidRoster creation excludes unreleased class/race identities;
- RaidRoster login benches unreleased classes regardless of dirty dev-character level;
- RaidRoster sync clamps bot target level to the live realm cap instead of blindly copying a level-80 dirty master.

Audit expansion:
- `.era audit` reports active RNDbot class/race leaks;
- `.era audit` reports future profession presence or profession skill values above the live 300/375/450 cap.

Still TODO: server character-creation enforcement, trainers/recipes, full profession behavior, Group Composer client-side DK hiding, and broader persistent guild-bot identity handling.

CI: commit uses `[local-ci]` on `stoffes-pc`.
- First static pass on `2d9dc432` found an old reserve-query assertion that still required `guid,name,class,level`; the implementation intentionally adds `race` so era race policy can be enforced. The contract now requires persisted race metadata too.

## 2026-09-21 — ERA-02 slice 1: read-only integrity audit scaffold

Status: **IMPLEMENTATION PUSHED; exact-head local CI required**.

Implemented GM-only `.era audit`:
- reports live era, level cap and progression ceiling;
- FAILs if Individual Progression or Playerbots runtime caps drift from EraPolicy;
- counts online RNDbots above the live cap and prints examples;
- counts preserved stored RNDbots above cap as WARN/quarantined, with examples;
- validates Outland/Northrend map gates against released era;
- scans future Adventure Catalog entries for map-policy leaks;
- prints one read-only PASS/WARN/FAIL summary and never mutates world state.

Remaining audit sections: item provenance/equipped bot gear, AH, vendors/currencies, professions, classes/races, PvP, convenience systems, geography/transports and automated rewards.

CI: `[local-ci]` is queued on `stoffes-pc`; exact final SHA must pass all required workflows.

## 2026-09-21 — ERA-01 slice 4b: non-destructive RNDbot quarantine

Status: **IMPLEMENTATION PUSHED; exact-head local CI required**.

Implemented through wrapper patch `0042-playerbot-era-cap-quarantine.patch`:
- RNDbot login selection skips stored characters above `AiPlayerbot.RandomBotMaxLevel`, which EraPolicy now owns at runtime;
- active ungrouped RNDbots discovered above the cap are removed from the active population event/state and logged out;
- their character records are not downlevelled, deleted or re-geared, preserving identity/history for TBC/WotLK release;
- a future-era bot already in a live player group is not forcibly removed mid-run; it remains an audit/runtime cleanup case until the group ends;
- fixed-level randomization is clamped to the live runtime max so `DisableRandomLevels` cannot accidentally jump beyond the era cap.

This is deliberately quarantine, not destructive normalization. Expansion release makes preserved identities eligible again naturally.

CI: `[local-ci]` queues behind the earlier exact-head jobs on `stoffes-pc`.

## 2026-09-21 — ERA-01 slice 4a: Playerbots runtime cap synchronization

Status: **IMPLEMENTATION PUSHED; exact-head local CI required**.

Implemented:
- EraPolicy now synchronizes both Individual Progression `BotAccountsMaxLevel` and Playerbots `randomBotMaxLevel` to the live 60/70/80 era cap;
- Playerbots `RandomBotLevelMgr` reloads its working level brackets after the central cap changes;
- RaidRosterWorld reasserts the policy on server startup and one second after config reload, avoiding module-hook ordering drift;
- ordinary online/offline Group Composer candidates outside the live era cap are rejected through EraPolicy;
- automated RaidRoster gearing refuses bots above the live era cap before any equipment is stripped or replaced.

Important scope boundary:
- this does not yet quarantine already-stored over-cap RNDbot identities before login. That is the next slice and will preserve those characters for later expansion release rather than destructively downlevelling them.
- item provenance is still separate ERA-07 work.

CI: `[local-ci]` queues behind the earlier slice-3 jobs on `stoffes-pc`; exact SHA must complete all required workflows before this slice is green.
- First staging pass on `40d6ed4f` exposed one stale slice-1 assertion that expected the IP cap assignment directly inside `ApplyRealmEra()`. The assignment now correctly lives inside `SyncRuntimeBotCaps()` beside the Playerbots cap update; the contract is updated to verify that centralized location.

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
- First slice-3 exact-head checks exposed a **test assertion bug**, not a runtime/code regression: the contract forbade the token `requiredEra` anywhere, but the new central-policy implementation legitimately uses a local `EraPolicy::Era requiredEra` variable for an error message. The contract now specifically forbids the removed legacy field `RealmEra requiredEra;` instead.

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
