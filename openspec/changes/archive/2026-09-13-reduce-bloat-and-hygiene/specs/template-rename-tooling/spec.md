# template-rename-tooling Specification

## MODIFIED Requirements

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
