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

Latest fully verified green implementation:

- `91f8cff1beeb6d09875c60a1b1aee7fab662c20f`
- Commit: `fix: repair RDF autoaccept patch format [local-ci]`
- Group Composer client checks: **SUCCESS**
- Stage Group Composer V4 backend: **SUCCESS**
- Group Composer V4 compile: **SUCCESS** on `stoffes-pc`
- Integration build: **SUCCESS** on `stoffes-pc`

This checkpoint contains **runtime pass 3** and addon version **0.15.0**: deterministic Playerbot RDF proposal acceptance, player-relevant era defaults, locked/inapplicable dungeon difficulties, Recommendation/modal/icon layout fixes, selected-activity-era difficulty validation, and the lowest-real-human +/-3 bot peer policy. The implementation is compile/integration green; the changed behaviors remain runtime-test TODO until observed in game.

### Active P0 observability follow-up

Runtime-pass-3.1 source commit: `b9ed63e5b82ad360e648bebd624dc85a3000bd94`.

Typed-UI generated bundle commit: `68adeb52bb1d50e3a4e7ff013f5a538895405837`.

This 0.15.1 follow-up does not change the lowest-human rule; it makes the already-generic calculation visible in status as `Lowest-human target Lv X · bots Lv A-B`. A level-14, level-23, level-31 or any other lowest real human is treated identically by the same formula. Exact-head CI must be checked on the newest `[local-ci]` follow-up before deployment.

The earlier one-shot per-account **Vanilla-fresh next-character override** remains available for genuine low-level testing on the WotLK dev realm.

## North star

Build a private WoW world that can be developed on WotLK 3.3.5a while delivering a deliberate Vanilla → TBC → WotLK journey, populated by persistent Playerbots, with Group Composer making parties/raids easy enough that friends can choose an activity and play without GM-command babysitting.
