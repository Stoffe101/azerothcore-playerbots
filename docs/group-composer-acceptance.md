# Group Composer acceptance matrix

This checklist is the manual in-game acceptance gate for the WoW 3.3.5a Group Composer feature. Automated CI validates syntax, protocol contracts and pinned backend compilation, but these scenarios must still be exercised on the actual realm because invitation flow, Playerbots login timing, RDF handoff and live raid subgroup placement are runtime behaviors.

## Safety gate

Before any scenario below, open Group Composer and verify that opening the addon does not invite, remove, log in or move anybody. `Find Roster`, `Auto Arrange` and manual subgroup moves are preview-only. Only the confirmed `Assemble Roster` action may change the live group.

If a real human joins after a preview was generated, Assemble must refuse and require a new Find Roster. Real humans must never be silently removed. If a human invite is declined, the same Assemble attempt must not spam repeat invitations.

## Dungeon 5-player baseline

Use a level-appropriate character and select a normal or heroic dungeon.

1. Solo human DPS, target `1 Tank / 1 Healer / 3 DPS`.
2. Find Roster.
3. Verify exactly five preview members including the human.
4. Verify the human occupies one DPS slot rather than causing three additional DPS bots.
5. Verify one tank, one healer and three DPS total.
6. Assemble and confirm.
7. Verify selected bots join automatically and no unselected human is touched.
8. Queue through Dungeon Finder for a stock Normal/Heroic dungeon and verify the composed role masks are accepted.
9. Enter the dungeon and verify existing Playerbots dungeon behavior still drives navigation/combat rather than Group Composer trying to become a second dungeon AI system.

Repeat with the human manually overridden to Tank. The preview must then add `1 Healer + 3 DPS`, not another tank. Inside the dungeon, bots must respect human tank authority.

## Two-human dungeon

Start with two real humans in the party: one Tank and one DPS.

Expected composed result: `2 humans + 3 bots`, specifically `1 Healer + 2 DPS` bots. Both humans must be locked anchors. Declining or leaving during the reviewed-to-assembled transition must produce a clear failure rather than silent replacement.

## Full-human validation

Form a complete five-human party and Find Roster.

Expected: no bots selected. Group Composer acts only as a composition validator/organizer. Assemble must not manufacture bot slots simply because bot fallback is enabled.

## ICC 25 baseline

Select Icecrown Citadel 25 with the standard default `2 Tanks / 6 Healers / 17 DPS`, Prefer Guild enabled, world fallback enabled and class/utility balancing enabled.

Expected:

- Exactly 25 total preview members.
- Exactly 2 tanks raid-wide, not one tank per subgroup.
- Exactly 6 healers raid-wide.
- Exactly 17 DPS raid-wide.
- Exactly five raid subgroups of at most five members each.
- The composing human is present and locked.
- Suitable guild Playerbots are preferred before ordinary world fillers unless an already-grouped safe member is deliberately retained.
- Required class/spec rows are satisfied before Preferred pins or soft optimization.
- No duplicate character GUIDs.

After Assemble, verify the live raid membership exactly matches the reviewed preview and the live subgroup arrangement matches Groups 1-5.

## Mostly-human ICC 25

Start with five humans already grouped: `1 Tank / 1 Healer / 3 DPS`.

Expected bot fill: `1 Tank / 5 Healers / 14 DPS`. All five humans remain roster anchors and may be rearranged between subgroups but must never be silently replaced.

## 40-player legacy raid

Select Molten Core 40 using the fallback `5 tank-capable / 10 healers / 25 DPS` profile.

Expected:

- 40 total members.
- Eight raid subgroups, five members each when full.
- Role targets are raid-wide, never eight mini-dungeon groups.
- Auto Arrange distributes the already selected roster without changing roster membership.
- Full-group subgroup swaps complete correctly even when no target subgroup has a free slot.

Repeat a manual move between two full subgroups. The server-side atomic swap must make the live raid match the reviewed preview after Assemble.

## Required versus Preferred constraints

Create a raid with only one remaining Healer slot. Add a Required Holy Paladin healer preference and a Preferred pinned healer that is also available.

Expected: the Required Holy Paladin is secured first. The Preferred pin may only be selected if another valid slot remains. A soft preference must never consume the final slot needed by a hard requirement.

Repeat with the Required candidate unavailable. Find Roster must fail clearly instead of substituting a merely Preferred candidate and pretending the requirement was met.

## Guild fallback

Use a target where the guild pool can satisfy all but one critical role.

Expected: Group Composer uses suitable guild members first, then fills the actual missing role from the world/managed fallback pool. It must not create an invalid guild-only composition just to maximize guild representation.

Disable world fallback and repeat. The search must fail if the guild/eligible existing group cannot satisfy required roles.

## Persistent pins

Pin a familiar guild Playerbot as Preferred and build multiple rosters while they are available.

Expected: the familiar member should recur when suitable, but a Preferred pin may fall back cleanly if unavailable or if selecting them would violate a Required constraint.

Change the pin to Required. If unavailable, Find Roster must fail instead of silently replacing them.

## Offline human anchor

Have a real human already in the group, provide the required manual role override, then let that human go offline before Find/Assemble.

Expected preview behavior: the human remains visible as a preserved locked anchor and is never silently pruned. Expected assembly behavior: the composition must not be reported successfully assembled while a required human participant is offline. The UI/server should clearly require that human to return or the user to explicitly reform the party and search again.

## Snapshot drift

After Find Roster but before Assemble, deliberately change one selected ordinary guild/world bot so its current Playerbots role no longer matches the reviewed role, or make it unavailable.

Expected: Assemble revalidates the reviewed snapshot and refuses stale non-managed bot state. Managed roster bots may be reconciled by their controlled spec/gear lifecycle during assembly.

## Titan Rune modes

Select Alpha, Beta and Gamma in Dungeon mode.

Expected: profiles and preview retain the selected Titan Rune mode. Group Composer must not pretend these custom modes are stock 3.3.5a RDF difficulty IDs. The ordinary Dungeon Finder handoff should refuse with the explicit Titan Rune message until/where the custom realm integration provides its supported entry path.

## Failure and retry UX

Exercise at least these failures:

- insufficient tank candidates
- insufficient healer candidates
- unavailable Required class/spec
- unavailable Required pin
- added human already in another group
- cross-faction human while cross-faction grouping is disabled
- selected world bot goes offline after preview
- real human joins after preview
- human declines invite
- assembly timeout

Every failure must preserve humans, avoid silently assembling nonsense, explain why the reviewed roster cannot be committed, and allow the user to correct the configuration and retry.

## Long-session UI regression

Open the People editor, repeatedly refresh anchors, switch modes, alter roles, Find Roster and clear/rebuild previews for at least 50 cycles. Test with a human-heavy raid if possible.

Expected: human-role dropdowns, class/spec preference rows, main roster preview rows and Roster Editor subgroup cards are pooled/reused. Repeated refreshes must remain responsive without progressive frame growth or major FPS degradation, and scrolling/section layout must stay intact for large 25/40-player rosters. Verify that the main Roster Rules panel shows the composing character as a locked human anchor and does not offer a fake "Keep Me" toggle.

## Release gate

Group Composer is ready to leave draft status only when:

- Lua 5.1 checks pass.
- Source/client-server contract checks pass.
- Pinned AzerothCore + Playerbots backend compile passes.
- Dungeon 5-player acceptance passes.
- 10/25/40 raid role-wide composition passes.
- Full raid subgroup application passes.
- Human-first safety cases pass.
- Required/Preferred ordering passes.
- Guild preference with world fallback passes.
- No destructive action occurs before explicit confirmed Assemble.

The product rule remains: **Admin Panel controls the world. Group Composer controls the adventure party.**
