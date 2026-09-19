# Group Composer typed UI layer

This directory is the TypeScript source of truth for the active Group Composer client UI.

```text
TypeScript
  -> TypeScriptToLua
  -> Lua 5.1
  -> native WoW Frames / Buttons / Textures / FontStrings
```

There is no browser, React runtime, virtual DOM, Chromium, client injection, or Warden-delivered UI.

## Active shell

`GroupComposerModernUI.lua` is generated from this directory and is the shell loaded by the addon TOC.
The old Lua dashboards remain only as migration/history files and are not part of the active load path.

The typed UI currently owns:

- the Dungeon and Raid dashboard,
- activity and difficulty selectors,
- live activity eligibility hints,
- human role anchors,
- per-slot dungeon Auto/exact builds,
- raid Quick Composition, Specific Builds and Prepared Roster views,
- reusable role-aware class/spec selection,
- partial exact requirements with Auto remainder,
- raid templates and custom profiles,
- Humans & Pins,
- composition options including minimum item-level floor,
- progress, warnings, coverage and assembly/travel actions,
- reusable visible scroll rails for long selectors, templates and build lists.

Server-side Group Composer remains authoritative for candidate eligibility, activity level requirements,
roster selection, preparation, assembly, instance entry and Titan Rune handoff.

## Build

From the repository root:

```bash
./build-client-ui.sh
```

To also copy the generated Lua bundle into the addon source tree:

```bash
./build-client-ui.sh --sync
```

The compiler versions are pinned:

- TypeScript 6.0.2
- TypeScriptToLua 1.37.1
- Lua target 5.1

The runtime remains retained-mode native WoW UI. Frames are created once and updated, with no reconciler.
