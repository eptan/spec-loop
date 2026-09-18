# Automate OpenSpec Archiving

## Dependencies

None.

## Why

`scripts/check-openspec-archive.sh` already requires every OpenSpec change with a fully checked
`tasks.md` to be archived before its PR can merge (`npm run check` fails otherwise) — so archiving a
completed change was never actually optional, only manual. In practice this meant an agent or contributor
had to remember to run `openspec archive <name> --yes` (or `/archive-change`) as a separate step before
every PR that closed out a change, purely to satisfy a gate that was going to require it anyway. The user
named this directly: "specs are not archiving when their closing PRs are created."

There is no automation linking a PR's creation or merge to archiving today. `scripts/pr.sh` stages,
checks, commits, and pushes; nothing in that path, or anywhere in CI, ever calls `openspec archive`.

## What Changes

- Extract the "which active changes are fully complete but unarchived" detection already in
  `check-openspec-archive.sh` into a new, shared `scripts/list-completed-changes.sh`, and have
  `check-openspec-archive.sh` call it instead of duplicating the logic inline.
- `scripts/pr.sh`: before staging, run `scripts/list-completed-changes.sh` and archive every change it
  lists automatically (`npm exec openspec -- archive <name> --yes`). This does not lower the bar for what
  counts as "done" — it automates a step that was already mandatory for the PR to merge, using the exact
  same detection the merge gate itself relies on, so nothing gets archived that the gate would not already
  have required.
- Stage the resulting archive output (`openspec/changes/archive/**`, updated `openspec/specs/**`)
  regardless of whether the caller passed `--all` or explicit file paths, since it is a required part of
  the commit once produced, not an optional extra.
- State which changes were auto-archived in the generated PR body's `## OpenSpec` section when the caller
  did not supply an explicit body.
- Note the automation in `AGENTS.md` next to the existing "archive only when complete" rule, and in the
  `pull-request-automation` skill's list of what the script is responsible for.

## Non-Goals

- No change to what makes a change eligible for archiving — still exactly "every task in `tasks.md` is
  checked," the same signal `check-openspec-archive.sh` already enforces. Checking a task box remains the
  one action that must only happen once the work is genuinely verified; this change does not add or relax
  any verification step, it removes a manual invocation of a step that was already required.
- No archive-on-merge automation (a GitHub Action or bot committing to `main` after the fact). Branch
  protection already requires every change to land through a PR with a passing `quality` check, and a
  completed-but-unarchived change cannot pass that check — so by the time anything merges, archiving has
  already happened via `pr.sh`. A post-merge bot would also have nothing to commit to (`main` disallows
  direct pushes) without opening a second PR, which trades one manual step for a more awkward one.
- No change to `/archive-change` or the `openspec-lifecycle` skill — both remain available for archiving a
  change without immediately opening a PR.
