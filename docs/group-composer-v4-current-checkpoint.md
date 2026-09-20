# Group Composer V4 — Current Checkpoint

_Last updated: 2026-09-20_

## Verified branch state

Repository: `Stoffe101/azerothcore-playerbots`

Branch: `test/group-composer-v4`

Verified green implementation checkpoint before this documentation update:

`28f72c40d557b49116b4ff670b2b8f3fcac53c56`

Commit:

`test: checkpoint journey diagnostics and history [github-ci]`

The PC runner was intentionally offline, so this development round used GitHub-hosted CI.

Exact-checkpoint results:

- Group Composer client checks: **SUCCESS**
- Stage Group Composer V4 backend: **SUCCESS**
- Integration build: **SUCCESS**
- Group Composer V4 compile: **SUCCESS**

Do not confuse "build green" with "gameplay release-tested". The code checkpoint is green; several systems below still require real in-game validation.

---

## What this development round completed

### Persistent adventure progression history

Progression history no longer depends on the optional first-kill bounty/economy table.

New characters-database storage records real-player instanced boss kills with:

- player GUID;
- guild ID at the time of the kill;
- map ID;
- instance ID;
- creature/boss entry;
- difficulty;
- group size;
- kill timestamp.

A per-character summary also tracks:

- clear count;
- first kill time;
- last kill time;
- first/last guild association;
- first/last group size.

The implementation deliberately ignores Playerbots as history owners.

The Progression page now receives personal/guild clear counts and first-clear dates for activities that have a final boss configured in the authoritative Adventure Catalog.

Older test-realm bounty rows remain a compatibility fallback so existing historical clears do not disappear.

### Raid lockout awareness

Group Composer now reads AzerothCore's actual raid instance binds.

For supported raid activities it can report:

- whether the player has an active bind;
- saved instance ID;
- completed encounter-mask count;
- whether the bind is extended.

The Progression page displays active lockout information.

Recommended Activities can prioritize an unfinished saved raid as:

**Resume active lockout**

instead of presenting it as if the player were starting a fresh run.

### Activity Diagnostics page

A new development-facing **Diagnostics** page validates Group Composer's activity catalog against live server metadata.

It checks activity records for:

- unique IDs and names;
- valid Map.dbc entries;
- canonical AzerothCore entrance triggers;
- era-appropriate minimum levels;
- valid group/raid sizes;
- stock Normal RDF entries where relevant;
- configured final-boss creature templates;
- Playerbots support classification and notes.

Results are classified:

- **PASS**: structural data looks valid;
- **WARN**: structurally usable, but support is partial/experimental or stock RDF is unavailable;
- **FAIL**: a structural issue could make the activity unsafe or misleading.

This gives us a server-backed sanity scanner instead of manually discovering every broken catalog row in-game.

### Previously completed features preserved in this checkpoint

The checkpoint also retains the larger V4 work completed immediately before this round:

- true Vanilla -> TBC -> WotLK realm-era gating;
- era-aware level caps and progression ceilings;
- era-aware dungeon difficulty rules;
- Random Classic/TBC/WotLK Dungeon Finder routing;
- exact lock explanations for levels, progression, quests, keys/items and achievements;
- Vanilla/TBC/WotLK activity browser;
- Favorites and Recent Activities;
- saved dungeon party templates;
- Progression page;
- Recommended Activities page;
- explicit Build & Prepare -> Assemble -> Teleport lifecycle;
- Group Actions after assembly;
- Rebuild / Repair Roster;
- Leave Instance Together;
- safe Disband Composer Group;
- server-authored Why This Bot explanations;
- anti-boost peer-level bot limits;
- Azeroth Control three-era integration;
- test-realm versus future fresh-release-realm separation.

---

## What is code-complete but still needs in-game validation

These are implemented and CI-tested, but should not yet be treated as proven gameplay behavior:

- persistent boss clear counts/dates;
- guild clear aggregation;
- raid lockout display;
- Resume active lockout recommendations;
- Activity Diagnostics output against the running realm;
- anti-boost bot selection across low-level Vanilla/TBC content;
- Random Classic Dungeon Finder handoff;
- saved dungeon templates in real client use;
- Rebuild / Repair after a member disappears;
- Leave Instance Together;
- safe Composer disband;
- Why This Bot popup content;
- full three-era release flow;
- exact activity access reasons across the complete catalog.

---

## What is still left to build

### Higher-priority remaining product work

1. **Smarter Recommended Activities**
   - gear/item-level upgrade opportunities;
   - unfinished attunements/quest chains;
   - catch-up activity suggestions;
   - guild-bot availability;
   - actual roster feasibility;
   - stronger guild progression context.

2. **Richer raid readiness**
   - pre-assembly warnings for encounter-specific composition needs;
   - consumable/readiness summaries;
   - clearer "this group can enter but is probably not ready" distinction.

Multi-human raid lockout conflicts are now handled by the co-op preflight: Composer compares the selected raid/difficulty's real AzerothCore instance binds for every online human anchor and blocks conflicting saved instance IDs before roster assembly.

3. **Progression history v2**
   - explicit Composer activity ID in history;
   - complete participant roster per clear;
   - first-guild-clear record;
   - richer difficulty/size presentation;
   - potentially a guild history/timeline view.

4. **Playerbots encounter validation**
   - run real Vanilla/TBC/WotLK encounters;
   - promote Playable -> Guild Ready only after successful mechanic testing;
   - improve AI strategies where testing reveals failures.

5. **Fresh release realm tooling**
   - preserve the current realm permanently as the dev/test realm;
   - create a guarded clean-realm procedure;
   - start the eventual friends realm at Vanilla with no debug/test history;
   - keep migrations/config/code identical to the tested release checkpoint.

6. **Friend/public access**
   - `wow.skrra.dev` for the WoW realm hostname;
   - optional `join.skrra.dev` for HTTPS registration/onboarding;
   - public IPv4 / CGNAT check;
   - router/firewall forwarding of only WoW auth/world ports;
   - keep MySQL, SOAP, Ollama and internal sidecars private.

---

## Next test session

When the server PC is back on, deploy the latest green code with:

```bash
git switch test/group-composer-v4
git pull
./update.sh
```

Then start with the development realm. Do **not** create the fresh friends realm yet.

Suggested order:

1. open Group Composer Diagnostics and inspect every FAIL/WARN;
2. test a genuinely low-level Vanilla character and confirm overleveled bots are rejected;
3. test Vanilla dungeon browsing and Random Classic RDF;
4. test persistent raid clear history with a real boss kill;
5. test an active raid lockout and Resume active lockout;
6. test Group Actions and Why This Bot;
7. manually release TBC on the test realm and repeat era checks;
8. manually release WotLK and test Titan Rune/WotLK-only behavior.

Any runtime failure should be fixed on `test/group-composer-v4` and sent through the appropriate CI path before moving forward.

---

## CI rule

When the PC is online and we deliberately want the self-hosted build, use `[local-ci]`.

When the PC is offline, use `[github-ci]`.

For every release-worthy Group Composer checkpoint, verify the exact SHA against:

1. Group Composer client checks
2. Stage Group Composer V4 backend
3. Group Composer V4 compile
4. Integration build

Never call a checkpoint green until all four relevant workflows for that exact SHA have completed successfully.
