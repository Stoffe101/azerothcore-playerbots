# Group Composer in-game test report

Use this alongside `docs/group-composer-acceptance.md` and the combined runtime-hardening acceptance procedure when testing the live WoW 3.3.5a realm. Record exact results rather than relying on memory.

## Environment

- Date:
- Tester:
- Combined branch / commit:
- Runtime-hardening base SHA: `6fa5137abba55030bcdc3ce4c38cdee7a3d78946`
- WoW client: 3.3.5a build 12340
- Client-pack SHA-256:
- Resolution:
- UI scale:
- Character / class / role:
- Number of online world Playerbots:
- Population target / state / capacity / pending:
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
| Titan Rune Alpha supported named handoff | ☐ Pass ☐ Fail | | |
| Titan Rune Beta / Trial of the Champion handoff | ☐ Pass ☐ Fail | | |
| Titan Rune Gamma / Frozen Halls handoff | ☐ Pass ☐ Fail | | |
| Unsupported Alpha + Trial of the Champion rejected | ☐ Pass ☐ Fail | | |
| Titan Rune Random queues only mode-supported Heroics | ☐ Pass ☐ Fail | | |
| Titan Rune stale reviewed roster rejected | ☐ Pass ☐ Fail | | |
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
| Composer works during population ramp | ☐ Pass ☐ Fail | | |
| Protected grouped/LFG bots survive downscale | ☐ Pass ☐ Fail | | |
| 1920x1080 layout / scrolling | ☐ Pass ☐ Fail | | |
| 3440x1440 layout / scaling | ☐ Pass ☐ Fail | | |
| 50-cycle UI/frame-pool regression | ☐ Pass ☐ Fail | | |
| Custom profile save / load / delete | ☐ Pass ☐ Fail | | |
| Profile preserves stable human/pin subgroup placement | ☐ Pass ☐ Fail | | |

## Failure capture

For every failure, record the exact `[GC]` or `[Titan Rune]` message shown in chat, what the live party/raid contained before pressing the button, the preview membership and subgroup layout, the population-controller state, and whether any real player or unrelated Playerbot was changed. If worldserver reports an assertion, crash, C++ error or LFG/Titan diagnostic anomaly, capture the relevant server log block before retrying.

Do not merge PR #20 or promote the combined branch solely because most rows pass. Any failure involving silent human removal, bot ownership hijacking, stale-preview destructive changes, unsupported Titan Rune activation, incorrect 25/40-player subgroup membership, population-controller corruption, or server instability is a release blocker.
