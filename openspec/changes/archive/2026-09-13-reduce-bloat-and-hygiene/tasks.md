# Tasks

## 1. Fix the package manifests

- [x] 1.1 Remove the unresolvable `types`/`default` entries from `packages/hello/package.json` and
      `packages/greeter/package.json`'s `exports` maps, keeping only `@spec-loop/source`.
- [x] 1.2 Reword `README.md`'s `build` target row and add a short paragraph on the source-only design and
      the `@spec-loop/source` condition.
- [x] 1.3 Give `packages/hello/tsconfig.lib.json` and `packages/greeter/tsconfig.lib.json` each their own
      `outDir`.

## 2. Secret check and CI supply-chain visibility

- [x] 2.1 Print which engine ran (`gitleaks` or fallback) on a passing `check-secrets.sh` result; state the
      fallback's narrow coverage in its warning text.
- [x] 2.2 Checksum the gitleaks download in `.github/workflows/check.yml` against its verified SHA-256.
- [x] 2.3 Document gitleaks in `README.md`'s Quick Start and `CONTRIBUTING.md`'s Local Setup; carry the
      "review guard, not a guarantee" caveat into `README.md`.

## 3. Remove unused skills

- [x] 3.1 Remove `.agent/skills/{monitor-ci,react-best-practices,next-best-practices,nx-import}` and
      `monitor-ci`'s `.opencode/commands`/`.opencode/agents` adapter files.
- [x] 3.2 Update `README.md`'s skill table to drop the four removed rows.
- [x] 3.3 Confirm `./scripts/check-harness.sh` still passes and no remaining tracked file references any
      of the four removed skills.

## 4. Shell hardening

- [x] 4.1 Fix word-splitting in `check-docs.sh` (`for file in $staged_files`), `check-secrets.sh`
      (`for file in $files`), and `rename-project.sh`'s content-rewrite loop (`for f in $files`) using a
      newline-only `IFS`.
- [x] 4.2 Fix `check-secrets.sh`'s unquoted `-- $files` pathspec by building positional parameters from
      the same newline-only split and passing `-- "$@"`.
- [x] 4.3 Validate `--owner` in `rename-project.sh` with the same rigor as `<new-name>`.
- [x] 4.4 Add a `sed_escape` helper and apply it to every value (`old_name`, `new_name`, `old_owner`,
      `new_owner`, `old_title`, `new_title`) interpolated into a `sed` pattern or replacement.

## 5. Dependency advisory visibility

- [x] 5.1 Add `docs/dependency-advisories.md` recording the current `GHSA-7w5x-hrqm-74c2` advisory with
      rationale and a revisit condition.
- [x] 5.2 Add `scripts/check-dependency-advisories.sh`, comparing `npm audit --json` findings against the
      accepted list; wire it into `.github/workflows/check.yml` as a separate step.
- [x] 5.3 Cross-reference the new doc from `SECURITY.md`.

## 6. Update the contract

- [x] 6.1 Apply the `repository-foundation` delta covering the documented source-only build shape.
- [x] 6.2 Apply the `spec-loop-governance` delta covering secret-check engine visibility, the checksummed
      CI download, and skills matching workspace technology.
- [x] 6.3 Apply the `template-rename-tooling` delta covering `--owner` validation and safe substitution of
      free-text values.
- [x] 6.4 Apply the `ci-governance` delta covering dependency advisory review.

## 7. Verification

- [x] 7.1 Confirm `npm run build`, `npm exec nx run greeter:test` (cross-package import via
      `@spec-loop/source`), and both packages' `typecheck` still succeed after the manifest and `outDir`
      fixes; confirm each package now has its own `.tsbuildinfo`.
- [x] 7.2 Confirm `check-secrets.sh` states its engine on a passing run, for both the `gitleaks` and
      fallback paths.
- [x] 7.3 Confirm the embedded gitleaks checksum matches a freshly downloaded copy of the pinned release
      artifact.
- [x] 7.4 Confirm `./scripts/check-harness.sh` passes after the skill removal and no tracked file
      references a removed skill.
- [x] 7.5 Confirm `--owner` validation rejects an invalid value and accepts a valid one; confirm a
      `--title` containing `/`, `&`, and `\` round-trips correctly through a real rename (verified via
      `git write-tree` against the current working tree).
- [x] 7.6 Confirm `scripts/check-dependency-advisories.sh` passes against the real, current advisory list,
      and fails when a listed id is removed (tested and reverted).
- [x] 7.7 Run `openspec validate reduce-bloat-and-hygiene --strict` and resolve any errors.
- [x] 7.8 Run `npm run check` and record the result in the PR.
