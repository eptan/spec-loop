# ci-governance Specification

## Purpose

Define how dependency-update automation participates in documentation and quality gates without weakening
checks for human-authored changes.

## Requirements

### Requirement: Dependabot-only version updates do not fail documentation freshness

The CI quality workflow MUST identify Dependabot-triggered runs explicitly. The documentation freshness check
MAY suppress only its documentation-presence failure for such a run when no documentation file is included.
All other quality gates MUST continue to run, and local or human-authored changes MUST retain the existing
documentation requirement.

#### Scenario: Dependabot version update proceeds to quality gates

- GIVEN a Dependabot pull request changes dependency versions without documentation
- WHEN the CI quality workflow runs
- THEN documentation freshness does not fail solely because no docs file changed
- AND secret, OpenSpec, harness, formatting, lint, typecheck, test, and build checks still run

#### Scenario: Human dependency change still requires documentation

- GIVEN a human-authored change modifies dependency or workflow files without documentation
- WHEN the local or CI documentation freshness check runs without the Dependabot indicator
- THEN it fails with the existing actionable documentation message

### Requirement: Dependency advisories are reviewed, not silently ignored

The repository MUST maintain a record of accepted dependency advisories with no available non-regressive
fix, naming each advisory's id and the reason it is accepted. A CI check MUST compare the dependency
scanner's findings against that record and fail when a finding is not present in it, so a new, unreviewed
advisory cannot land without at least one recorded decision. This check requires network access to the
package registry and therefore runs only in CI, not in the local, offline quality gate.

#### Scenario: An already-reviewed advisory does not fail CI

- GIVEN a dependency advisory is recorded in the accepted-advisories document with its id and rationale
- WHEN the dependency advisory check runs and the scanner reports that same advisory
- THEN the check passes

#### Scenario: A new, unreviewed advisory fails CI

- GIVEN a dependency advisory scan reports an advisory id not present in the accepted-advisories document
- WHEN the dependency advisory check runs
- THEN it fails and names the unreviewed advisory id
