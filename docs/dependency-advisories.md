# Dependency Advisories

`npm audit` is not part of the local or CI quality gate (`npm run check`) because it requires network
access to the registry; the repository's local checks are deliberately fast and offline. Instead,
`scripts/check-dependency-advisories.sh` runs as a separate CI step and compares `npm audit`'s findings
against the accepted list below, failing only on an advisory not yet reviewed here.

## Accepted Advisories

- GHSA-7w5x-hrqm-74c2 — `smol-toml`: Denial of Service via malformed TOML documents. Reached transitively
  through `nx` → `@nx/workspace` → `@nx/js`, `@nx/eslint` (all dev dependencies; no production code path).
  Every published `smol-toml` version through `1.7.0` is affected, and the only available remedy is a
  semver-major downgrade of `nx` itself (22.6.4), which is a step backward, not a fix. Accepted
  2026-09-13: the risk is a local build-time DoS on malformed TOML input this repository never parses. Not
  reachable from any check, script, or example in this repository. Revisit when `nx` publishes a release
  that resolves the transitive dependency.

## Adding A New Accepted Advisory

Add a bullet here naming the GHSA id, the affected package and dependency path, why it's accepted (or what
remedy is planned instead), and the date. `scripts/check-dependency-advisories.sh` extracts every
`GHSA-...` id present in this file as the accepted list — an advisory not listed here fails CI until it is
either fixed or recorded.
