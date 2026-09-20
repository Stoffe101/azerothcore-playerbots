# Group Composer V4 + Private WoW Server Status / Roadmap

_Last updated: 2026-09-20_

This document is the working handoff for the private AzerothCore + Playerbots server and the Group Composer V4 project.

## 1. Project goal

The goal is a private WoW 3.3.5a server that feels like a populated MMO rather than a solo sandbox. The technical base is AzerothCore + Playerbots, but the gameplay experience is intentionally progression-driven:

1. Start with a clean **Vanilla** realm state.
2. Play through Vanilla content.
3. Manually release **The Burning Crusade**.
4. Play through TBC content.
5. Manually release **Wrath of the Lich King**.
6. Keep old content available after later eras open.

Group Composer is the player-facing group/raid builder. Azeroth Control/Admin Panel is the world/server management surface.

---

## 2. Current development branch and deployment flow

Repository:

`Stoffe101/azerothcore-playerbots`

Active Group Composer branch:

`test/group-composer-v4`

For Group Composer development we use the local CI runner:

`stoffes-pc`

Local Integration runner labels:

`self-hosted, Linux, X64, wow-builder`

Local toolchain:

- Clang 18
- Ninja
- 8 parallel compile jobs
- persistent ccache
- Ubuntu 26.04 workaround pinning Clang 18 to GCC 15 libstdc++ with:
  `--gcc-install-dir=/usr/lib/gcc/x86_64-linux-gnu/15`

Do not remove that workaround without a specific reason.

When a commit should go through the PC build, use `[local-ci]` in the commit message.

Once a Group Composer commit is fully green and ready for in-game testing, deploy on the server with:

```bash
git switch test/group-composer-v4
git pull
./update.sh
```

`./update.sh` handles local module sync, patches, configs, Docker rebuilds, DB migrations, stack restart and client-addon sync.

---

## 3. What is completed

### Modern Group Composer shell

Group Composer V4 now uses the TypeScriptToLua UI path as the active modern shell.

The current addon version is:

`0.14.0`

The UI has been rebuilt around a cleaner one-border/content-first design with reusable controls, scroll frames, modern activity cards and scalable layouts.

### Stable group construction flow

The V4 flow is deliberately split into phases:

1. Configure activity and composition.
2. **Build & Prepare** a valid roster.
3. Review the prepared roster.
4. **Assemble** the live party/raid.
5. **Teleport to Instance** as an explicit player-confirmed action.

Important behavior already preserved:

- existing group members are sticky anchors instead of being silently replaced;
- guild bots are preferred when configured;
- disposable Playerbot capacity can be prepared without rewriting persistent guild identities;
- role/class/spec preferences are supported;
- human players and pinned bots are supported;
- subgroup arrangement is preserved for stable members;
- bot preparation is separated from destructive live-group changes.

### Real three-expansion realm gate

The server now has an explicit live-era state:

- **Vanilla**
- **TBC**
- **WotLK**

This is no longer just a WotLK released/not-released boolean.

The live era controls:

- level cap;
- Individual Progression ceiling;
- which expansion's activities are eligible;
- which dungeon difficulty families are valid;
- Admin Panel expansion controls;
- expansion-dependent teleport destinations;
- default fresh-character profile behavior.

Vanilla fresh start is a real clean start rather than a TBC-oriented bootstrap.

Manual release commands exist for advancing the realm:

- Vanilla -> TBC
- TBC -> WotLK

Existing characters are not automatically boosted when an expansion is released.

### Era-aware activity catalog

A server-authoritative Adventure Catalog now describes Group Composer activities across all three eras.

The catalog contains:

- activity ID and display name;
- dungeon/raid type;
- era;
- instance map;
- minimum level;
- minimum progression stage;
- preferred group size;
- Playerbots support state;
- support notes;
- final-boss entry where clear tracking is available.

Vanilla and TBC dungeons are now part of Group Composer rather than the browser being effectively WotLK-only.

### Era-aware difficulty rules

The browser and server now enforce era-specific rules:

- **Vanilla:** Normal dungeons
- **TBC:** Normal + Heroic
- **WotLK:** Normal + Heroic + Titan Rune Alpha/Beta/Gamma

Titan Rune modes cannot leak backward into Vanilla/TBC.

### Co-op access preflight

Activity availability is now checked for the **whole real-player composition**, not only the Group Composer owner.

Group Composer validates:

- the owner;
- every real player already in the live party/raid;
- manually added real players once their draft entry exists.

A friend can now make an activity visibly unavailable before assembly if they are missing the required level, progression milestone, quest chain, key/item, achievement or item-level gate.

The Unlock Requirements modal includes **Player:** rows so it is clear exactly which human is ready and which human is blocking the activity. Offline humans are treated as unresolved until they log in, because Composer cannot safely verify their quest/item/achievement state.

The same access rules are rechecked during Build & Prepare and again immediately before assembly, preventing a stale preview from allowing one human to strand the group at the portal.

For raids, this preflight also compares the real AzerothCore instance bind for every online human anchor at the selected difficulty. Humans saved to different instance IDs are rejected with a player-specific lockout-conflict reason before Composer commits the roster. An unbound friend remains compatible with a bound friend, so ordinary "join my saved run" play still works.

### Exact unlock-path modal

Locked activity cards are now interactive instead of dead ends.

Clicking a locked dungeon or raid opens a server-backed **Unlock Requirements** modal showing:

- expansion release state;
- character level;
- progression milestone with current/required stage;
- every detected quest in the prerequisite chain, individually marked completed or missing;
- required key/item entries;
- required achievements;
- average item-level gates;
- era-specific difficulty restrictions.

The card keeps the concise blocker, while the modal answers: **"Exactly what do I have to do to unlock this?"**

### Better locked-activity explanations

Activity eligibility is now server-authoritative and much more informative.

Instead of a generic lock, Group Composer can report concrete reasons such as:

- expansion not released;
- level requirement;
- progression milestone requirement;
- quest-chain requirement;
- item/key requirement;
- achievement requirement;
- item-level requirement;
- generic AzerothCore instance access failure only as a final fallback.

Progression locks also include the player's current stage and the required stage.

### Era-aware activity browser

The activity browser now has expansion pages/tabs for:

- Vanilla
- TBC
- WotLK

It also has:

- **Favorites**
- **Recent**

Activities can be starred, and recent selections are remembered in the addon database.

Cards display availability, era, support status and the exact lock reason when unavailable.

### Persistent clear history ledger

Boss-clear history is now recorded independently of the optional adventurer-economy bounty system.

For each real player and instanced dungeon/raid boss, the server stores:

- map and boss;
- instance ID;
- difficulty;
- group size;
- guild ID at the time of the kill;
- first and last kill timestamps;
- per-character clear count.

The Progression page uses final-boss entries from the authoritative Adventure Catalog to show personal and guild clear counts plus first-clear dates. Existing bounty rows remain a compatibility fallback for older test-realm clears.

### Raid-history detail view

Raid cards on the Progression page are now clickable.

The history modal shows:

- personal clear count and first recorded clear date;
- guild clear count and first recorded clear date;
- the real-player names recorded in the guild's first tracked final-boss instance;
- active lockout ID / completed encounter count / extended state;
- the activity's current availability/support explanation.

First-clear rosters come from the independent progression-event ledger. Very old test-realm clears that only exist in the legacy bounty table can still show completed status, but cannot reconstruct who was present.

### Progression page

Group Composer now has a dedicated **Progression** page.

It shows:

- current live realm era;
- current character progression stage;
- character level versus current era cap;
- next-expansion gate messaging;
- raids grouped by era;
- whether each raid is available or locked;
- whether **you** have cleared it;
- whether the **guild** has a recorded clear;
- the relevant support/lock note.

Current clear tracking uses existing adventure boss-bounty history where a final boss is defined, with progression-stage fallback for milestone raids. Guild completion is based on recorded boss clears from guild members. This is useful now, but it is also an area we can deepen later into a richer historical progression ledger.

### Raid lockout awareness

The journey/recommendation backend now reads AzerothCore's real player instance binds for raid activities.

For an active lockout Group Composer tracks:

- whether the character is currently bound;
- instance ID;
- number of completed encounter bits in the saved instance;
- whether the lockout is extended.

The Progression page shows active lockouts, and Recommended Activities prioritizes an unfinished raid the player is already saved to as **Resume active lockout** instead of pretending every raid recommendation is a fresh run.

### Smarter recommendation weighting

The recommendation order now uses more than simple era/level proximity.

It also prefers:

- an unfinished active raid lockout;
- a current-era raid where the guild has **no recorded clear yet**;
- content where the player's gear meets Composer's floor but is still below the activity's target, making it a sensible upgrade opportunity;
- actionable locked content with a concrete quest/key/achievement requirement.

Very overgeared farm content is still available, but is gently pushed down so it does not drown out progression and useful upgrades.

### Gear-aware recommendations

Recommended Activities now reuse the **same Composer gear profile** that prepares bots for an activity.

For an available recommendation the page can show:

- your current average item level;
- Composer's recommended floor;
- the stronger target item level when one is defined;
- **GEAR READY** when you meet the floor;
- **GEAR LOW** when the activity is technically unlocked but your character is below the recommended preparation floor.

This is advisory unless AzerothCore itself has a hard item-level access requirement. It prevents "unlocked" from being confused with "good idea right now" without fabricating a second independent gearing model.

### Friend-aware recommendation previews

Recommendation dry-runs now expose the real-human side of the preview, not just the bots.

A **GROUP READY** recommendation shows:

- how many real players are anchored;
- which human character names are being preserved;
- how many bots would be selected;
- how many selected bots are guild companions;
- the current eligible guild-candidate count.

This makes recommendations useful when friends are already grouped: the page can say, in effect, "the three of you are anchored and Composer only needs two bots," instead of presenting the recommendation as if it were a solo-player roster.

### Capacity-aware recommendations

Recommended Activities now dry-run the real Group Composer planner before presenting an available activity as group-ready.

For each available recommendation the backend reports:

- whether the current live player/bot pool can build a standard role layout right now;
- how many bots the preview would select;
- how many of those selected bots are guild companions;
- how many eligible guild candidates the planner saw;
- the exact planner error when the roster is not currently feasible.

The page labels cards **GROUP READY** or **ROSTER NEEDS WORK** rather than pretending every unlocked activity can immediately be formed.

The page also includes lower-priority **NEXT UNLOCK** cards for current-era activities that are still locked. These reuse the same exact level/progression/quest/item/achievement blocker text as the activity browser and cannot be configured until unlocked.

### Recommended Activities page

Group Composer now has a dedicated **Recommended Activities** page.

The server builds suggestions using:

- live realm era;
- player level;
- progression eligibility;
- activity support state;
- whether a progression raid is still uncleared;
- suitable current-era dungeons.

Recommendations can be clicked to configure Group Composer for that activity.

### Saved dungeon party templates

Templates are no longer raid-only.

Custom five-player dungeon party templates can now save and restore:

- role counts;
- activity/difficulty;
- class/spec preferences;
- humans;
- pinned bots;
- other composition options.

Raid templates still keep the built-in expansion-aware coverage presets.

### Azeroth Control / Admin Panel era integration

Azeroth Control now understands the same three-era model.

It includes:

- Vanilla/TBC/WotLK live-state display;
- era-specific level/progression limits;
- manual TBC release;
- manual WotLK release;
- era-aware starter profiles;
- era-aware progression controls;
- TBC/WotLK destination locks;
- Vanilla-first presentation instead of assuming TBC is the baseline.

### Activity catalog diagnostics

Group Composer now has a development-facing **Diagnostics** page that validates every catalog activity against the live server data.

For each dungeon/raid it checks:

- unique Composer ID and display name;
- Map.dbc presence;
- canonical AzerothCore entrance trigger used by explicit instance teleport;
- era-appropriate minimum level;
- group/raid size contract;
- stock Normal Dungeon Finder entry when applicable;
- configured final-boss creature entry for progression history;
- Playerbots support classification and notes.

Results are grouped into **PASS**, **WARN** and **FAIL**. Experimental/not-ready Playerbots support is a warning; broken structural data such as a missing map, entrance or final-boss creature is a failure.

### Post-assembly lifecycle and roster explanations

The reviewed roster now remains useful after assembly/teleport instead of becoming a dead-end state.

Planned/current lifecycle controls include:

- **Rebuild / Repair Roster** using the current configuration and live group as sticky anchors;
- **Leave Instance** using AzerothCore's canonical go-back trigger while keeping the reviewed group assembled;
- **Disband Composer Group** with strict leader/exact-roster safeguards so Composer cannot remove an unreviewed player;
- an in-addon **Group Actions** modal for Rebuild/Repair, Leave Instance Together and safe disband;
- clickable prepared dungeon/raid roster members with a **Why this bot?** explanation;
- member-level rationale including role/spec, guild preference, pinned/sticky status, source pool, readiness, utility, current item level when available and peer-level eligibility.

### Existing deployment safety

The server's public-access support already has useful hardening:

- MySQL is intended to stay loopback-only;
- SOAP is not intended to be publicly exposed;
- auth brute-force lockout is enabled;
- only WoW auth/world ports should be exposed;
- nightly backups are supported;
- the web registration site is designed to sit behind a reverse proxy/tunnel rather than be WAN-forwarded directly.

---

### Latest implementation checkpoint

The current V4 feature set now includes the remaining original UX items and the next reliability/history layer:

The latest continuation also adds a **structured exact unlock-path modal** for locked activities, backed by the server's real quest/item/achievement/access-requirement data.

- exact activity lock explanations, including quest/item/achievement/progression blockers;
- Vanilla/TBC/WotLK-aware browsing and difficulty rules;
- era-aware Random Dungeon Finder handoff, including the stock 3.3.5a Random Classic category;
- Progression and Recommended Activities pages;
- Favorites and Recent Activities;
- saved dungeon party templates;
- anti-boost peer-level bot selection;
- post-assembly Group Actions;
- clickable server-authored **Why this bot?** rationale;
- persistent real-player boss-clear history;
- personal/guild clear counts and first-clear dates;
- clickable Raid History details with the first recorded guild-clear roster;
- raid lockout awareness and **Resume active lockout** recommendations;
- activity catalog diagnostics;
- roster-aware recommendations that dry-run the real planner;
- **GROUP READY / ROSTER NEEDS WORK / NEXT UNLOCK** recommendation states.

The exact-commit CI rule below still applies before deployment.

## 4. CI status and definition of green

For every exact Group Composer commit we care about these workflows:

- **Group Composer client checks**
- **Stage Group Composer V4 backend**
- **Group Composer V4 compile**
- **Integration build**

A build is not considered green until the relevant workflows for the **same exact commit** have all completed successfully.

The local Integration build has already been proven working on `stoffes-pc`, including the Clang 18 / GCC 15 libstdc++ workaround.

The last fully verified baseline before the current continuation round is `349fd352c42179802f8d76051ec88085f7e3c073` (`docs: refresh Group Composer completion handoff [github-ci]`). All four required workflows completed successfully for that exact commit.

The continuation work after that baseline adds roster-aware recommendations and first-guild-clear roster history. Because `stoffes-pc` is intentionally offline, these commits use `[github-ci]`. Treat the newest branch head as deployable only after all four exact-head workflows complete successfully.

Even a fully green source/build checkpoint still requires real in-game validation before being treated as release-quality gameplay.

---

## 5. Immediate next steps

### A. Deploy this green checkpoint to the test realm

The current realm remains the development/testing realm. When the server PC is back on, deploy:

```bash
git switch test/group-composer-v4
git pull
./update.sh
```

This deployment includes the new characters-database migration for persistent adventure progression history.

### B. Run the in-game validation matrix

Static tests, TypeScriptToLua checks and C++ builds are green, but the following still need real-client/server validation.

#### Vanilla

- fresh level-1 character behavior;
- level cap 60 and progression ceiling;
- TBC activities visibly locked;
- Vanilla dungeon and raid browsing;
- Normal-only dungeon difficulty;
- Random Classic Dungeon Finder handoff;
- anti-boost bot level band;
- exact locked-activity explanations;
- Progression clear/lockout display;
- Recommended Activities;
- Favorites / Recent;
- saved dungeon party templates;
- Activity Diagnostics page;
- Group Actions and Why This Bot.

#### TBC

- manually release TBC;
- level cap becomes 70;
- Shattrath and TBC activities unlock;
- WotLK stays locked;
- Normal/Heroic dungeon rules;
- TBC raid templates/progression;
- anti-boost behavior while leveling 60-70;
- exact attunement/key/quest lock explanations where AzerothCore has access requirements.

#### WotLK

- manually release WotLK;
- level cap becomes 80;
- Northrend/Dalaran/Argent destinations unlock;
- WotLK raids/dungeons unlock;
- Titan Rune Alpha/Beta/Gamma appear only here;
- explicit Teleport to Instance;
- active raid lockout display and Resume active lockout recommendation;
- persistent clear counts and first-clear dates.

### C. Validate the new persistent progression history

The new ledger is implemented and compiled, but should be exercised with real kills.

Test:

1. Kill a tracked raid final boss once.
2. Confirm Progression shows the personal clear count and first-clear date.
3. Kill it again in a new instance and confirm the clear count increments.
4. Repeat with another real guild member and confirm guild clear history updates.
5. Verify Playerbot kills do not create fake real-player history.
6. Verify old test-realm bounty history still appears through the compatibility fallback.

The current ledger records player GUID, guild-at-kill, map, instance, boss, difficulty, group size, first/last timestamps and counts. Future history polish can still add explicit activity IDs, the complete participant roster for each clear, and a dedicated first-guild-clear record.

### D. Use Activity Diagnostics as a release gate

The new Diagnostics page should be run after deployment.

Structural **FAIL** results should be fixed before an activity is considered trustworthy. Typical failure checks include missing maps, missing entrance triggers, invalid final-boss entries or an invalid raid-size contract.

**WARN** is intentionally softer. It includes experimental/not-ready Playerbots support and cases such as an activity having no stock RDF entry while fixed-instance travel is still valid.

### E. Continue real Playerbots encounter validation

The catalog deliberately distinguishes:

- Guild Ready
- Playable / experimental
- Not Ready

Do not promote an encounter to Guild Ready just because the instance technically loads. Validate mechanics with real composed groups first.

### F. Smarter recommendations after runtime validation

Recommendation capacity-awareness is now implemented.

The page now dry-runs the real deterministic Group Composer planner for each available recommendation and shows:

- **GROUP READY** when the current human/bot pool can form a standard composition;
- **ROSTER NEEDS WORK** with the real planner failure when it cannot;
- selected bot count;
- selected guild-bot count;
- eligible guild-candidate count;
- lower-priority **NEXT UNLOCK** cards using the exact activity blocker when something is not yet available.

The remaining recommendation upgrades worth adding after runtime validation are:

- gear/item-level upgrade opportunities;
- more deliberate catch-up weighting;
- unfinished attunement/quest chains as guided objectives rather than only blocker text;
- likely dungeon upgrades;
- stronger guild progression context;
- optional first-guild-clear/history context in recommendations.

The target remains a useful answer to: **"What should we do tonight?"**

---

## 6. Remaining work after the current continuation round

The major Group Composer product features are now implemented. The remaining work is increasingly validation, tuning and release engineering rather than missing core UI.

### Must validate in-game

- full Vanilla -> TBC -> WotLK expansion-gate flow;
- low-level anti-boost behavior with real Playerbots;
- multi-human groups with 2-5 real players;
- exact quest/key/achievement lock explanations against real characters;
- persistent clear count increments and first-guild-clear rosters;
- raid lockout/resume behavior;
- Group Actions after real instance travel;
- Activity Diagnostics results for every listed activity;
- roster-aware recommendations against the real bot population.

### Still worth building

- gear/item-level-aware activity recommendations;
- richer guided attunement objectives beyond the new exact unlock-path modal, such as map/NPC breadcrumbs and recommended quest order across optional branches;
- smarter catch-up weighting;
- richer first-guild-clear/history presentation;
- optional recommendation weighting by guild progression and available friends;
- a guarded **create fresh release realm** workflow that leaves the development realm untouched;
- friend onboarding/registration polish for `join.skrra.dev`;
- continued Playerbots encounter-strategy validation and fixes.

### Release engineering

The current realm stays the dirty development/test realm. Before inviting friends for the real journey, create a separate clean realm starting at Vanilla with fresh character/guild/progression databases and the exact tested server/addon release commit.

---

## 7. Making the server reachable through skrra.dev

The clean layout is:

- `skrra.dev` -> keep the existing portfolio website
- `wow.skrra.dev` -> WoW realm hostname
- `join.skrra.dev` -> optional HTTPS registration/download/instructions page

The important distinction is that a domain name does **not** HTTP-forward the WoW protocol. DNS resolves the hostname to your home/public endpoint, and the router/firewall forwards the WoW TCP ports to the server PC.

### Recommended direct-hosting setup

#### 1. DNS

Create a DNS record:

```text
wow.skrra.dev  ->  your WAN/public IPv4
```

If skrra.dev uses Cloudflare, the WoW record must be **DNS only / unproxied**. The normal Cloudflare orange-cloud HTTP proxy cannot carry the WoW auth/world protocol.

If your public IP changes, use a DDNS/Cloudflare API updater so `wow.skrra.dev` follows the current WAN IP.

#### 2. Server environment

Use a strong unique DB root password first.

Then set:

```env
PUBLIC_REALM_ADDRESS=wow.skrra.dev
```

On Windows/WSL, keep `LAN_IP` set to the Windows host's LAN address so local clients receive a reachable private address.

The existing setup logic is designed so LAN players can still use the LAN route while remote players receive the public realm address.

#### 3. Router/firewall

Forward only:

```text
TCP 3724 -> server PC TCP 3724   # authserver
TCP 8085 -> server PC TCP 8085   # worldserver
```

Do **not** forward:

```text
3306  MySQL
7878  SOAP / GM console
8090  raw web registration service
8091  lore sidecar
11434 Ollama
```

If practical, restrict TCP 3724/8085 to the public IPs of your friends. That is much safer than exposing the game services to the whole internet.

Keep external world port 8085 as 8085 because the realm advertises that port to clients.

#### 4. Windows firewall / WSL

Make sure Windows Defender Firewall permits inbound TCP 3724 and 8085 to the server host.

The router should forward to the **Windows PC's LAN IP**, not a transient WSL 172.x address.

#### 5. Realm/client configuration

Friends should use:

```text
set realmlist wow.skrra.dev
```

The server's `PUBLIC_REALM_ADDRESS` setup should advertise the same public hostname through the realm list.

#### 6. Registration site

The repository already contains `webreg/`, a small registration/download service.

A good public layout is:

```text
join.skrra.dev -> HTTPS reverse proxy / Cloudflare Tunnel -> LAN webreg:8090
```

Do not directly port-forward 8090 to the internet.

Cloudflare Tunnel is suitable for the **web registration site**, even though it is not a replacement for the raw WoW TCP 3724/8085 connection.

Use one account per real player and do not give friends GM privileges.

#### 7. Check for CGNAT before relying on port forwarding

Compare:

- the WAN IPv4 shown by the router; and
- the public IPv4 seen by an external "what is my IP" service.

If they differ significantly, or the router WAN address is private / carrier-grade NAT space, normal inbound port forwarding may not work.

If the ISP uses CGNAT, options are:

- ask the ISP for a public IPv4;
- use a VPN mesh such as Tailscale/ZeroTier for a small trusted friend group;
- use a small VPS as a TCP relay/tunnel endpoint and point `wow.skrra.dev` at the VPS.

For the cleanest "friends type one domain and connect" experience, a real public IPv4 at home is simplest.

---

## 8. Realm lifecycle: test realm vs fresh release realm

The current realm is intentionally the **development/testing realm**. It is allowed to accumulate test characters, debug progression, temporary boosts, experimental guild state and repeated expansion-gate changes.

It should **not** become the permanent friends realm by slowly cleaning it up.

When the project reaches a release-quality checkpoint, create a separate fresh realm/database state with:

- brand-new character and guild data;
- Vanilla as the live era;
- level cap 60;
- progression at the true starting stage;
- no test clears, debug quest completions or raid-ready boosts;
- production-safe account/admin settings;
- the same tested server code, modules and addon versions as the release commit.

The preferred release flow is to preserve the test realm for future development and create the fresh realm from clean database volumes/backups, rather than destructively wiping the only test environment. A future maintenance task should package this into a deliberate "create fresh realm" procedure with backup/confirmation guards.

### Anti-boost Group Composer rule

Group Composer now treats bot level as part of roster eligibility.

For the selected activity era:

- disposable Composer capacity is prepared toward the player's level, capped by that expansion's level cap;
- non-grouped bots more than **2 levels above the player's effective level for that era** are excluded;
- bots can never exceed the selected activity era's cap;
- persistent guild companions are never silently downleveled;
- an already-grouped overleveled bot is not kicked automatically. Instead Composer refuses the build with an explicit message so the player can remove it manually;
- assembly rechecks the same ceiling so a bot cannot level/change between preview and commit and slip into a boost run.

Real human players are not subject to this bot-only restriction.

---

## 9. Friend-ready launch checklist

Before inviting friends:

- [ ] Latest exact Group Composer commit is green in all four relevant workflows.
- [ ] Server deployed with `./update.sh`.
- [ ] Vanilla -> TBC -> WotLK release flow tested in-game.
- [ ] Group Composer tested with at least one real second player.
- [ ] Strong DB root password set.
- [ ] Nightly backups verified.
- [ ] `wow.skrra.dev` resolves to the correct public endpoint.
- [ ] TCP 3724 and 8085 are the only game ports forwarded.
- [ ] MySQL/SOAP/Ollama/lore sidecar remain private.
- [ ] Windows firewall rules verified.
- [ ] Friend accounts are normal player accounts, not GM accounts.
- [ ] `join.skrra.dev` registration site is behind HTTPS/tunnel if enabled.
- [ ] Client/addon distribution contains only files you are allowed to share.
- [ ] Friends use `set realmlist wow.skrra.dev`.
- [ ] Auth/world logs monitored during the first external test.

---

## 10. Product direction after friends can join

Once external multiplayer works reliably, the project can shift from "make the systems function" to "make the world feel alive."

High-value next areas:

1. extend the new progression ledger with full participant rosters, explicit activity IDs and first-guild-clear records;
2. make Recommended Activities gear-, attunement-, guild-roster- and composition-aware;
3. add richer encounter-readiness diagnostics before raid assembly;
4. continue Playerbots strategy/mechanic validation for experimental Vanilla/TBC/WotLK encounters;
5. friend-facing onboarding through `join.skrra.dev`;
6. package a safe fresh-realm creation procedure for the eventual release realm;
7. add release/reset tooling for future Vanilla -> TBC -> WotLK seasons without touching the permanent test realm;
8. continue UI/runtime polish so normal play rarely requires GM commands.

The north star stays the same: **a private WoW world that progresses through three eras, feels populated by persistent players/bots, and is easy enough that friends can simply join, choose an activity and play.**

