# template-rename-tooling Specification

## Purpose

Give a fork owner one command that renames every tracked identity string and file/directory name in the
template — instead of the incomplete manual checklist this replaced — and keep that rename safe to re-run
and compatible with tracking the upstream template repository afterward.

## Requirements

### Requirement: A single command renames the template's identity throughout the tracked tree

The repository MUST provide `npm run rename -- <new-name>` as a single command that rewrites the
project's kebab-case name, npm scope, GitHub owner, repository URLs, and title-case name across every
tracked file, and renames every tracked file or directory whose name contains the old kebab-case name,
excluding `openspec/changes/archive/**`.

#### Scenario: Renaming updates the package scope everywhere it is used

- **GIVEN** a workspace where `packages/hello/package.json` exports `@<old-name>/hello` and
  `packages/greeter/src/index.ts` imports from `@<old-name>/hello`
- **WHEN** a contributor runs `npm run rename -- <new-name>`
- **THEN** `packages/hello/package.json` exports `@<new-name>/hello`
- **AND** `packages/greeter/src/index.ts` imports from `@<new-name>/hello`
- **AND** `npm run build` still resolves the dependency between the two packages

#### Scenario: Renaming leaves archived OpenSpec records untouched

- **GIVEN** an archived change under `openspec/changes/archive/` whose content references the old
  kebab-case project name
- **WHEN** a contributor runs `npm run rename -- <new-name>`
- **THEN** the archived change's content and directory name are unchanged

### Requirement: The rename command is idempotent

Running the rename command a second time with the same target name MUST succeed without error and MUST
NOT alter a workspace already renamed to that target. Every value the command interpolates into a
substitution pattern or replacement (the kebab-case name, the owner, and the title, whether derived or
supplied via `--title`/`--owner`) MUST be escaped so that a value containing a substitution
metacharacter cannot corrupt the rewrite or silently change what gets matched. The `--owner` option MUST be
validated to the same rigor as `<new-name>`, failing fast on an invalid value before any tracked file is
modified.

#### Scenario: Re-running the rename command after it already applied

- **GIVEN** a workspace already renamed to `<new-name>`
- **WHEN** a contributor runs `npm run rename -- <new-name>` again
- **THEN** the command exits successfully
- **AND** no tracked file outside `openspec/changes/archive/**` changes

#### Scenario: A free-text title containing substitution metacharacters is not corrupted

- **GIVEN** a contributor passes `--title` containing a forward slash, an ampersand, or a backslash
- **WHEN** the rename command rewrites tracked file content
- **THEN** the title is substituted literally everywhere it appears
- **AND** no unrelated content is altered by an unescaped substitution metacharacter

#### Scenario: An invalid owner fails fast

- **GIVEN** `--owner` contains a character outside the allowed set, or a leading, trailing, or doubled
  hyphen
- **WHEN** a contributor runs the rename command
- **THEN** the command exits with a non-zero status before modifying any tracked file

### Requirement: The rename command regenerates the lockfile and leaves the workspace verifiable

After rewriting `package.json` and every package manifest, the rename command MUST run `npm install` to
regenerate `package-lock.json`, and `npm run check` MUST pass afterward.

#### Scenario: A renamed workspace still passes the verification gate

- **WHEN** a contributor runs `npm run rename -- <new-name>` followed by `npm run check`
- **THEN** `npm run check` passes without further manual edits

#### Scenario: A broken rename target fails fast instead of leaving a silently inconsistent workspace

- **GIVEN** `<new-name>` is not a valid kebab-case identifier
- **WHEN** a contributor runs `npm run rename -- <new-name>`
- **THEN** the command exits with a non-zero status before modifying any tracked file

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
