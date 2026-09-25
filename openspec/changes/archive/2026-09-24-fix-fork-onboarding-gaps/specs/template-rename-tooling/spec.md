# template-rename-tooling Specification

## ADDED Requirements

### Requirement: The rename command preserves the upstream template reference

`package.json` MUST record the upstream template repository URL as `template.upstream`. The rename command
MUST leave that value unchanged in `package.json` and in every line of a tracked file that names `upstream`,
while still rewriting the repository's own `repository`, `bugs`, and `homepage` URLs, so a renamed fork's
upstream-tracking recipe still points at the template rather than at the fork itself.

#### Scenario: The upstream-tracking recipe survives a rename

- **GIVEN** `TEMPLATE.md` quotes the `template.upstream` URL in its `git remote add upstream` line
- **WHEN** a contributor runs `npm run rename -- <new-name> --owner <new-owner>`
- **THEN** that line and `package.json`'s `template.upstream` still contain the original URL
- **AND** `package.json`'s `repository.url` names `<new-owner>/<new-name>`

### Requirement: The rename command can rewrite the CI push trigger's branch

The rename command MUST accept `--default-branch <branch>`, validated as a plain git branch name before any
file is modified, and MUST rewrite the branch named in the CI workflow's push trigger to it. The option
MUST work on a workspace whose name and owner are already final, and MUST NOT rename the git branch itself.

#### Scenario: A fork on master updates its CI trigger

- **GIVEN** the CI workflow's push trigger names `main`
- **WHEN** a contributor runs `npm run rename -- <name> --default-branch master`
- **THEN** the push trigger names `master`
- **AND** running the same command again changes no tracked file

#### Scenario: An invalid branch name fails fast

- **GIVEN** `--default-branch` is given a value containing `..`, a trailing `/`, or a leading hyphen
- **WHEN** a contributor runs the rename command
- **THEN** it exits with a non-zero status before modifying any tracked file

## MODIFIED Requirements

### Requirement: The template onboarding guide documents upstream tracking after a rename

`TEMPLATE.md` MUST describe how a fork owner adds the upstream template repository as a git remote to pull
future improvements, MUST state that the rename command only rewrites identity-string lines so future
upstream merges conflict only on those lines, MUST state that the upstream URL itself is preserved by the
rename, and MUST describe how a repository that imported the template without shared git history brings
later template changes over as a patch.

#### Scenario: A fork owner sets up upstream tracking

- **WHEN** a contributor follows `TEMPLATE.md`'s upstream-tracking section
- **THEN** they can add the upstream repository as a named git remote
- **AND** the guide states which kind of merge conflicts to expect from a prior rename

#### Scenario: A squash import can still take template updates

- **GIVEN** a repository that imported the template as a single commit rather than a fork
- **WHEN** its owner follows `TEMPLATE.md`'s upstream-tracking section
- **THEN** the guide gives a patch-based recipe that does not require shared history
