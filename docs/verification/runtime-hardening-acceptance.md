# Runtime hardening acceptance

This procedure validates the exact build under test. Keep the command transcript, the client screenshots,
and the log window together. A source or compile pass does not fill any runtime cell in the matrix.

## 1. Verify, assemble, build, and start

Run from WSL in the deployment checkout:

```bash
cd ~/AzerothCore
git branch --show-current
git rev-parse HEAD
git merge-base --is-ancestor f8f5a1b0f37b4eb71964fc17fe50bc2d137adbe5 HEAD
git status --short
./backup.sh
date -u +%Y-%m-%dT%H:%M:%SZ | tee /tmp/runtime-hardening-start.utc
set -o pipefail
./update.sh 2>&1 | tee ~/runtime-hardening-update.log
git status --short
cd azerothcore-wotlk
docker compose ps
docker compose logs --no-color --since "$(cat /tmp/runtime-hardening-start.utc)" ac-db-import ac-authserver ac-worldserver \
  | tee ~/runtime-hardening-startup.log
docker inspect -f '{{.State.Running}} {{.RestartCount}} {{.State.ExitCode}}' ac-worldserver
```

Expected: ancestry command exits 0; `update.sh` and DB import exit 0; authserver and worldserver are
running; restart count is 0; the post-update tracked status is empty. Run the automated checks after
assembly:

```bash
cd ~/AzerothCore
bash tools/test-source-completion.sh
cd azerothcore-wotlk/modules/mod-era-talents
lua5.1 client-addon/EraTalents/test_comms.lua
luac5.1 -p client-addon/EraTalents/*.lua
```

## 2. Population ramp and downscale

Log in with the real GM character and open `/ap`. For each row below, press the named one-click button.
Wait until the panel and `.botdiag` both show the requested target, sufficient usable capacity, the exact
online count, and zero pending logins. Hold 1500 for at least five minutes. While each transition runs,
leave the human moving, chatting, opening vendors, and casting to detect a world-thread freeze.

Capture diagnostics from another WSL terminal:

```bash
cd ~/AzerothCore/azerothcore-wotlk
python3 ../tools/wgconsole.py ~/bot-500.log  ".botdiag"
python3 ../tools/wgconsole.py ~/bot-750.log  ".botdiag"
python3 ../tools/wgconsole.py ~/bot-1000.log ".botdiag"
python3 ../tools/wgconsole.py ~/bot-1500.log ".botdiag" "wait:300" ".botdiag"
docker stats --no-stream ac-worldserver | tee ~/bot-1500-docker-stats.log
```

Run this order through the UI:

1. 500, then 750.
2. 750, then 1000.
3. 1000, then 1500; hold five minutes.
4. 1500, then 1000, then 750, then 500.
5. During a fresh 500 to 1500 transition, press 750 before convergence. Verify the latest target becomes
   750 and the controller does not continue toward 1500.
6. During downscale, keep one random bot grouped, one in LFG, one in a battleground queue, and one in a
   persistent guild containing a human. Verify those bots are deferred and the human stays connected.

After every step:

```bash
docker inspect -f '{{.State.Running}} {{.RestartCount}} {{.State.ExitCode}}' ac-worldserver
docker compose logs --no-color --since "$(cat /tmp/runtime-hardening-start.utc)" ac-worldserver \
  | grep -Ei 'assert|fatal|segmentation|prepared statement|duplicate.*login|pet_spell.*duplicate|disconnect|kicked' || true
```

## 3. RDF during population changes

Use the stock WotLK Dungeon Finder; do not use a custom grouping shortcut.

1. Queue a solo human DPS at stable 500. While queued, select 750. Accept, teleport in, complete a pull,
   teleport out, leave, and requeue.
2. Queue a solo human tank at 750. While queued, select 1000. Require bot healer and DPS roles; accept and
   teleport in. Confirm Dungeon Clear guides between fights without taking pull or tank authority.
3. Queue a human healer at 1000. While queued, select 1500. Exercise decline, cancel, requeue, accept, and
   teleport.
4. At stable 1500, enter a random dungeon, change the target to 1000 while inside, die and resurrect, then
   leave and requeue.
5. Repeat one valid specific-dungeon queue and one invalid level/progression selection. Verify a normal
   rejection instead of a disconnect.
6. Disconnect and reconnect while queued and while inside an RDF instance. Record the resulting queue and
   group state.

Preserve the `Human LFG request`, `Human LFG leave`, and `Human LFG teleport` log lines for every failure or
disconnect investigation.

## 4. New-character Era Talents

Create a brand-new character and enter the world once. Do not reload or relog.

1. Open Era Talents immediately. The controls must remain disabled only while the initial snapshot is in
   progress.
2. Spend the first legal point, then several more legal points. Each click must show a brief pending state,
   receive one authoritative delta, update remaining points and dependencies, and reject a second click
   while one is pending.
3. Wait more than two seconds after deliberately blocking one response, if practical. Verify the addon
   requests a full snapshot and recovers without `/reload`.
4. Check the server rows and the in-game spellbook for the purchased ranks.
5. Repeat after `/reload`, logout/login, and a worldserver restart.

## 5. Human action bars

Use a human with populated bars. Before testing, record `character_action` and take screenshots of every bar.

```bash
cd ~/AzerothCore/azerothcore-wotlk
set -a; source .env; set +a
docker compose exec -T ac-database mysql -uroot -p"$DOCKER_DB_ROOT_PASSWORD" acore_characters \
  -e "SELECT guid,button,action,type FROM character_action WHERE guid=<HUMAN_GUID> ORDER BY button" \
  | tee ~/actionbar-before.tsv
```

Test ordinary relog, `/reload`, logout/login, Era Talent allocation, a legal Era rank upgrade, trainer spell
rank upgrade, respec/reset, starter/profile application, and worldserver restart. Export the same query to
`~/actionbar-after.tsv` and compare it. All still-valid abilities and unrelated buttons must keep their slots;
the old rank may change only to the learned replacement. Review every `ActionButton loading problem` line:
`ownerType=human` requires investigation, while an invalid generated bot row may be cleaned by the native
validator.

## 6. Persistence restart and final counts

Leave the saved target at 1500, restart, and verify the saved target is authoritative while population ramps
under backpressure. Then return it to the desired operating value.

```bash
cd ~/AzerothCore/azerothcore-wotlk
docker compose restart ac-worldserver
docker compose logs -f --since 0s ac-worldserver
python3 ../tools/wgconsole.py ~/bot-after-restart.log ".botdiag"
docker inspect -f '{{.State.Running}} {{.RestartCount}} {{.State.ExitCode}}' ac-worldserver
docker compose logs --no-color --since "$(cat /tmp/runtime-hardening-start.utc)" ac-worldserver \
  | tee ~/runtime-hardening-final.log
for pattern in 'assert' 'fatal' 'prepared statement' 'duplicate.*login' 'pet_spell.*duplicate'; do
  printf '%s: ' "$pattern"
  grep -Eic "$pattern" ~/runtime-hardening-final.log || true
done
```

Inspect the final log manually because a raw word such as `fatal` can appear in harmless configuration text.
Record actual human disconnects separately from client-initiated logout/reload events.

## Result matrix

| Target | Accepted | Capacity | Online reached | Stable |
|---:|:---:|:---:|:---:|:---:|
| 500 | NOT TESTED | NOT TESTED | 0/500 | NOT TESTED |
| 750 | NOT TESTED | NOT TESTED | 0/750 | NOT TESTED |
| 1000 | NOT TESTED | NOT TESTED | 0/1000 | NOT TESTED |
| 1500 | NOT TESTED | NOT TESTED | 0/1500 | NOT TESTED |

Also record the worldserver restart count, confirmed assertion/fatal/prepared-statement/duplicate counts,
human disconnect count, five-minute 1500-bot CPU/memory sample, and any population-controller
`lastWorldTickMs` stall diagnostics. Mark client-only action-bar, new-character, RDF, and Dungeon Clear rows
`NOT YET RUNTIME VERIFIED` until performed with build 12340.
