# Repository Foundation

## Purpose

The repository provides a small, deterministic starting point for spec-driven Nx projects.

## Requirements

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

### Requirement: Example logic has a direct contract

The example MUST expose a typed function with explicit behavior for valid and invalid input.

#### Scenario: Greeting a named person

- **WHEN** `greet` receives a non-empty name
- **THEN** it returns a greeting containing the trimmed name

#### Scenario: Rejecting empty input

- **WHEN** `greet` receives only whitespace
- **THEN** it throws an error rather than returning an ambiguous result

### Requirement: A second package demonstrates inter-package dependency

The repository MUST provide a second library that depends on the `hello` library's typed export, so
project-boundary and dependency-sequencing conventions are demonstrated in working code rather than
described only in prose.

#### Scenario: Composing a dependent package

- **WHEN** `packages/greeter`'s `announce` function receives a non-empty name and occasion
- **THEN** it returns a message built from `hello`'s `greet` output plus the occasion

#### Scenario: Dependent package adds its own validation

- **WHEN** `announce` receives only whitespace for `occasion`
- **THEN** it throws an error rather than returning an ambiguous result

#### Scenario: Verifying the workspace covers both packages

- **WHEN** a contributor runs the documented verification commands after `npm ci`
- **THEN** both `hello` and `greeter` build, typecheck, lint, and test successfully without network access
  or credentials
