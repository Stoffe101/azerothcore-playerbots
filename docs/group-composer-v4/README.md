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
6. Use `DEVELOPMENT_RULES.md` before changing code or CI.
7. Verify the actual branch head and exact-head GitHub Actions results before claiming anything is green.
8. Treat runtime screenshots/results from the user as newer truth than assumptions in older design prose.

## Documentation rule for every future pass

Every meaningful development/runtime pass must update documentation **before it is considered complete**:

- `CURRENT_STATE.md`: current branch state, latest verified green implementation, active runtime findings.
- `PASS_LOG.md`: append what the pass changed, why, CI result and what it exposed next.
- `NEXT_WORK.md`: update only when priorities/backlog change.
- `TEST_MATRIX.md`: update when a new test becomes required, passes, fails, or is blocked.
- `DEVELOPMENT_RULES.md`: update only when workflow/deployment rules change.

Historical design docs stay in the repository, but do not force a new chat to reconstruct the present from archaeology.

## Current checkpoint at the start of this documentation pass

Last fully verified green implementation before the current pass:

- `3b548b3d29539a1ae0816d10db0e943546d3626c`
- Group Composer client checks: success
- Stage Group Composer V4 backend: success
- Group Composer V4 compile: success on `stoffes-pc`
- Integration build: success on `stoffes-pc`

The active pass stored alongside this documentation adds a one-shot per-account **Vanilla-fresh next-character override** for genuine low-level testing on the WotLK dev realm. Do not call that new pass green until its exact commit completes the required workflows.

## North star

Build a private WoW world that can be developed on WotLK 3.3.5a while delivering a deliberate Vanilla → TBC → WotLK journey, populated by persistent Playerbots, with Group Composer making parties/raids easy enough that friends can choose an activity and play without GM-command babysitting.
