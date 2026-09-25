# Agent Instructions

## Mission

This is a public, teaching-oriented Nx foundation for future agentic software projects. Keep it small,
deterministic, composable, and understandable. Prefer patterns that teach a team how to structure a repo
over features that imitate a production system without a real use case.

## Authority And Workflow

- Read the relevant accepted specs under `openspec/specs/` and the matching active change before editing.
- Treat accepted OpenSpec requirements and scenarios as the behavioral source of truth.
- Put architecture and tradeoffs in `design.md`, execution steps in `tasks.md`, and teaching explanations
  in `README.md`, `docs/`, or `plans/`.
- If behavior is ambiguous, update the active OpenSpec artifacts before coding through the ambiguity.
- Implement the smallest contract-covered slice; do not add speculative compatibility layers.
- Update documentation in the same change when commands, outputs, workflows, configuration, or layout change.
- Archive an OpenSpec change only after every task and verification requirement is complete.
  `scripts/pr.sh` does this automatically for any change in that state before staging — do not check a
  task box until it is genuinely done, since that is the only signal the automation trusts.

## Repository Design

- Use Nx project boundaries and targets as the workspace's structural and execution model.
- Put reusable application or domain logic in `packages/`; keep future apps in `apps/` thin and compositional.
- Keep governance, specifications, and repository automation at the root boundary.
- Keep examples deterministic, local-only, and free of credentials or required network access.
- Keep application logic independent from reports, presentation, and agent tooling.

## Safety Boundaries

- Never commit credentials, tokens, private keys, `.env` files, dependency directories, caches, or generated output.
- Do not add provider integrations, deployment authority, destructive commands, or external side effects
  without an explicit reviewed OpenSpec change and user authorization.
- Treat agent configuration as an adapter, not an authority grant. MCP access must remain read-only or
  bounded to documented Nx operations.
- Do not use plans, README prose, or agent suggestions as substitutes for accepted requirements.
- Do not bypass hooks or checks with `--no-verify`, `--skip-checks`, or equivalent flags unless the user
  explicitly authorizes a documented tooling outage.

## Nx Conventions

Generic Nx task guidance (prefer `nx` over underlying tooling, prefix the package manager, use `nx_docs`
instead of guessing flags, invoke the `nx-workspace` skill for exploration) lives in the auto-managed
"General Guidelines for working with Nx" block below; do not restate it here. This section carries only
the repo-specific rules:

- For scaffolding or project structure changes, use the `nx-generate` skill first and prefer Nx generators.
- Preserve explicit `lint`, `typecheck`, `test`, and `build` targets for every project.

## Verification

Before considering work complete, run:

```bash
npm run check
```

This is the canonical local gate, and CI runs it unchanged. It includes strict OpenSpec validation,
harness topology, OpenSpec archive completeness, roadmap freshness, documentation freshness, secret
scanning, formatting, linting, type checking, tests, and builds. CI additionally runs
`./scripts/check-ci-only.sh` (the rename fixture and the dependency-advisory review, which need the
network); `scripts/pr.sh` runs that script before opening a pull request, and a change that touches
dependencies or the rename tooling should run it by hand first. Also run an exact end-to-end command for
every changed runnable workflow or integration path and record the result in the PR.

## Shared Agent Harness

`.agent/commands/` and `.agent/skills/` are canonical. `.opencode/`, `.claude/`, `.agents`, and
`CLAUDE.md` are discovery symlinks and must not contain copied divergent content. Run
`./scripts/check-harness.sh` after changing harness files. Restart the harness after changing project-local
commands or skills.

See [`docs/repository-orientation.md`](docs/repository-orientation.md) for the detailed repository map,
agent loop, harness adapters, and MCP boundary.

## Neutral Repository Attribution

- Use neutral role labels such as `contributor`, `reviewer`, or `agent` in repository-produced content.
- Do not add provider names, commercial identities, logos, marketing signatures, or generated-by watermarks
  to new repository documentation, reports, reviews, or status records.
- Preserve existing human-authored attribution, copyright, licensing, and historical review records.
- Repository rules cannot remove branding injected by an external Claude UI, API gateway, or organization
  platform; platform-level changes belong to the responsible administrator or product settings.
- Use the `neutral-repository-attribution` skill when producing repository reviews, reports, or documentation.
- Use the `agent-rule` skill and `/agent-rule` command when turning a repository request into a durable rule
  in this file.

## Pull Requests

Create and switch to a feature branch before making file changes intended for a pull request, not only
before running `scripts/pr.sh` — implementation should never sit as uncommitted work on the default
branch. Use the
repository PR template and `scripts/pr.sh` when explicitly asked to create a PR; pass `--reuse-branch` when
the branch already exists. Before doing so, inspect status, the complete diff, recent commits, remote
tracking, OpenSpec tasks, and verification output. Do not commit directly to the default branch,
force-push, or include unrelated worktree changes. `.githooks/pre-commit` rejects a local commit made while
the default branch is checked out.

<!-- nx configuration start-->
<!-- Leave the start & end comments to automatically receive updates. -->

## General Guidelines for working with Nx

- For navigating/exploring the workspace, invoke the `nx-workspace` skill first - it has patterns for querying projects, targets, and dependencies
- When running tasks (for example build, lint, test, e2e, etc.), always prefer running the task through `nx` (i.e. `nx run`, `nx run-many`, `nx affected`) instead of using the underlying tooling directly
- Prefix nx commands with the workspace's package manager (e.g., `pnpm nx build`, `npm exec nx test`) - avoids using globally installed CLI
- You have access to the Nx MCP server and its tools, use them to help the user
- For Nx plugin best practices, check `node_modules/@nx/<plugin>/PLUGIN.md`. Not all plugins have this file - proceed without it if unavailable.
- NEVER guess CLI flags - always check nx_docs or `--help` first when unsure

<!-- nx configuration end-->
