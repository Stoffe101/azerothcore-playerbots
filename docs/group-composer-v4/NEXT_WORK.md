# Next Work / Backlog

This file is priority-ordered. Do not re-add items already marked implemented in `CURRENT_STATE.md`.

## P0 — Finish the current validation loop

1. **DONE:** one-shot low-level starter pass is green at `86ce6c8d`.
2. Deploy with:
   ```bash
   git switch test/group-composer-v4
   git pull
   ./update.sh
   ```
3. Re-test the runtime-pass-2 fixes:
   - existing bot tank + existing bot DPS shown as locked;
   - existing real human shown as locked;
   - Composer fills only missing roles;
   - Random Heroic reaches Blizzard RDF role check/search;
   - selector/recommendation text stays inside cards;
   - Raid Template tabs do not overlap.
4. Use `.ap nextstarter vanilla` to create a genuine low-level throwaway character.
5. Validate low-level anti-boost and Vanilla dungeon access with real Playerbots.

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

## P3 — Candidate feature bank

See `FEATURE_IDEAS.md` for the maintained idea list. Do not implement the entire idea bank blindly.

Highest-leverage candidates after P0/P1:
- Expansion Command Center;
- Classic-style Vanilla/TBC LFG Board integrated with Composer;
- persistent guild bot bench;
- bot crafting orders + guild-bank steward;
- dynamic world population director;
- wipe analyzer / raid coach;
- guild chronicle / trophy history;
- character journey page.

Promote one candidate at a time into P1/P2 only when its prerequisites are clear and the current runtime loop is stable.

## Possible polish after runtime evidence

Only build these if testing shows they add real value:
- richer consumables/readiness summary;
- more spec/talent-aware utility/buff coverage;
- richer per-clear analytics;
- safe quest-giver/location breadcrumbs where authoritative metadata supports them;
- recommendation weighting refinements based on actual recommendations seen in game.
