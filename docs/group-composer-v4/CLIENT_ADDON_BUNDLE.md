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

## GearAdvisor

Local addon: `client-addons-src/GearAdvisor`.

Purpose:
- attach a separate panel to the right side of the stock Character window;
- display equipped average item level;
- auto-detect class and dominant talent tree;
- show role-aware gearing guidance;
- distinguish hard caps/targets from ordinary stat priority;
- show current relevant character stats;
- show remaining shortfall such as hit/expertise/defense;
- refresh on equipment/talent/stat changes.
- keep long cap/status values aligned in separate label/value columns;
- expose cap-specific explanations and current/target detail on hover;
- show the detected spec icon and class-colored identity line;
- anchor to the opposite side of CharacterFrame automatically when the preferred right-side panel would run off-screen.

Profile coverage:
- all ten WotLK classes;
- every talent tree;
- Feral has Cat DPS / Bear Tank variants;
- Death Knight Blood/Frost/Unholy can switch DPS/Tank guidance;
- v0.2.0 expands key-stat rows where the profile needs a seventh metric (for example Feral Cat hit, Enhancement haste and Rogue haste);
- Arms uses a 1260 Armor Penetration rating boss reference for the Battle Stance baseline instead of presenting the generic 1400 rating number as universally correct.

Era behavior:
- baseline physical hit, spell hit and tank defense targets change by realm era;
- WotLK Armor Penetration hard-cap guidance is hidden outside WotLK;
- the server-reported Group Composer era wins when available;
- detailed stat-priority text remains WotLK-focused, and v0.2.0 now says so visibly in the panel on Vanilla/TBC instead of letting a Wrath priority look era-authentic;
- full Vanilla/TBC spec-weight fidelity remains a future research pass.

The former `ExtendedCharacterStats` source remains in Git history/source for reference but is skipped from the generated bundle because GearAdvisor supersedes its UI/function.

## Runtime acceptance

Before calling the pass accepted in game:
1. build/download the generated zip;
2. verify WeakAuras, Details and GearAdvisor load on 3.3.5a without Lua errors;
3. open CharacterFrame and confirm GearAdvisor sits beside it without overlap; at a narrow resolution/UI scale confirm it flips to the left instead of leaving the screen;
4. test at least one caster, healer, melee, tank and hunter profile;
5. switch dual spec and verify immediate profile refresh;
6. compare displayed hit/expertise/defense values to the stock character sheet / known gear totals;
7. test Feral and Death Knight variant toggles;
8. hover every cap row and verify tooltip text + current/target detail;
9. verify long hit/rating and Armor Penetration rows remain aligned rather than clipping into labels;
10. confirm the panel close button hides it and `/ga` restores it;
11. confirm ExtendedCharacterStats is absent from the distributed pack.
