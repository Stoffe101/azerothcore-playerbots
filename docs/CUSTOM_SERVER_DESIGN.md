# Custom Server Direction

This fork is tuned around a TBC -> WotLK progression experience with a persistent AI guild.

## Core principles

- Free/local only: no paid AI APIs are required for the intended experience.
- Playerbots owns combat and supported encounter mechanics. This fork does not invent speculative boss AI for unsupported fights.
- The human player should not need to micromanage bots during normal dungeon or raid play.
- Guildmates should become persistent recurring characters with identities, relationships, memories, roles and progression.
- The raid leader should explain grounded encounter tactics and coordinate the raid without requiring manual bot commands.
- Vanilla is legacy/optional content. New real-player characters begin at level 60 at the start of TBC progression.
- Quality-of-life is preferred over travel friction: dungeon/raid entrance teleporting is planned.
- Progression rewards should be fun and combat-focused. No profession-material filler. Caches can contain consumables, gold, useful gear, rare upgrades and occasional jackpot items.
- Professions should primarily be a guild social service: players can ask guildmates to craft useful items rather than being forced to level professions themselves.

## Initial QoL profile

The AdventureStart player script currently applies only to newly-created real-player characters:

- Level 60 start
- Individual Progression stage 8 (beginning of TBC)
- Full world-map reveal
- Playerbots, random bots and addclass bots are excluded

These settings are configurable in `mod_raid_roster.conf` under `AdventureStart.*`.

## Planned work

1. Starter gear / bags / riding / consumables appropriate for TBC entry.
2. Adventure Stone or equivalent dungeon/raid entrance teleport UI with eligibility checks and group handling.
3. Era-aware, class/spec-aware progression caches and first-clear/milestone rewards.
4. Persistent AI guild identities, personalities, relationships and long-term memory using local models.
5. Automatic dungeon and raid composition plus a grounded raid-leader layer.
6. Guild crafting requests backed by deterministic recipe/material checks and actual crafting/trading.
7. Organic guildmate gearing/progression so persistent companions keep earned upgrades rather than being overwritten every sync.

`main` should remain the stable/playable branch. New work should flow through `develop` and focused feature branches.
