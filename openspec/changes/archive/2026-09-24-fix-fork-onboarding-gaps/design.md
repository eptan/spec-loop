# Design

## Context

Every defect here was found by reading a real fork's diff against the template it imported: fourteen
template-owned files changed, and each edit was mechanical, which means the template could have made it
unnecessary. The fixes below each target the invariant the fork had to restore by hand.

## Decisions

### One script for the CI-only checks, run by `pr.sh` after the commit

The two CI-only checks stay out of `scripts/check.sh` for the reasons already recorded in their headers:
one needs the registry, the other takes several seconds and would regress the per-commit gate. The defect
is not that they are separate; it is that their list lived only in the workflow YAML, where nothing local
could run it. `scripts/check-ci-only.sh` is that list, and both the workflow and `scripts/pr.sh` call it,
so the two cannot drift.

`scripts/pr.sh` runs it after `git commit` rather than before, because `scripts/test-rename.sh` archives
`HEAD`: run before the commit it would test the previous commit's rename script, not the one being
submitted. Running after the commit and before the push keeps the "nothing red reaches GitHub" property.
On failure the script does `git reset --soft HEAD~1` and clears `committed`, which returns the worktree to
the state a `scripts/check.sh` failure leaves: changes staged, branch present. The existing cleanup trap
then unstages and deletes a branch this run created, so the accepted "A failed run can be retried without
manual cleanup" scenario holds for this failure too, and a `--reuse-branch` run keeps its branch as before.

### Detect the default branch instead of parameterizing it

The pre-commit hook and `scripts/pr.sh` need the branch at run time, in a clone that has a remote, so
detection is both possible and free: `origin/HEAD` is set by `git clone`, and the `main`/`master` fallback
covers a fresh `git init` plus `git remote add`, which never sets it. The fixture in
`scripts/test-pr-fork.sh` is exactly that fallback case (a clone of an empty bare repository, then a push),
and it now runs one case on `main` and one on `master` so the detection, not a default, is what the
assertion proves. The CI workflow cannot detect anything at trigger time, so it keeps a literal branch and
the rename command gains `--default-branch` to rewrite it. Docs say "the default branch" rather than a
name, which is what the accepted `workflow-governance` scenario already said.

### Protect the upstream URL by a recorded value and a line address, not by excluding a file

The rename command cannot tell the upstream URL from the fork's own `repository.url`: both contain
`<owner>/<name>`. Excluding `TEMPLATE.md` from the rename would leave its other identity strings stale.
Recording the URL once, as `template.upstream` in `package.json`, gives the command a value it can protect
with the same placeholder round-trip it already uses for archived change ids. The placeholder is applied
only on lines that name `upstream`, which is true of the `TEMPLATE.md` recipe line and of the
`package.json` field, and false of the `repository`, `bugs`, and `homepage` lines that must still be
rewritten; the fixture asserts both halves. A repository without the field behaves exactly as before.

### A conventions check that discovers packages

The check's purpose is to catch a half-finished replacement, where one file of a pair was updated and the
other was not. That purpose does not depend on the pair being `packages/hello`; it applies to every
`src/index.ts` and `src/index.test.ts` pair under `packages/`, including `greeter` today and a fork's own
packages tomorrow. The only thing the old check protected beyond that was the existence of an example
library, which the new check keeps as "at least one tested pair exists" without naming it.

### `--default-branch` without a rename is allowed

A fork owner may have renamed already and only later discovered the workflow still names `main`. The early
"nothing to rename" exit therefore yields when `--default-branch` is given, the content rewrite runs only
when the identity changed, and the file-rename passes run only when the name changed, because `git mv`
refuses to move a path onto itself.

## Risks

- **`scripts/pr.sh` now takes several seconds longer and needs the registry before pushing.** It already
  needs the network to push and to call `gh`, and the cost is paid once per pull request, not per commit.
  `--skip-checks` remains the documented escape hatch and now names both scripts in the PR body.
- **The `upstream` line address is a convention, not a guarantee.** A future line that names `upstream` and
  contains the URL for another reason would be preserved too. The fixture would not catch that, but such a
  line would also be one the template intends to preserve.
- **`origin` is assumed to be the remote of record.** A clone with a differently named remote falls through
  to the `main`/`master` probe, which still matches every repository this template has produced so far.
