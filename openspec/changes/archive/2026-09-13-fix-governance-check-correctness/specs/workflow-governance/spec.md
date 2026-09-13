# workflow-governance Specification

## MODIFIED Requirements

### Requirement: Dependency declarations are executable

Repository checks MUST validate that every active OpenSpec change declares `## Dependencies` with either
`None` or exact existing change names. A dependency MUST be considered ready only when its governing change is
archived and its required tasks and verification evidence are complete. The check MUST NOT crash when the
`openspec/changes/` directory or its `archive/` subdirectory does not yet exist; it MUST treat either
absent directory as containing no entries and report its normal pass or fail result rather than an
unhandled error.

#### Scenario: Unknown dependency fails closed

- GIVEN an active OpenSpec change names a nonexistent dependency
- WHEN the repository dependency check runs
- THEN it reports the exact missing dependency and fails

#### Scenario: Missing archive directory does not crash the check

- GIVEN a fresh checkout where `openspec/changes/archive/` does not exist yet (a fork right after
  clearing inherited history, or a new project generated from this template)
- WHEN the dependency check runs
- THEN it completes with its normal pass or fail result
- AND it does not raise an unhandled error naming an internal file path
