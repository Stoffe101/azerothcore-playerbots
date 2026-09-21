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

Current ERA-07 work: **slice 3 integration repair in progress**. Static wrapper patch `0044` was abandoned after two exact-head attempts proved that PlayerbotFactory is rewritten by multiple wrapper/EraTalents patches and cannot safely be targeted as another order-sensitive unified diff. The replacement is `tools/apply-playerbot-era-item-policy.py`: a strict, fail-loud source transformer run after the complete patch stack in setup, update, Integration and Group Composer compile. Central provenance remains the authoritative item allow/veto layer; older Playerbots/EraTalents heuristics remain only as conservative backstops for now. Exact-head GitHub-hosted CI is still required before slice 3 is called green.

The peer policy is generic: the **lowest real human at any level** is the peer target. Status exposes `Lowest-human target Lv X · bots Lv A-B` so arbitrary mixed-level groups can be checked directly. Examples such as 80+14 or 80+23 are illustrative only.

All changed runtime behavior still requires in-game observation before the corresponding `TEST_MATRIX.md` rows become PASS.

The earlier one-shot per-account **Vanilla-fresh next-character override** remains available for genuine low-level testing on the WotLK dev realm.

## North star

Build a private WoW world that can be developed on WotLK 3.3.5a while delivering a deliberate Vanilla → TBC → WotLK journey, populated by persistent Playerbots, with Group Composer making parties/raids easy enough that friends can choose an activity and play without GM-command babysitting.
