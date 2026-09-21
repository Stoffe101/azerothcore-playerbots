# ERA-07 item provenance data

This directory defines the reproducible chronology source for automated item-era filtering.

## Source model

`sources.json` pins exact CMaNGOS Classic, TBC and WotLK full-database commits **and Git blob SHAs**. The generator downloads those immutable compressed dumps into the ignored local cache, verifies byte size + Git blob identity, then reads only the `item_template` entry IDs.

For every item ID that exists in the live AzerothCore `acore_world.item_template`:

- present in the pinned Classic DB -> earliest era **Vanilla**;
- otherwise present in the pinned TBC DB -> earliest era **TBC**;
- otherwise present in the pinned WotLK DB -> earliest era **WotLK**;
- absent from all three -> **UNKNOWN**.

No item-ID threshold, required-level rule or item-level rule is used as provenance.

## Fail-closed unknowns

UNKNOWN does **not** mean WotLK. It means the historical snapshots do not prove the item chronology. Automated AH listing blocks UNKNOWN in every era until it is reviewed and added to `overrides.csv`.

The generated manifest is chronology evidence, not proof that an item was obtainable in every patch/phase of that expansion. Normal AHBot validity/binding/category filters still apply, while later phase-specific provenance remains separate work.

## Overrides

`overrides.csv` is the review ledger. Use:

```csv
item_id,earliest_era,note
12345,tbc,Confirmed TBC item despite source-database omission
20000-20005,vanilla,Confirmed Classic range
```

Allowed eras are `vanilla`, `tbc`, `wotlk`, and `unknown`.

## Runtime outputs

`configure-era-item-provenance.sh` exports the live world item IDs, runs `tools/generate-era-item-provenance.py`, and caches generated files under `.cache/era-item-provenance/`. Fresh setup and every `./update.sh` run regenerate this central snapshot before the final worldserver restart. `configure-ahbot.sh` reuses the same generated output instead of owning a second chronology path:

- `item-era.csv` - live-world provenance ledger;
- `ah-disabled-vanilla.txt`;
- `ah-disabled-tbc.txt`;
- `ah-disabled-wotlk.txt`;
- `metadata.json`.

The disabled files are compact comma/range lists. The central script writes **all three** lists plus the live item-count/fingerprint into `mod_raid_roster.conf`, where EraPolicy validates and selects the active list from the live realm era. A small patch to the pinned `mod-ah-bot-plus` separately consumes the current profile through `AuctionHouseBot.EraProvenanceDisabledItemIDs` without overwriting the operator's normal `DisabledCustomItemIDs`.

ERA-07 slice 2 makes deterministic RaidRoster/Group Composer gear preparation consume the central policy and extends `.era audit` to existing auction stock plus stored RNDbot equipped gear. Starter/catch-up gear, vendors/rewards, loot/crafting and other automated item paths still need promotion before ERA-07 can become DONE.
