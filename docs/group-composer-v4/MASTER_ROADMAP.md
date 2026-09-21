# Master Accepted Roadmap

_Status: canonical execution board. All items below are explicitly approved for the project. This file tracks delivery; `FEATURE_IDEAS.md` and `ERA_FIDELITY.md` hold the longer design rationale._

_Accepted-roadmap structure verified at `b1d1d896c9b1b4f249532de0d6b5244e40615798`: client/backend checks SUCCESS, Group Composer compile SUCCESS on `stoffes-pc`, Integration SUCCESS on `stoffes-pc`._

## Status rules

- **DONE** = implemented and backed by the relevant exact-SHA CI plus runtime/acceptance evidence when runtime behavior is involved.
- **PARTIAL** = useful foundations already exist, but the approved feature is not complete.
- **IN PROGRESS** = the current active implementation pass.
- **TODO** = approved but not started as a complete feature.
- **BLOCKED** = approved but waiting on a prerequisite or technical constraint.
- A checkbox becomes `[x]` **only when status is DONE**.
- Every pass that changes one of these items must update this file, `CURRENT_STATE.md`, `PASS_LOG.md`, and any affected tests/backlog docs.
- When an item becomes DONE, record the finishing commit/test evidence in its notes or the corresponding pass log entry.

## What we are doing now

### NOW-01 — Finish the existing Group Composer runtime validation

**Status: IN PROGRESS**

Runtime-pass-3 implementation is exact-head CI green at `91f8cff1beeb6d09875c60a1b1aee7fab662c20f`. Deploy it, then finish the P0 tests already listed in `TEST_MATRIX.md`:

- existing human/bot anchors and missing-role fill;
- Random WotLK Heroic → Blizzard RDF proposal acceptance/completion;
- Recommendation/unlock-modal/human-icon/template layout;
- character-relevant Activity Browser/Progression defaults and difficulty locks;
- low-level one-shot Vanilla starter;
- lowest-real-human +/-3 anti-boost/peer behavior.

**Why first:** these are already implemented and waiting for real evidence. Starting a large era-policy refactor before validating them would mix old runtime defects with new architecture and make failures harder to attribute.

### NOW-02 — Admin security + addon launchers

**Status: IN PROGRESS**

While runtime testing is temporarily unavailable:
- harden Azeroth Control so only server-authorized GM sessions can expose/open the UI while privileged commands remain server-authoritative;
- add a clickable Group Composer minimap launcher without removing `/gc`.

These are bounded security/QoL changes that do not invalidate the pending P0 runtime evidence.

### NOW-03 — ERA-01 Central Era Policy

**Status: IN PROGRESS**

Runtime testing is unavailable, so architectural work continues in bounded exact-CI slices. The first slice establishes the canonical EraPolicy and migrates Adventure Catalog/Admin expansion control. Subsequent slices migrate remaining consumers without mixing every world system into one commit.

### NOW-04 — Client addon bundle + gearing guidance

**Status: WoWSims preset layer DONE + local-CI green at `998d297a`; simulation adapter + client visual acceptance IN PROGRESS**

Bounded client QoL work:
- maintained Details-WotLK and NoM0Re WeakAuras are bundled;
- GearAdvisor replaces the duplicate raw ExtendedCharacterStats panel;
- v0.2.1 layout/anchoring is exact-head local-CI green at `1f5ef71c`;
- v0.3 removes static priority text as item-upgrade authority;
- new Interface 30300 WoWSimsBridge exports the correct live-era character/bags to WoWSims Classic/TBC/WotLK; first SHA `97178c40` is superseded by a client-workflow parse repair and is not considered green;
- pinned WoWSims engines become the future baseline/candidate simulation authority;
- GearAdvisor will explain simulated cap/stat trades rather than merely warn about losing hit/expertise/etc.;
- unsupported/unvalidated era/spec models must not receive fabricated percentages.

Preset harvesting is now real-image verified. Next simulator work is authoritative snapshot overlay, baseline/candidate request construction, asynchronous compare transport and explanation. GearAdvisor v0.3.1 / Group Composer layout-safety acceptance remains required on the real 3.3.5a client.


### NEXT-01 — ERA-01 + ERA-02

After P0 is stable, the first new implementation should be:

1. **ERA-01 Central Era Policy**
2. **ERA-02 Era Integrity Scanner**

They are the dependency spine for most other approved era work. First define one truth; then make leakage measurable before trying to fix every leak.

---

# Era relevance roadmap

## Era kernel and containment

- [ ] **ERA-01 — Central Era Policy system — IN PROGRESS**
  - Canonical `EraPolicy.h/.cpp` now owns the era enum, current-era derivation, 60/70/80 caps, progression ceilings/minimums, release comparison and era application.
  - Adventure Catalog and AdminPanelExpansion now alias/delegate to EraPolicy; their duplicate enum/state/cap tables are removed.
  - Slice 2 migrates starter/catch-up availability, player progression shortcuts, direct Composer Titan Rune access and bot progression sync.
  - Slice 3 adds a Map.dbc-backed map policy and migrates Admin/Composer teleport boundaries to it.
  - Slice 4a synchronizes Playerbots runtime max-level/brackets to the live era and fences Composer/RaidRoster automated prep.
  - Slice 4b non-destructively quarantines stored/ungrouped RNDbots above the live cap instead of downlevelling or deleting them.
  - Finish when Group Composer, bots, AH, vendors, professions, travel, starter/catch-up, Titan Rune and PvP consume one authoritative policy rather than inventing independent era logic.

- [ ] **ERA-02 — Era Integrity scanner — IN PROGRESS**
  - GM-only read-only `.era audit` scaffold is implemented for cap drift, RNDbot quarantine, map gates and future Composer-map leakage.
  - PASS/WARN/FAIL sections for bots, AH, gear, vendors, professions, travel/maps, Composer catalog, classes/races, PvP/systems and automated rewards.
  - Current sections include caps, RNDbot quarantine, maps, future Composer-map leakage, active bot classes/races/professions, AH profile drift and ERA-07 provenance profile/coverage. Existing-auction stock and stored RNDbot equipped gear are scanned; the integrated vendor/reward slice adds automated vendor catalogs, pending Titan rewards, AI Guild stock and queued automated purchases. PvP/geography and broader world-content scans remain TODO.

- [ ] **ERA-03 — Strict bot era rules — PARTIAL**
  - Existing foundation: Composer anti-boost and bot-to-master progression sync.
  - Bot progression sync is now bounded by the central live EraPolicy so dirty/future progression cannot be copied into earlier-era bots.
  - Composer now derives its bot peer band from the lowest real human (+/-3), clamps it to the activity floor and live realm cap, and revalidates that band at planning/preparation/assembly boundaries.
  - Runtime Playerbots max-level/brackets now follow the central 60/70/80 era cap; Composer candidates and automated RaidRoster gear prep reject over-cap bots.
  - RNDbot pre-login/active-population quarantine is implemented in slice 4b.
  - ERA-07 slice 2 gates deterministic RaidRoster/Group Composer synthetic gear selection against central item provenance and audits stored RNDbot equipped gear; it does not mutate contaminated stored gear.
  - Guild/persistent-bot policy plus future-era enchants/gems/glyphs/consumables/recipes and other Playerbots randomization paths remain TODO.

- [ ] **ERA-04 — Bots progress with the world — TODO**
  - Expansion release raises what existing bots may grow into.
  - Do not replace the world with instant max-level raid-ready bots.
  - Preserve persistent bot identity and history across expansion transitions.

- [ ] **ERA-05 — Era-aware bot geography — TODO**
  - Vanilla population centered in Kalimdor/Eastern Kingdoms.
  - TBC shifts appropriate bands/endgame toward Outland.
  - WotLK adds Northrend.
  - Avoid unreleased-continent bot activity and obvious player-follow teleport spam.

- [ ] **ERA-06 — Era-aware Auction House profiles — PARTIAL**
  - Named Vanilla/TBC/WotLK market profiles are implemented in `configure-ahbot.sh` with a persisted profile marker and audit drift check.
  - Category containment is implemented: Vanilla no Gems/Glyphs; TBC Gems/no Glyphs; WotLK both; seller equip/use ceiling is 60/70/80.
  - The old unconditional Wrath consumable boosts are now WotLK-profile-only; fresh configuration defaults to Vanilla. Full legal-stock provenance remains ERA-07.

- [ ] **ERA-07 — Item expansion-provenance filtering — IN PROGRESS**
  - Slice 1 is exact-head local-CI green at `44adb851`: exact pinned Classic/TBC/WotLK DB identity determines earliest expansion without level/item-ID chronology guesses.
  - Slice 2 is exact-head local-CI green at `e96d009`: generated chronology is central EraPolicy state, all three blocklists coexist, the live world item set is fingerprinted, setup/update regenerate it, existing auctions + stored RNDbot equipment are audited, and deterministic RaidRoster/Group Composer gear prep is gated.
  - Slice 3 is exact-head GitHub-CI green at `e990dff5`: PlayerbotFactory item generation uses central readiness/allow callbacks applied through a strict post-patch transformer, and AdventureStart/catch-up fail before destructive/one-time state changes.
  - Slice 4 is exact-head GitHub-CI green at `e1a2e6fa`: Adventure Cache direct gear/potion rewards use central provenance and pending rewards survive provenance failure.
  - Slice 5 source `9499939`, integrated at `304aee8d`, is **IMPLEMENTED / exact-head local CI required**: Titan Rune vendors/exchange/pending rewards/Gamma signets and AI Guild stock/mail/AH/item-service helpers fail closed on unavailable/future/UNKNOWN provenance; four custom Titan IDs are reviewed WotLK overrides and audit coverage is extended.
  - UNKNOWN IDs fail closed for protected automation; explicit overrides are the review ledger.
  - Still TODO: runtime provenance generation evidence, protocol loot injection, recipe discovery/profession crafting, ordinary loot/crafting/recipes, enchant-spell chronology, ArenaRoster PvP gear generation and remaining non-PlayerbotFactory item paths.

- [ ] **ERA-08 — Profession progression — PARTIAL**
  - Central EraPolicy now defines Vanilla 300, TBC 375, WotLK 450 and audit detects over-cap active RNDbot profession skills.
  - Central policy marks Jewelcrafting from TBC.
  - Central policy marks Inscription from WotLK.
  - Trainers, recipes, bot profession behavior and crafting systems obey the policy.

- [ ] **ERA-09 — Expansion-specific classes and races — PARTIAL**
  - Central policy + Composer/RaidRoster server paths now enforce Death Knight only in WotLK; Group Composer 0.15.3 also hides DK in the Build Selector before WotLK.
  - Central policy + Composer/RaidRoster candidate paths now enforce Blood Elf/Draenei from TBC.
  - Enforce Vanilla Alliance Paladin / Horde Shaman rules where technically practical.
  - Server enforcement wins over merely hiding options in an addon.

## Group Composer era identity

- [ ] **ERA-10 — Era-aware Group Composer — PARTIAL**
  - Existing foundation: three-era activity browser and progression gates.
  - Activity Browser/Progression now default to the highest released era relevant to the character.
  - Dungeon difficulty choices expose locked/inapplicable states, and backend validity follows the selected activity's era.
  - Current era dominates the UI.
  - Older released content becomes Legacy/Leveling/Attunement.
  - Future content hidden or Journey-preview locked.
  - Class/spec selectors obey active era: Death Knight is hidden before WotLK; remaining race/faction-era presentation work is still TODO.

- [ ] **ERA-11 — Different raid-composition brain per era — PARTIAL**
  - Vanilla: 40/20-man class-heavy planning, faction restrictions and Vanilla utility.
  - TBC: 25/10-man, optimize each five-player subgroup for party-local buffs/totems/synergy.
  - WotLK: 10/25-man raid-wide utility/buff optimization.
  - Review explains placement decisions.

- [ ] **ERA-12 — Classic dungeon workflow for Vanilla/TBC — PARTIAL**
  - Vanilla/TBC use Composer group formation + reviewed prepare/travel rather than pretending Wrath RDF is the native experience.
  - WotLK can hand Random Normal/Heroic to Blizzard RDF where appropriate.
  - Classic LFG Board may become the social front end later under FEATURE-02.

## World/system lifecycle

- [ ] **ERA-13 — Era-aware vendors and currencies — PARTIAL**
  - No future badges/emblems/catch-up/reputation rewards.
  - Automated regear/prep cannot obtain later-era vendor items.
  - Integrated ERA-07 vendor/reward slice gates Titan Rune reward catalogs, purchases/exchange, pending rewards and Gamma signets through central item provenance.
  - AI Guild automated/manual item-service helpers are provenance-gated before stock/treasury/inventory/request-state mutation.
  - Broader core vendors/currencies, quest/NPC cleanup, Titan Rune spawning/map lifecycle and other world-system containment remain TODO.

- [ ] **ERA-14 — Era-aware travel — PARTIAL**
  - Existing activity travel is progression-gated.
  - Central EraPolicy now derives map era from Map.dbc and gates Admin Panel / Group Composer teleport destinations.
  - Finish world-level Outland/Northrend portal/transport entry enforcement and remaining teleport paths.
  - Flying begins with TBC; Cold Weather Flying belongs to WotLK.

- [ ] **ERA-15 — Era-aware PvP — TODO**
  - Vanilla battleground lifecycle/rewards.
  - TBC arenas + TBC PvP progression.
  - WotLK arena lifecycle + Wintergrasp.
  - Bot level/gear rules apply equally to PvP.

- [ ] **ERA-16 — Later convenience-system gates — TODO**
  - Gate dual spec, glyph economy, heirloom acquisition and other clearly later gameplay systems where technically practical.
  - Investigate Barber Shop and similar later systems.
  - Unavoidable 3.3.5a client chrome is not the same thing as enabling later gameplay.

- [ ] **ERA-17 — Guild Bank lifecycle — TODO**
  - Investigate disabling normal Guild Bank access in Vanilla and enabling it with TBC.
  - Preserve safe migration of guild state.

- [ ] **ERA-18 — Quest/NPC/content leakage audit — TODO**
  - Identify obvious later-added old-world NPCs, quest hubs, vendors, rewards and changed loot that materially undermine earlier-era progression.
  - Prioritize meaningful leaks rather than attempting a blind full 1.12 database reconstruction.

- [ ] **ERA-19 — Era-correct bot dialogue/knowledge — PARTIAL**
  - Existing chatter/guild-life foundations exist.
  - Bots must know the current expansion/phase and avoid treating unreleased raids, continents, materials and events as current life.

- [ ] **ERA-20 — Expansion launch physically changes the world — PARTIAL**
  - Existing manual expansion-release foundation exists.
  - Finish portal/transport activation, population migration, AH profile expansion, Adventure Guide/Composer refresh, announcements/dialogue, Chronicle entry and post-release audit.

---

# Broader feature roadmap

## Administration, safety and onboarding

- [ ] **FEATURE-01 — Expansion Command Center — TODO**
  - Admin Panel control room for current era/phase, integrity, next-release preview, backup checkpoint, confirmation, transition and post-audit.
  - Depends heavily on ERA-01, ERA-02 and FEATURE-19.

- [ ] **FEATURE-18 — Friend onboarding portal at join.skrra.dev — PARTIAL**
  - Existing registration/addon-distribution groundwork and target hostname exist.
  - Finish friend-facing account registration, realm status/current era, client/addon setup, changelog and starter guidance while keeping admin/DB services private.

- [ ] **FEATURE-19 — Safe snapshot / rollback tooling — PARTIAL**
  - Snapshot DB + config + Git SHA + migration summary before major releases.
  - Clear restore instructions and guardrails against targeting the permanent dev realm accidentally.

- [ ] **FEATURE-20 — Optional challenge rules — TODO**
  - Opt-in Hardcore, Self-Found, no-AH, no-bot-assistance, slow-XP, reduced-raid-size profiles.
  - Must never contaminate canonical friends-realm progression.

## Social grouping, guild and persistent bots

- [ ] **FEATURE-02 — Classic LFG Board for Vanilla/TBC — TODO**
  - Human-created activity listings.
  - Friends join naturally; bots may volunteer for missing roles.
  - Convert accepted listing into a reviewed Group Composer plan.
  - No auto-completion of social decisions.

- [ ] **FEATURE-03 — Persistent Guild Bot Bench — PARTIAL**
  - Existing guild-bot preference/persistent roster foundations exist.
  - Add trusted named bench, preferred roles, gearing, attendance/clear history and Composer priority.

- [ ] **FEATURE-04 — Bot professions and crafting orders — TODO**
  - Search recipes, show required mats, use real player/guild materials, craft and deliver.
  - Never conjure missing materials.

- [ ] **FEATURE-05 — Guild Bank Steward — TODO**
  - Bots maintain configurable stocks, deposit useful materials and build raid-consumable kits.
  - Respect reserved/rare items and keep an explainable ledger.

- [ ] **FEATURE-06 — Dynamic World Population Director — TODO**
  - Organic player-aware bot activity in leveling zones, capitals, current hubs, BG queues, dungeon entrances and profession/economy spaces.
  - Integrates ERA-04/05 rather than fighting them.

- [ ] **FEATURE-15 — Bot relationships / identities — PARTIAL**
  - Existing chatter/guild relationship systems are the foundation.
  - Persist raid attendance, preferred roles, guildmates, recent adventures, professions and restrained personality tendencies.

- [ ] **FEATURE-17 — Raid Night Planner — TODO**
  - Schedule target raid, reserve real friends first, pin bench bots, inspect lockouts/utility and build the reviewed raid when participants are online.

## Guidance, readiness and raid intelligence

- [ ] **FEATURE-07 — Attunement / Progression Assistant — PARTIAL**
  - Existing exact unlock reasons and ordered NEXT STEP are foundations.
  - Finish actionable NPC/objective breadcrumbs, shared friend-step context and upcoming unlock explanation without auto-completing quests.

- [ ] **FEATURE-08 — Raid Readiness Planner — PARTIAL**
  - Existing gear-floor/utility/readiness systems are foundations.
  - Add enchants, era-valid consumables, resistance sets, repairs, ammo/reagents and class essentials.
  - Bots may be prepared automatically; humans remain advisory.

- [ ] **FEATURE-09 — Wipe Analyzer / Raid Coach — TODO**
  - Factual post-wipe timeline: first deaths, avoidable mechanics, missed interrupts/dispels, tank/healer failure, positioning/strategy failures.
  - Useful both to players and to Playerbot AI development.

- [ ] **FEATURE-14 — Smart Bot Loot Council — PARTIAL**
  - Existing Smart Loot is the foundation.
  - Add upgrade size, role/spec, set bonuses, duplicate waste and bench importance.
  - Human loot remains human-controlled; bot decisions get an explainable ledger.

## History, world flavor and identity

- [ ] **FEATURE-10 — Guild Chronicle / Trophy Room — PARTIAL**
  - Existing personal/guild clear history, first-clear roster and recent timeline are foundations.
  - Add expansion milestones, wipe history/first-kill context, notable loot and eventual website presentation.

- [ ] **FEATURE-11 — Character Journey page — TODO**
  - Personal timeline for levels, first dungeons/raids, attunements, notable drops, reputations and expansion transitions.

- [ ] **FEATURE-12 — Realm-first announcements — TODO**
  - Configurable meaningful firsts: 60/70/80, profession caps, raid clears, legendary milestones.
  - Keep frequency tasteful.

- [ ] **FEATURE-13 — Expansion Opening Event — TODO**
  - Countdown/announcement, faction-leader dialogue, portal/transport activation, bot gathering/migration and permanent Chronicle entry.
  - Works with ERA-20 and FEATURE-01.

- [ ] **FEATURE-16 — World Newspaper / Herald — TODO**
  - Weekly/recent realm events: clears, levels, guild milestones, expansion state and curated bot flavor.
  - Could be NPC/addon first and website-backed later.

---

# Execution sequence

This is the default order unless runtime evidence changes it.

## Phase 0 — Validate what already exists

- NOW-01 current Group Composer P0 runtime tests.
- Fix regressions before broad architecture work.

## Phase 1 — Build the era kernel

1. ERA-01 Central Era Policy.
2. ERA-02 Era Integrity scanner.
3. FEATURE-19 snapshot/rollback foundation early enough to protect future transition work.

## Phase 2 — Stop future-era leakage

4. ERA-03 strict bot era rules.
5. ERA-07 item provenance manifest.
6. ERA-06 AH profiles.
7. ERA-08 professions.
8. ERA-09 classes/races.
9. ERA-13 vendors/currencies.
10. ERA-14 travel.
11. ERA-15 PvP.
12. ERA-16 convenience systems.
13. ERA-17 Guild Bank lifecycle.
14. ERA-18 quest/NPC/content leakage.
15. ERA-19 chatter knowledge boundaries.

## Phase 3 — Make each expansion play differently

16. ERA-10 Group Composer era UX.
17. ERA-11 per-era composition brains.
18. ERA-12 Vanilla/TBC dungeon workflow.
19. ERA-04 gradual bot progression.
20. ERA-05 bot geography/population behavior.
21. FEATURE-02 Classic LFG Board.
22. FEATURE-06 Dynamic World Population Director.

## Phase 4 — Persistent guild life and raid tools

23. FEATURE-03 Bot Bench.
24. FEATURE-04 Crafting Orders.
25. FEATURE-05 Guild Bank Steward.
26. FEATURE-07 Attunement Assistant.
27. FEATURE-08 Readiness Planner.
28. FEATURE-09 Wipe Analyzer.
29. FEATURE-14 Smart Bot Loot Council.
30. FEATURE-15 Bot relationships.
31. FEATURE-17 Raid Night Planner.

## Phase 5 — Make the realm remember

32. FEATURE-10 Guild Chronicle.
33. FEATURE-11 Character Journey.
34. FEATURE-12 Realm firsts.
35. FEATURE-16 Newspaper / Herald.

## Phase 6 — Expansion-release experience

36. ERA-20 full world transition.
37. FEATURE-01 Expansion Command Center.
38. FEATURE-13 Expansion Opening Event.
39. FEATURE-18 Friend onboarding portal.
40. FEATURE-20 optional challenge profiles after the canonical experience is stable.

## Priority override rule

Runtime evidence beats this ordering. A blocker discovered while testing may jump ahead, but the reason and dependency change must be written into `PASS_LOG.md` and `NEXT_WORK.md`.


### WoWSims GearAdvisor simulation track

- **DONE + green:** 3.3.5a WoWSimsBridge export foundation and GearAdvisor v0.3 authority change at `c420b300`.
- **IN PROGRESS:** private Docker-network WoWSims service with pinned Classic/TBC/WotLK CLI engines and baseline-vs-candidate comparison.
- **NEXT:** authoritative worldserver request builder, support/validation matrix enforcement, candidate item swap, addon transport and human-readable cap/stat trade explanation.


### WoWSims authoritative-state boundary

- **DONE + green:** private pinned-engine service foundation at `aba336fd`.
- **DONE + green:** worldserver-owned character snapshot and structural model validation at `0e4fadb2`.
- **DONE + green:** pinned per-era model coverage catalog repair at `7c959151`.
- **DONE + green:** engine-native preset harvesting at `998d297a` (Vanilla 24/15 routes, TBC 15/15, WotLK 37/33).
- **IN PROGRESS:** authoritative snapshot overlay, baseline RaidSimRequest construction, candidate slot mutation, asynchronous service queue and addon result/explanation protocol.


### 2026-09-21 WoWSims candidate isolation follow-up
- baseline authoritative request builder is exact-head green at `f3e17eb7`;
- candidate request builder is the current local-CI slice with exact one-slot structural diff enforcement;
- automatic simulation remains disabled at this boundary;
- server-authoritative bag enumeration is the intended source for future “Sim Bags” candidate state;
- GearAdvisor v0.3.2 fixes the key-stat label/value row alignment before runtime visual acceptance.


### 2026-09-21 WoWSims Sim Bags manifest slice
- candidate-isolation prerequisite `8d3ff2be` is exact-head green;
- current slice moves bag-candidate discovery to authoritative worldserver Item objects;
- service validates one-slot swap manifests and fingerprints without sim execution;
- ambiguous preset resolution + async execution remain the next WoWSims milestones.


### 2026-09-21 WoWSims canonical-preset slice
- Sim Bags manifest checkpoint `52ac5255` is exact-head green;
- current slice defines canonical preset selection without arbitrary source ordering;
- character fields that the worldserver always overwrites are removed before comparing harvested preset assumptions;
- multi-candidate routes auto-resolve only when all surviving assumptions are equivalent;
- non-equivalent routes fail closed at image build rather than selecting silently;
- next simulator milestone remains asynchronous compare execution and result transport.


### 2026-09-21 WoWSims preset-policy repair
- candidate `4ba6b74d` is failed/superseded after the real Classic image exposed legitimate non-equivalent route variants;
- phase families within one talent build select the latest pinned upstream phase;
- distinct talent builds remain runtime-selectable by unique closest live talents;
- unresolved/tied cases fail closed;
- real-image CI must report selectableRouteCount == routeCount for every era before the slice can be green.


### 2026-09-21 WoWSims asynchronous comparison slice
- integrated/preset-policy base `66c13cb1` is exact-head green on all four workflows;
- current slice moves full Sim Bags comparisons off the world thread;
- service reuses one baseline simulation for the complete candidate batch;
- worker inputs are immutable serialized snapshots/candidates only;
- tank comparisons remain fail-closed until an approved survivability metric exists;
- result status remains UNVALIDATED; GearAdvisor transport and mechanics validation remain next.


### 2026-09-21 GearAdvisor automatic Sim Bags transport slice
- async execution + real-image glyph-aware preset routing are exact-head green at `d449136f`;
- current slice delivers queue/result/stale/error state into GearAdvisor through a 3.3.5a-compatible system-message protocol;
- queue-time character and bag snapshots are revalidated before delivery;
- unvalidated models cannot render authoritative UPGRADE/DOWNGRADE language;
- manual WoWSims export remains available;
- cap/stat trade explanations and route promotion to SIM_BACKED remain later validation work.
