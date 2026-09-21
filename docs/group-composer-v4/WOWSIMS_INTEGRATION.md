# WoWSims Integration

_Status: v0.3 authoritative snapshot integration in progress; service foundation is green at `aba336fd`, snapshot slice exact-head local CI required._

## Decision

WoWSims is the authoritative item-upgrade simulation family for the Skrra realm.

Do **not** use Pawn/static stat weights as the final upgrade decision. GearAdvisor may display mechanical caps and current stats, but a claim that item A is better/worse than item B must come from a validated WoWSims model for the live realm era/spec, or be reported as unsupported/uncertain.

Pinned upstream engines are recorded in `data/wowsims/sources.json`.

## Era routing

The server-reported Group Composer era is authoritative:

- VANILLA -> `wowsims/classic` / `https://www.wowsims.com/classic/`
- TBC -> `wowsims/tbc-new` / `https://www.wowsims.com/tbc/`
- WOTLK -> `wowsims/wotlk` / `https://www.wowsims.com/wotlk/`

A level-based fallback is allowed only when Group Composer has not yet received server state. It must be labeled as a fallback.

Never reuse a WotLK weight/model for Vanilla or TBC.

## Client architecture

### GearAdvisor

GearAdvisor owns presentation:

- current era/spec/role;
- equipped average item level;
- mechanical cap/current-stat visibility;
- simulation result;
- human-readable explanation of the trade;
- confidence/support status.

Static `profile.priority` strings are not shown as upgrade authority in v0.3+.

### WoWSimsBridge

`client-addons-src/WoWSimsBridge` is our own Interface 30300 exporter.

The current upstream WoWSims exporter targets modern Classic interface versions, so it is used only as a schema/reference source. The Skrra bridge uses 3.3.5a APIs and exports:

- race/class/level;
- dominant talent tree + talent string;
- equipped item IDs;
- enchants;
- TBC/WotLK gems;
- Vanilla/TBC random suffix where present;
- WotLK glyphs;
- professions;
- server era metadata.

Commands:

- `/wsim` — open bridge;
- `/wsim export` — character export;
- `/wsim bags` — equippable bag-item export for batch/top-gear simulation.

The generated client bundle includes WoWSimsBridge automatically because it packages all local addons under `client-addons-src/`.

## Automatic simulation backend

Target lifecycle:

1. GearAdvisor identifies a candidate item and replacement slot.
2. The server already knows the authoritative current character, gear, talents and live era.
3. A local simulation service builds a pinned WoWSims `RaidSimRequest` for that era/spec.
4. Run baseline and candidate with equivalent encounter/buff/rotation settings.
5. Return baseline metric, candidate metric, variance/confidence and relevant stat/cap deltas.
6. GearAdvisor explains the result in plain language.

The three pinned engines expose `wowsimcli sim --infile <RaidSimRequest JSON>`, so the backend does not need browser scraping.

### Automatic backend foundation

The first automatic-backend slice adds `wowsims-service/` and deployment helper `configure-wowsims-service.sh`.

- Docker builds the exact Classic/TBC/WotLK commits from `data/wowsims/sources.json`.
- `GET /health` reports binary/pin readiness.
- `POST /v1/sim` runs one era-specific `RaidSimRequest`.
- `POST /v1/compare` runs baseline and candidate requests and returns DPS/HPS baseline, candidate, delta and delta percent.
- request size, process timeout and concurrent simulator count are bounded.
- the service accepts only the three fixed era binaries and never executes caller-supplied shell commands.
- Compose uses `expose: 8092`, not a published host `ports` mapping, so the API remains private to `ac-network`.

This slice does **not** yet mean item hovers automatically simulate. The next adapter must build validated RaidSimRequest payloads from authoritative worldserver character state, call `http://ac-wowsims:8092`, and transport the result plus trade explanation to GearAdvisor.

## Trade explanation contract

An item result must answer **why**, not merely show an arrow.

Example:

> UPGRADE — +73 DPS (+1.6%)
>
> You lose 22 Hit Rating and end 8 rating below the boss hit target, increasing expected misses slightly. You gain 48 Agility and 36 Crit Rating. In your current talents, buffs, rotation and gear, WoWSims still produces +73 average DPS, so those gains outweigh the small hit loss.
>
> Source: WotLK WoWSims, pinned model <commit>. Confidence: sim-backed.

Another valid result:

> DOWNGRADE — -51 DPS (-1.1%)
>
> The item adds 61 Crit Rating, but removing your current boots drops you 43 Hit Rating below the boss target. WoWSims loses 51 average DPS in this exact setup, so the extra crit does not compensate for the additional misses.

### Cap states

Explanations distinguish:

- **still capped:** losing rating does not cross the cap, so the lost over-cap rating had little/no direct cap value;
- **drops below cap:** quantify the post-swap shortfall and still let the sim decide whether other gains outweigh it;
- **reduces over-cap waste:** explain that excess hit/expertise/defense was not helping the relevant cap;
- **crosses a breakpoint/cap:** explicitly call it out;
- **proc/set/weapon sensitive:** mention when the result is driven by mechanics not represented by simple visible stat deltas.

Never say “you must never drop below hit cap” if the full simulation shows the complete gearset is stronger below it.

## Confidence policy

- **SIM-BACKED:** validated WoWSims model for this era/spec and the candidate effect is represented.
- **LIMITED:** sim exists but the item/model has a known unsupported effect or the spec model is alpha/experimental.
- **UNSUPPORTED:** no validated model for this era/spec. Do not invent a stat-weight winner.

The addon must surface this status.

## Coverage

WoWSims coverage is not identical across eras/specs. Some Classic models are Alpha/Beta or unlaunched, and some healing specs are not launched in the WotLK simulator.

Therefore:

- keep a versioned support matrix;
- validate a model against the Skrra/AzerothCore mechanics before calling it authoritative;
- unsupported profiles keep mechanical GearAdvisor caps/current stats but do not receive fabricated upgrade percentages.

## Server compatibility

WoWSims models Blizzard Classic-era mechanics. Skrra runs AzerothCore on a 3.3.5a client with custom progression features.

Before enabling automatic authority for a model, validate at minimum:

- level/era;
- talent implementation;
- relevant spell coefficients/mechanics;
- item/proc/set implementation;
- race/profession bonuses;
- raid buffs/debuffs assumed by the preset;
- fight duration/target armor and other encounter defaults.

If Skrra intentionally differs, either configure the sim to match or label the result LIMITED.

## Runtime acceptance

Bridge:
- export parses as JSON;
- era changes route to the correct WoWSims family;
- equipped item IDs/enchants/gems match the in-game character;
- talent string matches the active build;
- WotLK glyphs match;
- bag export is accepted by the corresponding batch simulator.

Automatic backend (future slice):
- baseline result is stable within configured error;
- candidate swap changes only intended item slot(s);
- result returns to GearAdvisor;
- hit/expertise/defense/ArP trade explanations match actual before/after state;
- special-effect items are never described as if their result came only from raw visible stats.


## Authoritative worldserver snapshot

The automatic path must not trust client-exported combat state when the server already owns the truth. The worldserver snapshot therefore contains:

- live EraPolicy token and realm cap;
- character level, class, race and role;
- active dual-spec slot, dominant tree and per-tree point totals;
- a DBC-ordered active talent string;
- the exact 17 WoWSims equipment positions;
- permanent enchant IDs;
- socket gem item IDs resolved from live socket enchantments through SpellItemEnchantment.dbc;
- random-property/suffix metadata;
- active glyph property + spell IDs;
- learned primary professions and skill levels.

The first endpoint, `POST /v1/snapshot/validate`, performs structural/era validation only. A valid snapshot returns `AVAILABLE_UNVALIDATED` plus a semantic model key. That status is deliberately weaker than SIM-BACKED. It means routing exists, not that Skrra/AzerothCore mechanics, buffs, rotation, encounter preset or spec options have been validated.

The manual commands `.wowsims snapshot` and `.wowsims validate` exist to prove this boundary in game. Full baseline/candidate simulations must use an asynchronous queue or worker so the world thread is never held while `wowsimcli` runs.


## Pinned model coverage catalog

Model availability is now separate from model validation.

`data/wowsims/model-support.json` records, per era:

- exact WoWSims repository + engine commit;
- exact `proto/api.proto` Git blob identity;
- every spec field exposed by the pinned `Player.spec` oneof;
- allowed Skrra class/tree/role routes into those fields;
- validation status for each route.

Current status is `ENGINE_PRESENT_UNVALIDATED` for every catalogued route. This means the engine actually exposes the model, but Skrra has not yet validated the required preset assumptions. An uncatalogued class/tree/role combination returns `UNSUPPORTED`.

The catalog intentionally captures differences between engine families instead of pretending their proto names are interchangeable. Examples include Classic `tank_warrior`, TBC `dps_warrior`, WotLK `protection_warrior`, Classic `warden_shaman`, TBC `feral_cat_druid` / `feral_bear_druid`, and WotLK `deathknight` / `tank_deathknight`.

`GET /v1/models` exposes the pinned catalog summary for diagnostics. The next layer must pin the non-character inputs that addon import intentionally does not provide: rotation, spec options, raid/party buffs, debuffs, consumes, encounter target/duration and simulation options.
