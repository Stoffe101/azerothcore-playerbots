# Post-stabilization roadmap

This document recovers the useful work that exists on the old feature branches without merging those branches wholesale. They diverged before the current server-stability work, so features should be reimplemented/cherry-picked deliberately against `feature/tbc-start-qol-final`.

## Now: WotLK endgame loop

### Titan Rune dungeons
- Defense Protocol Alpha / Beta / Gamma on WotLK heroic dungeons.
- Classic-style baseline health/damage scaling.
- Beta final-boss Sidereal Essence.
- Gamma per-boss Defiler's Scourgestone.
- Dalaran exchanges for Ulduar hard-mode style rewards and high-value ToC/Ulduar rewards.
- Scourgestone -> Sidereal conversion.
- Next polish: exact Classic dungeon-family rune mechanics, Gamma helper buffs, and phase-accurate bonus raid loot tables.

## Recovered feature branches

### `feature/adventure-guide-finder`
The broad player-facing Adventure Guide/Finder concept:
- central AdventureCatalog
- progression-aware recommendations
- dungeon/raid finder flow
- compatibility / readiness display
- travel/teleport assistance
- group director integration

### `feature/guild-group-director`
AI guild group formation and role filling:
- build groups from guild/playerbots
- tank/healer/DPS composition
- group readiness and activity flow

This is one of the highest-value recoveries for the intended "play WoW with an AI guild" experience.

### `feature/raid-leader-foundation`
Deterministic raid-leader knowledge rather than LLM combat decisions:
- encounter knowledge surface
- raid-leader command/foundation
- intended future boss-callout/mechanics coordination

### `feature/encounter-lifecycle`
Dungeon/raid lifecycle automation:
- encounter state tracking
- wipe detection/recovery direction
- regroup/rebuff/refill/ready flow
- no automatic pull

### `feature/smart-loot-protection`
Loot quality-of-life foundation:
- main-spec upgrade > off-spec > greed logic
- protection against bots taking meaningful human upgrades
- groundwork for optional personal loot / bad-luck protection

### `feature/ai-guild-persistence` and `feature/ai-guild-services`
Persistent AI-guild state:
- guild/service context stored across restarts
- hooks for guild chatter and service state
- foundation for guild bank/mail/crafting/shopping services

### `feature/adventurer-economy`
Adventure-driven economy work:
- persistent economy state
- AH pricing/control extensions
- intended loop where normal adventuring can fund progression without requiring professions

### `feature/adventure-controls`
Progression/catch-up controls and an early Adventure Controls UI:
- character catch-up state
- progression controls
- convenience/bootstrap actions

### `feature/adventure-teleport-rewards`
Early travel/reward helpers that later fed into the broader Adventure Guide idea.

## Product roadmap recovered from the old Adventure System plan

1. Adventure Guide/Finder, progression compatibility, recommendations, travel.
2. Guild Group Director so the player can form competent bot groups naturally.
3. Encounter lifecycle: wipe recovery, buffs, warlock prep, pet management.
4. Smart loot and human-upgrade protection, then optional personal loot/bad-luck protection.
5. Raid Leader mechanics foundation and boss-specific deterministic behavior.
6. Persistent guild services: guild bank, mail, crafting requests, shopping/AH wanted list.
7. Adventure streak/first-clear rewards and economy telemetry.
8. Optional account/alt catch-up to already-earned progression ceilings.
9. Experimental raid practice/encounter skip tools only after the normal progression loop is proven stable.

## Hard rules retained

- Normal play should not require memorizing bot dot-commands.
- Combat and encounter mechanics remain deterministic; LLMs are social/personality only.
- Convenience should not silently erase progression.
- Rewards should remain era/spec-aware and resistant to trivial farming.
- Do not wholesale-merge the old branches: salvage their useful pieces into the current stable branch.
