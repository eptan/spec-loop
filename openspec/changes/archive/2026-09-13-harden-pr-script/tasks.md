# Tasks

## 1. Fix the PR body command injection

- [x] 1.1 Replace the unquoted heredoc building `pr_body` with `printf '%s'`-style templating in
      `scripts/pr.sh`, preserving the exact rendered template text.

## 2. Make a failed run idempotent

- [x] 2.1 Add `created_branch` and `committed` state flags; set `created_branch=true` only when this run
      creates a new branch, and `committed=true` only immediately after a successful `git commit`.
- [x] 2.2 Extend the exit trap: when `committed` is not true, run `git reset` and, only when
      `created_branch` is true, `git branch -D "$pr_branch"`.
- [x] 2.3 Remove the redundant second `require_branch "$pr_branch"` call.

## 3. Update the contract

- [x] 3.1 Apply the `workflow-governance` delta: PR body construction MUST treat every interpolated value
      as literal text unconditionally, and a failed run MUST leave the repository in a state where the
      identical command can be re-run without manual git surgery.

## 4. Verification

- [x] 4.1 Templating test: run a scratch harness calling the same body-construction line with a
      `--message` containing `` `touch /tmp/pwned` `` and `$(touch /tmp/pwned2)`; confirm no file is
      created and the literal text appears in the rendered body — both before and after this change, since
      the original unquoted heredoc was found not to be exploitable via variable content on reproduction
      (documented in `design.md`). The test guards the property going forward regardless of how the
      template's static text changes later.
- [x] 4.2 Idempotency test: force `check.sh` to fail (e.g. a throwaway unformatted file), run `pr.sh`,
      confirm it fails, then confirm `git status --porcelain` shows nothing staged and the created branch
      no longer exists; re-run the identical command after removing the throwaway file and confirm it
      succeeds.
- [x] 4.3 Reused-branch safety: confirm a branch that existed before the run (with `--reuse-branch`) is
      never deleted by the new cleanup path, whether or not this run commits.
- [x] 4.4 Run `npm run check` and record the result in the PR.
