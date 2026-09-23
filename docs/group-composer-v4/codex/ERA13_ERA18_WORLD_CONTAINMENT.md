# ERA-13 / ERA-18 world containment work log

## Base / branch

- Base: `2de33c609bb05ed363a242f613396748b6a12a97` (`docs: finalize ERA-07 world loot checkpoint [local-ci]`), verified before editing.
- Branch: `codex/era13-era18-world-containment` in `/home/skrra/AzerothCore-era13-era18-world-containment`.
- Scope: read-only world NPC/vendor/quest leakage audit and safe containment of authoritative project-owned paths. One persistent realm opens Vanilla, then TBC, then WotLK cumulatively.

## Repository/database paths investigated

- `modules/mod-raid-roster/src/EraAuditCommand.cpp`, `EraPolicy.h`, `EraPolicy.cpp`: central era and existing read-only scanner.
- `modules/mod-titan-rune/src/TitanRuneSystem.cpp`: startup Dalaran NPC creation and custom vendor interactions.
- `modules/mod-titan-rune/data/sql/db-world/base/`: Titan creature/gameobject templates and custom vendor catalog.
- `modules/mod-titan-rune/src/TitanRuneDevice.cpp`, `TitanRuneGamma.cpp`, `TitanRunePlagueGladiator.cpp`, `TitanRuneAffixes.cpp`, `TitanRuneFrostArcane.cpp`, `TitanRuneTitan.cpp`: temporary creature/object presentation.
- Pinned core world schema in `azerothcore-wotlk/data/sql/base/db_world/`: `creature`, `creature_template`, `gameobject`, `gameobject_template`, `creature_addon`, `gameobject_addon`, `npc_vendor`, `game_event_npc_vendor`, `npc_trainer`, `creature_default_trainer`, `trainer`, `trainer_spell`, `creature_queststarter`, `creature_questender`, `gameobject_queststarter`, `gameobject_questender`, `quest_template`, `quest_template_addon`.
- Pinned core loader/handler paths: `src/server/game/Globals/ObjectMgr.cpp` (`LoadCreatures`, `LoadGameobjects`, `LoadQuests`, quest starter/ender loaders, `LoadVendors`, `LoadTrainers`); `src/server/game/World/World.cpp` startup load order, including creature/gameobject addon and spawn-group loading; `src/server/game/Handlers/ItemHandler.cpp` ordinary purchase/list-inventory handling; `src/server/game/Handlers/QuestHandler.cpp` quest query/accept and `CanTakeQuest` path.
- Repository-wide module search found no other module-owned `Creature::SaveToDB` world spawn path. It did find ordinary player/item persistence and Titan temporary summons.

## Findings

- `TitanRuneWorldScript::OnStartup()` calls `EnsureDalaranNpcs()` unconditionally. `SpawnPersistentNpc()` writes a `creature` spawn via `Creature::SaveToDB()` and records it in `mod_titan_rune_vendor_spawns`. The three entries are coordinator, Sidereal vendor, and Scourgestone vendor on map 571. Existing spawn records cause startup to skip recreation.
- Existing `.era audit` uses central `EraPolicy` and grouped read-only loot-template queries; it emits bounded examples and PASS/WARN/FAIL rows.
- Titan module SQL creates templates 900110-900112 but no static `creature` rows for those three. Startup creates their Dalaran map 571 `creature` rows and tracks GUIDs in `mod_titan_rune_vendor_spawns`; this persistent state survives reload/restart. It is not a disposable per-player summon.
- Titan device, orb, warden, plague cache, mirror, crusher and cauldron are temporary summons reached through supported WotLK heroic dungeon mode or `GetActiveMode`. Central WotLK release must guard the common heroic/mode boundary. Map 571 and Titan dungeon maps have independent central map gating, but map gating alone does not prevent startup DB writes or stale-GM interaction.
- Ordinary vendors come from `npc_vendor` and event vendor stock from `game_event_npc_vendor`. Creature spawn/map comes from `creature`; creature template `npcflag` and `ScriptName` can add interactions. A vendor item can have a known future item era while its NPC chronology remains unknown.
- Ordinary vendor stock is loaded by `ObjectMgr::LoadVendors`, and the core purchase path is `WorldSession::HandleBuyItemOpcode` in `ItemHandler.cpp`. The `PlayerScript::OnPlayerSendListInventory` hook can observe a vendor list request but does not by itself supply a proven per-item or NPC chronology. Broad purchase gating needs an authoritative dataset and a reviewed core boundary.
- Quest availability uses `creature_queststarter`/`creature_questender` and gameobject equivalents linked to spawns; `quest_template` contains start and reward items, while `quest_template_addon` carries additional requirements but no expansion release field. Quest level and ID are not chronology proof.
- `ObjectMgr` loads quest templates and relation tables at startup; `QuestHandler.cpp` checks `CanTakeQuest` for query/accept. This is a clean core enforcement path only after quest chronology can be established; this slice does not invent it.
- Trainers use `creature_default_trainer`, `trainer`, `trainer_spell` and legacy `npc_trainer`; a spell chronology source is not available in central item provenance.
- `creature_addon` and `gameobject_addon` decorate spawns by GUID; they do not establish earliest expansion. No universal NPC/quest chronology dataset was found in the wrapper or pinned schema.
- Read-only dirty-dev DB inspection found `creature.id` rather than pinned core's `creature.id1`; the audit now uses an `information_schema.COLUMNS` SELECT to pick the present column. This is a live schema compatibility finding, not an assumed chronology rule.
- On the `id1` layout, spawn-to-vendor/trainer/quest relations also inspect `id2` and `id3` alternate entries. The dirty-dev `id` layout has one entry column.
- The dirty-dev DB currently has exactly one `creature` row each for Titan entries 900110, 900111 and 900112 on map 571, with three tracking rows in `mod_titan_rune_vendor_spawns`. That is a concrete persisted WotLK world-presentation leak if the dev realm is viewed in a pre-WotLK state. No rows were changed. Ordinary vendor stock has 40,221 `npc_vendor` definitions and creature quest starters have 7,717 relations in this snapshot; broad automatic suppression would be unsafe.

## Decisions

- Runtime: central `EraPolicy::IsEraReleased(Wotlk)` now gates Titan Dalaran spawn creation and the module's common heroic/mode boundary. A world tick creates the three reviewed spawns after WotLK opens on the same running realm. Coordinator and vendor gossip/commands reject before WotLK, including already-persisted dirty-dev spawns. Titan item provenance remains the separate item legality check before currency mutation.
- Audit: map-grouped counts use `EraPolicy::TryMapEra` for a continent lower bound, and explicitly retain unknown content chronology on allowed maps. Item-grouped ordinary vendor stock and quest start/reward fields use `TryItemEra` without upgrading an item inference into NPC/quest chronology. Future/UNKNOWN ordinary definitions are WARN, while early persistent Titan spawn rows are FAIL. All queries are SELECT, examples cap at five per category.
- Query scope: ten map-grouped spawn/relation SELECTs (including legacy trainers and event vendors), one `information_schema.COLUMNS` SELECT, one grouped Titan `creature` SELECT, two Titan template/tracked-spawn COUNTs, nine definition/addon/trainer COUNTs, two vendor-item GROUP BY queries, and eleven single-column grouped `quest_template` item queries. Results stream grouped rows rather than constructing an in-memory world table; each emitted category has at most five examples.

## Deliberate deferrals

- No generic NPC-ID or quest-ID chronology inference. Ambiguous core content will be reported as UNKNOWN.
- Ordinary core vendor purchases, trainer learning, and quest acceptance are not blanket blocked by this slice: the pinned DB has no authoritative earliest-release field for old-world NPCs, spells, or quests. This remains an ERA-13/ERA-18 gap.
- No world-table DELETE/UPDATE migration or dev-realm cleanup. Existing early Titan spawns on a dirty dev realm are reported and their interactions blocked; physically removing previously persisted rows was not attempted.
- Expansion phase within WotLK (Alpha/Beta/Gamma unlock timing) is outside this WotLK-release gate and still requires separate phase validation.

## Tests/checks

- `git show -s --format="%H %s" 2de33c609bb05ed363a242f613396748b6a12a97`: exact base confirmed.
- `git rev-parse HEAD` in isolated worktree: exact base confirmed.
- `python3 tools/tests/era-world-containment.py --compile-build /home/skrra/actions-runner/_work/azerothcore-playerbots/azerothcore-playerbots/build`: source contracts PASS; focused Clang `-fsyntax-only -Werror` PASS for `TitanRuneSystem.cpp` and `EraAuditCommand.cpp` against exact-base runner compile commands.
- Repeated the focused source contracts and Clang check after the dirty-dev schema compatibility fix and additional definition counts: PASS.
- Repeated the same command after making Titan spawn creation retry every 30 seconds until all three project-owned entries are tracked: PASS.
- Repeated source contracts and focused Clang after alternate `id2`/`id3` relation coverage: PASS. Re-ran `git diff --check` and focused `EraAuditCommand.cpp` codestyle: PASS.
- `bash tools/test-source-completion.sh` with a temporary symlink to the exact-base runner core: PASS (`chatter-grounding`, `human-navigator`, `runtime-hardening` and the new ERA world source contract). The temporary symlink was removed afterward. The existing preflight script now invokes the new contract; no workflow or runner routing was changed.
- AzerothCore C++ codestyle on `mod-titan-rune`: PASS. Focused `EraAuditCommand.cpp` codestyle: PASS. Full `mod-raid-roster` codestyle reports pre-existing multiple blank lines only in `WoWSimsService.cpp` and `WoWSimsCommand.cpp` (parallel lane); those files were not touched.
- Read-only `mysql` SELECTs on the dirty-dev `acore_world` checked map-grouped `creature` counts, the three Titan entries and tracking count, ordinary vendor/quest counts, and a vendor-spawn relation query: PASS. The first exact-base `id1` query exposed the older live `id` schema; no write query was issued.
- Read-only `COUNT(*)` checks confirmed all nine unresolved definition/addon/trainer tables and `game_event_npc_vendor` exist on the dirty dev DB. This does not validate worldserver command output or same-realm release transitions.
- Exact read-only probe invocation was `wsl.exe -d Ubuntu -- sh /tmp/era-world-readonly.sh` (temporary local script, not committed). It ran `mysql -uroot -N acore_world -e` inside `ac-database` with only `SHOW COLUMNS`, `SELECT id,map,COUNT(*) FROM creature WHERE id IN (900110,900111,900112) GROUP BY id,map`, `SELECT COUNT(*) FROM mod_titan_rune_vendor_spawns`, the `npc_vendor` spawn semi-join, and table `COUNT(*)` queries. The initial `id1` SELECT failed with unknown column and triggered the compatibility fix; subsequent `id` SELECTs passed.
- Codestyle commands: `cd modules/mod-titan-rune && python3 /home/skrra/actions-runner/_work/azerothcore-playerbots/azerothcore-playerbots/azerothcore-wotlk/apps/codestyle/codestyle-cpp.py` passed. The same command from `modules/mod-raid-roster` failed on unrelated WoWSims files. Re-running it from `/tmp/era-world-codestyle` with only `src/EraAuditCommand.cpp` symlinked passed.
- `git diff --check`: PASS before final log/test additions; rerun at handoff.

## Runtime TODO

- Validate Vanilla, TBC, and WotLK on the same test realm; startup/reload and GM/normal player checks remain.
- Check `.era audit` row counts/examples against the live world DB and time the eight grouped map queries plus grouped vendor/quest-item queries.
- On a fresh Vanilla state verify no Titan Dalaran persistent rows are created and no device/warden/orb appears. At TBC verify the same. On WotLK advance verify the tick creates NPCs without restart and permits legal interactions. Restart/reload and purchase/exchange attempts remain untested.
- Check existing dirty-dev Titan spawns are flagged by audit and cannot be used pre-WotLK. The map gate is expected to keep normal players out, but physical stale-row visibility to GM requires runtime observation.

## Integration notes

- `EraAuditCommand.cpp`, `TitanRuneSystem.cpp` and `tools/test-source-completion.sh` are likely shared integration touch points. Canonical project docs are intentionally untouched.
- Pinned core schema was inspected from the exact-base self-hosted runner checkout. No core SQL or module SQL was modified.

## Suggested canonical documentation updates

- `CURRENT_STATE`: record bounded ERA-13/ERA-18 audit categories and Titan WotLK world-gate source status; mark runtime acceptance TODO.
- `PASS_LOG`: append exact isolated source commit and focused contract/Clang results; do not mark four-workflow CI green.
- `NEXT_WORK`: retain live Vanilla/TBC/WotLK audit, ordinary old-world NPC/quest chronology provenance, and broader vendor/trainer enforcement as next work.
- `MASTER_ROADMAP`: move ERA-13/ERA-18 only to partial audit/containment, not complete; mention Titan Dalaran lifecycle and unresolved core chronology.
- `ERA_FIDELITY`: document map era as lower bound, separate item/NPC/quest chronology, and cumulative same-realm activation.
- `TEST_MATRIX`: add source-contract and focused compile evidence, plus live fresh-realm/dirty-dev acceptance scenarios.
