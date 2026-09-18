# Task Scheduling

## Purpose

The repository provides a deterministic, local-only task-graph scheduling capability. A set of tasks with
`dependsOn` edges is turned into a complete dependency-ordered plan, or a wave schedule bounded by a
parallelism cap. The `task-graph` package holds the pure core and `task-sched` composes it into `plan`,
`ready`, and `schedule`; `apps/planner` is a thin CLI over that surface. Output is a pure function of its
input: no clock, no network, no third-party runtime dependencies.

## Requirements

### Requirement: Task input is a strict, typed shape

The `task-graph` package MUST accept a `Task` value of the shape
`{ id: string, dependsOn?: string[] }` and reject an input whose shape does
not match — a non-string `id`, an `id` that is empty after trimming, or a
`dependsOn` entry that is not a string — by throwing an error whose message
names the offending `id` (or `undefined` when absent). Duplicate `id`s MUST
be rejected with a message naming the duplicated `id`.

#### Scenario: A single valid task is accepted

- **GIVEN** `[ { id: 'a' } ]`
- **WHEN** the input is validated
- **THEN** validation succeeds and the returned value is a valid plan

#### Scenario: A non-string id is rejected with its value in the message

- **GIVEN** `[ { id: 42 } ]`
- **WHEN** the input is validated
- **THEN** validation throws an error whose message contains `42`

### Requirement: Topological ordering is deterministic

`topoOrder(tasks)` MUST return a topological ordering of the given input such
that every task appears after every task it depends on. When more than one
ordering is valid, the tie-break MUST be by input declaration order (first
declaration wins on equal readiness), not alphabetical or hash order. For a
fixed input the function MUST return the same array on repeated invocations.

#### Scenario: A diamond graph orders deterministically

- **GIVEN** a four-task graph shaped `root -> a` and `root -> b` with `c`
  depending on both `a` and `b`
- **WHEN** `topoOrder` is called repeatedly
- **THEN** every call returns the identical order
- **AND** `root` precedes `a` and `b`, and `c` follows both `a` and `b`

### Requirement: Cycles, self-dependencies, and unknown dependencies are rejected

`validate` MUST reject a graph containing a cycle, a self-dependency, or a
dependency on an id not present in the input, in each case with an error
message that names the offending id(s) in a stable order. The error message
MUST include the phrase `'cycle'` for a cycle, `'depends on itself'` for a
self-dependency, and `'unknown dependency'` for a missing id so an agent or
human reading the output can act on it.

#### Scenario: A two-node cycle is rejected with both ids

- **GIVEN** `[ { id: 'a', dependsOn: ['b'] }, { id: 'b', dependsOn: ['a'] } ]`
- **WHEN** the input is validated
- **THEN** validation throws an error whose message names `a` and `b`
- **AND** the message contains the phrase `'cycle'`

#### Scenario: A self-dependency is rejected with the offending id

- **GIVEN** `[ { id: 'a', dependsOn: ['a'] } ]`
- **WHEN** the input is validated
- **THEN** validation throws an error whose message names `a`
- **AND** the message contains the phrase `'depends on itself'`

#### Scenario: An unknown dependency is rejected with the missing id

- **GIVEN** `[ { id: 'a', dependsOn: ['missing'] } ]`
- **WHEN** the input is validated
- **THEN** validation throws an error whose message contains
  `'unknown dependency'` and the id `missing`

### Requirement: Readiness is a pure predicate

`isReady(task, completed)` on `task-graph` and the equivalent `ready(tasks,
completed)` on `task-sched` MUST return `true` exactly when every id in the
task's `dependsOn` is present in `completed` (and the task id is not already
in `completed`). An empty `dependsOn` (or absent) MUST be ready. The
predicate MUST not mutate its inputs and MUST produce the same result for the
same argument pair on repeated invocations.

#### Scenario: A task with no dependencies is ready immediately

- **GIVEN** `[ { id: 'a' } ]` and `completed = []`
- **WHEN** readiness is computed for `a`
- **THEN** it is ready

#### Scenario: A task is not ready until all of its dependencies are completed

- **GIVEN** `[ { id: 'a' }, { id: 'b', dependsOn: ['a'] } ]` and `completed = []`
- **WHEN** readiness is computed
- **THEN** `a` is ready and `b` is not
- **WHEN** `completed` is `[ 'a' ]`
- **THEN** `b` is ready

### Requirement: A plan is a complete, dependency-ordered list

`plan(tasks)` on `task-sched` MUST return every input id exactly once, in a
dependency-ordered sequence, and MUST throw if the input is invalid (cycle,
self-dependency, unknown dependency, or malformed shape). For an empty input
the plan MUST be an empty array.

#### Scenario: An empty input yields an empty plan

- **GIVEN** `[]`
- **WHEN** `plan` is called
- **THEN** it returns `[]`

### Requirement: Wave scheduling respects a parallelism cap and preserves input order

`schedule(tasks, parallel)` on `task-sched` MUST return an array of waves,
each wave being a list of ids no larger than `parallel`, such that concatenating
the waves yields a plan-equivalent ordering. Within a single wave the ids MUST
appear in their input declaration order. A chain of length n with `parallel=1`
MUST occupy exactly n successive waves, one id per wave.

#### Scenario: A chain with parallel=1 occupies three successive waves

- **GIVEN** a three-node chain `a -> b -> c` and `parallel = 1`
- **WHEN** `schedule` is called
- **THEN** it returns three waves, each of length 1, in the order `a, b, c`

#### Scenario: A diamond fixture with parallel=2 respects the cap

- **GIVEN** a four-task graph `root -> a`, `root -> b`, `c -> {a, b}` and
  `parallel = 2`
- **WHEN** `schedule` is called
- **THEN** no wave contains more than two ids
- **AND** concatenating the waves yields a plan-equivalent ordering (every id
  appears exactly once, and each id occurs after all of its dependencies)

### Requirement: The `planner` CLI exposes a deterministic, local-only command

`apps/planner` MUST expose two subcommands — `plan <file>` and
`schedule <file> [--parallel N]` — that read a single JSON file, validate it
against the `task-graph` contract, call the matching `task-sched` entry point,
and print a string to stdout. Each invocation MUST be a function of the file
contents and flags only (no clock, no network, no environment read inside the
two packages), so `plan` on a fixed fixture yields byte-identical stdout on
repeated runs, and `--format json` yields JSON that `JSON.parse` accepts. The
CLI MUST reject unknown flags and unknown subcommands with a non-zero exit
code and a message that names the rejected token.

#### Scenario: `plan` on a fixed fixture yields identical stdout on every run

- **GIVEN** a fixture file whose contents are a valid task graph
- **WHEN** `node --conditions=@spec-loop/source
--experimental-strip-types apps/planner/src/main.ts
plan <fixture>` is invoked twice in a row
- **THEN** both invocations print byte-identical stdout
- **AND** the exit code is 0 on both

#### Scenario: `--format json` on `plan` outputs valid JSON

- **GIVEN** a valid task graph fixture
- **WHEN** `plan <fixture> --format json` is invoked
- **THEN** the exit code is 0
- **AND** stdout is parseable by `JSON.parse`
- **AND** the parsed value contains the input task ids

#### Scenario: An invalid fixture (cycle) produces a stable, non-zero error

- **GIVEN** a fixture file containing a cycle
- **WHEN** `plan <fixture>` is invoked twice in a row
- **THEN** both invocations exit with a non-zero code
- **AND** both invocations print the same error text (same ids, same phrase)
