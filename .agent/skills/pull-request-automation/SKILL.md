---
name: pull-request-automation
description: Use when creating commits or pull requests with scripts/pr.sh, /pr, gh pr create, or PR automation; uses session context and git diffs to write meaningful commit messages and PR bodies.
---

# Pull Request Automation

Use this skill when the user asks to create a commit, push a branch, open a pull request, run `/pr`, or automate PR creation. The OpenCode command name is exactly `/pr`; do not require a dotted command name, namespace, or extra prefix.

Implementation for a pull request should already be happening on a feature branch, created before file
changes began — not on `main`. If a branch already exists when this skill runs, pass `--reuse-branch` so
the script continues on it instead of requiring a fresh one.

## Source Of Truth

Use `scripts/pr.sh` for execution. Do not hand-roll a separate Git/GitHub workflow unless the script is missing or broken and the user approves a fallback.

The script is responsible for:

- archiving any OpenSpec change with every task checked, automatically, before staging
- staging explicit files or `--all`
- running secret checks
- running repository checks unless skipped explicitly
- committing
- pushing
- creating the pull request
- staying on the PR branch until `gh pr create` completes
- restoring the branch that was current at script startup

## Build Meaningful Commit And PR Text

Before running the script, derive the commit message, branch name, PR title, and PR body from evidence.

Use these inputs:

- the current session context, including the user's stated goal and important implementation decisions
- `git status --short`
- `git diff` for unstaged changes
- `git diff --staged` for staged changes
- `git log --oneline -10` for repository commit style
- verification output from checks already run in the session
- relevant OpenSpec tasks or requirements touched by the change

Do not use generic summaries such as `update files`, `misc changes`, or `fix stuff`. Name the actual behavior or governance change.

Good examples:

```text
chore(repo): add guarded pull request automation
docs(governance): document commit and pr workflow
feat(greeter): compose greeting from the hello package
```

Bad examples:

```text
chore: update
fix: changes
docs(repo): misc
```

## PR Body Requirements

The PR body should include:

- Summary: bullets describing the actual changes
- Verification: commands run and whether they passed or were blocked
- Risk/notes: skipped checks, local tooling outages, generated artifacts, data/report changes, or OpenSpec implications

Use the session log/context to mention important blocked checks accurately. For example, if `uv` is unavailable, state that Python checks were blocked because `uv` was not installed; do not claim they passed.

## File Selection

Prefer explicit file paths when the worktree contains unrelated changes. Use `--all` only when the user clearly wants all current changes included and the status review confirms there are no unrelated or unsafe files.

Never include:

- `.env` or local secret files
- raw or normalized market data
- generated `runs/`
- credentials in fixtures or logs
- final-holdout outputs unless explicitly approved and compliant with the spec

## Branch Restoration

The automation must remain on the PR branch through commit, push, and `gh pr create`. It should only restore the starting branch after PR creation completes or after a failure path exits.

After running `scripts/pr.sh`, check and report the final branch with `git branch --show-current`. The expected final branch is the branch that was current before the script started.

If branch restoration fails, stop and report the exact branch state. Do not attempt destructive recovery.

## Safety Rules

- Only commit, push, or create a PR after explicit user intent.
- Inspect `git status`, `git diff`, and recent commits before committing.
- Do not amend, force-push, skip hooks, or use interactive Git commands unless explicitly requested.
- Do not bypass checks with `--skip-checks` unless the reason is documented in the PR body.
- If the script fails after switching branches, rely on its trap first, then verify the branch.
