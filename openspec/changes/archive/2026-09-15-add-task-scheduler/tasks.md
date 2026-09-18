# Tasks: Add a Deterministic Task-Graph Scheduler

## 1. OpenSpec artifacts

- [x] 1.1 Add this change (`proposal.md`, `design.md`, `tasks.md`) and its
      `specs/task-scheduling/spec.md` delta under `openspec/changes/`.
- [x] 1.2 Add a roadmap row named `Task scheduling` governing
      `add-task-scheduler` with status `In progress` to `plans/roadmap.md`.
- [x] 1.3 `npm exec openspec -- validate add-task-scheduler --strict` passes.

## 2. Repository prerequisites

- [x] 2.1 Extend root `package.json` `workspaces` to include `apps/*`.
- [x] 2.2 Add `tsconfig.base.json`, `eslint.config.mjs`, root
      `package.json`, and `package-lock.json` to `nx.json` `namedInputs.sharedGlobals`.
- [x] 2.3 `npm install` succeeds and `node_modules/@spec-loop` shows the two
      existing package symlinks still.

## 3. `packages/task-graph` (pure core)

- [x] 3.1 Add `packages/task-graph/package.json` (name `@spec-loop/task-graph`,
      `"private": true`), exporting `.` through the `@spec-loop/source`
      condition.
- [x] 3.2 Add `packages/task-graph/project.json` with `build`, `typecheck`,
      `lint`, and `test` targets matching `packages/hello/project.json`'s shape.
- [x] 3.3 Add `packages/task-graph/tsconfig.lib.json` extending
      `tsconfig.base.json` plus `"declaration": true`.
- [x] 3.4 Implement `packages/task-graph/src/index.ts`: `Task` type,
      `validate(tasks)`, `topoOrder(tasks)`, and `isReady(task, completed)`.
- [x] 3.5 Add `packages/task-graph/src/index.test.ts` covering: valid input
      order, cycle rejection (message names cycle IDs), self-dependency
      rejection, unknown-dep rejection (message names the missing ID), and a
      single-node graph.

## 4. `packages/task-sched` (composition)

- [x] 4.1 Add `packages/task-sched/package.json` (name `@spec-loop/task-sched`,
      depends on `@spec-loop/task-graph: "*"`, exports `.` through the
      `@spec-loop/source` condition).
- [x] 4.2 Add `packages/task-sched/project.json` with the four targets and
      `implicitDependencies: ["task-graph"]`.
- [x] 4.3 Add `packages/task-sched/tsconfig.lib.json` extending
      `tsconfig.base.json` plus `"declaration": true`.
- [x] 4.4 Implement `packages/task-sched/src/index.ts`: `plan(tasks)`,
      `schedule(tasks, parallel)`, and `ready(tasks, completed)`, importing
      the `task-graph` surface.
- [x] 4.5 Add `packages/task-sched/src/index.test.ts` covering: empty input,
      diamond determinism, readiness gating, wave scheduling with `parallel>=1`
      (waves respect the cap, input order preserved inside a wave), and a
      three-chain task with `parallel=1` occupying three successive waves.

## 5. `apps/planner` (thin CLI)

- [x] 5.1 Add `apps/planner/package.json` (name `@spec-loop/planner`, depends
      on both `@spec-loop/task-*` packages, `"private": true`).
- [x] 5.2 Add `apps/planner/project.json` with `test` and `run` targets using
      `node --conditions=@spec-loop/source --experimental-strip-types`.
- [x] 5.3 Implement `apps/planner/src/main.ts`: `plan <file> [--format
table|json]` and `schedule <file> [--parallel N] [--format table|json]`;
      read the JSON synchronously, validate, call `task-sched`, and print the
      result (stable column alignment for table, `JSON.stringify(v, null, 2)`
      for json).
- [x] 5.4 Add `apps/planner/src/planner.test.ts` e2e covering at least:
      `plan` on a fixture → deterministic table, `plan` with `--format json`
      → valid JSON, `schedule --parallel 2` on a diamond fixture → two waves,
      and an invalid fixture (cycle) printing the same error on every run.

## 6. Docs

- [x] 6.1 Add a section to `docs/repository-orientation.md` describing the
      new packages, the CLI, and the `--conditions=@spec-loop/source` runtime
      convention (with the exact command to run `planner`).
- [x] 6.2 Reference `apps/planner` and the two new packages in `README.md`
      next to the existing `hello`/`greeter` mentions.
- [x] 6.3 Add or update a `docs/` note (a new `docs/task-scheduling.md` or a
      paragraph in an existing doc) that documents the input JSON shape and the
      two commands, so `check-docs.sh` has a doc-change companion for the
      implementation change.

## 7. Verification

- [x] 7.1 `npm run check` passes end to end (openspec strict validate +
      harness + archive + plan freshness + deps + governance + conventions +
      attribution + docs + secrets + format + workspace links + typecheck +
      lint + test + build).
- [x] 7.2 Record the exact commands and outputs in the PR body for:
      `plan` on a valid fixture file (default table output), `plan --format json`
      (valid JSON containing the input ids), and
      `schedule --parallel 1` on a three-node chain (three single-id waves).
- [x] 7.3 `npm run rename -- <new-name>` continues to work across the new
      packages and the new app (the rename tool is name-agnostic but must not
      break on the new paths).
- [x] 7.4 Archive the change once 1.3, 4._, 5._, 6.*, and 7.1 are all
      `[x]` and `npm run check` is green, then flip the roadmap row to
      `Complete`.
