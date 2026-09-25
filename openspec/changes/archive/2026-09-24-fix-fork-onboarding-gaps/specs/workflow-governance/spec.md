# workflow-governance Specification

## ADDED Requirements

### Requirement: The default branch is detected, not hard-coded

The pre-commit hook and the PR automation MUST determine the repository's default branch at run time from
the repository itself (the remote's recorded HEAD, falling back to a branch named `main` or `master`)
rather than from a literal branch name in either script, so a fork that adopts a different default branch
keeps the same guardrails without editing them. Repository guidance MUST refer to "the default branch"
rather than to a specific name.

#### Scenario: A fork on master is protected by the hook

- GIVEN a repository whose default branch is `master` and whose hooks are installed
- WHEN a contributor runs `git commit` with `master` checked out
- THEN the commit is rejected with a message naming `master` and the feature-branch remedy
- AND a commit on a feature branch of that repository is not rejected for its branch

#### Scenario: The PR helper targets the detected default branch

- GIVEN a repository whose default branch is `master` and no `--base` argument
- WHEN a contributor runs the PR helper
- THEN the pull request is opened against `master`
- AND an explicit `--base` still overrides the detected branch

### Requirement: PR automation runs the CI-only checks before pushing

When checks are enabled, the PR automation MUST run the repository's CI-only check script after creating
the commit and before pushing it. If that script fails, the automation MUST undo the commit while leaving
the changes staged and the branch in place, so the identical command can be re-run after the cause is
fixed, and the existing failure cleanup MUST apply as for any failure before a commit. When checks are
skipped, the generated pull-request body MUST name the CI-only script among the skipped checks.

#### Scenario: A CI-only failure undoes the commit and leaves the run retryable

- GIVEN the local quality gate passes and the CI-only check script fails
- WHEN the PR helper runs with checks enabled
- THEN no commit remains on the branch and nothing is pushed
- AND the changes are staged again, and a branch created by this run is removed by the existing cleanup

#### Scenario: Skipping checks is recorded for both scripts

- GIVEN the PR helper runs with `--skip-checks`
- WHEN it generates the default pull-request body
- THEN the skipped-checks section names both the local gate and the CI-only script
