# ci-governance Specification

## ADDED Requirements

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
