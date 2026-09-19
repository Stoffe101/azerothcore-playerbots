# 3440x1440 Naowh-inspired preset target

This is the primary UI layout target for the project's WoW 3.3.5a client pack.

The goal is a clean, compact, raid/dungeon-first layout inspired by the public visual style of Naowh's UI without copying or redistributing any private or paid profile data.

## Design goals

- Native target: 3440x1440 ultrawide.
- Keep combat-critical information inside the central 2560px region so eye travel stays low.
- Use the outer ultrawide space for chat, meters, guild/social information and optional bot-management panels instead of stretching core combat frames apart.
- Compact player/target frames around the lower center.
- Central cast bar and proc/cooldown tracking above the action bars.
- Small action bars with low visual noise.
- Raid frames near the lower-left / left-center combat region, not at the extreme screen edge.
- Damage/threat meter on the right side when installed later.
- RestedXP route panel toward the upper-right outer region.
- TidyPlates ThreatPlates as the default nameplate base.
- Enemy nameplates prioritize cast visibility, threat state, debuffs and target recognition over decoration.
- Friendly nameplates remain visually quieter.
- AI Guild, Adventure Guide and Admin Panel controls belong in ultrawide side space and must not cover boss mechanics.

## Nameplate target

Use `TidyPlates_ThreatPlates` from the exact 3.3.5a fork pinned by `build-client-pack.sh`.

Desired characteristics after in-game tuning:

- narrow, highly readable health bars;
- strong current-target highlight;
- clear threat coloring without excessive visual noise;
- non-target enemy cast bars enabled;
- important player debuffs visible while low-value aura clutter is suppressed;
- CC state visually distinct;
- compact name and level text;
- stacking enabled where the 3.3.5a client permits it;
- no oversized PvE class icons;
- performance biased toward stable raid FPS.

## ElvUI target

- player and target frames close to center;
- compact party/raid frames;
- minimal decorative chrome;
- action bars low and centered;
- cast bars directly in the combat sightline;
- buffs/debuffs compact and intentionally filtered;
- chat and non-combat panels pushed outward into ultrawide space.

`build-client-pack.sh` is the authoritative addon manifest and already pins ElvUI, ThreatPlates, RestedXP, WeakAuras, DBM, Pawn, MinimapButtonButton and the project's server-specific addons. The older `client-pack/addons.json` experiment is intentionally not restored because it duplicated a smaller, now-outdated subset of that manifest.

Exact SavedVariables/import strings must only be committed after validation on the real 3.3.5a client at 3440x1440. Do not guess coordinates or ship an untested ElvUI profile.
