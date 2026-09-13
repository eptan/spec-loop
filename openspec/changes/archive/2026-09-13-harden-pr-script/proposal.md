# Harden PR Script

## Why

An adversarial review of the repository (2026-09-13) found and reproduced two real defects in
`scripts/pr.sh`, the script every PR in this repo goes through:

1. **Heredoc-based body construction relies on subtle, shell-dependent semantics instead of an
   unambiguous one.** The default body was built with `pr_body="$(cat <<EOF ... EOF)"` — an unquoted
   heredoc delimiter. The review that raised this flagged it as a live command-injection path (a
   `--message` containing `$(...)` or backticks being executed rather than inserted literally); direct
   reproduction on this repo's `/bin/sh` (bash in POSIX mode) shows that claim does not hold — parameter
   expansion substitutes a variable's value once and does not rescan the result for further command
   substitution, so `--message` content is not actually executable today. What is real: the heredoc's
   _static template text_, not variable content, is what an unquoted heredoc actually re-interprets, so
   the safety of this construct depends on no future edit ever adding a literal backtick or `$(...)` to
   the template itself — a property that is not obvious from reading the code and holds only by
   coincidence, not by design. Moving to `printf`-style templating removes that dependency entirely: no
   interpolated value, and no future edit to the static text, can change how the result is interpreted.
2. **Non-idempotent failure state.** The script switches to the PR branch and stages before running
   `./scripts/check.sh` (`scripts/pr.sh:187`-`210` before this change). When the gate fails, `set -eu`
   trips and the exit trap switches back to `start_branch` — but the index is a single object per
   repository, not per branch, so the staged changes travel with it. The result: `start_branch` (often
   `main`, now guarded by `.githooks/pre-commit`) ends up with the whole change staged, and an empty
   feature branch is left behind. Reproduced:

   ```sh
   $ git switch -c tmp-branch && echo junk > junk.txt && git add -A && git switch main
   $ git status --porcelain
   A  junk.txt
   $ git branch --list tmp-branch
     tmp-branch
   ```

   A retry after fixing the failure has to be untangled by hand — reset the stage, delete or reuse the
   leftover branch — before the script can be run again.

## Dependencies

None.

## What Changes

- Replace the unquoted heredoc with `printf '%s'`-style templating: interpolated values are always
  literal text by construction, regardless of content, and the property no longer depends on the static
  template text staying backtick- and `$()`-free. `--body-file` (already unaffected by either form) is
  unchanged.
- Track whether this run created a new branch (`created_branch`) and whether a commit actually landed
  (`committed`). On any exit before a successful commit, the trap now also unstages (`git reset`) and,
  only if this run created the branch, deletes it (`git branch -D`) — so a failed run is idempotent and
  the exact same command can be re-run after fixing the failure, with no manual git surgery. A branch that
  already existed before this run (`--reuse-branch`) is never deleted, regardless of outcome.
- Remove the redundant `require_branch "$pr_branch"` call that ran a second time with no state change
  between it and the call immediately before it.

## Non-Goals

- No change to running checks before staging — `check-secrets.sh` and `check.sh` operate on
  `git diff --cached`, so staging must happen first; the fix is idempotent cleanup on failure, not
  reordering.
- No change to `--body-file` handling, which was already correct.
- No change to the commit subject construction (`subject="${commit_type}(${scope}): ${summary}"`), which
  is a plain assignment with no expansion risk.
