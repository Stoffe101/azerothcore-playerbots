# Group Composer in-game test report

Use this alongside `docs/group-composer-acceptance.md` when the feature reaches the live 3.3.5a realm. The acceptance matrix defines what must be tested; this file keeps the results reproducible instead of relying on memory.

## Environment

- Date:
- Tester:
- Realm branch / commit:
- WoW client: 3.3.5a build 12340
- Resolution:
- UI scale:
- Character / class / role:
- Number of online world Playerbots:
- Number of eligible guild Playerbots:

## Result table

| Scenario | Result | Notes / exact error | Screenshot or log reference |
| --- | --- | --- | --- |
| Addon opens with zero group mutation | ☐ Pass ☐ Fail | | |
| Solo 5-player dungeon 1/1/3 | ☐ Pass ☐ Fail | | |
| Human tank dungeon | ☐ Pass ☐ Fail | | |
| Two-human dungeon | ☐ Pass ☐ Fail | | |
| Full-human party validation | ☐ Pass ☐ Fail | | |
| Stock Normal RDF handoff | ☐ Pass ☐ Fail | | |
| Stock Heroic RDF handoff | ☐ Pass ☐ Fail | | |
| Titan Rune Alpha preserved / safe handoff refusal | ☐ Pass ☐ Fail | | |
| Titan Rune Beta preserved / safe handoff refusal | ☐ Pass ☐ Fail | | |
| Titan Rune Gamma preserved / safe handoff refusal | ☐ Pass ☐ Fail | | |
| ICC 10 Normal | ☐ Pass ☐ Fail | | |
| ICC 10 Heroic | ☐ Pass ☐ Fail | | |
| ICC 25 Normal 2/6/17 | ☐ Pass ☐ Fail | | |
| ICC 25 Heroic | ☐ Pass ☐ Fail | | |
| Mostly-human ICC 25 | ☐ Pass ☐ Fail | | |
| TBC 25-player legacy difficulty | ☐ Pass ☐ Fail | | |
| Classic 20-player raid | ☐ Pass ☐ Fail | | |
| Classic 40-player raid / 8 groups | ☐ Pass ☐ Fail | | |
| Full-subgroup atomic swap | ☐ Pass ☐ Fail | | |
| Required preference beats Preferred pin | ☐ Pass ☐ Fail | | |
| Required unavailable fails clearly | ☐ Pass ☐ Fail | | |
| Prefer Guild + world fallback | ☐ Pass ☐ Fail | | |
| Fill World disabled boundary | ☐ Pass ☐ Fail | | |
| Persistent Preferred pin | ☐ Pass ☐ Fail | | |
| Persistent Required pin | ☐ Pass ☐ Fail | | |
| Late human join blocks stale Assemble | ☐ Pass ☐ Fail | | |
| Human decline does not invite-spam | ☐ Pass ☐ Fail | | |
| Selected bot role/spec drift blocks stale Assemble | ☐ Pass ☐ Fail | | |
| Bot controlled by another real player is protected | ☐ Pass ☐ Fail | | |
| 1920x1080 layout / scrolling | ☐ Pass ☐ Fail | | |
| 3440x1440 layout / scaling | ☐ Pass ☐ Fail | | |
| 50-cycle UI/frame-pool regression | ☐ Pass ☐ Fail | | |
| Custom profile save / load / delete | ☐ Pass ☐ Fail | | |
| Profile preserves stable human/pin subgroup placement | ☐ Pass ☐ Fail | | |

## Failure capture

For every failure, record the exact `[GC]` message shown in chat, what the live party/raid contained before pressing the button, the preview membership and subgroup layout, and whether any real player or unrelated Playerbot was changed. If the worldserver reports an assertion, crash or C++ error, capture the relevant server log block before retrying.

Do not merge PR #20 solely because most rows pass. Any failure involving silent human removal, bot ownership hijacking, stale-preview destructive changes, incorrect 25/40-player subgroup membership, or server instability is a release blocker.