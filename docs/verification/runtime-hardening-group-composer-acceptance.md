# Combined runtime-hardening + Group Composer acceptance

This is the preferred one-pass manual test order for `test/runtime-hardening-group-composer`. It deliberately interleaves the runtime-hardening checks with Group Composer so the realm/client only needs one deployment and one client pack. The detailed source procedures remain in `runtime-hardening-acceptance.md` and `../group-composer-acceptance.md`.

## Preflight

Before launching the client, record the exact branch and SHA, rebuild from the combined branch, verify database import/auth/world startup, and confirm worldserver restart count is zero. Build a fresh client pack from the same checkout and record its SHA-256. Do not mix the previous Codex client pack with this combined branch because Group Composer and its Titan Rune handoff are client-side additions.

Open `/ap` and `/gc` after login. Merely opening either panel must not mutate the live group, queue state, population target or Titan Rune selection.

## One-pass test order

1. **Stable 500 baseline.** Confirm AdminPanel and `.botdiag` report target 500, online 500, usable capacity at least 500 and zero pending logins. Open Group Composer at the normal desktop resolution and capture a screenshot before touching any roster action.
2. **500 -> 750 with a DPS dungeon.** As a human DPS, build a standard 1/1/3 Group Composer party and start the population transition to 750 while assembling/queueing. Enter through stock RDF, complete a pull, teleport out/in, leave and requeue. Check human LFG diagnostics and worldserver health.
3. **750 -> 1000 with human tank.** Compose with the human locked as Tank. The preview must add one Healer and three DPS, not another Tank. Queue while raising target to 1000. Inside the dungeon verify Dungeon Clear helps navigation but does not take pull/tank authority.
4. **1000 -> 1500 with human healer and failure paths.** Exercise cancel, decline, requeue and teleport while raising target to 1500. Hold 1500 for at least five minutes and capture `.botdiag`, Docker stats and worldserver health.
5. **Titan Rune integration at stable population.** Assemble a Group Composer five-player party and test Alpha on a base supported dungeon, Beta on Trial of the Champion, Gamma on a Frozen Halls dungeon, unsupported Alpha + Trial of the Champion, and Random for each protocol. After entering supported runs, verify `.titan status` shows the expected active protocol. Random Titan Rune must use only protocol-supported Heroic dungeon IDs.
6. **Era first-login and action bars.** Run the runtime-hardening new-character Era Talents and human action-bar cases from `runtime-hardening-acceptance.md`. This is best done before very large raid assembly so screenshots/logs stay easy to attribute.
7. **10-player raid.** Validate one WotLK Normal and one actual Heroic-capable raid preset. Confirm roles are raid-wide, humans are locked anchors and preview actions do not touch live membership.
8. **ICC 25.** Test 2/6/17, then a mostly-human roster. Verify five subgroups, Required before Preferred, guild preference with world fallback, persistent pins, profile save/load, manual move and Auto Arrange.
9. **Legacy 40.** Assemble Molten Core 40, verify eight five-player groups and exercise a move between two already-full subgroups. The atomic subgroup swap must make the live raid exactly match the reviewed preview.
10. **Downscale protection.** Return 1500 -> 1000 -> 750 -> 500 while keeping protected bots in a live group/LFG/battleground queue/persistent human guild as described by the runtime-hardening procedure. Confirm the controller defers protected sessions and Group Composer does not lose or hijack its live humans/bots.
11. **Latest-target-wins.** Start 500 -> 1500 and select 750 before convergence. The persisted target must settle on 750 rather than continuing toward 1500.
12. **UI regression.** Run the Group Composer 50-cycle People/preview/profile refresh test and inspect both 1920x1080 and 3440x1440 if both displays/modes are available. Scrollbars, pooled widgets and subgroup cards must remain responsive.
13. **Restart persistence.** Exercise the runtime-hardening saved-target restart test, then return to the preferred operating target. Re-open Group Composer after relog/restart and verify saved custom profiles are intact.

## Stop conditions

Stop the pass and preserve logs immediately if any of these occur: worldserver restart/assertion/segfault/fatal error, prepared-statement failure, silent removal of a real human, a Playerbot controlled by another real player being hijacked, a stale Group Composer preview making destructive changes, Titan Rune activating an unsupported map/mode combination, 25/40-player subgroup corruption, persistent population target corruption, or human action-bar loss beyond an expected learned-rank replacement.

A failure in one feature does not authorize testing through destructive state. Capture the exact `[GC]`, `[Titan Rune]`, AdminPanel or worldserver message, restore a safe state, and fix before continuing that path.

## Release decision

The combined branch is a test candidate, not a merge target. Keep PR #20 draft and keep `main` untouched until both the runtime-hardening client-only matrix and Group Composer's full acceptance matrix pass on the same deployed build.
