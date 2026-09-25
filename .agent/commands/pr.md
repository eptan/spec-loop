---
description: /pr creates a guarded commit and pull request using scripts/pr.sh, then returns to the starting branch.
agent: build
---

Create a commit and pull request for the current work using `scripts/pr.sh`.

This project command is invoked exactly as `/pr`. Do not require or suggest a dotted command name, namespace, or extra prefix.

User arguments:

```text
$ARGUMENTS
```

Workflow:

1. Load the `pull-request-automation` skill.
2. Inspect the current branch, `git status --short`, `git diff`, `git diff --staged`, and `git log --oneline -10`.
3. Use the current session context and the inspected diff to choose a meaningful conventional commit message and PR title/body.
4. If the user supplied explicit `scripts/pr.sh` flags in `$ARGUMENTS`, preserve them unless they would commit secrets, generated data, or the wrong files.
5. If required flags are missing, infer safe values from the session and diff when possible:
   - `--type`: one of `feat`, `fix`, `docs`, `test`, `refactor`, `chore`, `ci`
   - `--scope`: concise repo area, for example `repo`, `governance`, `openspec`, or a package name
   - `--message`: imperative summary based on the actual changes
   - `--branch`: kebab-case branch name based on the message
6. Ask one concise question if the intended files or PR base branch are ambiguous.
7. If the current branch (from step 2) is already a feature branch, not the default branch, pass that branch to
   `--branch` with `--reuse-branch` so the script continues on it instead of requiring a fresh one.
8. Run `./scripts/pr.sh` with either explicit file paths after `--` or `--all` only when the user clearly wants all current changes included.
9. Ensure the script stays on the PR branch until `gh pr create` completes.
10. Report the PR URL and confirm the final branch after the script completes.

Do not commit, push, or create a PR unless the user explicitly requested PR automation in this command invocation. Do not use `--skip-checks` unless the user explicitly requested it or a documented local tooling outage blocks checks.
