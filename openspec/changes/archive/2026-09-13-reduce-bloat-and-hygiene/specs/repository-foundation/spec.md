# Repository Foundation

## MODIFIED Requirements

### Requirement: A new contributor can verify the workspace

The repository MUST document and expose commands for formatting, type checking, linting, testing,
and building the example project. Documentation of the `build` command MUST accurately describe what it
emits; if a package is source-only (declaring only a private, in-workspace consumption condition in its
`exports` map, with no entry that resolves outside this workspace), that MUST be stated rather than implied
to produce a standard consumable package.

#### Scenario: Run the standard quality gates

- **WHEN** a contributor runs the documented verification commands after `npm ci`
- **THEN** each command completes successfully without network access or credentials

#### Scenario: A package's exports map only names conditions that actually resolve

- **GIVEN** `packages/hello` or `packages/greeter`'s `package.json`
- **WHEN** a contributor inspects its `exports` map
- **THEN** every entry resolves to a real path produced by that package's own `build` target or its source
  tree
- **AND** no entry names a path the build does not produce
