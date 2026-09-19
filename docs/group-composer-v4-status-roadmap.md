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

## 4. CI status and definition of green

For every exact Group Composer commit we care about these workflows:

- **Group Composer client checks**
- **Stage Group Composer V4 backend**
- **Group Composer V4 compile**
- **Integration build**

A build is not considered green until the relevant workflows for the **same exact commit** have all completed successfully.

The local Integration build has already been proven working on `stoffes-pc`, including the Clang 18 / GCC 15 libstdc++ workaround.

The feature commit that added Favorites/Recents completed both the full Integration build and Group Composer compile successfully on the local runner, but its client/staging tests exposed stale test expectations from the newly added dungeon-template behavior. Those test contracts are being updated before calling the current branch fully green.

---

## 5. Immediate next steps

### A. Finish the latest CI gate

Update stale tests for:

- dungeon template saves;
- new activity/history UI behavior.

Then push another `[local-ci]` commit and require all four relevant workflows to pass on that exact commit.

### B. Deploy and perform in-game validation

After full green:

```bash
git switch test/group-composer-v4
git pull
./update.sh
```

Then test the real client, not just static/compile contracts.

Minimum runtime matrix:

#### Vanilla
- fresh level-1 start;
- level cap 60;
- TBC content visibly locked;
- Vanilla dungeon browsing;
- Vanilla raid browsing;
- no Heroic/Titan Rune dungeon modes;
- progression locks/reasons;
- Progression page;
- Recommendations page;
- favorites/recents;
- dungeon party templates.

#### TBC
- release TBC manually;
- cap raises to 70;
- Outland/TBC activities unlock;
- Shattrath unlocks;
- WotLK remains locked;
- Normal/Heroic dungeon rules;
- TBC raid progression and recommendations.

#### WotLK
- release WotLK manually;
- cap raises to 80;
- Northrend unlocks;
- WotLK raids/dungeons unlock;
- Titan Rune modes appear;
- Dalaran/Argent teleports unlock;
- full Progression/Recommendations behavior.

### C. Expand progression history

The current clear model is enough for useful UI, but the long-term version should have a dedicated progression-history store.

Suggested future fields:

- player GUID;
- guild ID at time of clear;
- activity ID;
- boss/raid completion;
- difficulty;
- raid size;
- first-clear timestamp;
- most-recent-clear timestamp;
- number of clears;
- first guild clear;
- characters present.

That would let the Progression page become a real guild history book rather than only a gate/status screen.

### D. Smarter recommendations

Future recommendations can include:

- current gear/item level;
- raid lockouts;
- unfinished attunement/quest chains;
- catch-up raids;
- dungeon upgrades;
- progression priority;
- guild clear history;
- number of eligible guild bots;
- composition feasibility.

The goal is for the page to answer: **"What should we do tonight?"**

### E. Continue runtime validation of Playerbots support

The Adventure Catalog intentionally distinguishes:

- Guild Ready
- Playable / experimental
- Not Ready

Do not promote an encounter to Guild Ready just because an instance exists. Move activities upward only after real in-game validation.

---

## 6. Making the server reachable through skrra.dev

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

## 7. Realm lifecycle: test realm vs fresh release realm

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

## 8. Friend-ready launch checklist

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

## 9. Product direction after friends can join

Once external multiplayer works reliably, the project can shift from "make the systems function" to "make the world feel alive."

High-value next areas:

1. richer guild progression history and first-kill records;
2. Group Composer recommendations based on the whole guild roster;
3. better encounter-readiness diagnostics before assembling a raid;
4. raid lockout awareness;
5. more Playerbots strategy coverage for experimental raids;
6. friend-facing onboarding through `join.skrra.dev`;
7. clean reset/new-season tooling for another Vanilla -> TBC -> WotLK journey;
8. continued polish of Group Composer and Azeroth Control so normal play rarely requires GM commands.

The north star stays the same: **a private WoW world that progresses through three eras, feels populated by persistent players/bots, and is easy enough that friends can simply join, choose an activity and play.**
