# 3440x1440 Naowh-inspired preset

This is the primary UI target for the custom client pack.

The goal is a clean, compact, raid/dungeon-first layout inspired by the public visual style of Naowh's UI without copying or redistributing any private/paid profile data.

## Design goals

- Native target: 3440x1440 ultrawide.
- Keep combat-critical information inside the central 2560px region so eye travel stays low.
- Use the extra ultrawide width for chat, meters, guild/social information and optional bot-management panels instead of stretching core combat frames apart.
- Compact player/target frames around the lower center.
- Central cast bar and proc/cooldown tracking above the action bars.
- Small action bars with low visual noise.
- Raid frames near the lower-left/left-center combat region, not at the extreme screen edge.
- Damage/threat meter on the right side.
- RestedXP route panel toward the upper-right outer region.
- TidyPlates ThreatPlates theme as the default nameplate base.
- Enemy nameplates prioritize cast visibility, threat state, debuffs and target recognition over decoration.
- Friendly nameplates remain visually quieter.
- Future AI Guild / Adventure Guide controls should live in the ultrawide side space and never cover boss mechanics.

## Nameplate target

Use `TidyPlates_ThreatPlates` from the pinned 3.3.5a fork.

Desired profile characteristics once the settings are authored and tested in-game:

- narrow health bars with high readability;
- strong current-target highlight;
- threat-based coloring that is obvious but not neon-heavy;
- non-target enemy cast bars enabled;
- important player debuffs visible, low-value aura clutter suppressed;
- CC state visually distinct;
- compact name text and level text;
- stacking enabled where the 3.3.5a client permits it;
- avoid oversized class icons in PvE;
- performance settings biased toward stable raid FPS.

## ElvUI target

The eventual ElvUI preset should visually match the same philosophy:

- player and target frames close to center;
- compact party/raid frames;
- minimal borders and decorative chrome;
- action bars low and centered;
- cast bars directly in the combat sightline;
- buffs/debuffs compact and intentionally filtered;
- chat and non-combat panels pushed outward into ultrawide space.

Exact SavedVariables/import data should only be committed after validation on a real 3.3.5a client at 3440x1440. Do not guess coordinates or ship a profile that has not been visually tested.
