# Development / CI / Deployment Rules

These rules are operational requirements, not suggestions.

## Branch

All Group Composer V4 work goes to:

`test/group-composer-v4`

## CI routing

Self-hosted runner:
- name: `stoffes-pc`
- labels: `self-hosted, Linux, X64, wow-builder`
- Clang 18
- Ninja
- 8 compile jobs
- persistent ccache

Local Ubuntu 26.04 requires Clang 18 to use GCC 15's libstdc++:

`--gcc-install-dir=/usr/lib/gcc/x86_64-linux-gnu/15`

Do not remove/change that workaround without a concrete reason.

Routing:
- `[local-ci]`: force compile/Integration onto `stoffes-pc`.
- `[github-ci]`: explicitly force GitHub-hosted CI.
- With `[local-ci]` and the runner offline, the job waits instead of silently switching to GitHub.

Integration workflow:
`.github/workflows/integration-build.yml`

## Definition of green

For the **same exact commit SHA**, relevant workflows must complete successfully:

1. Group Composer client checks
2. Stage Group Composer V4 backend
3. Group Composer V4 compile
4. Integration build
5. Group Composer typed UI when `client-ui` changes

Never report a build as green from a previous SHA.

If a job fails:
- inspect failed job/logs;
- fix the cause;
- push another appropriate CI commit;
- repeat until the exact final commit is successful.

## Generated UI

`client-ui` is the TypeScript source of truth for the modern addon shell.

The typed UI workflow can publish a generated bundle commit:
`build(group-composer): refresh modern UI bundle`

If that happens, follow the generated branch head. Do not overwrite it with a force push. Rebase/fast-forward any follow-up test/doc fix onto the new head.

## Documentation requirement

For every meaningful pass:
- update `CURRENT_STATE.md`;
- append `PASS_LOG.md`;
- change `NEXT_WORK.md` if priority changed;
- change `TEST_MATRIX.md` when test status/coverage changed;
- change `ERA_FIDELITY.md` whenever expansion-stage rules, bot/economy/world gates or release-transition behavior changed;
- change `MASTER_ROADMAP.md` whenever an approved ERA/FEATURE item changes status, dependency, scope or completion evidence.

A pass is not done if its code exists but the canonical handoff still describes the previous reality.

## Deployment

Only after exact-head CI is green and the change is ready for in-game testing:

```bash
git switch test/group-composer-v4
git pull
./update.sh
```

`./update.sh` handles module sync, patches/config, Docker rebuild, DB migrations and stack restart.

## Realm safety

- Current realm is permanent dirty dev/test realm.
- Do not wipe/sanitize it to fake a release.
- Future friends realm is a separate clean realm/database state.
- Fresh release engineering happens only after gameplay validation.
