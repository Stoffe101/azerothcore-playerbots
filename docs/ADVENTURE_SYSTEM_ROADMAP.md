# Adventure Systems Roadmap

This document is the canonical feature roadmap for the custom persistent-AI-guild server.

## Product rules

- Normal play must not require bot micromanagement or memorized dot-commands.
- Combat decisions stay deterministic in Playerbots / server code. Local LLMs may phrase social text, never own survival-critical mechanics.
- Finder defaults to content marked **Guild Ready**. Experimental/WIP content is visible as context but never silently presented as supported.
- Convenience features must not erase progression unless the player explicitly opts into a skip.
- Reward systems must be spec-aware, era-aware and protected against infinite vendor/AH farming.
- Human professions remain optional. Adventuring, guild services and the simulated economy must provide viable progression.

## A. Adventure Guide and navigation

### Adventure Finder
Status: **IN PROGRESS** (`feature/adventure-guide-finder`)

- Dungeon/raid finder lists only Guild Ready content by default.
- Central shared catalog owns activity name, alias, map, level/progression requirement, group size and compatibility status.
- Supported filters: dungeons, raids, all.
- Server remains authoritative for unlock checks.
- Dungeon formation reuses Guild Group Director.
- Raid formation reuses persistent RaidRoster.

### Compatibility overlay
Status: **IN PROGRESS**

- Green: Guild Ready / normal Finder content.
- Yellow: playable/experimental with explicit caveats.
- Red: Not Ready and never offered as normal Finder content.
- Compatibility notes come from the same catalog as Finder/travel.

### Adventure teleport map
Status: **PLANNED NEXT**

- Visual TBC/WotLK travel board/map in the client addon.
- Only server-approved activities can be teleported to.
- Group travel remains leader-only, alive and out-of-combat.
- Return-to-previous-location support should be added after basic map travel is validated.

### Personal roadmap
Status: **IN PROGRESS**

- Shows current level/progression, recommended Guild Ready content, next tier and experimental blockers.
- Later: gear-upgrade suggestions and first-clear tracking.

### Exploration options
Status: **PLANNED**

Per-character/account-selectable modes:
- Normal exploration.
- Reveal current expansion.
- Reveal all maps.
- Optional flight-path unlock modes.

## B. Encounter lifecycle

### Raid boss practice mode
Status: **PLANNED / HIGH RISK**

- Explicit practice session flag.
- No boss loot, lockout credit, achievements, first-kill bounty or progression completion.
- Safe reset/retry loop.
- Only enabled for encounters we can reliably reset in the pinned core.
- Must not be implemented as fake boss copies with guessed scripts.

### Automatic wipe recovery
Status: **PLANNED NEXT**

On confirmed full group wipe:
1. wait until combat ends;
2. release/resurrect safely using supported APIs;
3. regroup at a known safe point;
4. repair/rebuff/refill where configured;
5. deterministic brief/ready state;
6. never auto-pull.

### Encounter skip vote
Status: **PLANNED / EXPERIMENTAL ONLY**

- Available only for yellow/red encounters explicitly allow-listed by us.
- Human players vote; AI guild members do not override human votes.
- Skip gives no boss loot, first-kill bounty, achievement or bad-luck credit.
- Skip must move progression to the next safe encounter without directly killing/rewarding the boss.

### Auto buff logic
Status: **PLANNED NEXT**

- Long-duration party/raid buffs before departure/pulls.
- Rebuff after wipe/death when safe.
- No spam during combat.
- Respect class/spec and avoid redundant buff conflicts.

### Warlock prep
Status: **PLANNED NEXT**

- Healthstones before challenging content.
- Soulstone sensible healer/tank fallback target.
- Summoning only when it solves a real missing-member problem.

### Smart pet management
Status: **PLANNED NEXT**

- Ensure appropriate hunter/warlock pet is active when useful.
- Dismiss/park pets for known dangerous pathing encounters.
- Restore normal pet state after the encounter.

## C. Loot and rewards

### Smart loot rules
Status: **PLANNED**

- Main-spec upgrade > off-spec > greed.
- Spec-aware using maintained Playerbots stat/equip scoring where possible.
- Human-friendly option without making bots incapable of progressing.
- Never award unusable armor/weapon types as a smart recommendation.

### Personal loot option
Status: **PLANNED**

- Optional per-character/per-group mode.
- Server performs an independent spec-aware eligible roll from the defeated boss's real loot source.
- Must not duplicate normal group loot when personal mode is active.
- Needs explicit handling for quest items, legendary fragments and unique encounter objects.

### Bad-luck protection
Status: **PLANNED**

- Tracks eligible boss kills without receiving a meaningful main-spec upgrade.
- Protection increases only for items the player could legitimately receive.
- Resets/decreases when a protected upgrade is won.
- Practice/skip kills do not count.
- Hard caps prevent guaranteed current-tier BiS vending-machine behavior.

### Adventure streak rewards
Status: **PLANNED**

Examples:
- consecutive unique dungeon clears;
- first full raid clear;
- multiple supported bosses without abandoning the run;
- no-wipe bonus.

Rewards feed Adventure Caches / gold / consumables / cosmetics, not profession materials.

## D. Persistent guild services

### Guild mail
Status: **PLANNED**

- Server-generated mail only from grounded events/services.
- Crafted orders, shopping deliveries, milestone congratulations and returned guild-bank items.
- Mail text may be locally phrased by the LLM; attached items/gold remain deterministic.

### Guild crafting requests
Status: **PLANNED**

Natural request -> deterministic service pipeline:
1. resolve requested item;
2. find persistent guildmate with profession + recipe;
3. calculate materials;
4. source from guild bank/player/AH according to settings;
5. craft or refuse with the true missing requirement;
6. trade/mail actual item.

The LLM must never claim an item was crafted unless the backend succeeded.

### Guild bank economy
Status: **PLANNED**

- Persistent guild inventory/gold ledger.
- Spare BoEs, cloth, gems, profession materials and consumables.
- Human can deposit useful drops without taking a profession.
- Guild crafters consume real stock.
- Audit trail for generated/consumed gold/items.

### Guild shopping service
Status: **PLANNED**

- Buy consumables/gear/materials from the simulated AH on request.
- Configurable payment source: player funds or guild allowance.
- Hard maximum price / fair-price guard.
- Delivery by trade/mail.

### Smart AH buy list
Status: **PLANNED**

- Per-character wanted-item list with max price.
- Alerts on reasonable matching listings.
- Optional auto-buy disabled by default; if enabled, strict budget and price guards.

### Inflation control
Status: **PLANNED**

- Economy telemetry first: gold sources/sinks, AH median bands, inventory counts, human purchasing power.
- Tune AH liquidity before changing prices.
- Adaptive changes must be bounded and slow; never rewrite the economy radically from one sample.
- Normal adventuring should fund repairs, consumables, normal mounts and reasonable AH upgrades.

## E. Account / alt progression

### Alt-friendly account progression
Status: **PLANNED**

Optional account-wide inheritance categories:
- map exploration;
- flight paths;
- selected raid/content unlocks;
- collection/cosmetic state where supported;
- reputation catch-up multiplier rather than blindly cloning reputations.

### Instant alt bootstrap
Status: **PLANNED**

- Player chooses target expansion/progression already earned by the account.
- Level, spells, riding and bags initialized safely.
- Optional one-time spec-aware catch-up gear.
- Join persistent guild automatically.
- Never bootstrap past the account's earned ceiling unless Adventure Controls explicitly skips forward.

## Implementation order

1. Adventure Guide/Finder + compatibility + roadmap + travel board.
2. Wipe recovery + buff/warlock/pet preparation.
3. Smart loot + personal loot + bad-luck protection.
4. Guild bank/crafting/mail/shopping + AH wanted list.
5. Adventure streak rewards + economy telemetry/inflation control.
6. Account-wide progression + instant alt bootstrap.
7. Practice mode and encounter-skip framework after encounter-reset/lockout behavior is validated on the running server.

Every slice remains draft until it is compiled and exercised against the pinned server/client build.
