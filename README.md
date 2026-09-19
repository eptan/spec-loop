# Spec Loop

Spec Loop is a small, public Nx monorepo built to teach one thing: how to run agentic software work with
the same discipline a well-run engineering team already uses. Specs come before code. Every piece of code has
an owner and a boundary. Evidence beats trust. An agent can do real work here, but it can't redefine the job,
skip a check, or publish anything on its own.

Forking this to start your own project? Read [`TEMPLATE.md`](TEMPLATE.md) first. For the thinking behind
it, read [Building Agentic Software Without Losing Discipline](https://binarylogic.live/blog/building-agentic-software-without-losing-discipline).

## What's In It

- **Two teaching libraries.** `hello` is tiny and deterministic, so the structure and feedback loop stay
  visible. `greeter` depends on it, so dependency resolution and sequencing happen in running code instead
  of a diagram. Neither pretends to be a real product.
- **One real capability.** A task planner: give it tasks and what each one waits on, and it returns the
  order to run them in, or waves of parallel work under a cap. `task-graph` holds the pure logic,
  `task-sched` composes it, and `apps/planner` is a thin CLI over both. See
  [`docs/task-scheduling.md`](docs/task-scheduling.md).
- **The loop around them.** Specs, checks, agent commands, and skills that every change goes through,
  whether a person or an agent makes it.

## How Work Moves

An agent working in this repo is a contributor, not an operator with free rein. Four layers keep it honest:

| Question                    | Answered by                                               |
| --------------------------- | --------------------------------------------------------- |
| What should the system do?  | Accepted OpenSpec requirements, the behavioral authority  |
| Where does the code belong? | Nx projects, each with an owner and a dependency boundary |
| How does the work get done? | Repository rules in [`AGENTS.md`](AGENTS.md)              |
| Is it ready for review?     | Automated checks that supply the evidence                 |

The agent harness gives agents reusable commands and skills, and its MCP access stays read-only or limited
to documented workspace operations. Publishing, deploying, and touching credentials stay with a human, full
stop.

A change follows a real engineering lifecycle: discovery, proposal, design, planning, implementation,
verification, review, archival. Agents can move faster through it. They don't get to skip the parts that
make it trustworthy. Much of the bookkeeping runs itself: `scripts/pr.sh` archives a finished change when
its pull request goes up, and `./scripts/spec-status.sh` shows what's in progress in one command.

This is a work in progress by design. The repo stays small and legible on purpose, so the lessons scale to
bigger agentic monorepos without hiding how the mechanics work. New capabilities arrive through the same
spec-driven loop the repo teaches. Check the roadmap and OpenSpec change history to see where it's headed.

## Design Intent

The repository helps a team move from idea to reviewable implementation without losing the reasoning along
the way.

- **Contracts first.** Behavior lives in accepted OpenSpec requirements and scenarios, not in someone's
  head.
- **Bounded architecture.** Nx projects draw clear ownership and dependency lines.
- **Evidence over ceremony.** Every change ships with executable tasks and recorded verification.
- **Safe automation.** Agents can inspect and run bounded repository tasks. They don't get credentials or
  standing authority to publish, deploy, or act externally.
- **Portable foundations.** Examples avoid provider lock-in, network calls, and secrets.

## Quick Start

```bash
npm ci
npm run check
```

Install the local hooks once per clone:

```bash
./scripts/install-git-hooks.sh
```

`npm run check` runs strict OpenSpec validation, agent-harness and roadmap checks, documentation and secret
checks, then Nx formatting, linting, type checking, tests, and builds.

The secret check uses [gitleaks](https://github.com/gitleaks/gitleaks#installing) when it's on `PATH`, and
falls back to a narrow keyword pattern otherwise. Install gitleaks locally for real coverage — either way,
per [`SECURITY.md`](SECURITY.md), this check is a review guard, not a guarantee.

Forking this to start your own project? After `npm ci`, run `npm run rename -- <your-project-name>` to
rewrite every tracked identity string, npm scope, and file/directory name in one pass — see
[`TEMPLATE.md`](TEMPLATE.md) for the full one-time setup path.

## Key Commands

The repository keeps its common engineering actions executable and visible:

| Command                                        | What it does                                                                                                                  |
| ---------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------- |
| `npm run check`                                | Runs the complete local quality gate: specs, harness, governance, docs, secrets, formatting, Nx checks, tests, and builds.    |
| `npm exec nx show projects`                    | Lists the projects known to the Nx workspace.                                                                                 |
| `npm exec nx graph`                            | Opens the workspace project and dependency graph.                                                                             |
| `npm exec nx run hello:test`                   | Runs the deterministic test target for the example library.                                                                   |
| `npm exec nx run greeter:test`                 | Runs the test target for the second example library, which depends on `hello`.                                                |
| `npm exec nx run task-graph:test`              | Runs the contract tests for the pure task-graph core.                                                                         |
| `npm exec nx run task-sched:test`              | Runs the contract tests for the composition surface (`plan`, `ready`, `schedule`).                                            |
| `npm exec nx run planner:test`                 | Runs the end-to-end CLI tests for `apps/planner`.                                                                             |
| `npm exec openspec -- validate --all --strict` | Strictly validates every accepted and active OpenSpec artifact.                                                               |
| `./scripts/pr.sh`                              | Archives finished changes, runs guarded checks, commits, pushes, and opens a pull request (from a fork without write access). |
| `./scripts/spec-status.sh`                     | Lists each capability with an active change and its completed tasks, read live from OpenSpec.                                 |

The agent harness adds workflow commands for the spec and review loop:

| Command                  | What it does                                                                   |
| ------------------------ | ------------------------------------------------------------------------------ |
| `/roadmap`               | Adds a capability to the roadmap with an OpenSpec change and its dependencies. |
| `/next`                  | Selects and implements the next dependency-ready change.                       |
| `/spec-audit <name>`     | Reviews an active change for gaps and drift without editing files.             |
| `/verify-change <name>`  | Checks an active change against its tasks and evidence without mutating it.    |
| `/archive-change <name>` | Archives a fully verified change and updates its roadmap milestone.            |
| `/pr`                    | Creates a guarded commit and pull request through `scripts/pr.sh`.             |
| `/check-harness`         | Audits command, skill, symlink, and CI wiring without editing files.           |
| `/agent-rule`            | Adds one durable rule to `AGENTS.md`.                                          |

None of these commands grant an agent permission to publish, deploy, or take external action without an
explicit request.

## Skill Library

The reusable agent skill library lives in the canonical `.agent/skills/` directory. Skills give agents
focused working methods, not hidden authority. Discovery adapter paths like `.opencode/skills/` and
`.claude/skills/` just point back to this shared library.

| Skill                            | Focus                                                                 |
| -------------------------------- | --------------------------------------------------------------------- |
| `nx-workspace`                   | Explore projects, targets, dependencies, and workspace configuration. |
| `nx-run-tasks`                   | Run Nx targets and diagnose task failures.                            |
| `nx-generate`                    | Scaffold Nx projects and code through generators.                     |
| `nx-ai-agent-skills`             | Apply Nx-oriented practices when working with agents.                 |
| `openspec-change`                | Create a contract-backed OpenSpec change.                             |
| `openspec-contract-audit`        | Audit an active change for contract completeness and grounding.       |
| `openspec-lifecycle`             | Verify and archive changes with evidence and repository checks.       |
| `roadmap-execution`              | Select the next dependency-ready roadmap change.                      |
| `pull-request-automation`        | Prepare safe commit and pull-request automation.                      |
| `repository-harness-audit`       | Review commands, skills, adapters, and harness governance.            |
| `link-workspace-packages`        | Link packages in the npm workspace correctly.                         |
| `agent-rule`                     | Turn repository requests into durable agent rules.                    |
| `neutral-repository-attribution` | Keep repository-produced documentation and reports neutral.           |
| `nx-plugins`                     | Discover and add Nx technology plugins.                               |

Keep new reusable skills in `.agent/skills/`, document their boundaries, and expose them through the
existing discovery symlinks instead of copying divergent versions into adapter directories.

## Nx Workflow

```bash
npm exec nx show projects
npm exec nx graph
npm exec nx run hello:test
```

Project targets are intentionally explicit:

| Target      | Purpose                                       |
| ----------- | --------------------------------------------- |
| `lint`      | Static code-quality checks                    |
| `typecheck` | TypeScript validation without emitting output |
| `test`      | Deterministic project tests                   |
| `build`     | Emit type declarations                        |

Every package is source-only: `build` emits `.d.ts` files for editor and downstream typecheck
support, not runnable `.js`. Other packages in this workspace import them directly by source through the
`@spec-loop/source` package export condition (see `packages/greeter/src/index.ts`), so no build step is
required to consume them within this workspace. Use Nx targets rather than invoking project tooling
directly. Applications compose reusable libraries instead of holding domain logic: `apps/planner` is argument
parsing, one call into `task-sched`, and printing.

## Spec-Driven Workflow

OpenSpec is the behavioral source of truth here. The normal lifecycle:

1. Read the relevant accepted specs and current implementation.
2. Create and strictly validate `openspec/changes/<name>/`.
3. Record architecture in `design.md` and ordered work in `tasks.md`.
4. Implement only the contract-covered behavior.
5. Run `npm run check` and record exact evidence.
6. Verify the change. Once every task is checked, `scripts/pr.sh` archives it when the pull request goes up.

Each change artifact has its own job. `proposal.md` explains why. `design.md` explains how. `tasks.md`
explains execution. `specs/<capability>/spec.md` defines behavior. Plans teach sequencing; they don't
replace requirements.

See [`plans/spec-driven-workflow.md`](plans/spec-driven-workflow.md) and
[`docs/governance.md`](docs/governance.md) for the full workflow.

For the detailed directory map, authority boundaries, agent loop, harness adapters, and MCP boundary, see
[`docs/repository-orientation.md`](docs/repository-orientation.md).

Planning and dependency conventions are documented in
[`docs/dependency-patterns.md`](docs/dependency-patterns.md).

## Repository Map

| Path                | Responsibility                                                                      |
| ------------------- | ----------------------------------------------------------------------------------- |
| `apps/`             | Deployable applications; `planner` is the first thin CLI over `task-sched`          |
| `packages/`         | Reusable libraries and domain logic; `hello`, `greeter`, `task-graph`, `task-sched` |
| `openspec/specs/`   | Accepted behavioral contracts                                                       |
| `openspec/changes/` | Proposed, not-yet-archived changes                                                  |
| `scripts/`          | Repository checks, hooks, and PR automation                                         |
| `.agent/`           | Canonical agent commands and skills                                                 |
| `docs/`             | Durable policy and contributor explanations                                         |
| `plans/`            | Teaching sequence and roadmap, not requirements                                     |
| `.github/`          | CI, issue templates, and pull-request guidance                                      |

## Contributing

Read [`AGENTS.md`](AGENTS.md), the relevant accepted spec, and [`CONTRIBUTING.md`](CONTRIBUTING.md) before
making a change. Pull requests should explain the contract, the verification you ran, any checks you
skipped, and any generated output. You don't need write access: `./scripts/pr.sh` forks the repository and
opens the pull request from your fork (see [`CONTRIBUTING.md`](CONTRIBUTING.md)). The repository is licensed under the [MIT License](LICENSE).
