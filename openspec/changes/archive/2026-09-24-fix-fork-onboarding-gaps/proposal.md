# Fix Fork Onboarding Gaps

## Dependencies

None.

## Why

A fork of this template (a private habit-tracking project, forked 2026-09-24) went from the teaching
examples to eight archived domain changes in one day, so the loop itself held. An audit of that fork found
that nearly every adaptation cost landed in the same few template-owned files, and that each cost is a
template defect rather than a fork decision:

1. **The local gate is not the CI gate, but the docs say it is.** `TEMPLATE.md:59-61` and `AGENTS.md`'s
   Verification section both describe `npm run check` as the gate CI runs. `.github/workflows/check.yml:39-42`
   runs two more steps after it, `scripts/test-rename.sh` and `scripts/check-dependency-advisories.sh`, and
   `scripts/pr.sh:260-264` runs only `scripts/check.sh` before opening a pull request. In the fork, every CI
   run on its two domain pull requests and on the merge to its default branch failed on the advisory step
   while both PR bodies truthfully reported `npm run check` exit 0. The list of CI-only steps exists only
   inside the workflow file, so nothing local can run it.
2. **The rename command rewrites the upstream URL to the fork itself.** `scripts/rename-project.sh`
   substitutes `<owner>/<name>` in every tracked file, and `TEMPLATE.md:79`'s
   `git remote add upstream https://github.com/salzayat/spec-loop.git` contains exactly that string. After
   the fork's rename, its `TEMPLATE.md` told its owner to track `eptan/edb`, defeating the one section of the
   page that is meant to outlive the rename. The command has no way to know which occurrence is the
   upstream reference.
3. **The default branch is hard-coded as `main` in six places.** `.githooks/pre-commit:8`,
   `scripts/pr.sh:41`, `.github/workflows/check.yml:6`, `scripts/test-pr-fork.sh:56`, `AGENTS.md`, and
   `CONTRIBUTING.md` all name `main`. The accepted `workflow-governance` scenario "Direct commit to the
   default branch fails closed" is written in terms of the default branch, but the hook that implements it
   compares against the literal `main`, so a fork on `master` had no protection until it edited the hook,
   and `scripts/pr.sh` would have opened its pull requests against a branch that did not exist.
4. **Step 2 of `TEMPLATE.md` cannot be completed without editing a governance script.**
   `scripts/check-repository-conventions.sh:11-24` requires `packages/hello/src/index.ts` and its test to
   exist by name. The guide's own step 2 says to replace `packages/hello`; the fork had to patch the script
   to name its first package instead, and the marker check it carries forward now looks for a marker that
   file will never have. `scripts/pr.sh:12` and `.agent/commands/pr.md` also cite `greeter` as a scope
   example, which stops meaning anything once the example is gone.
5. **A squash import has no upstream to merge.** `TEMPLATE.md`'s upstream-tracking section assumes shared
   git history. The fork imported the template as one commit, which is a reasonable way to start a private
   project, and the documented `git merge upstream/main` cannot apply to it. The guide offers no other path.

## What Changes

- Add `scripts/check-ci-only.sh`, the single definition of the checks CI runs beyond `scripts/check.sh`
  (the rename fixture and the dependency-advisory review). `.github/workflows/check.yml` calls it instead
  of listing the steps itself, and `scripts/pr.sh` runs it after the commit and before the push, undoing
  the commit and leaving the changes staged when it fails so the run stays retryable exactly as a
  `scripts/check.sh` failure does. `--skip-checks` skips it too and the generated PR body says so.
- Add `scripts/default-branch.sh`, which resolves the default branch from `origin/HEAD`, then a `main` or
  `master` branch, then `main`. `.githooks/pre-commit` refuses commits on whatever it returns, and
  `scripts/pr.sh` uses it as the default `--base`. `scripts/test-pr-fork.sh` runs its two cases on `main`
  and `master` and asserts each pull request targets the detected branch.
- Give `scripts/rename-project.sh` a `--default-branch <branch>` option that rewrites the CI workflow's
  push trigger, the one remaining literal mention, and make it preserve the upstream template URL recorded
  as `template.upstream` in `package.json` on every line that names `upstream`. `scripts/test-rename.sh`
  asserts both, and accepts `RENAME_FIXTURE_TREE` so the rename script can be tested before it is committed.
- Make `scripts/check-repository-conventions.sh` apply the `TEMPLATE:REPLACE` agreement check to every
  `packages/*/src/index.ts` and `index.test.ts` pair and require only that at least one such pair exists,
  so replacing or removing `packages/hello` needs no script edit. Replace the `greeter` scope examples in
  `scripts/pr.sh` and `.agent/commands/pr.md` with generic ones.
- Correct the gate description in `TEMPLATE.md`, `README.md`, `AGENTS.md`, `CONTRIBUTING.md`,
  `docs/dependency-advisories.md`, and the `pull-request-automation` skill; say "the default branch" where
  `AGENTS.md`, `CONTRIBUTING.md`, the `/pr` command, and that skill said `main`; document
  `--default-branch`, the preserved upstream URL, and a patch-based recipe for squash imports in
  `TEMPLATE.md`.

## Non-Goals

- No change to which checks `scripts/check.sh` runs or to its offline, per-commit property; the CI-only
  checks stay out of it for the reasons each script's header states.
- No attempt to collapse a fork's inherited template history (the 25 archived template changes, the
  template-only specs, or roadmap rows such as "Fork rename automation"). That is a larger design decision
  about which accepted capabilities a fork may retire, and it needs its own change.
- No change to `scripts/check-docs.sh`'s local behavior of skipping when nothing is staged.
- No rename of the git branch itself by `--default-branch`; it rewrites the workflow trigger only.
