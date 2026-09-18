# Design: Add a Deterministic Task-Graph Scheduler

## Determinism is a first-class requirement

`plan()`, `schedule()`, `topoOrder()` all produce values that are functions
of their argument only. No `Date`, no `Math.random`, no `process.env` inside
the two packages; the CLI is the only layer that reads files or the argv.
Tie-breaking is by _input declaration order_ (first declared wins on equal
readiness), not alphabetical. The 8 scenarios in the accepted spec pin this
by asserting the exact output for a fixed input on repeated runs.

Consequence: the packages have a 0-size runtime dependency footprint
(Node built-ins only), and the CLI can be a single `main.ts` with a tiny arg
parser that rejects unknown flags rather than adding a `commander` dep.

## Two packages rather than one

`task-graph` owns `Task` and the single-node properties: validation
(cycle / self-dep / unknown-dep / empty id), topological order, and
`isReady(task, completed)`. It does not know what a "wave" is.

`task-sched` owns the plan-level operations: `plan(tasks)` → ordered ID list,
`schedule(tasks, parallel)` → array of waves, and `ready(tasks, completed)` →
the set of IDs whose dependencies are all in `completed`. It imports
`task-graph` and composes it; a caller sees one public surface.

This mirrors the existing `hello` → `greeter` teaching shape: two packages,
one way of depending, and each package's test file asserts its own contract.
A single combined package would test both layers at once and lose the
boundary the repository is trying to teach.

## `isReady` is a pure predicate, not a scheduler

The scheduler's core loop is:

```
ready = tasks.filter(t => t.dependsOn.every(d => d in completed))
```

Because `isReady` is a predicate, `plan()` is just "run readiness until
nobody new is ready" (Kahn's algorithm expressed in plain terms), and
`schedule(tasks, parallel)` is "repeat `plan` with a per-iteration cap
until all IDs are emitted." The cap is applied _after_ readiness: wave 0 is
the ready set with `parallel` entries, wave 1 is recomputed against
`completed + wave 0`, and so on. No priority scoring, no work-stealing.

This keeps the public surface at three functions plus one type, and lets every
scenario in the spec be asserted against a single pure call.

## The CLI is thin by construction

`apps/planner/src/main.ts` parses argv (positionals + `--format`,
`--parallel`), reads the given file synchronously with `node:fs`, parses the
JSON, calls one of the two `task-sched` entry points, and writes a string to
`process.stdout`. No `process.on`, no `setTimeout`, no global state. The two
subcommands are the only verbs. The `--conditions=@spec-loop/source` flag on
the test target is the same convention `packages/greeter` already uses and is
the mechanism that makes `@spec-loop/task-graph` resolve to its source tree
at runtime for Node — no `paths`, no bundler, no dist needed to run or test.

Because the CLI never touches the network or the clock, the e2e scenario in
the accepted spec is fully reproducible on a `npm ci` machine.

## Cache inputs (`nx.json`)

`nx.json:5` currently lists only `{projectRoot}/**/*` + `sharedGlobals: []`. A
warm `.nx/` cache therefore does _not_ invalidate when `tsconfig.base.json`,
`eslint.config.mjs`, the root `package.json`, or `package-lock.json` change.
CI never hits this (fresh checkout) but local development does, and it is the
reason a change to a shared compiler option can silently be cached as the
old result. The fix — add those four files to `namedInputs.sharedGlobals` —
is included here because the new packages multiply the number of projects
whose cached outputs depend on those inputs, so the pre-existing bug becomes
more visible the moment this change lands.

## Workspace layout

Root `package.json` workspaces currently lists only `packages/*`. Adding
`apps/*` is a two-line change and is what lets `npm install` symlink
`node_modules/@spec-loop/task-graph` and `node_modules/@spec-loop/task-sched`
into `apps/planner` the same way it already does for `packages/greeter`.
Each `apps/planner/package.json` declares its dependencies on the two new
packages; the Nx `project.json` for `planner` adds
`"implicitDependencies": ["task-graph", "task-sched"]` so the task graph
orders the two library `build` targets before `planner`'s own targets.

## Deterministic error messages

`validate` throws errors whose messages include the offending IDs in a stable
order (input order for unknown-deps, cycle order for cycles). The spec's
scenarios pin the message shape (not just the throw) so an agent or human
reading the output gets an actionable pointer rather than `"invalid"`.
