# Design

## Context

`check-openspec-archive.sh` already made "a completed change must be archived before merge" a hard
requirement — CI enforces it, and this session hit that exact gate repeatedly, always resolving it by
running `openspec archive` by hand before invoking `pr.sh`. The user's report is accurate as a description
of the workflow, not of a broken invariant: the merge gate was never bypassable, only the _automation_ of
satisfying it was missing.

## Decisions

### Detection lives in one script, called from two places

`check-openspec-archive.sh`'s Python block (`totalTasks > 0 and completedTasks == totalTasks`) and the new
auto-archive step in `pr.sh` need the identical list. Extracting it into
`scripts/list-completed-changes.sh` means the merge gate and the automation that satisfies it can never
disagree about what counts as "complete" — a future change to the completion rule only needs to happen in
one place.

### `pr.sh` is the automation point, not a post-merge bot

Considered and rejected: a GitHub Action that archives after a PR merges. Two problems make this worse,
not better. First, it has nothing to commit to — `main` requires a PR (branch protection, `enforce_admins:
true`), so a bot discovering an unarchived-but-complete change after merge would need to open a _second_
PR just to archive it, and that second PR's own `quality` check would then need a human or another bot to
merge it, an infinite regress the manual step never had. Second, it cannot actually occur under the current
gates: `check-openspec-archive.sh` already blocks a merge if a completed change isn't archived, so nothing
reaches `main` in the state a post-merge bot would need to react to. `pr.sh` is the only point in the
workflow where "about to satisfy the merge gate" and "have write access to the branch" coincide, which is
why it's the automation point.

### Archiving before staging, not after

`openspec archive` writes files (moves the active change directory into `openspec/changes/archive/`,
updates `openspec/specs/<capability>/spec.md`). Running it before the staging step means those writes are
just more files on disk when `git add -A` or the explicit-paths loop runs — no special-casing needed for
the `--all` path. The explicit-paths path does need one addition (`git add -- openspec/` after archiving)
because a caller who names specific files never listed `openspec/changes/archive/**` or
`openspec/specs/**`, and those are not optional once produced.

### The archive loop uses `for`-with-`IFS`, not pipe-into-`while` — found by running the real script, not just an isolated test

The first draft used `printf '%s' "$completed_changes" | while IFS= read -r name; do ...; done`. In
isolation (a standalone `set -eu` script, and inside a throwaway fixture repository), that pattern worked
correctly — a failing command inside it aborted the whole script under both this system's `/bin/sh` (bash
in POSIX mode) and `dash` (Ubuntu's `/bin/sh`, what CI runs). But running the real, complete `pr.sh` end to
end against this repository's actual working tree — not a fixture — surfaced a different failure mode:
`completed_changes` was correctly non-empty, the `if` block was entered, and yet the `while read` loop
ran zero iterations, with no error and no output from the loop body at all. Added explicit debug tracing
directly in `pr.sh` to confirm this rather than guess, then reproduced it twice. The isolated tests hadn't
been wrong about `set -e` semantics; something about the pipe's read end was empty by the time the loop
started consuming it in this script's fuller context, and that difference never showed up in a smaller
reproduction. Rather than keep chasing the discrepancy, switched to the `for change_name in $completed_changes`
form with `IFS` temporarily set to newline-only — the same pattern already proven reliable elsewhere in
this exact codebase this session (`check-docs.sh`, `check-secrets.sh`, `rename-project.sh`'s content-rewrite
loop) — and confirmed it archives correctly on the first real run. The pre-existing, structurally identical
`printf '%s' "$paths" | while IFS= read -r path; do git add -- "$path"; done` a few lines below (staging
explicit paths) was converted to the same `for`/`IFS` form for the same reason: it is the same fragile
construct in the same file, and this change is already touching that code.

### The PR body states what was auto-archived, rather than staying silent

Silently archiving a change and only showing it in the diff is technically sufficient, but the whole point
of raising this was to remove _manual_ toil, not visibility. Naming the auto-archived change(s) in the
default PR body's `## OpenSpec` section (only when the caller didn't supply an explicit body) makes the
automation self-documenting in the artifact a reviewer actually reads.

## Risks

- **An agent checks every task box before work is genuinely verified, and the automation archives
  prematurely.** Not a new risk — `check-openspec-archive.sh` already treats "all tasks checked" as the
  completion signal, and `AGENTS.md`/`openspec-lifecycle` already require a task be checked only once
  verified. This change does not weaken that signal or add a new one; it only removes the manual
  invocation of an already-mandatory step.
- **A change fails to archive due to a real spec-delta problem (as reproduced during this change's own
  verification — a dropped scenario).** Correct, intended behavior: the script aborts via `set -e`, the
  existing failure-cleanup trap unstages and removes any branch this run created, and the underlying
  problem (the spec delta itself) is surfaced to the caller rather than silently skipped.
