# Using This Repository As A Template

This checklist is for the moment right after you fork or clone this repository to start your own
spec-driven, agent-governed project. It is a one-time setup path, in order. `CONTRIBUTING.md` covers the
ongoing change workflow you'll use afterward.

## 1. Rename the identity strings

This project's name, npm scope, and repository owner are baked into more places than a fork owner should
have to hunt down by hand: `package.json`, every `packages/*/package.json`, `tsconfig.base.json`'s custom
condition, `openspec/config.yaml`, the live OpenSpec capability directory, and several docs. Run the
rename command instead of editing them one at a time:

```bash
npm run rename -- <new-name>
```

`<new-name>` must be lowercase kebab-case (e.g. `my-project`). The command reads your current name and
owner from `package.json`, rewrites every tracked file and file/directory name that references them, and
finishes by running `npm install` to regenerate `package-lock.json` — so a broken rename fails immediately
instead of surfacing later as a confusing build error. Pass `--owner <owner>`, `--title <title>`, or
`--description <description>` to change those too; run `npm run rename -- --help` for the full option
list. The command refuses to run on a dirty git worktree and is safe to re-run.

If your repository's default branch is not `main`, pass `--default-branch <branch>` as well. It rewrites
the CI workflow's push trigger, the one place the branch is named literally; the pre-commit hook and
`scripts/pr.sh` detect the default branch from the remote (`scripts/default-branch.sh`) and need no edit.
The command does not rename the git branch itself.

`README.md`'s title and opening description aren't identity strings the command can infer generically —
update those by hand to describe your actual project.

## 2. Replace the teaching examples

`packages/hello` and `packages/greeter` are deterministic, dependency-linked example libraries built to
teach the repository's structure — not a foundation to build a real project on. Every tracked file meant to
be replaced or substantially adapted carries a literal `TEMPLATE:REPLACE` marker comment. Find them all:

```bash
grep -rn TEMPLATE:REPLACE packages/
```

Replace `packages/hello`'s implementation and test with your first domain capability, and either replace
`packages/greeter` with your second capability (keeping the same dependency-on-the-first pattern) or delete
it if your project doesn't need a second package yet. Update `openspec/specs/repository-foundation/spec.md`
to describe your capability's actual contract instead of `greet`/`announce`. `npm run check`'s convention
check looks at every package's `src/index.ts` and `src/index.test.ts` pair and fails only when the two
disagree on whether the marker is still present — replacing both together (removing the marker from both)
passes cleanly, and the check needs no edit once `hello` is gone.

The task planner (`packages/task-graph`, `packages/task-sched`, and `apps/planner`) is different. It's a
working capability with its own accepted spec, `openspec/specs/task-scheduling/spec.md`, not a teaching
fixture, so it carries no `TEMPLATE:REPLACE` marker. Keep it if your project can use a dependency-ordered
task planner. To drop it, treat the removal like any other behavior change: propose it as an OpenSpec change
so the spec, the orientation index, and [`docs/task-scheduling.md`](docs/task-scheduling.md) go with it.

## 3. Verify the workspace

```bash
npm ci
./scripts/install-git-hooks.sh
npm run check
```

`npm run check` must pass before you build anything else. It validates specs, harness wiring, docs
freshness, secrets, formatting, types, tests, and builds, and it runs offline. CI runs that same gate plus
`./scripts/check-ci-only.sh`: the rename fixture and the dependency-advisory review, which need the
network or several seconds. `scripts/pr.sh` runs that script too, after committing and before pushing, so
a branch is never green locally and red in CI on a check it never ran. Run it by hand whenever you want
the full CI result before opening a pull request:

```bash
./scripts/check-ci-only.sh
```

## 4. Propose your first domain change

Once the workspace is clean and renamed, stop editing example code directly and start using the OpenSpec
workflow this repository is built to teach. Use the `/roadmap` command (or the `roadmap-execution` skill)
to add your first real capability, or read [`docs/repository-orientation.md`](docs/repository-orientation.md)
for the full agent loop: propose, validate, implement the smallest contract-covered slice, verify, archive.

From here, [`CONTRIBUTING.md`](CONTRIBUTING.md) and [`docs/governance.md`](docs/governance.md) govern how
work proceeds.

## Tracking upstream template updates

To keep pulling improvements from this template after you've renamed and started your own project, add it
as a second remote:

```bash
git remote add upstream https://github.com/salzayat/spec-loop.git
git fetch upstream
git merge upstream/main
```

Because `npm run rename` only rewrites real identity strings (no placeholder round-trip), an upstream merge
conflicts only on the specific lines the rename touched — file names and content mentioning the old
project name, npm scope, or owner. Resolve those conflicts by keeping your fork's renamed value; everything
else merges cleanly. The URL above is the one identity string the rename leaves alone: it is recorded as
`template.upstream` in `package.json`, and the command preserves it wherever a line names `upstream`, so a
renamed fork still points here rather than at itself. The `upstream` remote is only for pulling:
`scripts/pr.sh` resolves a pull request's repository from `origin` (or its parent, when `origin` is a
fork), so adding `upstream` never redirects your pull requests to the template.

If you imported the template as a single commit instead of forking it, there is no shared history to
merge. Record the upstream commit you imported in that commit's message, then bring later template
changes over as a patch instead:

```bash
git fetch upstream
git diff <imported-upstream-commit> upstream/main | git apply --3way
```
