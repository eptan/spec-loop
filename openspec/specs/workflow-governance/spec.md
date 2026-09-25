# workflow-governance Specification

## Purpose

Govern the executable parts of the contribution workflow: PR automation must pass body content literally
and dependency updates must be checked for readiness before merge, so contributors and agents get the same
guardrails whether they run `scripts/pr.sh` by hand or through an agent command.

## Requirements

### Requirement: PR automation preserves literal body content

The PR automation MUST support reading a pull-request body from an explicit file path and MUST pass its
contents literally, including Markdown backticks and OpenSpec change names. Inline body input and file body
input MUST be mutually exclusive. A missing or unreadable body file MUST fail before commit or push. The
generated default body MUST be built with a mechanism (such as `printf`-style templating) that treats
every interpolated value as literal text unconditionally, rather than a mechanism whose safety depends on
the template's own static text never containing a shell metacharacter. A run that fails before a commit is
created MUST leave the repository in a state where the identical command can be re-run without manual
cleanup: any branch created by that run MUST be removed and any staged changes MUST be unstaged, unless the
branch existed before the run began. Before staging, the automation MUST archive every active OpenSpec
change whose tasks are fully complete, using the same completion detection the pre-merge archive-
completeness gate relies on, so a completed change never has to be archived as a separate manual step
before its closing pull request can be created. The archive output MUST be staged as part of the same
commit regardless of whether the caller staged all changes or named explicit paths. When the current user has no write access to the repository, the automation MUST push the branch to a fork of it owned by that user, creating the fork when it does not exist, and MUST open the pull request against the upstream repository with the fork's branch as its head; it MUST NOT attempt a push to the repository itself that the user's permissions cannot satisfy. A user with write access MUST continue to push to the repository directly.

#### Scenario: Markdown body survives PR automation

- GIVEN a body file contains backticks, shell-looking text, and an OpenSpec change name
- WHEN the contributor runs the PR helper with that body file
- THEN the created pull request receives the exact file contents
- AND the helper does not execute or expand the body contents

#### Scenario: Direct commit to the default branch fails closed

- GIVEN the repository's default branch is checked out
- WHEN a contributor or agent runs `git commit` with the repository's hooks installed
- THEN the commit is rejected with a message naming the feature-branch remedy
- AND no commit is created

#### Scenario: PR automation on an existing feature branch is unaffected

- GIVEN a feature branch was already created before implementation began
- WHEN the contributor runs the PR helper with `--reuse-branch`
- THEN it continues on that branch, stages, checks, commits, and pushes as before

#### Scenario: Generated body text is always literal regardless of the static template

- GIVEN a `--message` value contains a command substitution or backtick sequence
- WHEN the PR helper builds its default body from that value
- THEN the rendered body contains the literal text
- AND this holds independent of whether the template's own static text later gains a literal backtick or
  `$()` sequence

#### Scenario: A failed run can be retried without manual cleanup

- GIVEN the PR helper creates a new branch, stages changes, and the quality gate then fails
- WHEN the run exits without creating a commit
- THEN the created branch no longer exists and the staged changes are unstaged
- AND running the identical command again, after fixing the failure, succeeds

#### Scenario: A reused branch is never deleted by failure cleanup

- GIVEN a branch already existed before this run, invoked with `--reuse-branch`
- WHEN this run fails before creating a commit
- THEN the branch is not deleted

#### Scenario: A completed change is archived automatically before its closing PR

- GIVEN an active OpenSpec change has every task in `tasks.md` checked
- WHEN a contributor runs the PR helper for any change, including one unrelated to that OpenSpec change
- THEN the helper archives the completed change before staging
- AND the archive output is included in the resulting commit without a separate manual archive step

#### Scenario: A failed automatic archive aborts the run instead of silently continuing

- GIVEN a completed change's OpenSpec delta is invalid (for example, it drops a scenario the accepted
  spec still has)
- WHEN the PR helper attempts to archive it automatically
- THEN the helper aborts before staging or committing
- AND the existing failure-cleanup behavior applies, the same as any other failure before a commit

#### Scenario: A contributor without write access opens a PR from a fork

- GIVEN the current user has read-only access to the repository
- WHEN the contributor runs the PR helper
- THEN the branch is pushed to the contributor's fork, which is created if it does not exist
- AND the pull request targets the upstream repository with the head `<contributor>:<branch>`
- AND no branch is pushed to the upstream repository

#### Scenario: A maintainer with write access is unaffected by fork support

- GIVEN the current user has write access to the repository
- WHEN the maintainer runs the PR helper
- THEN the branch is pushed to the repository itself, no fork is created, and the pull request head is the
  bare branch name

### Requirement: Dependency declarations are executable

Repository checks MUST validate that every active OpenSpec change declares `## Dependencies` with either
`None` or exact existing change names. A dependency MUST be considered ready only when its governing change is
archived and its required tasks and verification evidence are complete. The check MUST NOT crash when the
`openspec/changes/` directory or its `archive/` subdirectory does not yet exist; it MUST treat either
absent directory as containing no entries and report its normal pass or fail result rather than an
unhandled error.

#### Scenario: Unknown dependency fails closed

- GIVEN an active OpenSpec change names a nonexistent dependency
- WHEN the repository dependency check runs
- THEN it reports the exact missing dependency and fails

#### Scenario: Missing archive directory does not crash the check

- GIVEN a fresh checkout where `openspec/changes/archive/` does not exist yet (a fork right after
  clearing inherited history, or a new project generated from this template)
- WHEN the dependency check runs
- THEN it completes with its normal pass or fail result
- AND it does not raise an unhandled error naming an internal file path

### Requirement: Roadmap order reflects dependency readiness

Roadmap checks MUST reject a dependent change listed before an unready predecessor and MUST require `Blocked`
status when a named predecessor is not ready. A milestone MAY be `Pending` or `In progress` only when its
predecessors are ready; `Complete` remains reserved for archived changes with recorded verification.

#### Scenario: Unready predecessor blocks later work

- GIVEN roadmap change B depends on unarchived change A
- AND B appears after A but is marked `Pending`
- WHEN the roadmap dependency check runs
- THEN it reports B as blocked or drifted
- AND it does not accept B as dependency-ready

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
