# Client Addon Bundle

_Status: implementation exact-head GitHub-CI green at `de842ba842721f32d588ba5d9818b872f9a6c805`; in-game acceptance still TODO._

## Distribution model

`fetch-client-addons.sh` builds `client-dist/client-addons.zip`, which the registration site serves as the one-file addon/data-patch download. External addons are pinned to reproducible revisions/releases; locally authored addons come from `client-addons-src/`.

## Current requested additions

### WeakAuras

Use **NoM0Re/WeakAuras-WotLK**, not the old Bunny67 WA 4.0.0 fork.

Pinned release:
- release: `5.22.0-b3706bd4`
- commit: `b3706bd47879f2f6bd246db1098cba57ad20c54d`
- asset: `WeakAuras2.zip`
- SHA-256: `83f620454d221440df10faa0d52ba704b4cc53aed5ee94010e35eae37c008175`

The release is a multi-folder addon package; bundle every top-level addon directory containing a TOC.

### Details

Use the maintained **5Buttons/Details-WotLK** 3.3.5a fork.

Pinned commit:
- `a237261866afaed8c0faf751d682c5d1fcae399d`

It is a multi-folder package. The main Details addon plus its shipped companion plugins are bundled using the existing TOC-discovery rule.

## GearAdvisor + WoWSims

Local addons:
- `client-addons-src/GearAdvisor`
- `client-addons-src/WoWSimsBridge`

GearAdvisor purpose:
- companion panel beside the stock Character window;
- equipped average item level;
- auto-detected class/talent tree/role mode;
- current relevant stats;
- era-valid mechanical caps/shortfalls;
- WoWSims-backed simulation result/explanation.

**Static stat-priority strings are no longer the upgrade authority in v0.3.** They are not rendered as the answer to “is this item better?”

WoWSimsBridge v0.1:
- Interface 30300;
- reads Group Composer's server era when available;
- routes Vanilla -> WoWSims Classic, TBC -> WoWSims TBC, WotLK -> WoWSims WotLK;
- exports gear IDs/enchants, TBC/WotLK gems, talents, professions and WotLK glyphs;
- `/wsim export` produces character import JSON;
- `/wsim bags` produces equippable bag-item JSON for batch/top-gear simulation.

Pinned upstream sources live in `data/wowsims/sources.json`. The modern upstream exporter is reference/schema input only; it does not target Interface 30300, so Skrra ships its own bridge.

Upgrade policy:
- supported + validated era/spec -> WoWSims result is authoritative;
- model limitation -> label LIMITED;
- no validated model -> label UNSUPPORTED;
- never silently substitute a WotLK model, Pawn score or invented stat weight for another era.

Explanation policy:
- show baseline -> candidate DPS/TPS/healing metric and percent delta;
- quantify important stat changes;
- explain whether lost hit/expertise/defense remains capped, crosses the cap, or removes over-cap waste;
- if other gains outweigh a cap loss, say so and cite the simulated result;
- if the swap loses, explain the dominant trade;
- proc/set/weapon-sensitive results must not be described as raw-stat arithmetic only.

The former `ExtendedCharacterStats` source remains for history but is skipped from the generated bundle.

See `WOWSIMS_INTEGRATION.md` for the backend and confidence contract.


## Runtime acceptance

Before calling the pass accepted in game:
1. build/download the generated zip;
2. verify WeakAuras, Details and GearAdvisor load on 3.3.5a without Lua errors;
3. open CharacterFrame and confirm GearAdvisor sits beside it without overlap; at narrow resolutions/UI scales verify it compares both sides and chooses the side with more usable space instead of blindly flipping left;
4. test at least one caster, healer, melee, tank and hunter profile;
5. switch dual spec and verify immediate profile refresh;
6. compare displayed hit/expertise/defense values to the stock character sheet / known gear totals;
7. test Feral and Death Knight variant toggles;
8. hover every cap row and verify tooltip text + current/target detail;
9. verify long hit/rating and Armor Penetration rows remain aligned rather than clipping into labels;
10. confirm the panel close button hides it and `/ga` restores it;
11. confirm ExtendedCharacterStats is absent from the distributed pack;
12. run `/wsim export` and verify the JSON imports into the simulator matching the live server era;
13. run `/wsim bags` and verify equippable bag items are accepted by WoWSims batch/top-gear import;
14. compare exported item IDs/enchants/gems/talents/professions against the live character;
15. confirm Vanilla never routes to TBC/WotLK and TBC never routes to WotLK;
16. confirm GearAdvisor no longer presents a static stat-priority ranking as the reason an item is better.
