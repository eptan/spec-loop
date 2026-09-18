# workflow-governance Specification

## MODIFIED Requirements

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
commit regardless of whether the caller staged all changes or named explicit paths.

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
