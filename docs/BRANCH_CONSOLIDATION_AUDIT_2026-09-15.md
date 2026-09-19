# Branch consolidation audit

## Result

Audit baseline: `a65f445433e2d7ba333e1c9578f2b281d303fbcd`
(`codex/integration-source-completion-2026-09-15`). Working branch:
`codex/final-consolidation-2026-09-15`.

All 56 remote branches under `origin` were audited after `git fetch origin --prune`.
They resolve to 35 distinct tip commits. The audit found no **C. UNIQUE + DESIRED**
branch. No historical branch was merged, no historical commit was cherry-picked, and no
source behavior was ported. The current tree already contains the desired behavior, usually
with later safety and architecture work. The only repository change from consolidation is
this audit.

Disposition totals:

| Disposition | Count |
|---|---:|
| A. FULLY CONTAINED | 11 |
| B. SUPERSEDED | 31 |
| C. UNIQUE + DESIRED | 0 |
| D. UNIQUE + OBSOLETE/UNDESIRED | 1 |
| E. SAFETY/BACKUP ONLY | 10 |
| F. TEMP/JUNK | 3 |
| **Total** | **56** |

## Method

For every remote ref, the audit recorded its tip, merge-base with the baseline, and
`baseline..branch` commit count. It inspected unique logs, `git cherry`, direct and
merge-base tree diffs, branch-only paths, shared-tip groups, and the relevant source and
configuration in both trees. A zero unique count means the branch tip is already an
ancestor of the baseline. A nonzero count does not by itself mean functionality is missing.

The semantic comparisons concentrated on:

- adventure start, profiles, controls, guide/catalog/travel, catch-up, economy and
  Individual Progression/Era Talents integration;
- guild persistence, services, autonomy, economy, relationships and memory;
- encounter lifecycle, wipe recovery, raid leadership, Smart Loot and Dungeon Clear;
- Titan Alpha/Beta/Gamma activation, families, mechanics, loot, currencies, pending
  rewards, vendors, Mysterious Device and restart identity;
- pinned patches, module loaders/CMake, SQL locations/order, defaults, setup/update scripts;
- pinned client addons, packaging, installer behavior and resolution documentation.

The current implementations are the split `mod-raid-roster`, `mod-playerbot-chatter`, and
`mod-titan-rune` systems documented in `SOURCE_COMPLETION_2026-09-15.md`. In particular:

- the standalone adventure branches predate the current profile store, transactional kits,
  hardened travel/director logic, source-safe controls and authoritative encounter resets;
- old `PBChatterRelationships` and `mod-living-world` prototypes were absorbed into
  `PBAIGuildStore`, `PBAIGuildLife`, `PBAIGuildServices`, and `PBAIGuildAutonomy`;
- old monolithic Titan files were replaced by the current family/mechanic, activation,
  loot, reward, persistence, vendor and Gamma helper components;
- the old `client-pack/addons.json` and `windows/Setup-Client.ps1` experiment duplicates a
  smaller addon set. `build-client-pack.sh` retains the same exact third-party pins and adds
  the project addons, Atlas/WDM handling, archive checks and `windows/Install-Client-Pack.ps1`;
- the Dark Portal branch's configurable map and exact default coordinates remain in the
  current start system, which now adds data-defined profiles and validation around them.

## Every remote branch

`Ported` is `No` throughout because there were no category C findings. `Delete` means only
after the exact consolidation commit has passed the real local update, startup, gameplay and
restart tests and has then been promoted to `main`.

| Branch | Tip SHA | Merge-base | Unique commits | Disposition | Notable unique content | Ported | Replacement/current implementation | After promotion |
|---|---|---|---:|---|---|---|---|---|
| `archive/pre-cleanup-2026-09-14` | `a22102375da004201f8c7b7ea9cc3570f29fe6c3` | `24f060517f3f60efa21814ac39b1637ad5d7a8d4` | 177 | E | Archive aggregation of historical feature histories; its final tree equals `develop` | No | All desired descendants and later source-completion fixes are in current | Tag if desired, then delete |
| `backup/main-before-integration-promotion-2026-09-15` | `0ab5a8bf1052c5d9e7e2ef80347a6185f1756bf4` | `0ab5a8bf1052c5d9e7e2ef80347a6185f1756bf4` | 0 | E | Named safety copy of the current pre-promotion `main` tip | No | Exact tip is already in current history | Tag if desired, then delete |
| `backup/pre-final-titan-polish-2026-09-15` | `6a0ee2a9ed76b35c7ebba821b38a86dfd2f5cdfe` | `6a0ee2a9ed76b35c7ebba821b38a86dfd2f5cdfe` | 0 | E | Pre-polish Titan safety snapshot | No | Current is 54 commits ahead | Tag if desired, then delete |
| `backup/pre-guild-director-port-2026-09-15` | `75388210bff4bc61646c983ae17e4a29660a8a2c` | `75388210bff4bc61646c983ae17e4a29660a8a2c` | 0 | E | Pre-director safety snapshot | No | Current is 78 commits ahead | Tag if desired, then delete |
| `backup/pre-main-merge-2026-09-15` | `c740f1b3ca64d13b191436008a0747bf5e145c27` | `c740f1b3ca64d13b191436008a0747bf5e145c27` | 0 | E | Safety snapshot shared by three backup refs | No | Current is 65 commits ahead | Tag if desired, then delete |
| `backup/pre-titan-finalization-2026-09-15` | `c740f1b3ca64d13b191436008a0747bf5e145c27` | `c740f1b3ca64d13b191436008a0747bf5e145c27` | 0 | E | Safety alias of `c740f1b3` | No | Current is 65 commits ahead | Tag if desired, then delete |
| `backup/pre-titan-rune-completion-2026-09-15` | `15c98773f5f846ae3f661ec394ad61cfaf4bb3f1` | `15c98773f5f846ae3f661ec394ad61cfaf4bb3f1` | 0 | E | Pre-completion Titan safety snapshot | No | Current is 73 commits ahead | Tag if desired, then delete |
| `backup/pre-titan-rune-completion-pass2-2026-09-15` | `c740f1b3ca64d13b191436008a0747bf5e145c27` | `c740f1b3ca64d13b191436008a0747bf5e145c27` | 0 | E | Safety alias of `c740f1b3` | No | Current is 65 commits ahead | Tag if desired, then delete |
| `codex/integration-source-completion-2026-09-15` | `a65f445433e2d7ba333e1c9578f2b281d303fbcd` | `a65f445433e2d7ba333e1c9578f2b281d303fbcd` | 0 | A | Exact source-completion baseline | No | Exact tree is the parent of this audit | Tag `source-completion-2026-09-15`, then delete |
| `develop` | `24f060517f3f60efa21814ac39b1637ad5d7a8d4` | `24f060517f3f60efa21814ac39b1637ad5d7a8d4` | 0 | A | Older integration line, fully ancestral | No | Current is 172 commits ahead | Delete under the requested trunk model |
| `feature/adventure-controls` | `2a8d140d4dd024471ae357cf3c2680ae819cf888` | `2fafb40846b1b9c78ac2d569f77a90c6611af6f3` | 29 | B | Control panel/rates, catch-up claim and addon iteration | No | `AdventureControl*`, `AdventureCatchupCommand`, current addon and `db-characters` migration | Delete |
| `feature/adventure-guide-finder` | `c0a0e0f971c9ad7404a773a5a12fde8bd47885ff` | `2fafb40846b1b9c78ac2d569f77a90c6611af6f3` | 27 | B | Finder/travel UI, guide addon and roadmap iteration | No | Current `AdventureGuide`, catalog, command/travel and response-stream UI | Delete |
| `feature/adventure-guide-finder-backup` | `76bbab24b0b1caddce9f9394eccafb4db487ca29` | `2fafb40846b1b9c78ac2d569f77a90c6611af6f3` | 15 | E | Backup of the early guide/guild-director implementation | No | Current guide and `GuildGroupDirector` supersede the snapshot | Delete |
| `feature/adventure-teleport-rewards` | `0191120f630f72ec823b2e9edff1d2e87e5aefec` | `2fafb40846b1b9c78ac2d569f77a90c6611af6f3` | 7 | B | Era-aware dungeon entrance travel and party checks | No | Current `AdventureCommand`, `AdventureCatalog`, and hardened group/director travel | Delete |
| `feature/adventurer-economy` | `4c1d565254360ef3e94bce104a5a923245830358` | `2fafb40846b1b9c78ac2d569f77a90c6611af6f3` | 10 | B | First-kill bounty persistence and AH/gold status | No | Current `AdventureEconomy` plus resource-backed guild economy | Delete |
| `feature/ai-guild-persistence` | `f7fe47b9f3a7fca5fb3d1aae983eba340ed277a9` | `2fafb40846b1b9c78ac2d569f77a90c6611af6f3` | 12 | B | Guild personality, event, memory and relationship persistence | No | Current `PBAIGuildStore` and grounded chatter context with synchronization fixes | Delete |
| `feature/ai-guild-services` | `8f08274297fba52cbfc820c25afeeb6141f679a7` | `2fafb40846b1b9c78ac2d569f77a90c6611af6f3` | 10 | B | Earlier guild identity/event/memory snapshot despite branch label | No | `PBAIGuildStore`, `PBAIGuildServices`, `PBAIGuildLife`, and `PBAIGuildAutonomy` | Delete |
| `feature/client-addon-pack` | `a1ce8daf6d14f733162ae213e65b680064f5fbb1` | `2fafb40846b1b9c78ac2d569f77a90c6611af6f3` | 1 | B | Early TBC-profile start/map reveal snapshot; no completed pack | No | Current start/profile flow and reproducible client pack | Delete |
| `feature/client-addon-pack-ultrawide` | `a1ce8daf6d14f733162ae213e65b680064f5fbb1` | `2fafb40846b1b9c78ac2d569f77a90c6611af6f3` | 1 | B | Same early snapshot; no validated ultrawide layout | No | Shared pack plus documented 3440x1440 real-client tuning gate | Delete |
| `feature/client-ui-pack` | `d164afd2f8807f1b11f32771c944d98d034fd8fa` | `2fafb40846b1b9c78ac2d569f77a90c6611af6f3` | 8 | B | Pinned addon JSON, download/install script and ultrawide layout specification | No | Same pins in `build-client-pack.sh`; broader generated pack and safer installer | Delete |
| `feature/client-ui-pack-final` | `a1ce8daf6d14f733162ae213e65b680064f5fbb1` | `2fafb40846b1b9c78ac2d569f77a90c6611af6f3` | 1 | B | Alias of the incomplete early client/start snapshot | No | Current pack and documented visual-validation gate | Delete |
| `feature/client-ui-pack-impl` | `a1ce8daf6d14f733162ae213e65b680064f5fbb1` | `2fafb40846b1b9c78ac2d569f77a90c6611af6f3` | 1 | B | Alias of the incomplete early client/start snapshot | No | Current pack and documented visual-validation gate | Delete |
| `feature/client-ui-pack-work` | `a1ce8daf6d14f733162ae213e65b680064f5fbb1` | `2fafb40846b1b9c78ac2d569f77a90c6611af6f3` | 1 | B | Alias of the incomplete early client/start snapshot | No | Current pack and documented visual-validation gate | Delete |
| `feature/encounter-lifecycle` | `37d582b5301d5b96f4052522471de917640d3334` | `2fafb40846b1b9c78ac2d569f77a90c6611af6f3` | 32 | B | Encounter service, preparation and authoritative wipe recovery | No | Current `EncounterLifecycle`, auto clear, reset checks, timing and retry fixes | Delete |
| `feature/encounter-recovery-prep` | `8f08274297fba52cbfc820c25afeeb6141f679a7` | `2fafb40846b1b9c78ac2d569f77a90c6611af6f3` | 10 | B | Ref points to the early guild-persistence snapshot, not later recovery code | No | Current `EncounterLifecycle` and current guild persistence both cover its intended area | Delete |
| `feature/full-adventure-stack` | `bddf417424f5e23db39ea72581366bb591c3ff5b` | `bddf417424f5e23db39ea72581366bb591c3ff5b` | 0 | A | Integrated adventure stack snapshot | No | Exact tip is an ancestor; current is 256 commits ahead | Delete |
| `feature/full-adventure-stack-guildsync` | `0d98fe0b3ca2fdfd4516801509516518d1b2d47c` | `0d98fe0b3ca2fdfd4516801509516518d1b2d47c` | 0 | A | Integrated guild-sync stack snapshot | No | Exact tip is an ancestor; current is 177 commits ahead | Delete |
| `feature/full-adventure-stack-guildsync2` | `bddf417424f5e23db39ea72581366bb591c3ff5b` | `bddf417424f5e23db39ea72581366bb591c3ff5b` | 0 | A | Alias of the integrated full-adventure snapshot | No | Exact tip is an ancestor; current is 256 commits ahead | Delete |
| `feature/guild-group-director` | `2598061e3e245fb298a431785cd60505a101139e` | `2fafb40846b1b9c78ac2d569f77a90c6611af6f3` | 17 | B | Role-aware party formation, destination matching and travel | No | Current `GuildGroupDirector` adds validated composition, multi-human and safety handling | Delete |
| `feature/living-world-titan-runes` | `f692a37eed284fe740fe596733ab4127a747a59a` | `2fafb40846b1b9c78ac2d569f77a90c6611af6f3` | 20 | B | Prototype living-world module, relationships and monolithic Titan implementation | No | Split guild-life/autonomy/store services and full current `mod-titan-rune` | Delete |
| `feature/living-world-titan-runes-actual` | `41586d95da24726e48a84d4d4f9eaabbbd6ccbdc` | `2fafb40846b1b9c78ac2d569f77a90c6611af6f3` | 18 | B | Older living-world/Titan prototype tip | No | Current split guild and Titan implementations | Delete |
| `feature/living-world-titan-runes-buildfix` | `41586d95da24726e48a84d4d4f9eaabbbd6ccbdc` | `2fafb40846b1b9c78ac2d569f77a90c6611af6f3` | 18 | B | Alias of older prototype tip; no additional build fix | No | Current module wiring and successful pinned native build | Delete |
| `feature/living-world-titan-runes-buildfix2` | `41586d95da24726e48a84d4d4f9eaabbbd6ccbdc` | `2fafb40846b1b9c78ac2d569f77a90c6611af6f3` | 18 | B | Alias of older prototype tip; no additional build fix | No | Current module wiring and successful pinned native build | Delete |
| `feature/living-world-titan-runes-buildfix3` | `41586d95da24726e48a84d4d4f9eaabbbd6ccbdc` | `2fafb40846b1b9c78ac2d569f77a90c6611af6f3` | 18 | B | Alias of older prototype tip; no additional build fix | No | Current module wiring and successful pinned native build | Delete |
| `feature/living-world-titan-runes-compile` | `41586d95da24726e48a84d4d4f9eaabbbd6ccbdc` | `2fafb40846b1b9c78ac2d569f77a90c6611af6f3` | 18 | B | Alias of older prototype tip; no distinct compile result | No | Current module wiring and successful pinned native build | Delete |
| `feature/living-world-titan-runes-finalize` | `8b35558381f76ee74925a57211e5241219a670c6` | `2fafb40846b1b9c78ac2d569f77a90c6611af6f3` | 26 | B | Prototype wiring/fixups for living-world, relationships and monolithic Titan | No | Current split modules, corrected loaders/config/SQL and complete Titan protocols | Delete |
| `feature/living-world-titan-runes-finish` | `41586d95da24726e48a84d4d4f9eaabbbd6ccbdc` | `2fafb40846b1b9c78ac2d569f77a90c6611af6f3` | 18 | B | Alias of older prototype tip | No | Current split guild and Titan implementations | Delete |
| `feature/living-world-titan-runes-ready` | `41586d95da24726e48a84d4d4f9eaabbbd6ccbdc` | `2fafb40846b1b9c78ac2d569f77a90c6611af6f3` | 18 | B | Alias of older prototype tip | No | Current split guild and Titan implementations | Delete |
| `feature/living-world-titan-runes-ready2` | `41586d95da24726e48a84d4d4f9eaabbbd6ccbdc` | `2fafb40846b1b9c78ac2d569f77a90c6611af6f3` | 18 | B | Alias of older prototype tip | No | Current split guild and Titan implementations | Delete |
| `feature/living-world-titan-runes-work` | `41586d95da24726e48a84d4d4f9eaabbbd6ccbdc` | `2fafb40846b1b9c78ac2d569f77a90c6611af6f3` | 18 | B | Alias of older prototype tip | No | Current split guild and Titan implementations | Delete |
| `feature/raid-leader-foundation` | `7d2ce97644ded37fdd527e970e5d1714f46d934d` | `2fafb40846b1b9c78ac2d569f77a90c6611af6f3` | 7 | B | Verified TBC encounter briefs and command foundation | No | Current knowledge/command/auto system adds strict grounding and stale-response rejection | Delete |
| `feature/smart-loot-protection` | `c2ff447509f0dfd309627cdcf7df00af418ecc25` | `2fafb40846b1b9c78ac2d569f77a90c6611af6f3` | 37 | B | Upgrade scoring, loot policy patch and durable boss dry streaks | No | Current `SmartLootSystem`/store and pinned patch retain exact-source reset hardening | Delete |
| `feature/tbc-start-qol` | `1e8bd36b684f9bad972b53f39608e061c981a96a` | `a92ec5faa64d92f3a2a8090fd87f879cdd66943a` | 1 | D | Only unique change is obsolete `docs/DEV_BRANCHING.md` workflow | No | Requested trunk-oriented `main` workflow supersedes that document | Delete |
| `feature/tbc-start-qol-backup` | `2fafb40846b1b9c78ac2d569f77a90c6611af6f3` | `2fafb40846b1b9c78ac2d569f77a90c6611af6f3` | 0 | E | Old TBC-profile safety snapshot | No | Exact tip is an ancestor; current is 408 commits ahead | Delete |
| `feature/tbc-start-qol-final` | `efcda877e9496e4fb3a72041a9252dc9c5a04982` | `efcda877e9496e4fb3a72041a9252dc9c5a04982` | 0 | A | Integrated TBC-style profile/QoL snapshot | No | Exact tip is an ancestor; current is 285 commits ahead | Delete |
| `feature/tbc-start-qol-merge` | `a92ec5faa64d92f3a2a8090fd87f879cdd66943a` | `a92ec5faa64d92f3a2a8090fd87f879cdd66943a` | 0 | A | Integrated pre-feature snapshot | No | Exact tip is an ancestor; current is 402 commits ahead | Delete |
| `feature/tbc-start-qol-review` | `a92ec5faa64d92f3a2a8090fd87f879cdd66943a` | `a92ec5faa64d92f3a2a8090fd87f879cdd66943a` | 0 | A | Review alias of integrated pre-feature snapshot | No | Exact tip is an ancestor; current is 402 commits ahead | Delete |
| `feature/tbc-starter-progression` | `95c34d0e8c2b5e165810e2c1b54ff64288ca81d7` | `2fafb40846b1b9c78ac2d569f77a90c6611af6f3` | 19 | B | Starter profiles/kits, cache claims and Individual Progression lifecycle | No | Current progression store/control/kit adds validation and transactional grants | Delete |
| `fix/audit-adventure-start-progression` | `dd689fa9678a63f6d7fe493ef81b380ba740351e` | `2fafb40846b1b9c78ac2d569f77a90c6611af6f3` | 16 | B | Start/IP audit fixes plus older setup/update helpers and an operational container recreation | No | Current start enum isolation, WSL helpers, pinned update flow and source-completion fixes | Delete |
| `fix/tbc-start-dark-portal` | `eabed2a78eb3707603bfde16523d5a6cf59c10ca` | `a92ec5faa64d92f3a2a8090fd87f879cdd66943a` | 4 | B | Standalone configurable Dark Portal first-login teleport | No | Same map/coordinates/config remain inside current validated profile-aware start flow | Delete |
| `ignore-this` | `2fafb40846b1b9c78ac2d569f77a90c6611af6f3` | `2fafb40846b1b9c78ac2d569f77a90c6611af6f3` | 0 | F | Explicit throwaway alias with no unique commits | No | None needed | Delete |
| `integration/bot-ai-refresh-2026-09-14` | `ef57dcb4befe69e5cb206bd26e8b1e0433c2fa6b` | `ef57dcb4befe69e5cb206bd26e8b1e0433c2fa6b` | 0 | A | Integrated bot-AI refresh baseline | No | Exact tip is an ancestor; current is 11 commits ahead | Delete |
| `main` | `0ab5a8bf1052c5d9e7e2ef80347a6185f1756bf4` | `0ab5a8bf1052c5d9e7e2ef80347a6185f1756bf4` | 0 | A | Current canonical branch before final promotion | No | Exact tip is in current history | **Keep; promote only after acceptance** |
| `sync/upstream-2026-09-13` | `7da03710f8cfbc9729760c9a9f54d19a217ad80c` | `7da03710f8cfbc9729760c9a9f54d19a217ad80c` | 0 | A | Upstream synchronization checkpoint | No | Exact tip is an ancestor; current is 407 commits ahead | Delete |
| `tmp-noop` | `2fafb40846b1b9c78ac2d569f77a90c6611af6f3` | `2fafb40846b1b9c78ac2d569f77a90c6611af6f3` | 0 | F | Temporary no-op alias | No | None needed | Delete |
| `tmp2-noop` | `2fafb40846b1b9c78ac2d569f77a90c6611af6f3` | `2fafb40846b1b9c78ac2d569f77a90c6611af6f3` | 0 | F | Temporary no-op alias | No | None needed | Delete |

## Missing-work decision

There are no category C branches. Consequently, nothing was ported. Restoring any divergent
historical source would reintroduce an older module boundary, duplicate SQL path, incomplete
client workflow, weaker synchronization, or less complete safety checks.

The audit leaves two intentional human acceptance items, neither of which is stranded branch
source:

1. Real-client visual tuning at 1080p, 1440p and 3440x1440 still requires the actual 3.3.5a
   client. No historical branch contains validated SavedVariables that should be imported.
2. Docker/runtime/gameplay/restart behavior must still be tested by the user on the installed
   server. The source audit cannot establish live balance, pathing, timing or persistence.

## Validation

The tree differs from the fully validated source-completion baseline only by this Markdown
audit. Validation was nevertheless rerun against the consolidation checkout:

- Reconciled the table mechanically against the fetched refs: 56 expected and 56 present,
  with no missing/extra branches and no tip, merge-base or unique-count mismatches. The
  calculated disposition counts match the summary.
- `tools/test-source-completion.sh` passed both C++ policy regressions:
  `chatter-grounding` and `human-navigator`.
- Verified all eight assembled repositories at the exact `repo-pins.txt` commits. In a new
  disposable checkout of those pins, all 24 wrapper patches applied forward in order, then
  all ten Era Talents core/module patches applied.
- The existing native Release/Ninja build tree is from the identical source baseline. Its
  consolidation rebuild passed; because this pass changes documentation only, Ninja found no
  translation unit to rebuild and ran only the revision-generation step. The full native build
  and final changed-unit checks at this exact source baseline remain recorded in the source
  completion report.
- All 29 module migrations passed in filename order against a new disposable MySQL 8.4
  database, then all 29 passed again against the populated database. The result retained 620
  protocol-loot rows, 62 Sidereal vendor rows and 138 Scourgestone vendor rows, with no
  unresolved loot-name output. The disposable container was removed afterward.
- All 29 tracked shell scripts passed `bash -n`; the generated pinned setup body passed its
  deterministic preflight. All 35 tracked addon Lua files parsed with Lua 5.1. Twenty-two
  workspace PowerShell files parsed without errors.
- BotGrid passed 103 headless Lua checks and AHPrice passed 37. The lore sidecar passed all 69
  pytest tests; its pinned dependencies emitted 37 deprecation warnings under Python 3.14.
- Rebuilt the addon-only client pack with `WDM_LANG=` and `IP_CLIENT_PATCH_V=0`. The
  114,868,586-byte ZIP contains 6,032 entries and 125 TOCs, includes every required addon,
  and contains no Git metadata, absolute/traversal path or missing required TOC.
- Scanned seven local module directories, 34 `Add*Scripts` definitions, 71 script registration
  IDs, 26 loader calls, 151 config keys and 29 SQL files. No duplicate module directory,
  definition, registration ID, loader call, config key or per-database SQL filename was found.
- Root whitespace review passed. Before the audit commit, this document was the only tracked
  worktree change; generated build/client artifacts remain ignored.

No installed server container, live database, client installation, `main`, `develop`, remote
branch or tag is changed by this audit.

## Suggested post-promotion tags and cleanup

Do not run these commands until the exact consolidation commit has passed the real local
`./update.sh`, startup, gameplay and restart tests and that exact commit is on `origin/main`.
They are a plan only; this audit does not create tags or delete refs.

```bash
cd ~/AzerothCore
git fetch origin --prune
tested_sha="$(git rev-parse origin/codex/final-consolidation-2026-09-15)"
test "$(git rev-parse origin/main)" = "$tested_sha"

git tag -a pre-consolidation-2026-09-15 0ab5a8bf1052c5d9e7e2ef80347a6185f1756bf4 -m "Pre-consolidation main"
git tag -a source-completion-2026-09-15 a65f445433e2d7ba333e1c9578f2b281d303fbcd -m "Source completion baseline"
git tag -a first-full-living-world-release "$tested_sha" -m "First full living world release"
git push origin pre-consolidation-2026-09-15 source-completion-2026-09-15 first-full-living-world-release

git push origin --delete \
  archive/pre-cleanup-2026-09-14 \
  backup/main-before-integration-promotion-2026-09-15 \
  backup/pre-final-titan-polish-2026-09-15 \
  backup/pre-guild-director-port-2026-09-15 \
  backup/pre-main-merge-2026-09-15 \
  backup/pre-titan-finalization-2026-09-15 \
  backup/pre-titan-rune-completion-2026-09-15 \
  backup/pre-titan-rune-completion-pass2-2026-09-15 \
  codex/integration-source-completion-2026-09-15 \
  codex/final-consolidation-2026-09-15 \
  develop \
  feature/adventure-controls \
  feature/adventure-guide-finder \
  feature/adventure-guide-finder-backup \
  feature/adventure-teleport-rewards \
  feature/adventurer-economy \
  feature/ai-guild-persistence \
  feature/ai-guild-services \
  feature/client-addon-pack \
  feature/client-addon-pack-ultrawide \
  feature/client-ui-pack \
  feature/client-ui-pack-final \
  feature/client-ui-pack-impl \
  feature/client-ui-pack-work \
  feature/encounter-lifecycle \
  feature/encounter-recovery-prep \
  feature/full-adventure-stack \
  feature/full-adventure-stack-guildsync \
  feature/full-adventure-stack-guildsync2 \
  feature/guild-group-director \
  feature/living-world-titan-runes \
  feature/living-world-titan-runes-actual \
  feature/living-world-titan-runes-buildfix \
  feature/living-world-titan-runes-buildfix2 \
  feature/living-world-titan-runes-buildfix3 \
  feature/living-world-titan-runes-compile \
  feature/living-world-titan-runes-finalize \
  feature/living-world-titan-runes-finish \
  feature/living-world-titan-runes-ready \
  feature/living-world-titan-runes-ready2 \
  feature/living-world-titan-runes-work \
  feature/raid-leader-foundation \
  feature/smart-loot-protection \
  feature/tbc-start-qol \
  feature/tbc-start-qol-backup \
  feature/tbc-start-qol-final \
  feature/tbc-start-qol-merge \
  feature/tbc-start-qol-review \
  feature/tbc-starter-progression \
  fix/audit-adventure-start-progression \
  fix/tbc-start-dark-portal \
  ignore-this \
  integration/bot-ai-refresh-2026-09-14 \
  sync/upstream-2026-09-13 \
  tmp-noop \
  tmp2-noop

git fetch origin --prune
git branch -r
```

The deletion list deliberately excludes `main` and includes the final consolidation branch
only after promotion. Review repository protection rules before running the single remote
deletion command.
