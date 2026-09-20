# Vanilla → TBC → WotLK Era Fidelity Contract

_Status: canonical design contract. Core era/progression pieces already exist; the full cross-system enforcement described here is **not yet complete**._

## Product promise

The future friends realm is one continuous world that progresses forward:

1. **Vanilla** — level cap 60.
2. **The Burning Crusade** — level cap 70; all legitimate Vanilla content remains available.
3. **Wrath of the Lich King** — level cap 80; legitimate Vanilla and TBC content remain available.

A later expansion may add content, systems and items. It must never make future-era content visible or obtainable before that expansion is released.

The technical base remains the WotLK 3.3.5a client/server. Therefore the practical target is **gameplay and progression fidelity on a 3.3.5a base**, not pretending the client binary itself literally became 1.12 or 2.4.3. Where exact historical UI/client behavior would require replacing the client, server-authoritative gameplay fidelity wins.

## Non-negotiable invariant

> If the realm is Vanilla, nothing that materially belongs to TBC or WotLK may affect normal play.
>
> If the realm is TBC, Vanilla + TBC are valid, but WotLK must not affect normal play.
>
> If the realm is WotLK, all three eras are available subject to normal character progression and raid-phase gates.

"Materially affect normal play" includes population, Group Composer, gear, items, professions, AH stock, vendors, loot, rewards, maps, travel, classes/specs, recommendations and catch-up/preparation systems.

## One server-authoritative era source

### Implemented ERA-01 foundation

`modules/mod-raid-roster/src/EraPolicy.h/.cpp` is now the canonical server policy surface for:
- the Vanilla/TBC/WotLK enum;
- current live realm era;
- realm/era level caps;
- progression ceilings and minimum progression per era;
- release comparison;
- canonical era display/token/key parsing;
- applying an era to Individual Progression + bot account level ceiling as one operation.

`AdventureCatalog` and `AdminPanelExpansion` must consume that API rather than carry independent era definitions. New systems should depend on EraPolicy directly or through a narrow compatibility facade, never re-create 60/70/80/progression tables locally.

This is a **foundation**, not completion of ERA-01. Slice 2 also moves starter/catch-up availability, player progression shortcuts, direct Composer Titan Rune access and bot progression sync onto EraPolicy. Item provenance, global bot enforcement and phase-within-era timing remain separate work.


Every subsystem should eventually consume one named policy/API instead of independently guessing from level, config or UI state.

Proposed shape:

- CurrentRealmEra() → Vanilla / TBC / WotLK.
- RealmLevelCap() → 60 / 70 / 80.
- IsEraReleased(era).
- IsActivityAllowed(activity).
- IsClassAllowed(class, faction).
- IsRaceAllowed(race).
- IsItemAllowed(itemId).
- IsSpellAllowed(spellId).
- IsProfessionAllowed(skill/spell).
- IsMapAllowed(mapId).
- IsBotAllowed(bot, humanContext).

The existing AdventureCatalog::CurrentRealmEra() already derives a three-era view from Individual Progression's realm progression ceiling. That is a useful starting point. The long-term rule is that **all gates consume the same source**, and the release state moves forward monotonically on the friends realm.

Downgrading a live friends realm is unsupported. Dev/test tooling may simulate earlier eras, but must not silently mutate the permanent dev realm or pretend a dirty database is a fresh release realm.

## What already exists

### DONE / existing foundations

- Individual Progression has the three hard level bands:
  - stages 0–7 → Vanilla, cap 60;
  - stages 8–12 → TBC, cap 70;
  - stages 13–18 → WotLK, cap 80.
- Manual expansion advance has already been runtime-verified for the TBC and WotLK transition holds.
- AdventureCatalog tags dungeons/raids with Vanilla/TBC/WotLK and blocks activities whose era is not released.
- Group Composer already has era-aware activity data, progression blockers and unlock explanations.
- RaidRosterEra::SyncBotToMaster can synchronize a Composer/roster bot to the real player's Individual Progression era.
- Era Talents provides Vanilla/TBC class-tree fidelity on the WotLK technical base.
- Composer anti-boost logic uses the **lowest real human** in the reviewed group as its peer reference, with a +/-3 bot band clamped by the selected activity minimum and live realm cap.
- Titan Rune is a WotLK-only feature family and should remain behind WotLK/phase gates.

### PARTIAL / must be proven or expanded

- Global random/world/guild bot population is not yet proven to obey the realm era as a hard population ceiling.
- Composer understands activity eras, but its **presentation, templates, subgroup optimization and class availability** still need explicit per-era behavior.
- The current AH setup is not era-safe. configure-ahbot.sh deliberately boosts WotLK materials, gems, flasks, combat potions and Fish Feast because the dev realm currently targets WotLK.
- The external mod-ah-bot-plus has useful level/item filters, but those alone cannot prove expansion provenance for every item.
- Full world-system fidelity for professions, vendors, future maps/transport, race/class availability and expansion-only systems is not yet centrally enforced.

## Group Composer across all three eras

Group Composer should feel like one addon that grows with the realm rather than three separate addons.

### Shared shell

Always show:

- **Current Era** in the header, for example VANILLA • LEVEL 60 CAP.
- current character level/progression;
- selected activity;
- existing human/bot anchors;
- missing roles;
- utility/readiness;
- clear reason text when something is locked.

The addon is an intentional QoL layer. It may make assembling/travelling easier than historical retail did, while still respecting what content, classes, gear and systems are actually released.

### Activity browsing

Default activity views should be era-aware:

- **Vanilla realm:** Vanilla only. TBC/WotLK may appear only in an optional Journey/Future view as visibly locked previews.
- **TBC realm:** TBC is the current endgame; Vanilla remains under a Legacy / Leveling section.
- **WotLK realm:** WotLK is the current endgame; Vanilla and TBC remain available as legacy/leveling/farm content.

Recommendations should prefer the current expansion's relevant progression. Older raids/dungeons should surface when they are useful for leveling, attunement, catch-up, achievements, farming or a saved lockout, not crowd out current progression.

### Era-correct classes and specs

Composer must not offer or silently create a class that does not belong to the released era.

Minimum rule:

- **Vanilla:** no Death Knights.
- **TBC:** no Death Knights.
- **WotLK:** Death Knights available.

For deeper fidelity, Vanilla should also respect historical faction class availability where appropriate, especially Alliance Paladin / Horde Shaman before TBC. Race availability should be enforced server-side, not merely hidden in the addon.

Spec labels, talent assumptions and role feasibility must follow Era Talents rather than WotLK-only assumptions.

### Era-specific raid composition

Do not reuse a WotLK raid template and merely change the raid size.

**Vanilla**
- 40-player and 20-player layouts.
- Class-heavy roster planning matters more than modern role symmetry.
- Utility coverage must understand Vanilla-era buffs/debuffs and faction class restrictions.
- No Death Knight slots.

**TBC**
- 25-player and 10-player layouts.
- Subgroups matter enormously because many buffs/totems are party-local.
- Composer should optimize **each 5-player subgroup**, not just total raid-wide counts.
- Shaman placement, party-local support and group synergies should be visible in Review.
- No Death Knight slots.

**WotLK**
- 10/25-player layouts.
- More utility becomes raid-wide and buff redundancy can be modeled globally.
- Death Knights enter the selector and template library.
- Titan Rune Alpha/Beta/Gamma appear only at their intended WotLK progression phases.

Templates should therefore be keyed by **era + activity + size + difficulty/phase**, with hand-tuned canonical defaults and Auto filling any slots the player did not pin.

### Dungeon flow

- Vanilla/TBC: Composer owns assemble + prepare + travel/teleport. Do not depend on Wrath Random Dungeon Finder as the fantasy of these eras.
- WotLK: Random Normal/Heroic may hand off to Blizzard RDF when appropriate; specific Composer activities can still use explicit travel/teleport.
- Existing humans/bots remain sticky in every era.
- Difficulty validity follows the **selected activity's era**, not merely the realm's maximum era. A released Vanilla dungeon therefore remains Normal-only even on a WotLK realm; Titan Rune applies only to WotLK dungeons.
- Activity Browser/Progression should open at the highest released era relevant to the character, while older released content remains manually browsable.
- Anti-boost rules remain active in every era. The lowest real human defines the peer target so a high-level friend cannot boost a lower-level human through Composer; a solo high-level player may still run trivial legacy content with high-level peer bots.

## Bot population fidelity

The friends realm should feel inhabited by characters who live in the same expansion as the players.

### Hard rules

- Vanilla: no normal bot above 60.
- TBC: no normal bot above 70.
- WotLK: normal cap 80.
- Composer may apply the stricter player-relative anti-boost rule on top of the realm cap.
- Bots cannot wear/use future-era gear, recipes or consumables.
- Bots cannot know/use future-era class mechanics that Era Talents or the era policy disables.
- Managed Composer preparation may fix role/talents/consumables, but must not conjure gear from progression the group has not reached.

### Population transition

When TBC opens, existing Vanilla bots should remain valid and become able to progress toward 70. Opening TBC should not instantly replace the world with a wall of freshly generated level-70 raid-geared bots.

Likewise WotLK unlock should let the existing population grow into Northrend.

For the fresh friends realm, generate/seed bots under the active cap from day one. On the dirty dev realm, prefer **quarantining/ignoring over-cap bots** for early-era tests rather than destructively rewriting the whole test population.

## Auction House and economy fidelity

The AH is a major contamination path and needs explicit era control.

### Current known gap

configure-ahbot.sh is WotLK-biased today. It explicitly prioritizes WotLK gems, flasks, combat/health/mana potions, Fish Feast and WotLK gathering materials. That must not be used unchanged on a Vanilla/TBC friends realm.

### Layered AH policy

Use several defenses together:

1. **Category gates**
   - Vanilla: no socket-gem category generated by the TBC socket system; no Glyph category.
   - TBC: socket gems allowed; Glyph category remains disabled.
   - WotLK: gems and glyphs allowed.

2. **Use/equip level ceiling**
   - Vanilla max 60.
   - TBC max 70.
   - WotLK max 80.
   mod-ah-bot-plus already exposes EquipItemUseOrEquipLevelRestrict.

3. **Item-level ceiling as a safety net**
   - useful as a second filter, but **never the sole definition of expansion** because item levels overlap between expansion datasets.

4. **Expansion provenance manifest**
   - build a reproducible item manifest that records the earliest allowed era for each auctionable item;
   - feed future-era IDs into the AH seller's disabled/custom filter or patch the seller to call the central policy;
   - keep explicit override files for edge cases;
   - test the generated manifest in CI.

5. **Existing auction audit**
   - before a fresh realm opens and after every expansion transition, audit live auctions for future-era items;
   - fresh Vanilla release must start clean;
   - do not silently delete legitimate player items during a normal forward expansion transition.

### Era market profiles

Have named profiles instead of one giant WotLK script:

- vanilla: cloth/leather/ore/herbs, Vanilla consumables, recipes and reasonable leveling gear.
- tbc: Vanilla stock remains; TBC mats, primals, gems, flasks and recipes enter the market.
- wotlk: Vanilla + TBC stock remains; Northrend mats, glyphs, WotLK flasks/food/gems enter.

The market should widen when an expansion opens rather than being replaced.

## World/content fidelity beyond Composer

### Must-have before friends-realm release

- Hard level cap 60/70/80.
- Outland unavailable before TBC.
- Northrend unavailable before WotLK.
- Future-expansion dungeon/raid portals and teleports blocked.
- Future-expansion loot/reward/catch-up items blocked.
- AH future-item filtering.
- Bot level/gear/era filtering.
- Profession skill ceilings:
  - Vanilla 300;
  - TBC 375;
  - WotLK 450.
- Jewelcrafting unavailable before TBC.
- Inscription unavailable before WotLK.
- Death Knights unavailable before WotLK.
- Era-aware vendor/reward filtering.
- Group Composer activity/template/class restrictions.
- AdventureStart and catch-up profiles cannot bypass the realm era on the friends realm.

### Strong fidelity targets

- Blood Elf/Draenei creation unavailable before TBC.
- Vanilla faction class restrictions where appropriate.
- Flying unavailable before TBC and only in era-valid locations/conditions.
- WotLK-only convenience systems such as dual spec gated until WotLK if practical.
- Expansion-specific badge/emblem vendors and currencies gated.
- Expansion transport routes/portals enabled only when their destination era is released.
- World-event/NPC additions reviewed for future-era leakage.

### Deep historical fidelity, separate scope

The 3.3.5a base contains later client mechanics and later versions of some old data. Exact recreation of every 1.12/2.4.3 item stat, trainer cost, mount level, client panel and patch-specific rule is a much larger project.

That deeper layer is optional and should be tracked explicitly rather than accidentally promised by a simple era gate. Era Talents demonstrates that targeted historical reconstruction is possible when a system is worth the effort.

## Expansion release transaction

Opening a new expansion should be one deliberate server operation with a preview, confirmation and audit.

Proposed sequence:

1. Verify the current final progression requirement.
2. Admin chooses Open TBC or Open WotLK.
3. Show a confirmation summary of what changes.
4. Advance the one server-authoritative realm era.
5. Raise level/profession caps.
6. Enable destination maps/transports/content.
7. Reconcile bot population policy.
8. Switch AH market profile and seed newly legal stock.
9. Refresh Group Composer catalog/templates/recommendations.
10. Run an era-integrity audit.
11. Broadcast the expansion opening to players.
12. Persist an audit/event row so the transition is explainable later.

The operation is forward-only on the friends realm.

## Era Integrity audit

Add a server/admin diagnostic that can answer "is this realm actually clean for its declared era?"

Suggested checks:

- realm era + expected level/profession caps;
- online bots above cap;
- stored/random bots above cap;
- bots wearing future-era items;
- future-era items currently listed on AH;
- future-era items in automated starter/catch-up kits;
- future activities exposed by Composer;
- future classes/races allowed;
- future map/teleport access;
- future profession trainers/recipes;
- future vendor inventory;
- WotLK-only systems enabled too early.

The audit should report **PASS / WARN / FAIL** with counts and examples. It should be read-only by default.

## Additional era-relevance checklist

The following are strong candidates for making the realm *feel* like the active expansion, not merely obey a level cap:

- **Population geography:** bot density should shift toward era-appropriate leveling/endgame hubs instead of Northrend remaining busy during Vanilla.
- **Bot knowledge boundary:** chatter, goals and guild ambitions should not reference unreleased continents/raids as current events.
- **PvP lifecycle:** Vanilla battlegrounds first; arenas arrive with TBC; Wintergrasp and WotLK PvP systems arrive with WotLK.
- **System lifecycle:** dual spec, heirloom acquisition, glyphs and other WotLK systems stay unavailable until WotLK where technically practical.
- **Travel lifecycle:** portal/transport/flying systems activate with the expansion that introduced the destination/mechanic.
- **Race/class lifecycle:** Blood Elf/Draenei with TBC; Death Knight with WotLK; Vanilla faction class restrictions where practical.
- **Profession lifecycle:** trainers, recipes and bot crafting behavior obey 300/375/450 and expansion-specific professions.
- **Vendor/currency lifecycle:** badges/emblems, reputation vendors and catch-up gear cannot leak from future eras.
- **Loot lifecycle:** audit later-reworked legacy drops so automated gearing cannot smuggle future-era power into earlier progression.
- **Event lifecycle:** holiday/world-event rewards should be audited for later-expansion additions.
- **Expansion opening world reaction:** announcements, NPC dialogue, population movement and Adventure Guide state should visibly change when a new era opens.

The full candidate list and non-era feature ideas live in `FEATURE_IDEAS.md`.

## Implementation order

1. **Central era policy + audit skeleton.**
2. **Bot population hard ceiling and future-gear rejection.**
3. **Group Composer era UX + class/template/subgroup rules.**
4. **AH era profiles + provenance filtering.**
5. **Profession/vendor/reward/map/transport gates.**
6. **One-button/manual expansion transition orchestration.**
7. **Fresh-realm acceptance matrix for Vanilla, TBC transition and WotLK transition.**

This order makes leaks visible early and avoids burying era logic independently inside every subsystem.
