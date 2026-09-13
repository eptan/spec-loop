# Design

## Context

`scripts/pr.sh` is the only sanctioned path to a commit and PR in this repo (`AGENTS.md`'s "Pull
Requests" section, the `pull-request-automation` skill). Both defects were introduced by choices that were
reasonable for the happy path but wrong under failure or adversarial input, so the fix targets each
precisely rather than restructuring the script.

## Decisions

### `printf` templating over an unquoted heredoc

Reproduced directly on this repo's `/bin/sh` (bash in POSIX mode) before writing this fix: a `--message`
value containing `$(touch /tmp/x)` or backticks, substituted into the original unquoted heredoc via
`${summary}`, does not execute — parameter expansion inside a heredoc substitutes a variable's value once
and does not rescan that value for command substitution. The claim that raised this finding does not hold
for variable content. What an unquoted heredoc _does_ re-interpret is literal backticks or `$()` written
directly in the template's own static text (there are none today), so the construct was safe only because
the template happens not to contain them — not because the construct is safe by design. `printf '%s'`
removes that dependency: every interpolated value is literal text unconditionally, and no future edit to
the static template text changes that. A quoted heredoc (`<<'EOF'`) was considered and rejected because it
would also stop the intended `${summary}` parameter expansion, which is the entire point of the template.

### Idempotent cleanup keyed on `committed`, not on which check failed

The trap cannot know _why_ `check.sh` failed, only _whether_ a commit happened. Keying cleanup on
`committed` (set only immediately after `git commit` succeeds) rather than on exit code or which check ran
means the same cleanup logic is correct whether the script died on `check-secrets.sh`, `check.sh`, a push
failure that happens before commit is impossible by construction (push happens after commit), or a
Ctrl-C. The only case cleanup must not touch is a reused branch (`created_branch=false`) — reusing
`--reuse-branch` on a branch with real prior commits must never be deleted just because _this_ run didn't
commit anything new.

### Why deletion is safe when `created_branch=true` and `committed=false`

If this run created the branch via `git switch -c`, the branch points at the same commit as
`start_branch` — nothing has been committed to it yet by definition of `committed=false`. Deleting it
loses nothing; the working-tree changes are untouched (`git branch -D` only removes the ref, not the
files), and `git reset` (also run in this path) returns the index to unstaged so the next attempt starts
from a clean, stageable state identical to before the first attempt.

## Risks

- **A different tool (not `pr.sh`) staged something on `start_branch` before this run began.** `git reset`
  runs unconditionally in the cleanup path when `committed=false`, which would unstage that too. This is
  an accepted, narrow risk: the branch-first workflow (`AGENTS.md`'s "Pull Requests" section) already
  expects the feature branch to be created before implementation, so `start_branch` should not carry
  unrelated staged work when `pr.sh` runs.
