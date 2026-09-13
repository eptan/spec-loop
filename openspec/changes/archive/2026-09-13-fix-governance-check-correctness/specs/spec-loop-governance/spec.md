# spec-loop-governance Specification

## MODIFIED Requirements

### Requirement: Governance checks cannot silently disappear in CI

The CI workflow MUST run the same aggregate governance and Nx quality command documented for local use.
Required validation tools MUST be pinned or their absence MUST fail the check instead of silently skipping
the corresponding gate. A gate that degrades to a fallback when its preferred tool is absent MUST use
matching logic that actually detects the case it claims to on every supported platform, and MUST NOT
depend on provider-specific credential names. When a precondition of the Nx quality targets is missing —
such as unlinked workspace packages — the aggregate check MUST fail with an explicit, actionable message
naming the remedy, rather than surfacing a misleading downstream error from a later target. A change that
touches only agent harness files (`.agent/`, `.agents`, `.claude/`, `.opencode/`) MUST NOT satisfy the
documentation-freshness requirement on its own; it MUST be paired with an actual documentation, README,
`AGENTS.md`, `CONTRIBUTING.md`, or OpenSpec update, the same as any other implementation change. When the
CI-computed diff range has no real base commit (an all-zero SHA), a check that compares content MUST NOT
crash on the malformed range; it MUST either skip explicitly with a stated reason, or substitute a
deliberately conservative range, chosen per the check's own risk (a documentation check may skip; a secret
scan MUST NOT skip and instead scans from the repository's root commit).

#### Scenario: Run the CI-equivalent check locally

- **WHEN** a contributor runs `npm run check` after `npm ci`
- **THEN** OpenSpec, harness, documentation, secret, formatting, lint, typecheck, test, and build checks
  either run successfully or report an explicit actionable failure

#### Scenario: Fallback secret scan matches a spaced assignment

- **GIVEN** the preferred secret scanner is not installed and the fallback pattern runs
- **WHEN** a staged change adds a credential assignment with whitespace around `=` on a supported platform
- **THEN** the fallback pattern matches it rather than silently passing

#### Scenario: Unlinked workspace packages fail with an actionable message

- **GIVEN** the workspace package links under `node_modules/` are absent
- **WHEN** a contributor runs the aggregate check
- **THEN** it fails before the Nx quality targets with a message naming the remedy (such as `npm install`)
- **AND** it does not surface a bare module-resolution error as the first symptom

#### Scenario: A harness-only change does not document itself

- **GIVEN** a staged change touches only files under `.agent/`, `.agents`, `.claude/`, or `.opencode/`
- **WHEN** the documentation freshness check runs
- **THEN** it fails, the same as any other implementation change with no documentation update
- **AND** it does not accept the harness change itself as satisfying its own requirement

#### Scenario: A malformed zero-SHA diff range does not crash a check

- **GIVEN** `CHECK_DIFF_RANGE` has an all-zero base commit SHA (a new branch's first push, or a
  repository's first push after this template is generated)
- **WHEN** the documentation freshness check or the secret scan runs
- **THEN** neither crashes with a git plumbing error
- **AND** the documentation check skips with an explicit stated reason
- **AND** the secret scan instead scans from the repository's root commit rather than skipping
