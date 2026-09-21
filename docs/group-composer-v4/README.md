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
