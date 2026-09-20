# Feature Ideas / Future Backlog

_Status: idea bank, not an implementation promise. Items become scheduled work only when promoted into NEXT_WORK.md._

The goal is to make the realm feel alive and era-correct without throwing away the quality-of-life advantages of a private server with Playerbots.

## Design filter

A feature is a strong fit when it does at least one of these:

- makes Vanilla → TBC → WotLK progression feel more authentic;
- makes Playerbots feel like persistent inhabitants instead of disposable NPCs;
- removes GM-command babysitting from normal play;
- helps a small group of friends experience raid/dungeon content naturally;
- gives useful information without automating the fun out of the game;
- is reversible/configurable and does not corrupt the permanent dev realm.

Features that materially trivialize progression should be optional, clearly labeled, or kept off the future friends realm.

## Era-relevance improvements

### High-value / should strongly consider

1. **Era-aware bot population director**
   - Vanilla world bots cap at 60, TBC at 70, WotLK at 80.
   - Zone distribution follows the current expansion and actual level bands.
   - Opening an expansion lets existing bots grow forward rather than spawning an instant army of max-level raid bots.
   - Bot gear, consumables, enchants, gems and professions obey the active era.

2. **Era-aware Auction House profiles**
   - Vanilla market contains Vanilla materials, consumables, recipes and gear.
   - TBC adds Outland materials, primals, gems, TBC recipes and consumables while retaining Vanilla stock.
   - WotLK adds Northrend materials, glyphs, WotLK gems/food/flasks while retaining older stock.
   - Era Integrity audit checks every automated listing for future-era leakage.

3. **Era-aware profession world**
   - Skill ceilings 300 / 375 / 450.
   - Jewelcrafting locked until TBC.
   - Inscription locked until WotLK.
   - Expansion-invalid trainers, recipes and automated crafting offers are hidden/rejected.
   - Bots should have believable profession skill for their level and era.

4. **Era-aware Group Composer identity**
   - Header clearly shows current expansion and cap.
   - Current expansion is the default activity view.
   - Older content remains under Legacy / Leveling / Attunement.
   - Future content is hidden or shown only as a locked Journey preview.
   - DK unavailable before WotLK.
   - Vanilla/TBC do not pretend Wrath RDF is their normal dungeon workflow.

5. **Era-specific raid composition intelligence**
   - Vanilla templates understand 40-player/20-player roster needs and faction class restrictions.
   - TBC templates optimize every 5-player subgroup for totems, party buffs and synergies.
   - WotLK templates optimize raid-wide buff coverage and 10/25-player roles.
   - Review should explain *why* a class/spec was placed in a subgroup.

6. **Era-aware vendors and currencies**
   - No badges/emblems/catch-up vendors from future eras.
   - Expansion-specific reputation vendors appear only when their expansion is live.
   - Automated regear/prep cannot buy or award a future-era item.

7. **Era-aware travel and geography**
   - Outland routes/portals disabled before TBC.
   - Northrend routes/boats/zeppelins/teleports disabled before WotLK.
   - Flying unavailable before TBC.
   - Cold Weather Flying and Northrend-specific travel remain WotLK.
   - Composer travel always passes the same central era policy.

8. **Expansion-system gates**
   - Arenas unavailable in Vanilla and enabled with TBC.
   - Death Knights unavailable until WotLK.
   - Dual spec gated until WotLK if technically practical.
   - Glyph economy/UI support treated as WotLK.
   - Heirloom acquisition disabled before WotLK.
   - Achievements can remain a client artifact on the 3.3.5a base, but should not leak future-era rewards/progression into Vanilla/TBC.

9. **Era-aware PvP**
   - Vanilla: battleground focus and Vanilla-appropriate rewards.
   - TBC: arenas and TBC PvP gear enter.
   - WotLK: WotLK arena seasons/rewards and Wintergrasp become available.
   - Bots in PvP obey era gear and level constraints.

10. **Era-aware world events**
    - Audit holiday/world-event NPCs, vendors and rewards for future-era additions.
    - Gate expansion-specific events and rewards instead of exposing the entire 3.3.5a event catalog from day one.

### Strong authenticity polish

- Historical faction class rules in Vanilla: Alliance Paladin, Horde Shaman.
- Blood Elf/Draenei unavailable until TBC.
- Era-correct riding/flying skill requirements and costs where practical.
- Era-correct reagent/ammo/pet requirements if the underlying 3.3.5a systems differ materially.
- Era-aware trainer spell filtering beyond talents.
- Era-aware loot-table audit for backported/reworked dungeon drops.
- Era-aware quest/NPC phasing for later-added quest hubs.
- Prevent future-era enchants, socket bonuses and consumables from automated systems.
- Bot chat/lore knowledge should not casually reference Northrend/Lich King events while the realm is still Vanilla.
- Guild bot ambitions should track the current expansion: Molten Core means something in Vanilla rather than being treated as obsolete content.
- Expansion-opening announcements and NPC chatter should make the world visibly react when TBC/WotLK opens.

### Optional deep-fidelity projects

These are much larger and should not block the basic Vanilla-first friends realm:

- reconstruct historically accurate 1.12/2.4.3 item stats where 3.3.5a changed old items;
- restore historical trainer costs/riding rules;
- reproduce old attunement requirements that later patches removed;
- rebuild historically changed dungeon/raid loot tables;
- hide or neutralize unavoidable Wrath client UI artifacts where possible;
- phase content by major patch inside an expansion, not only by expansion.

## Broader server feature ideas

### 1. Expansion Command Center

Admin Panel page showing:

- current era and raid phase;
- player/bot/profession/AH integrity status;
- what opening the next expansion will unlock;
- a dry-run preview;
- backup checkpoint;
- final confirmation;
- post-transition audit.

This becomes the cockpit for Vanilla → TBC → WotLK instead of relying on scattered GM commands.

### 2. Era Integrity dashboard

Player-safe summary plus detailed GM diagnostics:

- over-cap bots;
- future-era AH items;
- future-era equipped bot gear;
- leaked professions/classes/maps/vendors;
- Composer catalog mismatches;
- PASS/WARN/FAIL with examples.

### 3. Classic-style LFG Board for Vanilla/TBC

Instead of Wrath RDF:

- players post "Deadmines", "BRD", "Karazhan", etc.;
- real players can join;
- bots can volunteer to fill missing roles;
- Composer can turn the listing into a reviewed group;
- optional travel after the group is accepted.

This keeps the older-era social flavor while still making a tiny private realm playable.

### 4. Raid Night Planner

- choose raid/date/target size;
- reserve real friends first;
- save required/pinned bots as a bench;
- show expected buff/utility coverage;
- warn about lockout conflicts;
- "Build this raid" when everyone logs in.

### 5. Persistent Bot Bench / Guild Roster

Let the guild maintain a named bench of trusted bots:

- main tank bots;
- healing core;
- specialist utility;
- geared alts;
- attendance/clear history;
- preferred raid roles.

Composer should prefer the bench before random world bots.

### 6. Bot Crafting Orders

Ask a guild bot for an era-valid craft:

- search recipe;
- show required mats;
- use guild bank/player mats;
- queue craft;
- deliver by trade/mail;
- never conjure missing materials.

This makes professions useful on a low-population realm.

### 7. Guild Bank Steward

Bots can:

- deposit useful mats/consumables;
- keep configurable stock targets;
- avoid stealing rare/player-reserved items;
- prepare raid consumable kits;
- expose a readable ledger of deposits/withdrawals.

### 8. Dynamic World Population Director

Move bot activity toward where players actually are:

- leveling zones;
- capitals;
- current expansion hubs;
- battleground queues;
- dungeon entrances;
- profession/AH behavior.

Avoid teleport-spam around the player; changes should feel organic.

### 9. Attunement / Progression Assistant

Adventure Guide page that says:

- what is unlocked now;
- exact next attunement/quest step;
- where the next NPC/objective is;
- which friends are on the same step;
- which raid opens afterward.

No auto-completion, just excellent breadcrumbs.

### 10. Raid Readiness and Consumable Planner

Before Assemble:

- missing enchants;
- missing era-valid consumables;
- resistance requirements where relevant;
- repair state;
- ammo/reagents where relevant;
- class-specific raid essentials.

Allow "Prepare Bots" while humans remain advisory-only.

### 11. Wipe Analyzer / Raid Coach

After a wipe, give a short factual report:

- first deaths;
- avoidable mechanic failures;
- missing interrupts/dispels;
- tank/healer deaths;
- bot strategy failures;
- suggested retry action.

Especially useful while validating Playerbot raid AI.

### 12. Smart Loot Council for Bots

Humans retain normal loot choice. Bot loot can consider:

- upgrade size;
- role/spec;
- set bonuses;
- main-role priority;
- duplicate waste;
- guild bench importance.

Keep a loot ledger so decisions are explainable.

### 13. Guild Chronicle / Trophy Room

Persistent history:

- first guild kill;
- roster;
- date;
- deaths/wipes before first clear;
- screenshots/notes via website later;
- expansion completion milestones;
- "first Ragnaros", "first Illidan", "first Lich King".

Could feed a public page on join.skrra.dev later.

### 14. World First / Milestone Announcements

Realm-wide announcements for meaningful firsts:

- first level 60/70/80;
- first profession cap;
- first dungeon/raid clear;
- first legendary;
- expansion completion.

Keep it tasteful and configurable.

### 15. Expansion Opening Event

When TBC/WotLK is manually opened:

- server announcement;
- faction-leader dialogue;
- portal/transport becomes active;
- bots gather around the event;
- Adventure Guide updates;
- optional short countdown;
- permanent chronicle entry.

Makes expansion release feel like an event rather than a config toggle.

### 16. Bot Social Knowledge Boundaries

The chatter system should know:

- current expansion;
- current raid phase;
- guild kills;
- player's recent adventures;
- what content is still locked.

Bots should not talk as if Icecrown is yesterday's news while everyone is progressing Molten Core.

### 17. Character Journey Page

A personal Adventure Guide timeline:

- level milestones;
- dungeon clears;
- raid clears;
- attunements;
- notable drops;
- reputation milestones;
- expansion transitions.

Useful without changing gameplay balance.

### 18. Friend Onboarding Portal

join.skrra.dev could eventually provide:

- account registration;
- client/addon setup;
- realm status;
- current expansion;
- server rules;
- addon download;
- "what should I do next?" starter guide.

Keep admin/database services private.

### 19. Safe Snapshot / Rollback Tooling

Before major releases:

- DB snapshot;
- config/commit SHA stamp;
- migration summary;
- restore instructions;
- guard against accidentally targeting the dev realm when preparing the fresh friends realm.

### 20. Optional Challenge Profiles

Later, separate from the canonical friends experience:

- Hardcore character;
- Self-Found;
- no-AH;
- no-bot-assistance;
- reduced XP;
- raid-size challenge.

These should be opt-in character/realm rules and never contaminate the normal progression path.

## Candidates worth prototyping first

Once the current runtime validation loop is complete, the highest-leverage candidates are:

1. Era Integrity dashboard / central era policy.
2. Era-aware bot population ceiling.
3. Era-aware AH profiles.
4. Group Composer per-era templates and TBC subgroup optimizer.
5. Classic-style LFG Board for Vanilla/TBC.
6. Expansion Command Center.
7. Persistent Bot Bench.
8. Bot Crafting Orders.
9. Wipe Analyzer.
10. Guild Chronicle.

These candidates improve the core journey or make a low-population friends realm substantially more playable without simply handing out progression.
