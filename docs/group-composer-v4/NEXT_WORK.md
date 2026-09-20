# Next Work / Backlog

This file is priority-ordered. Do not re-add items already marked implemented in `CURRENT_STATE.md`.

## P0 — Finish the current validation loop

1. **DONE:** one-shot low-level starter pass is green at `86ce6c8d`.
2. **DONE:** runtime-pass-3 implementation/CI is green at `91f8cff1`.
3. Deploy the green branch with:
   ```bash
   git switch test/group-composer-v4
   git pull
   ./update.sh
   ```
4. Re-test runtime pass 3:
   - existing human/bot anchors remain sticky and the single class icon aligns correctly;
   - only missing roles are filled;
   - Random Heroic reaches role check, queue and successful bot proposal acceptance;
   - Recommendation text remains fully inside cards;
   - Unlock Requirements cleanly overlays Activity Browser;
   - low-level Activity Browser/Progression default to Vanilla;
   - impossible Heroic/Alpha/Beta/Gamma choices are visibly locked;
   - Raid Template tabs remain clean.
5. Re-test the player-relative peer rule:
   - solo player: bots stay within +/-3 of that player, bounded by dungeon minimum and live realm cap;
   - multiple humans: lowest real human is the reference;
   - level 80 solo in a trivial Vanilla dungeon may use high-level peer bots;
   - level 80 + level 14 friend targets bots around level 14 (13-17 for a level-13 dungeon).
6. Keep using the one-shot `.ap nextstarter vanilla` lane for low-level validation.

## P0.5 — Security / launcher polish while runtime testing is unavailable

1. Admin Panel GM-only client authorization + server-authoritative command protection.
2. Group Composer clickable minimap launcher while retaining `/gc`.
3. Once exact-head CI is green, runtime validation remains TODO until a GM and a normal account can be tested.

## P0.6 — First new architecture pass after runtime validation / while P0 runtime evidence is blocked

Do **not** start all approved features at once.

As soon as P0 runtime validation is stable:

1. Promote **ERA-01 Central Era Policy** to IN PROGRESS.
2. Build **ERA-02 Era Integrity Scanner** on top of it.
3. Add **FEATURE-19 Safe Snapshot / Rollback** before destructive release-transition work.
4. Then follow the dependency order in `MASTER_ROADMAP.md`.

Why: one authoritative era source prevents forty independent gates from drifting, and the audit tells us where WotLK/TBC leakage actually exists before we patch systems blindly.

## P1 — Era-fidelity hardening before the fresh friends realm

Design source: ERA_FIDELITY.md.

1. **Central era policy + read-only Era Integrity audit** so every subsystem uses one source of truth.
2. **Bot population fidelity:** hard realm cap, quarantine/ignore over-cap dev bots, prevent future-era bot gear/prep.
3. **Group Composer era behavior:**
   - current-era header/filtering;
   - no DK before WotLK;
   - era-specific templates;
   - TBC subgroup/party-local utility optimization;
   - current-expansion-first recommendations;
   - Vanilla/TBC Composer travel rather than pretending Wrath RDF existed there.
4. **Auction House fidelity:** replace the current WotLK-only market setup with Vanilla/TBC/WotLK profiles, level guards and a reproducible future-item provenance filter.
5. **World-system gates:** profession caps, Jewelcrafting/Inscription, vendors/rewards, maps/transports, expansion-only classes/races where practical.
6. **Expansion release transaction:** forward-only TBC/WotLK unlock with preview, bot/AH/Composer reconciliation and post-change audit.
7. Add CI/runtime acceptance coverage for zero future-era leakage at Vanilla and TBC stages.

Do not destructively "clean" the permanent dev realm to simulate release. The future friends realm remains a separate fresh database/world state.

## P1 — Runtime correctness still unproven

- Persistent clear counter increments from actual final-boss kills.
- First guild-clear roster snapshots with bots + real humans.
- Recent guild-clear timeline after repeated clears.
- Active raid lockout / Resume recommendation.
- Second real human:
  - access blocker;
  - ordinary invitation;
  - saved-instance conflict;
  - human anchor stability.
- Rebuild/Repair after a member disappears.
- Leave Instance Together after real travel.
- Safe disband after live group mutation.
- Why This Bot rationale against real roster data.
- Favorites/templates persistence across reload/relog.
- Era talents remain correct across relog.
- Full Vanilla → TBC → WotLK manual release flow.

## P1 — Playerbots encounter validation

Catalog labels are not proof that AI can execute an encounter.

For every raid tier:
- run real composed groups;
- record the first mechanic bots fail;
- patch strategy/positioning/targeting only from observed failures;
- keep `Playable/manual` or `Not Ready` until successful;
- promote to `Guild Ready` only after repeatable runs.

## P2 — Release engineering after gameplay validation

- Safe procedure to create a separate fresh realm.
- Preserve dev realm untouched.
- Fresh characters/guild/progression DB state.
- Vanilla live era and level cap 60.
- No debug boosts/test clear history.
- Exact tested server/module/addon release commit.
- Backup + confirmation guards.
- Friend-facing onboarding.

## P2 — Public friend access

- Verify router WAN IPv4 versus outside public IPv4 / CGNAT.
- `wow.skrra.dev` DNS-only record to public endpoint.
- Forward only TCP 3724 and 8085.
- Keep DB/SOAP/webreg/lore/Ollama private.
- Optional `join.skrra.dev` through HTTPS reverse proxy or Cloudflare Tunnel.
- Normal friend accounts, no GM.

## P3 — Approved feature roadmap

All 40 approved ERA/FEATURE items are tracked in `MASTER_ROADMAP.md`; `FEATURE_IDEAS.md` contains the long-form rationale.

Do not implement all forty in parallel. Promote items according to the execution phases/dependencies in the master roadmap, while allowing runtime blockers to override priority when documented.

## Possible polish after runtime evidence

Only build these if testing shows they add real value:
- richer consumables/readiness summary;
- more spec/talent-aware utility/buff coverage;
- richer per-clear analytics;
- safe quest-giver/location breadcrumbs where authoritative metadata supports them;
- recommendation weighting refinements based on actual recommendations seen in game.
