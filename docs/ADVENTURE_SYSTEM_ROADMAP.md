# Adventure Systems Roadmap

This document is the canonical feature/status map for the custom persistent-AI-guild server.

## Product rules

- Normal play must not require bot micromanagement or memorized dot-commands.
- Combat decisions stay deterministic in Playerbots / server code. Local LLMs may phrase social text, never own survival-critical mechanics.
- Finder defaults to content marked **Guild Ready**. Experimental/WIP content is visible as context but never silently presented as supported.
- Convenience features must not erase progression unless the player explicitly opts into a skip.
- Reward systems must be spec-aware, era-aware and protected against infinite vendor/AH farming.
- Human professions remain optional. Adventuring, guild services and the simulated economy should provide viable progression.
- "Implemented" below means the code path exists in this branch. Anything not yet exercised against the pinned live server/client is explicitly marked **runtime validation pending**.

## A. Adventure Guide and navigation

### Adventure Finder
Status: **IMPLEMENTED / RUNTIME VALIDATION PENDING**

- `AdventureCatalog` is the single server-authoritative activity table.
- Finder exposes only `Guild Ready` activities.
- Compatibility view exposes green/yellow/red support state without pretending experimental encounters are supported.
- Server validates level and Individual Progression stage before travel/preparation.
- Dungeon formation reuses Guild Group Director.
- Raid preparation reuses persistent RaidRoster.
- Client addon parses machine-readable `[AG]` transport once, avoiding duplicate rows when multiple chat frames receive system messages.

### Adventure travel board
Status: **IMPLEMENTED / RUNTIME VALIDATION PENDING**

- Client travel board is sourced from the authoritative Finder payload.
- Outland and Northrend destinations are paged instead of overflowing the 3.3.5 UI.
- Only unlocked `Guild Ready` destinations become clickable.
- Group travel is leader-only and requires the whole travelling party to be alive and out of combat.
- Server teleports to AzerothCore's registered exterior instance entrance, not guessed coordinates.

### Personal roadmap
Status: **IMPLEMENTED / RUNTIME VALIDATION PENDING**

- Shows character level and Individual Progression state.
- Gives a current tier and next-tier recommendation.
- Yellow/red content remains visibly caveated.

### Exploration options
Status: **PARTIAL**

- Existing AdventureStart profiles can reveal maps for new/bootstrap characters.
- Per-character Normal / current-expansion / all-map modes and flight-path inheritance remain future work.

## B. Group formation and encounter lifecycle

### Guild Group Director
Status: **IMPLEMENTED / RUNTIME VALIDATION PENDING**

- Conservative natural guild-chat dungeon requests such as `anyone up for Ramparts?` resolve through the Adventure catalog.
- Existing real-player parties are preserved and validated.
- Missing tank/healer/DPS slots are selected from the persistent roster.
- Manually-added non-roster bots are never silently hijacked.
- Asynchronous bot login is waited for before sync/travel.
- Composition, progression, alive state and combat state are revalidated at departure.

### Automatic wipe recovery
Status: **IMPLEMENTED / RUNTIME VALIDATION PENDING**

- Requires a confirmed full group wipe.
- Waits for AzerothCore's instance script to report that the encounter is no longer in progress.
- Never treats elapsed time alone as proof that a boss reset.
- Resurrects configured members only after the safe reset gate.
- Re-enters Playerbots non-combat/follow state and runs group preparation.
- Does not auto-pull or fabricate boss completion/rewards.

### Automatic encounter preparation
Status: **IMPLEMENTED / RUNTIME VALIDATION PENDING**

- Requests Playerbots' existing buff actions rather than duplicating class logic.
- Warlocks are asked to create healthstone/soulstone utility and use their existing healer soulstone strategy.
- Hunters recover/call pets; warlocks get a non-combat AI tick to correct pet state.
- Manual `.encounter prep` remains available as a fallback.

### Raid boss practice mode
Status: **PLANNED / HIGH RISK**

- Must suppress loot, lockouts, achievements, first-kill bounties, bad-luck credit and progression.
- Will only be enabled for encounters whose reset/lockout behavior can be proven safe on the pinned server.

### Encounter skip vote
Status: **PLANNED / EXPERIMENTAL ONLY**

- Human vote only.
- No boss kill/reward emulation.
- Only for explicitly allow-listed yellow/red encounters after safe next-encounter routing is validated.

## C. Loot and rewards

### Smart bot loot rules
Status: **IMPLEMENTED / RUNTIME VALIDATION PENDING**

- Playerbots Need threshold is configured for meaningful upgrades.
- Useful non-upgrades may be Greeded according to the smart-loot config.
- Upgrade checks reuse Playerbots `StatsWeightCalculator` and class/spec armor/weapon rules.
- TBC/WotLK armor-token class masks are handled separately.

### Bad-luck protection
Status: **IMPLEMENTED / RUNTIME VALIDATION PENDING**

- Tracks credited real-player dungeon/raid boss kills.
- Streak persistence is synchronous where an immediate reread is required.
- A streak resets only when a meaningful main-spec item is won from the exact defeated boss loot source.
- Trash/chests/unrelated containers cannot erase the boss streak.
- Current implementation tracks/provides protection state; it does not vend guaranteed BiS items.

### Personal loot option
Status: **PREFERENCE/STUB ONLY**

- Per-character preference persistence exists.
- Replacement-loot generation is deliberately **not enabled** yet.
- Normal group loot remains authoritative until duplicate-loot, quest-item, legendary-fragment and unique-object behavior is implemented and proven safe.

### Adventurer first-kill economy
Status: **IMPLEMENTED / RUNTIME VALIDATION PENDING**

- One-time per-character/per-boss dungeon and raid bounties.
- Claim is persisted before money is created.
- Money-cap failure releases the claim so a later legitimate kill can retry.
- Bots do not receive the synthetic bounty.

### Adventure streak rewards / caches
Status: **PARTIAL / FUTURE SLICE**

- Adventure progression storage already has pending-cache plumbing.
- Unique-clear/no-wipe streak scoring and cache contents are not finished and must not be advertised as live yet.

## D. Persistent AI guild personality and services

### Persistent guild personalities and memories
Status: **IMPLEMENTED / RUNTIME VALIDATION PENDING**

- Each bot receives a deterministic persisted personality seed and stable trait profile.
- Actual shared boss kills, group wipes and human deaths can create grounded memories.
- Relationship familiarity/trust counters are persisted.
- LLM identity context receives only persisted gameplay memories and is explicitly told not to invent shared history.
- Combat decisions remain entirely outside the LLM path.

### Guild chat responses
Status: **IMPLEMENTED / RUNTIME VALIDATION PENDING**

- Online bots in the same guild may answer ordinary guild chat using the same bounded fan-out behavior as group chat.
- Service commands are handled before conversational classification and do not wake normal chatter.
- General chat also has one guaranteed same-zone/same-faction responder when an eligible bot is online.

### Guild treasury, vault and mail services
Status: **IMPLEMENTED PROTOTYPE / RUNTIME VALIDATION PENDING**

Guild-chat service surface:

- `!services`
- `!bank`
- `!donate <gold>`
- `!deposit <itemId> [count]`
- `!withdraw <itemId> [count]`
- `!mail <itemId> [count] <guildmate>`
- `!buy <itemId> [count]`
- `!craft <itemId> [count]`
- `!requests`

Safety properties:

- Persistent treasury, stock and request tables.
- BoP, quest/key and above-epic items are rejected by the synthetic service path.
- Item counts are stack/attachment bounded.
- Vault removal is restored if mail creation fails.
- Requests are FIFO and remain queued when the treasury cannot fund the next request.

Current limitation: `!buy` and `!craft` charge a deterministic service price and synthesize a safe requested item. They do **not yet** consume a real AH listing or prove a guildmate knows the recipe and owns every reagent. That richer deterministic supply-chain pipeline remains planned.

### Real guild crafting/AH supply chain
Status: **PLANNED**

Target pipeline:
1. resolve request;
2. find persistent guildmate with profession + recipe;
3. calculate actual materials;
4. consume guild/player/AH stock with hard fair-price guards;
5. craft or return the true missing requirement;
6. trade/mail the real result;
7. persist an auditable item/gold ledger.

### Smart AH wanted list / inflation control
Status: **PLANNED**

- Wanted-item max-price alerts and optional guarded auto-buy remain future work.
- Economy telemetry must exist before adaptive price/liquidity tuning.

## E. Account / alt progression

### Alt-friendly account progression
Status: **PLANNED**

Possible opt-in inheritance:
- map exploration;
- flight paths;
- selected earned content unlocks;
- collection/cosmetic state where supported;
- reputation catch-up multiplier instead of blind reputation cloning.

### Instant alt bootstrap
Status: **PARTIAL FOUNDATION**

- TBC Adventure, TBC Raid Ready and WotLK Raid Ready character bootstrap profiles already exist.
- Account-earned-ceiling selection/inheritance is not implemented yet.

## F. Administration and population reliability

### Runtime bot population controls
Status: **IMPLEMENTED / RUNTIME VALIDATION PENDING**

- AdminPanel supports targets up to 1000 bots.
- Runtime target changes force Playerbots enabled + random-bot autologin.
- Account/character capacity is recalculated through upstream `RandomPlayerbotFactory`.
- Missing RNDbot capacity can be created and account assignments refreshed.
- Manager gets two bootstrap passes before normal world ticks take over.
- Watchdog detects a target with zero online bots, performs bounded repairs, resets its repair budget after recovery/target changes, and logs actionable diagnostics rather than retrying forever.
- `.botdiag` and `.botrepair` remain explicit administrator fallbacks.

## G. Raid knowledge

### Grounded encounter briefs
Status: **TBC IMPLEMENTED / WOTLK EXPANSION IN PROGRESS**

- Existing TBC briefs are tied to actual Playerbots strategy coverage and explicitly caveat unsupported cases such as Karazhan Chess.
- Finder compatibility and raid brief knowledge are intentionally separate: marking a raid Guild Ready does not license the LLM/brief system to invent encounter automation.
- WotLK brief coverage should only be expanded from inspected pinned Playerbots strategies.

## Release gate for this branch

The full-adventure branch is **source-integrated but not declared production-ready yet**. Before it replaces the current live branch:

1. complete source/API audit of the remaining new code paths;
2. build the pinned server once after the batch is complete;
3. run DB migrations and confirm worldserver clean startup;
4. validate 500 then 1000 bot population ramp without login storm;
5. install the client pack and smoke-test AdminPanel + Adventure Guide;
6. exercise one TBC dungeon, one WotLK dungeon and one Guild Ready raid with persistent roster bots;
7. force one controlled wipe and verify safe recovery without encounter/reward corruption;
8. exercise smart-loot/bad-luck bookkeeping and AI guild mail/vault service on disposable items;
9. only then fast-forward/merge the integration branch into the live branch.

Anything that fails a runtime test stays caveated or disabled rather than being painted green.
