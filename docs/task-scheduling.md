# Task Scheduling

A deterministic, local-only task-graph scheduler. It turns a set of tasks with
`dependsOn` edges into a complete dependency-ordered plan (or a wave schedule
bounded by a parallelism cap). No clock, no network, no third-party runtime
dependencies — the output is a pure function of the input.

## Why two packages

- `packages/task-graph` is the pure core: the `Task` shape, validation
  (cycle / self-dependency / unknown-dependency / malformed-shape rejection),
  a deterministic topological order, and the `isReady` predicate. It has no
  I/O.
- `packages/task-sched` composes the core into `plan()`, `ready()`, and
  `schedule()`. It depends on `task-graph` and is the public surface a caller
  imports.

This mirrors the `hello` → `greeter` teaching pair: one way of depending, two
packages, each with its own contract.

## Input shape

A JSON array of tasks. `id` is required and must be a non-empty string;
`dependsOn` is an optional array of ids:

```json
[
  { "id": "root" },
  { "id": "a", "dependsOn": ["root"] },
  { "id": "b", "dependsOn": ["root"] },
  { "id": "c", "dependsOn": ["a", "b"] }
]
```

## Commands

Run the CLI directly (no build step required — it resolves the packages by
source through the `@spec-loop/source` export condition). Note that
`npm exec nx run planner:build` emits type declarations only, because
`tsconfig.base.json` sets `emitDeclarationOnly` for every project; there is no
runnable `dist/` output, so the `node` command below is the only runtime:

```bash
# A dependency-ordered plan as a table (default) or JSON.
node --conditions=@spec-loop/source --experimental-strip-types apps/planner/src/main.ts \
  plan <file.json> [--format table|json]

# A wave schedule, capped at `--parallel` tasks per wave.
node --conditions=@spec-loop/source --experimental-strip-types apps/planner/src/main.ts \
  schedule <file.json> [--parallel N] [--format table|json]
```

Or through the Nx targets in `apps/planner/project.json`:

```bash
npm exec nx run planner:test
npm exec nx run planner:run -- plan <file.json> [--format table|json]
npm exec nx run planner:run -- schedule <file.json>
```

Nx reserves `--parallel` for itself and does not forward it to the target, so
the wave cap only takes effect with the direct `node` command above.

`--format json` (both subcommands) emits `JSON.stringify(value, null, 2)` so
the output is machine-readable and identical across runs.

## Determinism contract

- `plan()` returns every id exactly once, in a dependency-ordered sequence;
  ties are broken by input declaration order, not alphabetically.
- `schedule()` emits waves such that concatenating them is a plan-equivalent
  ordering; within a wave, ids keep their input order.
- Invalid input (cycle, self-dependency, unknown dependency, duplicate or
  non-string id) throws an error naming the offending id(s), e.g.
  `dependency cycle: a -> b -> a` or `unknown dependency: missing`.

## Boundaries

- The scheduler emits an in-memory plan and exits. It does not persist, queue,
  or dispatch.
- It performs no network access and reads no environment variables; the only
  input is the file you pass in.
- `apps/planner` is intentionally thin: argument parsing, file load, one call
  into `task-sched`, print. The two packages hold the logic.
