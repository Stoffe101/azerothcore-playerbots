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
5. Use `TEST_MATRIX.md` when the user is actively testing.
6. Read `ERA_FIDELITY.md` before changing expansion gates, bots, economy, world availability, templates, classes or release flow.
7. Use `DEVELOPMENT_RULES.md` before changing code or CI.
8. Verify the actual branch head and exact-head GitHub Actions results before claiming anything is green.
9. Read `FEATURE_IDEAS.md` when planning the next major feature rather than re-inventing ideas from chat history.
10. Treat runtime screenshots/results from the user as newer truth than assumptions in older design prose.

## Documentation rule for every future pass

Every meaningful development/runtime pass must update documentation **before it is considered complete**:

- `CURRENT_STATE.md`: current branch state, latest verified green implementation, active runtime findings.
- `PASS_LOG.md`: append what the pass changed, why, CI result and what it exposed next.
- `NEXT_WORK.md`: update only when priorities/backlog change.
- `TEST_MATRIX.md`: update when a new test becomes required, passes, fails, or is blocked.
- `DEVELOPMENT_RULES.md`: update only when workflow/deployment rules change.
- `ERA_FIDELITY.md`: update whenever expansion-stage behavior, economy/world gating, bot-era behavior or release-transition rules change.
- `FEATURE_IDEAS.md`: curated idea bank. Keep speculative ideas here until they are intentionally promoted into `NEXT_WORK.md`.

Historical design docs stay in the repository, but do not force a new chat to reconstruct the present from archaeology.

## Canonical expansion-stage contract

`ERA_FIDELITY.md` defines what Vanilla → TBC → WotLK means across Group Composer, bots, AH/economy, items, professions, world access and release transitions. The design is canonical; individual enforcement items remain tracked as TODO until implemented and runtime-proven.

## Latest verified planning/documentation checkpoint

Era-fidelity + feature idea-bank checkpoint:

- `402ce7c3c1acfbf8a85ef5b6f3d0d1f8282b13f8`
- Commit: `docs: expand era fidelity and server feature backlog [local-ci]`
- Group Composer client checks: **SUCCESS**
- Stage Group Composer V4 backend: **SUCCESS**
- Group Composer V4 compile: **SUCCESS** on `stoffes-pc`
- Integration build: **SUCCESS** on `stoffes-pc`

This checkpoint changes documentation/planning only; it does not claim the TODO/PARTIAL era-fidelity systems are implemented.

## Current verified implementation checkpoint

Latest fully verified green implementation:

- `86ce6c8dc8bd6faddbe0ae1cbd98c082424e21d4`
- Commit: `feat: add canonical handoff and low-level test starter [local-ci]`
- Group Composer client checks: **SUCCESS**
- Stage Group Composer V4 backend: **SUCCESS**
- Group Composer V4 compile: **SUCCESS** on `stoffes-pc`
- Integration build: **SUCCESS** on `stoffes-pc`

This checkpoint includes the canonical handoff system and the one-shot per-account **Vanilla-fresh next-character override** for genuine low-level testing on the WotLK dev realm. Runtime behavior is still tested separately from build success.

## North star

Build a private WoW world that can be developed on WotLK 3.3.5a while delivering a deliberate Vanilla → TBC → WotLK journey, populated by persistent Playerbots, with Group Composer making parties/raids easy enough that friends can choose an activity and play without GM-command babysitting.
