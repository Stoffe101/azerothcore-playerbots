# Group Composer typed UI layer

This directory is the source-of-truth foundation for the next Group Composer client UI.

```text
TypeScript
  -> TypeScriptToLua
  -> Lua 5.1
  -> native WoW Frames / Buttons / Textures / FontStrings
```

There is no browser, React runtime, virtual DOM, Chromium, client injection, or Warden-delivered UI.

## Current scope

The first implementation deliberately stays small:

- central theme tokens,
- native frame helpers,
- Stack layout primitive,
- custom Button and Modal widgets,
- NumberStepper,
- canonical WotLK role/class/spec data,
- a reusable role -> class -> spec BuildSelector.

The existing `DashboardV4.lua` remains active while this foundation is proven. The TypeScript layer is not yet the visible Group Composer shell.

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
