# Contributing

Spec Loop is a learning repository. Contributions should improve the foundation, demonstrate a
repeatable practice, or make an existing boundary clearer. Avoid adding framework-specific or provider-
specific machinery unless it supports a documented teaching goal.

## Before Editing

1. Read `AGENTS.md`.
2. Read the relevant accepted spec under `openspec/specs/`.
3. Find or create the active OpenSpec change that governs the work.
4. Inspect the current Nx project graph and related implementation.

Use [`docs/repository-orientation.md`](docs/repository-orientation.md) when locating implementation,
specification, governance, or agent integration files.
Use [`docs/agent-attribution.md`](docs/agent-attribution.md) for neutral contributor and reviewer attribution.

Behavior changes require a change under `openspec/changes/`. Documentation and workflow changes must
update the relevant docs in the same pull request. Keep requirements, architecture, tasks, and teaching
prose in their respective documents; do not duplicate contracts across README and plans.

## Local Setup

```bash
npm ci
./scripts/install-git-hooks.sh
npm run check
```

Install [gitleaks](https://github.com/gitleaks/gitleaks#installing) locally for full secret-scan coverage;
the check falls back to a narrower pattern when it's absent, which still runs on every commit but is a
review guard, not a guarantee (see [`SECURITY.md`](SECURITY.md)).

Useful Nx commands:

```bash
npm exec nx show projects
npm exec nx graph
npm exec nx run hello:test
```

## Change Workflow

1. Draft `proposal.md`, `design.md`, `tasks.md`, and the capability spec.
2. Run `npm exec openspec -- validate <change> --strict`.
3. Implement the smallest change that satisfies the scenarios.
4. Run `npm run check` and any changed-path end-to-end command. `./scripts/check-ci-only.sh` runs the
   network-dependent checks CI adds on top; `./scripts/pr.sh` runs it for you before opening the PR.
5. Update docs and task evidence after implementation.
6. Archive the change only when all tasks and verification are complete. `./scripts/pr.sh` does this for
   you: it archives every change whose `tasks.md` is fully checked, so check a box only when the task is done.

## Commit And PR Rules

Use small conventional commits: `type(scope): summary`. Do not commit credentials, `.env` files,
dependency directories, caches, generated output, or unexplained fixtures. Do not bypass hooks with
`--no-verify`.

Every pull request should state:

- What changed and why
- Which OpenSpec requirement or change it supports
- Exact verification commands and results
- Skipped checks and reasons, or `None`
- Whether data or generated output changed

Use `.github/pull_request_template.md` and `./scripts/pr.sh` for guarded PR automation after explicit
authorization.

## Contributing Without Write Access

You do not need push access to this repository. Contributions arrive as pull requests from a fork:

1. Clone the repository, or your own fork of it, and run the Local Setup steps above.
2. Create a feature branch: `git switch -c <branch>`. Do the work there, never on the default branch.
3. Run `./scripts/pr.sh` as usual. When you have no write access to the repository it detects that, forks
   it to your account if you have not already, pushes the branch to your fork, and opens the pull
   request against this repository. The same command works for maintainers, who push to the repository
   directly.

Without the GitHub CLI, do the same by hand: fork on GitHub, add your fork as a remote
(`git remote add fork <your-fork-url>`), `git push -u fork <branch>`, and open the pull request from your
fork's branch. CI runs on pull requests from forks; a maintainer may need to approve the first workflow
run for a new contributor.

## Review Standard

Review for behavioral correctness, clear boundaries, reproducibility, documentation freshness, and
teaching value. A passing check proves only that the check passed; it does not replace design or code
review.
