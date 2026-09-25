# repository-planning Specification

## MODIFIED Requirements

### Requirement: A fork owner has a single ordered onboarding path

The repository MUST provide a root-level guide that gives a fork owner an ordered, checkable sequence for
turning the template into their own project: rename identity strings, replace `TEMPLATE:REPLACE`-marked
example code, run the verification gate, then propose their first domain OpenSpec change. The verification
gate's check of the `TEMPLATE:REPLACE` marker MUST apply to every package's implementation and test pair
under `packages/` without naming any package, so replacing or removing a teaching example never requires
editing the check. It MUST accept both the unforked state (the marker present in every marked file) and a
completed replacement (the marker absent from every file that shared its replacement unit) as passing; it
MUST fail only when files that share a replacement unit disagree on whether the marker is still present.
The guide MUST state which checks run only in CI and how to run them locally before a pull request.

#### Scenario: Fork owner follows the guide to a verified, renamed project

- **WHEN** a contributor forks the repository and follows `TEMPLATE.md` in order
- **THEN** `package.json` and `README.md` no longer reference `spec-loop` or `salzayat/spec-loop`
- **AND** no tracked file under `packages/` contains a `TEMPLATE:REPLACE` marker
- **AND** `npm run check` passes without editing any script under `scripts/`

#### Scenario: Marker search covers every teaching example, not just the first one

- **WHEN** a contributor searches tracked implementation and test files for `TEMPLATE:REPLACE`
- **THEN** both `packages/hello` and `packages/greeter` implementation and test files are found

#### Scenario: A half-finished replacement fails, a completed one does not

- **GIVEN** a package's implementation and test share one replacement unit
- **WHEN** only one of the two still carries the `TEMPLATE:REPLACE` marker
- **THEN** the verification gate fails with a message naming that package
- **AND** the gate passes once both files agree, whether that means both still carry the marker or neither
  does

#### Scenario: The guide names the CI-only checks

- **WHEN** a contributor reads the verification step of `TEMPLATE.md`
- **THEN** it states that CI runs the local gate plus a named CI-only script
- **AND** it shows how to run that script locally
