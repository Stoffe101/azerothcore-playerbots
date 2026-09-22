# Group Composer V4 — Canonical Handoff

> **READ THIS FIRST in every new chat/session.**
>
> This folder is the live source of truth for Group Composer V4 and the surrounding WoW-server work. If an older document elsewhere in `docs/` conflicts with this folder, **this folder wins** unless a newer commit explicitly says otherwise.

## Repository and branch

- Repository: `Stoffe101/azerothcore-playerbots`
- Active branch: `test/group-composer-v4`
- Permanent development realm: dirty/test realm, never wipe it to make the friends realm.
- Future release realm: separate clean Vanilla-first realm after gameplay validation.
- Technical base: AzerothCore + Playerbots, WoW WotLK 3.3.5a build 12340.

## How a fresh chat should resume work

1. Read this file.
2. Read `CURRENT_STATE.md`.
3. Read the newest entries in `PASS_LOG.md`.
4. Read `NEXT_WORK.md`.
5. Read `MASTER_ROADMAP.md` for the accepted 40-item execution board and current statuses.
6. Use `TEST_MATRIX.md` when the user is actively testing.
7. Read `ERA_FIDELITY.md` before changing expansion gates, bots, economy, world availability, templates, classes or release flow.
8. Use `DEVELOPMENT_RULES.md` before changing code or CI.
9. Verify the actual branch head and exact-head GitHub Actions results before claiming anything is green.
10. Read `FEATURE_IDEAS.md` for long-form feature rationale rather than re-inventing ideas from chat history.
11. Treat runtime screenshots/results from the user as newer truth than assumptions in older design prose.

## Documentation rule for every future pass

Every meaningful development/runtime pass must update documentation **before it is considered complete**:

- `CURRENT_STATE.md`: current branch state, latest verified green implementation, active runtime findings.
- `PASS_LOG.md`: append what the pass changed, why, CI result and what it exposed next.
- `NEXT_WORK.md`: update only when priorities/backlog change.
- `TEST_MATRIX.md`: update when a new test becomes required, passes, fails, or is blocked.
- `DEVELOPMENT_RULES.md`: update only when workflow/deployment rules change.
- `ERA_FIDELITY.md`: update whenever expansion-stage behavior, economy/world gating, bot-era behavior or release-transition rules change.
- `FEATURE_IDEAS.md`: long-form design/rationale for approved and future feature concepts.
- `MASTER_ROADMAP.md`: canonical accepted execution board. Update status/checkbox/dependencies whenever one of the approved ERA/FEATURE items moves.

Historical design docs stay in the repository, but do not force a new chat to reconstruct the present from archaeology.

## Accepted roadmap rule

The user has explicitly approved all 20 era-relevance items and all 20 broader feature items captured in `MASTER_ROADMAP.md`. They are no longer speculative suggestions. They are approved backlog, but **approval does not mean implemented**. Work them in dependency order and cross them off only when the DONE rule in `MASTER_ROADMAP.md` is satisfied.

## Canonical expansion-stage contract

`ERA_FIDELITY.md` defines what Vanilla → TBC → WotLK means across Group Composer, bots, AH/economy, items, professions, world access and release transitions. The design is canonical; individual enforcement items remain tracked as TODO until implemented and runtime-proven.

## Latest verified planning/documentation checkpoint

Accepted master-roadmap checkpoint:

- `b1d1d896c9b1b4f249532de0d6b5244e40615798`
- Commit: `docs: promote accepted era and feature master roadmap [local-ci]`
- Group Composer client checks: **SUCCESS**
- Stage Group Composer V4 backend: **SUCCESS**
- Group Composer V4 compile: **SUCCESS** on `stoffes-pc`
- Integration build: **SUCCESS** on `stoffes-pc`

This checkpoint records all 40 user-approved roadmap items with stable IDs/statuses. It changes documentation/planning only; it does not claim TODO/PARTIAL systems are implemented.

## Current verified implementation checkpoint

Latest fully verified green implementation checkpoint:

- `e96d009552b01a84d7e70f4a8956b33b34900843`
- Commit: `feat: centralize ERA-07 item policy [local-ci]`
- Group Composer client checks: **SUCCESS**
- Stage Group Composer V4 backend: **SUCCESS**
- Group Composer V4 compile: **SUCCESS** on `stoffes-pc`
- Integration build: **SUCCESS** on `stoffes-pc`

The documentation checkpoint `253c22880c98ca89ed1abec65b2fa2ef8a46020a` is also exact-head green. ERA-07 slice 2 promotes provenance from an AH-only consumer into central EraPolicy, regenerates all three era blocklists automatically during setup/update, fail-closes deterministic RaidRoster/Group Composer gear preparation when chronology is missing/stale, and extends `.era audit` to existing auction stock plus stored RNDbot equipment.

Current client QoL pass: **DONE + exact-head GitHub-hosted CI green at `de842ba842721f32d588ba5d9818b872f9a6c805`**. The distributed addon bundle adds the maintained NoM0Re WeakAuras 3.3.5a backport and maintained Details-WotLK fork, supersedes the old ExtendedCharacterStats bundle entry with the new GearAdvisor character-side panel, and pins external addon inputs for reproducible downloads. Because `stoffes-pc` is currently offline, this pass uses `[github-ci]`.

GearAdvisor v0.2.0 visual/data polish is now prepared: wider/native-tooltip panel chrome, spec icon, aligned cap label/value columns, cap hover explanations, seven key-stat rows where needed, screen-edge-aware left/right anchoring, a panel close control instead of a CharacterFrame text button that could overlap Blizzard header text, explicit Vanilla/TBC warning for WotLK-only priority prose, and corrected Arms/Feral guidance. Runtime appearance still needs an in-game acceptance pass.

Current ERA-07 work: **slice 3 DONE + exact-head GitHub-hosted CI green at `e990dff5cd6e8c7fa317d4b94840320eb6b73adb`**. The final design replaces the fragile PlayerbotFactory static diff with `tools/apply-playerbot-era-item-policy.py`, a strict post-patch transformer run after the complete wrapper + EraTalents stack in setup, update, Integration and Group Composer compile. Central provenance is the authoritative item allow/veto layer; older Playerbots/EraTalents heuristics remain only as conservative backstops. Slice 4 is now **DONE + exact-head GitHub-hosted CI green at `e1a2e6fa89e375290247b42099c12dca8203c414`**: direct Adventure Cache gear/potion rewards use the same central policy and pending caches survive provenance failure.

The peer policy is generic: the **lowest real human at any level** is the peer target. Status exposes `Lowest-human target Lv X · bots Lv A-B` so arbitrary mixed-level groups can be checked directly. Examples such as 80+14 or 80+23 are illustrative only.

All changed runtime behavior still requires in-game observation before the corresponding `TEST_MATRIX.md` rows become PASS.

The earlier one-shot per-account **Vanilla-fresh next-character override** remains available for genuine low-level testing on the WotLK dev realm.

## North star

Build a private WoW world that can be developed on WotLK 3.3.5a while delivering a deliberate Vanilla → TBC → WotLK journey, populated by persistent Playerbots, with Group Composer making parties/raids easy enough that friends can choose an activity and play without GM-command babysitting.


### GearAdvisor v0.2.1 / WoWSims v0.3 direction

GearAdvisor v0.2.1 is **DONE + exact-head local-CI green at `1f5ef71cef6d1d18dc33e25a876f6e50b7d1caa5`** on `stoffes-pc`.

The next client slice is **IN PROGRESS / local CI required**: GearAdvisor v0.3 removes static stat-priority text as an upgrade authority and integrates a new Interface 30300 `WoWSimsBridge`. WoWSims Classic/TBC/WotLK becomes the authoritative upgrade engine when the exact era/spec model is supported and validated. Unsupported models must say so rather than falling back to invented/Pawn weights. See `WOWSIMS_INTEGRATION.md`.


WoWSims bridge CI note: exact head `97178c40` is **not green**. The client workflow YAML was malformed by the editing layer before a job could start; this did not establish an addon/runtime failure. A clean workflow reconstructed from the previously green `1f5ef71c` file is the current repair, and the next exact head must pass all four workflows on the intended local-CI route.


### WoWSims automatic backend checkpoint

WoWSimsBridge v0.1 / GearAdvisor v0.3 repair checkpoint `c420b300cf41455c7f20630b37fdbe37e4b744b4` is **fully green on all four exact-SHA workflows**.

Current implementation slice: `wowsims-service/` packages the three pinned WoWSims CLIs behind a private Docker-network API with single-sim and baseline-vs-candidate comparison endpoints. This is backend plumbing only until the worldserver request builder and GearAdvisor transport are connected.


### Authoritative WoWSims snapshot slice

The private simulator service foundation is exact-head green at `aba336fd00fae61ac1b2e12af070eba1359b0917`.

Current slice moves character truth to the worldserver. The server serializes live gear/enchant/gem/talent/glyph/profession/role/era state and the private service validates the snapshot without yet claiming that the model is simulation-authoritative. `.wowsims snapshot` and `.wowsims validate` are diagnostic commands for this boundary.


### Pinned WoWSims model catalog

Authoritative snapshot checkpoint `0e4fadb25c06462fb485831bb0875b07979b0ff4` is **fully green on all four exact-SHA workflows**.

Current slice replaces ad-hoc model naming with `data/wowsims/model-support.json`. Each Vanilla/TBC/WotLK route is tied to the exact pinned engine commit and exact `proto/api.proto` Git blob. Engine presence is still labeled `ENGINE_PRESENT_UNVALIDATED`; a route does not become SIM-BACKED until Skrra preset/mechanics validation is completed.


### Engine-native WoWSims preset harvesting

Model-catalog repair checkpoint `7c9591511ff25839812bfc99e78cf8cec4f5e9bd` is **fully green on all four exact-SHA workflows** and is the stable base for this slice.

The next layer harvests the pinned engines' own `FullCharacterTestSuiteGenerator` **Average** `RaidSimRequest` objects instead of manually recreating rotations, consumes, raid buffs, debuffs, encounter defaults and spec options. The production `wowsimcli` binaries are built before the temporary test-harness instrumentation, so the shipped CLIs remain exact upstream builds from the pinned commits.


### WoWSims preset checkpoint and addon layout-safety pass

Engine-native preset harvesting is **DONE + exact-head local-CI green at `998d297a7f38e941740c41bdc972842157de0e97`**. All four workflows succeeded, including both heavy jobs on `stoffes-pc`.

The real service image harvested:
- Vanilla: **24 requests / 15 routes**;
- TBC: **15 requests / 15 routes**;
- WotLK: **37 requests / 33 routes**.

These are reproducible engine-native preset candidates, not automatic SIM-BACKED approval. The next simulation slice overlays the authoritative worldserver snapshot onto a selected preset and constructs equivalent baseline/candidate requests.

Current client follow-up is a layout-safety pass: GearAdvisor v0.3.1 gets larger bounded era/simulation explanation regions, Group Composer buttons receive bounded labels, Activity Browser cards receive explicit two-line status space, and Recommendations reserve separate copy/action columns. TypeScript source and `GroupComposerModernUI.lua` move together. Real 3.3.5a visual acceptance remains required.


### Addon layout-safety checkpoint

Exact SHA `c9690919ab40c8d40c3af20fdb2e5847ca59bbf3` is **fully exact-head local-CI green**:
- Group Composer client checks: SUCCESS;
- Stage Group Composer V4 backend: SUCCESS;
- Group Composer V4 compile: SUCCESS on `stoffes-pc`;
- Integration build: SUCCESS on `stoffes-pc`.

This locks the static/client contract for GearAdvisor v0.3.1 and the Group Composer text-bound changes. Real 3.3.5a visual/runtime acceptance is still required before calling the UI visually accepted.


### Baseline request green + candidate isolation follow-up

Exact SHA `f3e17eb7dec14e5dcb272c77c981bef798aa320d` is **fully exact-head local-CI green** on client checks, backend staging, Group Composer compile and Integration. It establishes authoritative snapshot -> pinned preset -> baseline RaidSimRequest construction without running the simulator.

The next candidate keeps simulation disabled and adds:
- `POST /v1/snapshot/candidate-request`;
- one explicit equipment-slot mutation;
- recursive proof that no request data outside that slot changed;
- fail-closed handling for no-op swaps, invalid slots and unrepresentable WotLK random-property state;
- GearAdvisor v0.3.2 key-stat row alignment repair.

### Candidate-isolation checkpoint

Exact SHA `8d3ff2bea0f73092aeecac9653ae767cbc58a568` is fully exact-head local-CI green:
- Group Composer client checks: SUCCESS;
- Stage Group Composer V4 backend: SUCCESS;
- Group Composer V4 compile: SUCCESS on `stoffes-pc`;
- Integration build: SUCCESS on `stoffes-pc`.

This locks one-slot candidate request isolation, WotLK random-property fail-closed behavior and GearAdvisor v0.3.2 row alignment at the source/CI level. Real-client visual acceptance remains TODO.


### Sim Bags checkpoint + canonical preset selection

Exact SHA `52ac52552ff0a2c0920b391961887f52dd9ee7b6` is fully exact-head local-CI green on all four required workflows, including Integration on `stoffes-pc`. It locks the server-authoritative bag candidate manifest without executing simulations.

Current bounded slice: **IMPLEMENTED / exact-head local CI required**. The preset harvester now fingerprints only simulator assumptions that survive AzerothCore's authoritative character overlay. Single-preset routes are canonical directly; multi-preset routes auto-resolve only when every candidate is equivalent after removing server-owned character fields. Any remaining difference in rotation/APL, spec options, consumes, buffs/debuffs, encounter or sim assumptions fails the real image build instead of choosing arbitrarily. The service then selects exactly one canonical preset by default while retaining explicit SHA selection for diagnostics. Next after this boundary is green: asynchronous baseline/candidate compare execution off the world thread.


### Canonical preset repair after real-image evidence

Candidate `4ba6b74d8eeef844c53398c6ab3f44a9d089b862` is **FAILED / superseded**. Client checks passed and the focused backend checks passed, but the real pinned Classic image correctly rejected two kinds of non-equivalent Vanilla presets: phase-specific Elemental Shaman suites and Combat Rogue Daggers vs Sinister Strike builds.

The repaired policy keeps those meanings separate:
- same-talent phase variants select the latest upstream phase represented by the pinned engine;
- distinct upstream talent builds remain distinct route variants and the authoritative live talent string selects the unique closest build;
- equal-distance talent matches fail closed rather than selecting arbitrarily;
- identical post-overlay variants may still collapse deterministically;
- every route must be selectable by one of these explicit policies in the real Docker-image gate.

This remains preset selection only. No route becomes SIM-BACKED and no simulation is executed by this slice.


## Current ERA-07 automated vendor/reward integration candidate

Status: **IMPLEMENTED / exact-head local CI required**.

- Codex source commit: `9499939ed190af2d68989d69a99f7a58468be042` (`feat: extend ERA-07 to automated vendor rewards`), based on green WoWSims checkpoint `52ac5255...`.
- Integrated onto the newer WoWSims development line by merge commit `304aee8d759e52aa231705a91cc92417e43c206c`; none of the active WoWSims/GearAdvisor implementation files were replaced.
- Titan Rune Sidereal/Scourgestone vendor display, purchases and currency exchange now require ready/allowed central item provenance before currency can be spent.
- Pending Titan Rune rewards remain pending when provenance is unavailable or the item is not yet allowed; Gamma signets use the same fail-closed rule.
- AI Guild stock mail, conservation, automated AH buy/list flows and player-facing stock helpers now fail closed before item/stock/treasury/request-state mutation.
- Four reviewed custom Titan Rune currency/signet IDs are classified as WotLK in the central provenance override ledger.
- `.era audit` now inspects automated vendor catalogs, pending Titan rewards, AI Guild stock and queued automated purchases.
- Static/local checks passed on the Codex commit, but the integrated docs-synchronized head still requires the four exact-SHA workflows and runtime acceptance.
- ERA-07 and ERA-13 remain **PARTIAL / IN PROGRESS**. Protocol loot injection, AI Guild profession crafting/recipe discovery, ordinary loot/crafting/recipes, ArenaRoster PvP gear generation, broader quest/NPC/vendor cleanup and Titan Rune world-spawn/map lifecycle remain future slices.


### Integrated ERA-07 vendor/reward checkpoint and async WoWSims follow-up

Exact SHA `66c13cb1638fcb64fa66c3f96ab79c4490a072db` is fully green on all four required workflows. It includes the repaired WoWSims talent/phase preset-selection policy plus the integrated Codex ERA-07 automated vendor/reward guards.

Current bounded WoWSims slice: **IMPLEMENTED / exact-head local CI required**. Sim Bags comparison now has an asynchronous worldserver execution boundary: authoritative state is captured before enqueue, a worker performs the private service call, the service runs one baseline plus candidate simulations, and completion is drained back on the world thread. The status remains UNVALIDATED and tank item comparison remains fail-closed until a survivability metric is deliberately defined. GearAdvisor transport is the next simulator slice.


### Async WoWSims green + GearAdvisor transport

Exact SHA `d449136f406a942f4553b7adc54a972ce66837cd` is fully green on all four required workflows. This is the first checkpoint that simultaneously proves the real three-engine preset image after the Fire/Frostfire glyph discriminator and the off-world-thread Sim Bags C++ execution path.

Current slice: **GearAdvisor v0.3.3 automatic result transport / exact-head local CI required**. It adds an explicit Sim Bags action, stale-state rejection and a compact 3.3.5a system-message protocol. Current models remain unvalidated, so the UI must say UNVALIDATED GAIN/LOSS rather than claiming an authoritative upgrade.


### ERA-07 automated loot/crafting integration

Codex source `1fbb15f9295084147e3205383a84866e75e33683` is integrated on top of the fully-green GearAdvisor/WoWSims checkpoint `a8b56bd0674428f7a66b84af600f0ee8098ff821`. The source files did not diverge from Codex's `66c13cb1` base, so integration is conflict-free. Current status: **IMPLEMENTED / exact-head local CI required**.

Covered boundaries are Titan protocol loot injection, project-owned AI Guild queued/autonomous crafting and recipe-result checks, ArenaRoster synthetic gearing, and expanded `.era audit` coverage. The slice fails closed on unavailable/future/UNKNOWN provenance and introduces no chronology guesses or new item overrides. Ordinary AzerothCore world loot/recipe tables and broader upstream crafting remain later ERA-07 scope.

The previous GearAdvisor v0.3.3 Sim Bags transport head `a8b56bd0` is fully green on all four required workflows.
