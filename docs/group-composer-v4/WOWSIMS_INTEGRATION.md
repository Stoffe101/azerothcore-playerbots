# WoWSims Integration

_Status: preset harvesting is green; authoritative baseline request construction is implemented and awaiting exact-head local CI. Candidate mutation/simulation remains next._

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

The first endpoint, `POST /v1/snapshot/validate`, performs structural/era validation only. A valid catalogued snapshot returns `ENGINE_PRESENT_UNVALIDATED` plus a semantic model key. That status is deliberately weaker than SIM-BACKED. It means routing exists, not that Skrra/AzerothCore mechanics, buffs, rotation, encounter preset or spec options have been validated.

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


## Engine-native preset harvesting

Addon import intentionally does not provide the non-character assumptions needed for a complete simulation. Instead of retyping those assumptions, Skrra harvests the pinned engines' own full-character test fixtures.

The Docker builder first compiles the pristine pinned `wowsimcli`. Only **after** that binary exists, `harvest_presets.py` temporarily instruments the checkout's `core.RunTestSuite` and extracts the `Average` RaidSimRequest produced by `FullCharacterTestSuiteGenerator`.

That request carries the engine's own spec options, rotation/APL, consumes, individual/party/raid buffs, debuffs, encounter and sim options. The harvester does not turn an engine model into authority by itself. It creates a reproducible preset candidate.

Every output is classified against `model-support.json` using the actual proto oneof field in the generated Player, the dominant tree from the generated talent string, and tank/healer/DPS semantics from the generated raid request. Unclassified requests are fatal.

Models with no upstream RaidSimRequest remain without a preset. A concrete example is the pinned TBC healer-priest test, which is stats-only; Skrra will not manufacture a healing rotation for it.

The generated per-era `preset-index.json` records route coverage plus SHA-256 for each raw request. Health and `GET /v1/presets` expose that coverage. Automatic GearAdvisor results remain blocked until authoritative character fields are applied to one of these presets and the route is validated against Skrra/AzerothCore behavior.


## Verified preset coverage checkpoint

Exact SHA `998d297a7f38e941740c41bdc972842157de0e97` passed all four workflows. Its real service-image build produced ready preset catalogs for all three engines:

- Vanilla: 24 unique requests across 15 routes;
- TBC: 15 unique requests across 15 routes;
- WotLK: 37 unique requests across 33 routes.

Coverage means an engine-native request fixture exists for that route. It does **not** promote that route to SIM-BACKED. The next adapter must copy authoritative server-owned character state into the selected preset, preserve the preset's non-character assumptions, build baseline/candidate requests that differ only in the intended item slot, and then validate the result against Skrra/AzerothCore behavior.


## Baseline request-construction boundary

The first authoritative adapter deliberately stops **before simulation**.

`POST /v1/snapshot/request` accepts the worldserver snapshot plus an optional `presetSha256`. It:

1. validates era/class/tree/role against the pinned model catalog;
2. resolves the harvested route key;
3. selects exactly one preset, requiring `presetSha256` when multiple upstream presets exist;
4. recalculates the preset's canonical SHA-256 and rejects drift;
5. deep-copies the preset;
6. keeps preset-owned rotation/APL, spec options, consumes, buffs/debuffs, encounter and sim options;
7. replaces server-owned character state: name, race, class, equipment, talents and professions;
8. for WotLK, maps live glyph spell IDs to WoWSims glyph **item IDs** using the exact pinned engine's `assets/db_inputs/glyph_id_map.json`;
9. returns the complete request as `REQUEST_BUILT_UNVALIDATED`.

No call to `wowsimcli` is made by this endpoint. It cannot produce a SIM-BACKED result.

### Identifier contracts verified

- permanent item enchant from AzerothCore's `PERM_ENCHANTMENT_SLOT` is the SpellItemEnchantment **effect ID** expected by all three pinned WoWSims cores;
- AzerothCore negative random-property IDs represent random suffix entries, so `-1979` maps to WoWSims `randomSuffix: 1979`;
- positive random-property IDs are not silently reinterpreted and currently fail closed;
- WotLK WoWSims glyph proto values are glyph item IDs, while the server snapshot owns glyph spell IDs; translation therefore comes from the pinned WoWSims glyph database rather than a hand-maintained table.

### Remaining accuracy gates

Before any route becomes authoritative:
- resolve a canonical preset policy for routes with multiple upstream candidates;
- validate meta-gem activation handling and any item-specific database assumptions;
- construct candidate requests by mutating exactly the intended equipment slot;
- assert baseline/candidate requests are otherwise equivalent;
- run the comparison asynchronously so the world thread is never blocked;
- validate model mechanics against Skrra/AzerothCore and only then promote confidence to SIM-BACKED.


## Candidate request isolation

Baseline request construction is exact-head green at `f3e17eb7dec14e5dcb272c77c981bef798aa320d`.

The next boundary is `POST /v1/snapshot/candidate-request`.

Input:
- authoritative snapshot;
- exact candidate item object;
- explicit WoWSims equipment `slotIndex` 0-16;
- optional exact `presetSha256`.

Behavior:
1. build the baseline through the same snapshot/preset path;
2. deep-copy the baseline request;
3. translate the candidate with the same era item rules;
4. replace only `raid.parties[0].players[0].equipment.items[slotIndex]`;
5. recursively compare the complete requests;
6. fail if there is no difference or if any changed path exists outside the intended slot.

Output status is `CANDIDATE_REQUEST_BUILT_UNVALIDATED`. This endpoint does **not** call `wowsimcli`.

WotLK random-property state is explicitly rejected because the pinned WotLK `ItemSpec` has no random suffix/property field. Classic/TBC continue to accept only AzerothCore negative random-property IDs as suffix IDs.

For the eventual player-facing “Sim Bags” flow, candidate state should be captured from server-owned `Item` objects. The addon should request a scan/action; it should not be the authority for candidate enchant/gem/suffix state.


## Server-authoritative Sim Bags manifest

The client is not trusted to describe candidate item state. The worldserver now owns candidate discovery:

1. scan backpack and equipped bags;
2. require central item provenance to be ready;
3. reject items not allowed by the live era;
4. ask AzerothCore whether each real Item instance can equip into each canonical WoWSims slot;
5. exclude swaps that would alter a second slot outside the current one-slot request contract;
6. send candidate item state + allowed slot indexes to `POST /v1/snapshot/bag-candidates`;
7. build every swap from the same authoritative baseline;
8. reuse the exact candidate structural-diff guard;
9. return canonical SHA-256 fingerprints and counts only.

The endpoint returns `BAG_CANDIDATES_BUILT_UNVALIDATED`. It does not invoke `wowsimcli` and cannot produce SIM-BACKED authority.

This makes the future GearAdvisor "Sim Bags" action a request to the server, not a client-side item-parser authority. The next architecture gate is preset disambiguation followed by an asynchronous simulation queue whose completion is drained back onto the world thread.


## Canonical preset selection

Automatic simulation must not depend on generated array order or an arbitrary upstream test filename. The canonical policy compares the simulator-owned assumptions of every harvested request for a route after removing only fields that the authoritative AzerothCore snapshot always replaces: player name, race, class, equipment, talents, professions and glyphs.

- singleton route: canonical directly;
- multi-preset route with one surviving assumptions fingerprint: requests are equivalent after authoritative overlay, so the lowest pinned request SHA is used as a deterministic representative;
- multi-preset route with more than one surviving assumptions fingerprint: harvest/image build fails closed and reports the conflicting source/request/assumption hashes;
- service loading requires exactly one canonical request for every route;
- explicit `presetSha256` remains a diagnostic override, but normal baseline/candidate/Sim Bags construction uses the canonical request automatically;
- this policy does not claim mechanics correctness and does not promote `ENGINE_PRESENT_UNVALIDATED` to `SIM-BACKED`.

Rotation/APL, spec options, consumes, raid/party buffs, debuffs, encounter and simulation options remain simulator-owned assumptions. Differences in any of them therefore block automatic canonicalization.


## Preset variants after real-image validation

The first overlay-equivalence-only canonical policy at `4ba6b74d` was intentionally rejected by the real Classic image because a class/tree/role route can contain more than one legitimate simulator model.

The refined contract is:
1. retain upstream talent strings and phase metadata in the harvested index;
2. group candidates by talent build;
3. within one talent build, collapse truly equivalent requests and otherwise select the latest pinned upstream phase when the difference is a phase family;
4. if a route contains multiple talent builds, preserve one representative per build and select the unique closest build from the authoritative live talent string;
5. reject equal-distance ties or unresolved same-build differences;
6. expose route selection policy in the catalog/health response and require full selectable-route coverage in the real image.

This deliberately preserves Combat Rogue Daggers vs Sinister Strike while allowing Classic Elemental to use the latest phase assumptions available in the exact pinned engine. The realm does not currently emulate every Classic patch phase separately, so latest-upstream-phase is the explicit policy for same-build phase families.


## Asynchronous Sim Bags execution boundary

Once preset selection is deterministic, expensive simulator execution must not block AzerothCore's world thread.

The first execution slice therefore uses this contract:

1. On the world thread, capture the authoritative character snapshot and real bag candidate Item state.
2. Serialize that state immediately. Live `Player*`, `Item*`, `Bag*` and session objects never enter the worker queue.
3. Queue at most one active job per character and bound the global pending queue.
4. A dedicated worker performs the HTTP call to the private `ac-wowsims` service.
5. `POST /v1/snapshot/compare-bags` rebuilds the same validated baseline/candidate requests used by the manifest boundary.
6. For DPS, execute the baseline once and use raid DPS as the comparison metric. For healers, use raid HPS. Tanks fail closed because DPS is not an acceptable proxy for survivability.
7. Execute every accepted candidate against that same baseline request.
8. Return `BAG_COMPARE_COMPLETE_UNVALIDATED`, per-swap deltas and the best positive result only as diagnostic data.
9. Push the completed serialized response into a completion queue.
10. `RaidRosterWorld::OnUpdate` drains completions on the world thread, resolves the player by GUID again and only then touches the session/UI transport.
11. World shutdown stops and joins the worker; queued jobs are not allowed to outlive server teardown.

The service remains the only process that launches the pinned `wowsimcli` binaries. The worldserver worker merely waits on private-network HTTP away from the game loop.

This slice is deliberately not the final GearAdvisor feature. It proves scheduling, isolation and batch execution. The next layer must transport structured result/confidence/explanation data into GearAdvisor and provide an explicit Sim Bags action. No route becomes SIM-BACKED until its mechanics and assumptions are validated against the Skrra/AzerothCore server.


### Authoritative glyph variant discriminator

The WotLK real-image gate exposed a route that talents cannot identify by themselves: pinned upstream Mage `TestFire` and `TestFrostFire` use the same talent string but different simulator assumptions. They are not interchangeable presets.

The upstream fixtures also provide an authoritative character-level discriminator:
- Fire uses the Fireball major glyph;
- Frostfire uses the Frostfire major glyph;
- both otherwise share relevant Fire-model options/consumes.

Skrra therefore does not hardcode one fixture as preferred. Harvested variant metadata now retains the preset glyph item set. Dynamic selection compares:
1. distance from the live server-owned talent string;
2. symmetric-difference distance from the live server-owned glyph set after the existing pinned WotLK spell->item translation.

A unique best pair selects the variant. A tie fails closed. This policy also continues to handle routes whose variants are distinguished by talents alone. Filename/source order is never a selection signal.


## GearAdvisor result transport and stale-state contract

The async queue is useful only if its result can reach the 3.3.5a client without pretending stale or unvalidated data is authoritative.

The first player-facing transport uses the already-proven system-chat protocol pattern rather than a modern-only addon API:

- GearAdvisor sends `.wowsims simbags` as an explicit user action.
- The command immediately returns a `[GA]|SIMQUEUE` record after enqueue.
- Completion returns `SIM` for a best-positive candidate, `SIMNONE` when no positive candidate exists, `SIMERROR` on service failure and `SIMSTALE` when state changed.
- GearAdvisor installs a CHAT_MSG_SYSTEM filter and consumes only the `[GA]` records, leaving the normal human-readable server diagnostics available.
- The result record carries metric, baseline, candidate, percent delta, item ID, canonical WoWSims slot and current support status.
- The client resolves the cached item link/name locally and maps the canonical slot index to a readable slot label.

### Stale-result prevention

Queueing captures both:
1. the authoritative character snapshot;
2. the authoritative bag-candidate snapshot.

The worker receives serialized copies only. On completion, the world thread rebuilds both snapshots for the connected player. Any difference means the simulation no longer describes current state, so the response is discarded and GearAdvisor receives `SIMSTALE`.

### Authority wording

`ENGINE_PRESENT_UNVALIDATED` and other non-`SIM_BACKED` routes may display numerical simulator output, but GearAdvisor labels it `UNVALIDATED GAIN`, `UNVALIDATED LOSS` or `UNVALIDATED SIDEGRADE`. Only a future route that has passed Skrra mechanics/assumption validation and is explicitly promoted to `SIM_BACKED` may use authoritative `UPGRADE` / `DOWNGRADE` wording.
