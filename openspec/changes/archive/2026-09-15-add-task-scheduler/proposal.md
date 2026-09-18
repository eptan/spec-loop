# Add a Deterministic Task-Graph Scheduler

## Why

The repository currently demonstrates spec-driven Nx composition only through the
`hello`/`greeter` teaching pair. Its eponymous "spec loop" — spec → plan →
verified run — is enforced by a dozen shell scripts that inspect Markdown; there
is no typed, contract-tested primitive that a real tooling consumer (or an
agent, or a human) can call to turn a set of work items into a dependency-
ordered execution plan. A `task-scheduling` capability gives the loop a
composable core (pure `task-graph`), a composition layer (`task-sched`), and a
thin CLI (`planner`) in `apps/` that fills the currently-empty `apps/`
directory and demonstrates the packages→apps split the repository is teaching.
It doubles as a local-first planning primitive for the kind of work this
machine already does: ordering repo-by-repo dependency work by its
`dependsOn` edges and a parallelism budget.

## What Changes

- Add a new accepted capability `task-scheduling` under `openspec/specs/`
  with a typed, deterministic contract (validation, topological ordering,
  readiness, wave scheduling, and a CLI e2e) and the scenarios that pin it.
- Add `packages/task-graph` (`@spec-loop/task-graph`) — pure core: `Task`
  shape, `validate()`, `topoOrder()`, `isReady()`. No I/O, no clock, no
  runtime deps.
- Add `packages/task-sched` (`@spec-loop/task-sched`) — composition: `plan()`,
  `schedule({ parallel })`, `ready()`. Depends on `@spec-loop/task-graph`.
- Add `apps/planner` (`@spec-loop/planner`) — a thin CLI (`plan`, `schedule`)
  that reads a JSON task file, calls `task-sched`, and prints deterministic
  table or JSON output. Test target uses `node --conditions=@spec-loop/source`.
- Extend root `package.json` `workspaces` to include `apps/*` so `apps/planner`
  symlinks its package dependencies the same way `packages/*` do today.
- Extend `nx.json` `sharedGlobals` to cover `tsconfig.base.json`,
  `eslint.config.mjs`, root `package.json`, and `package-lock.json`, so a warm
  `.nx/` cache does not serve stale results when those shared inputs change
  (see design note §Cache inputs).

## Dependencies

None.

## Non-Goals

- Does not add persistence, a queue, or a dispatcher loop; the scheduler emits
  an in-memory plan and exits.
- Does not add network access, credentials, or external side effects — the CLI
  operates only on a user-supplied JSON file under the current directory.
- Does not turn `apps/planner` into a "platform" (no plugins, no config
  files, no env-var knobs); the input is a single JSON document and the output
  is deterministic plain text.
- Does not change the existing `hello` or `greeter` packages; the new packages
  coexist with them so the composition teaching pair remains available as a
  reference.
- Does not add a bundler, a runtime dep, or any third-party dependency beyond
  Node's built-in modules.
- Does not publish `@spec-loop/*` packages to a registry; all stay
  `"private": true` in-workspace.
