# Source completion and local acceptance gate

## Scope and branch

Working branch: `codex/integration-source-completion-2026-09-15`.
Base: `ef57dcb`, the fetched `origin/integration/bot-ai-refresh-2026-09-14`.
The separate checkout is `/home/skrra/AzerothCore-source-completion`.
No merge, history rewrite, force push, or deployment was performed.

The canonical context document and request were read before implementation. The live
integration, develop, main, backup and relevant historical feature refs were compared.
PR #19 remains an open draft targeting develop. Its current files and commits were inspected;
the conversation, review and inline-comment endpoints returned no discussion entries.
Historical branches were used to compare intent, with no wholesale merges.

## Fixes

### Pinned build and installation

- Correct the pinned faction API and map-to-instance-script accessor.
- Resolve the cache command's collision with Playerbots' real-player helper.
- Isolate PlayerbotFactory from Individual Progression's conflicting `GENERAL` enumerator.
- Close the missing raid-knowledge namespace.
- Split the updater's dependent `local` assignment so first-time module installation works
  under `set -u`.
- Pin the remaining compiled economy modules to the revisions used in this build. Both new
  pins were verified in their public upstream repositories. CI uses those same pins.
- Extend preflight to apply both new upstream patches and run the two policy regression tests.

### Starts and progression

- Reject disabled or above-ceiling profiles before changing level, kit or progression state.
- Validate the requested progression before applying the level boost.
- Preserve forward-only Individual Progression quest transitions, adjustment and phasing hooks.
- Stop first-login from force-resetting a starter kit already initialized by the login path.
- Track spec gear only for initialized starter profiles; clear poll state on logout.
- Preserve ordinary DK starting behavior while allowing deliberately raid-ready DKs to receive
  their spec gear after talents are assigned.
- Commit the full player save and initial/spec grant marker in one synchronous character-DB
  transaction. Refuse kit work during a far teleport, when the core defers full player saves.
- Make the catch-up schema upgrade repeatable.

### Guild persistence and economy

- Classify protected guilds by any member's account, including offline humans and humans in
  bot-led guilds. Read live membership instead of trusting an hourly negative cache entry.
- Add a small read-only guild-member predicate API to the pinned core; use it from Playerbots.
- Protect Randomize, RandomizeFirst, RandomizeMin and IncreaseLevel, as well as automated
  bot-guild deletion and assignment. Missing account/guild information is treated conservatively.
- Preserve normal recycling for guilds containing only random-account bots.
- Prevent entry/count guild stock from stripping bindings, wrapping or random properties.
  Deposits remove the exact eligible bag stacks and save inventory with the stock credit.
- Make the relationship-depth column additions repeatable.

### Raid communication

- Replace vocabulary-overlap grounding with ordered text equality after case/whitespace
  normalization. Changed assignments, negation, counts or additional mechanics fall back to
  deterministic wording. Semantic paraphrases are deliberately not accepted by this gate.
- Carry group, map, instance and creation time through the asynchronous reply queue.
  Discard briefs after combat starts, after a group/instance change, or after 30 seconds.
- Retain `storeMemory=false`; ordinary conversation observers accept human senders, so bot
  encounter narration does not enter social conversation memory through those observers.

### Titan protocols and rewards

- Preserve Dalaran/command next-run preferences and the separate in-dungeon device channel.
- Resolve missing human leaders conservatively. An explicit human-leader Off remains authoritative.
- Device activation no longer temporarily changes the leader's saved next-run preference.
- Validate group/leader identity again when a device channel finishes.
- Persist an activated protocol by map, instance and the instance save's reset deadline; restore it after map
  unload/restart. Remove saved activation when the core removes the instance ID.
- Reject invalid protocols and new activation after combat or encounter completion begins.
- Restrict protocol loot processing to creature and gameobject loot stores, excluding reuse by
  skinning or pickpocket processing.
- Use the pinned core's encounter-completion hook for currency, including scripted spell-credit
  encounters. Its `updated` flag identifies a newly completed encounter-mask bit.
- Include the reset deadline in reward deduplication. Save delivered inventory and the durable
  delivery marker in the same synchronous transaction. Full bags retain a pending reward.
- Resolve loot names with explicit compatible collation against stock `item_template` data.

### Dungeon navigation

- Extend Dungeon Clear's existing leader election with a human-only-tank guide. Prefer an alive
  DPS bot over a healer, then use a stable GUID tie-break. A bot tank, including a dead bot tank
  undergoing recovery, retains the normal tank-driven path.
- Keep the human's combat role and group/master flags unchanged. Suppress autonomous pulls,
  engagement and recovery combat maneuvers in guide mode; release the effective pull latch.
- Constrain route guidance to the human's vicinity and stop outside visible hostile aggro range.
  Truncate travel splines into short checked segments. Yield to normal following if the human
  moves beyond the guidance radius.
- Preserve encounter support for Oculus riders, HoR escape, hold-fire and scripted combat events,
  including the existing global encounter safety clamps.
- Auto-start on entry and login, retry while bots arrive, and detect a wipe even when a bot dies
  last. Track actual instance IDs. Run retries on player/map updates and stop timeout accumulation
  while the player is dead. Do not reset an enabled or manually paused run.

### Client packaging

- Correct the installer/archive output path to `client-dist/client-addons.zip`.
- Pin third-party addon git revisions, the Atlas archive commit and the WDM release.
- Strip Git metadata from the staged distribution; bundle only the selected WDM locale and
  explicitly enabled IP data patch.
- Preserve the existing TheraWoW-targeted installer and build-12340 client checks.
- The current pack is shared across resolutions. Historical 1080p/1440p/ultrawide work does not
  justify replacing it with an invented SavedVariables layout. The 3440x1440 visual arrangement
  still needs the real client, as documented by the existing client-pack workflow.

## Existing systems retained after inspection

- WotLK 3.3.5a/build 12340 remains the technical target; TBC profiles are progression profiles.
- AdventureProgressionStore remains authoritative; no obsolete progression cache was restored.
- Existing Era Talents allocation, point synchronization and Playerbot refresh paths were retained.
  No speculative refresh optimization was made to a feature already reported working in game.
- Titan family/difficulty checks, Confessor, Frost, Arcane/Tempo, Shadow/Web Wrap, Titan energy,
  Keeper/tentacle, Diminish Power, Sanity, damage suppression and Gamma helper logic remain.
- Frozen Halls retain their Gamma reward track with ordinary heroic scaling and mechanics.
- Alpha additive catch-up and token pools, Beta equipment replacement and Gamma's inherited loot
  layer stay in the normal loot pipeline before group-loot bookkeeping.
- Eregos/Tribunal/CoS/ToC chest aliases and Violet Hold common/random-lieutenant pools remain.
- Resource-backed stock, treasury, auction listings/purchases/deposits, reagent casting, travel,
  bank payloads and mail paths remain. No passive profession-gold or synthetic fulfillment was added.
- Ollama remains local/free-compatible dialogue, memory and wording support. It does not drive
  movement, spells or combat. WeakAuras remains the live danger-callout system.

## Validation performed

### Passed

- Exact pinned core and all seven external module revisions checked out in an isolated source tree:
  core `06234df3`, Playerbots `b6696bdb`, Individual Progression `977e2005`, Era Talents
  `3a0d9776`, Multibot Bridge `759c100d`, Dungeon Clear `29c53fd1`, Junk to Gold
  `2134690b`, and AH Bot Plus `f6858329`.
- Existing wrapper patches and Era Talents patch stack applied against those pins.
- New patches 0024 and 0025: forward application and reverse/already-applied checks passed.
- CMake Release/Ninja configuration discovered all 14 modules with scripts/modules linked statically.
- 88 custom/modified C++ translation units passed compiler syntax checks; a subsequent pass checked
  all 12 final changed translation units, including the two Playerbots persistence files: zero failures.
  Focused checks after final review also passed for the Titan reset identity and Auto Dungeon Clear changes.
- Native Release/Ninja full build completed successfully: 2,165 initial steps plus a 459-step
  final incremental rebuild after the last source synchronization. Both `authserver` and
  `worldserver` linked. Two final four-step rebuilds recompiled and relinked the Titan and
  Auto Dungeon Clear review fixes. This used Ubuntu GCC 15/Boost 1.90 rather than the deployment Docker image.
- 29 module SQL files executed in filename order against a disposable MySQL 8.4 instance using
  static reference tables copied read-only from the local world DB. Repeat application passed.
- The world reference has 46,096 item templates. Every protocol loot item name and every pool
  source name resolved. Result: 620 pool rows, 62 Sidereal vendor rows, 138 Scourgestone vendor rows.
- Confirmed Trophy of the Crusade cost 20 and Primordial Saronite cost 12. Reviewed the 1:1
  Scourgestone-to-Sidereal exchange implementation.
- Verified scripted encounter credits against the pinned scripts and live static encounter data:
  Tribunal 59046, Mal'Ganis 58630, Argent Challenge 68574, Black Knight 68663 and HoR escape 72830.
- All tracked shell scripts passed `bash -n`; changed deployment/pack/test scripts passed
  ShellCheck at warning severity. Setup bootstrap preflight passed.
- All project addon Lua parsed with Lua 5.1. BotGrid: 103 checks; AHPrice: 37 checks; zero failures.
- Six tracked PowerShell scripts parsed with the PowerShell parser: zero failures.
- Grounding and navigator action-policy C++ regression executables passed.
- Lore sidecar: 69 pytest tests passed; 37 dependency deprecation warnings under Python 3.14.
- Addon-only pack built with `WDM_LANG= IP_CLIENT_PATCH_V=0`; ZIP has 6,032 entries and 125 TOCs,
  including bundled upstream sub-addons. No Git metadata or path traversal entries.
- Changed C++ files passed the pinned style checker. Source/patch whitespace and git review were
  checked; patch context blank lines require excluding `blank-at-eol` from the outer patch-file check.

### Style-tool limitations

The unmodified whole-core C++ style command reports pre-existing pinned-tree/earlier-patch findings.
The stock SQL style command fails fetching `origin/master` because this validation checkout's
origin is a local shared-object clone. Running its checks directly on copied changed module SQL
reports existing temporary `ENGINE=Memory` tables, aliases and multi-line/dynamic SQL conventions.
Those are not SQL execution failures; the isolated MySQL migration/replay results above are the
actual database validation. No clean whole-repository linter result is claimed.

### Not exercised here

- The installed server's `./update.sh`, Docker image build, actual DB-updater bookkeeping, startup
  with the user's data/configuration, restart or gameplay using these new binaries.
- Concurrent online auctions, guild-bank operations, live gathering/crafting, crash injection,
  inventory-full recovery and actual group/master-loot distribution.
- In-game pathfinding, encounter timing, human-tank guidance, resurrection and wipe recovery.
- Titan mechanics/balance and every boss/chest in each protocol.
- A live Ollama pre-pull conversation or WeakAuras interaction.
- Installing into TheraWoW, SavedVariables rendering, or 1080p/1440p/3440x1440 visual testing.
- WDM/IP MPQ generation: the exercised build deliberately produced the addon-only pack.

The live server containers were not modified by this pass. Static world tables were read for
validation; all test SQL writes went to the separate disposable audit database.

## Exact WSL acceptance commands

Use the installed checkout, whose database/configuration belong to the real deployment. Both
local checkouts share git refs, so no remote push is needed for this local test.

```bash
cd ~/AzerothCore
git status --short
# Continue with a clean installed overlay checkout.
git switch -c codex/source-completion-local-test codex/integration-source-completion-2026-09-15
./backup.sh
set -o pipefail
./update.sh 2>&1 | tee ~/source-completion-update-2026-09-15.log
cd azerothcore-wotlk
docker compose ps
docker compose logs --no-color --tail=300 ac-authserver ac-worldserver
docker compose logs -f ac-worldserver
```

After the gameplay checks, test persistence:

```bash
cd ~/AzerothCore/azerothcore-wotlk
docker compose restart ac-worldserver
docker compose logs -f ac-worldserver
```

Optional source-policy regression rerun after `update.sh` assembles its patched tree:

```bash
cd ~/AzerothCore
bash tools/test-source-completion.sh
```

## Focused in-game smoke test

1. **Starts/progression:** create normal and DK characters; test adventure, TBC raid-ready and
   WotLK raid-ready. Relog before/after specialization. Check one starter kit, one spec kit, no
   progression rollback, correct phasing/talent points, and rejection above the configured ceiling.
2. **Era Talents:** learn supported talents, verify point/spell synchronization, relog, and change a
   bot's talents. Confirm refresh without repeated full rebuilds or unexpected reset.
3. **Playerbots:** recruit a normal party, enter a supported dungeon, and verify roles, combat,
   buffs, healing and loot. Compare normal bot-tank behavior with the prior integration.
4. **Guild persistence:** test human-led and bot-led guilds with an offline human member. Let
   recycling timers elapse and restart. Verify bot GUID/name, level, gear, guild, relationships
   and memories. Separately confirm bot-only population can still recycle.
5. **Economy:** deposit materials and gold; reject bound/wrapped/random-property stock. Request
   a real exact-stack auction buy and a known recipe. Check actual reagent/item/gold conservation,
   AH deposit and seller/buyer mail, bank payloads, insufficient funds/materials and repeat requests.
6. **Dungeon Clear:** automatic entry/login start, delayed bot arrivals, rest, loot, doors/events,
   pause/resume and wipe recovery. Include human-dies-first/bot-dies-last and a recovery over five minutes.
7. **Human tank:** use one human tank with DPS/healer bots and no bot tank. Verify a route guide
   between pulls, no automatic pull/tank-role takeover, normal DPS/healing during combat, no passive
   camp lock, short safe movement, human moving ahead, guide death/resurrection and continued routing.
8. **Titan authority:** use leader Off with a member Gamma preference; it must stay Off. Test each
   coordinator/command preference and separate device channel. Change leader during the channel;
   require a fresh choice. Verify personal preferences survive device activation and active runs cannot change mode.
9. **Alpha/Beta/Gamma mechanics:** run representative families in each protocol. Check Confessor
   stacks, Frost, Arcane image counts/Tempo, Shadow/Web Wrap, HoS/HoL energy/Keeper/tentacles,
   Diminish Power/Sanity, final damage suppression and Gamma helper behavior.
10. **Frozen Halls:** FoS, PoS and HoR heroic should award Gamma currency with normal heroic
    health/damage/mechanics. Complete the HoR escape, not merely Falric and Marwyn.
11. **Loot/currency/vendors:** cover Eregos, Tribunal, Mal'Ganis, Argent Challenge/Black Knight and
    Violet Hold lieutenants. Check normal group/master loot, Alpha/T7, Beta/T8, each Gamma encounter,
    full-bag pending delivery, no repeat awards, both catalogs, Trophy 20, Saronite 12 and exchange 1:1.
12. **Raid leader:** supported pre-pull brief, assignments and failed-pull advice. Unsupported
    encounters must remain honest. Delay/stop Ollama, start combat while a response is pending,
    change groups, and check no stale/mid-fight narration or encounter text in social memory.
13. **Restart:** leave a Titan instance active, record currencies, pending rewards, starter state,
    guild stock/treasury/gear and next-run preferences. Restart, reconnect and compare. Test a new
    reset-period run separately to confirm neither old activation nor currency deduplication leaks.
14. **Client:** install through the existing TheraWoW path. Open Azeroth Control (`/ap`), Adventure
    Controls, Era Talents and BotGrid; check Lua errors and positions at the actual resolution.
    Tune and save 3440x1440 positions in the client before calling that layout validated.

## Promotion evidence

Promote only after the exact tested commit has a successful real `./update.sh` log, Docker
compile, all module DB updates, clean auth/world startup, the smoke tests above, and a successful
restart/persistence round. Keep logs, SQL error output if any, and concise outcomes per scenario.
Resolve any crash, duplicate/lost resource, unauthorized protocol change, bot-role takeover or
regression before moving the tested commits to develop. Keep PR #19 unmerged until that evidence
exists; no main/develop merge is part of this completion pass.
