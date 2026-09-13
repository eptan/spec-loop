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
future improvements, and MUST state that the rename command only rewrites identity-string lines so future
upstream merges conflict only on those lines.

#### Scenario: A fork owner sets up upstream tracking

- **WHEN** a contributor follows `TEMPLATE.md`'s upstream-tracking section
- **THEN** they can add the upstream repository as a named git remote
- **AND** the guide states which kind of merge conflicts to expect from a prior rename
