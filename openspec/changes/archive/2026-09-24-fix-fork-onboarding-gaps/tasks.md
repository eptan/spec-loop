# Tasks

## 1. One definition of the CI-only checks

- [x] 1.1 Add `scripts/check-ci-only.sh` running `scripts/test-rename.sh` and
      `scripts/check-dependency-advisories.sh`, with a header saying why they stay out of `check.sh`.
- [x] 1.2 Replace the two named steps in `.github/workflows/check.yml` with one step calling it.
- [x] 1.3 In `scripts/pr.sh`, run it after `git commit` and before the push when checks are enabled; on
      failure `git reset --soft HEAD~1`, clear `committed`, and die with a message saying the changes are
      staged again. Make `--skip-checks` skip it and name both scripts in the generated PR body.
- [x] 1.4 Stub `check-ci-only.sh` in `scripts/test-pr-fork.sh`'s fixture.

## 2. Detect the default branch

- [x] 2.1 Add `scripts/default-branch.sh` (origin/HEAD, then `main` or `master` as a remote-tracking or
      local branch, then `main`).
- [x] 2.2 Use it in `.githooks/pre-commit` and as `scripts/pr.sh`'s default `--base`.
- [x] 2.3 Run `scripts/test-pr-fork.sh`'s maintainer case on `main` and its contributor case on `master`,
      copying `default-branch.sh` into the fixture, and assert each `gh pr create` names that `--base`.

## 3. Rename tool

- [x] 3.1 Record `template.upstream` in `package.json`.
- [x] 3.2 In `scripts/rename-project.sh`, protect that value with a placeholder on lines naming `upstream`
      before the identity substitutions and restore it after them.
- [x] 3.3 Add and validate `--default-branch <branch>`; rewrite the `branches: [...]` push trigger in
      `.github/workflows/check.yml`; allow the option without an identity change; skip the file-rename
      passes when the name is unchanged.
- [x] 3.4 In `scripts/test-rename.sh`, pass `--default-branch trunk` and assert the upstream URL survives in
      `TEMPLATE.md` and `package.json`, `repository.url` was still renamed, and the trigger names `trunk`.
      Accept `RENAME_FIXTURE_TREE` so an uncommitted rename script can be tested before it is committed.

## 4. Conventions check and scope examples

- [x] 4.1 Rewrite `scripts/check-repository-conventions.sh` to check marker agreement for every
      `packages/*/src/index.ts` and `index.test.ts` pair, naming the package in the failure, and to require
      at least one such pair.
- [x] 4.2 Replace the `greeter` scope examples in `scripts/pr.sh` and `.agent/commands/pr.md`.

## 5. Docs

- [x] 5.1 `TEMPLATE.md`: `--default-branch` in step 1, the generic marker check in step 2, the accurate gate
      description plus `check-ci-only.sh` in step 3, the preserved upstream URL and the squash-import patch
      recipe in the upstream section.
- [x] 5.2 `README.md` and `AGENTS.md`: describe `npm run check` as the local gate CI runs plus
      `check-ci-only.sh`; add the script to the README command table.
- [x] 5.3 `CONTRIBUTING.md`, `.agent/commands/pr.md`, the `pull-request-automation` skill, and
      `docs/dependency-advisories.md`: say "the default branch", name `check-ci-only.sh` where the PR
      helper's steps are listed.

## 6. Contract

- [x] 6.1 Apply the deltas under `specs/` for `ci-governance`, `workflow-governance`,
      `template-rename-tooling`, and `repository-planning`.

## 7. Verification

- [x] 7.1 `./scripts/test-pr-fork.sh` passes with the `main` and `master` cases.
- [x] 7.2 `RENAME_FIXTURE_TREE=$(git write-tree) ./scripts/test-rename.sh` passes against the working tree; a
      rename with `--default-branch develop` only, on an already-named tree, exits 0, changes only the
      workflow trigger, and is a no-op on a second run; `a..b`, `trailing/`, `-lead`, and `x.lock` are
      refused before any file changes.
- [x] 7.3 `./scripts/default-branch.sh` prints `main` here and `master` in a clone whose `origin/HEAD` is
      `master`.
- [x] 7.4 Conventions check: both markers present passes, both absent passes, one absent fails naming the
      package.
- [x] 7.5 `.githooks/pre-commit` refuses a commit on the detected default branch and allows one elsewhere.
- [x] 7.6 `npm exec openspec -- validate fix-fork-onboarding-gaps --strict` passes.
- [x] 7.7 `npm run check` and `./scripts/check-ci-only.sh` pass.
- [x] 7.8 Record the exact output of 7.7 in the pull request.
