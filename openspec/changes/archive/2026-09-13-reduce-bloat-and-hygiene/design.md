# Design

## Context

Five findings, unified only by not fitting the earlier three groups (workflow safety, fork path,
governance-check correctness). Two decisions were explicitly given rather than inferred: keep the example
packages as source-only teaching fixtures, and remove rather than keep-just-in-case the four
technology-mismatched skills.

## Decisions

### Source-only stays source-only; fix the manifest instead of the build

Making `hello`/`greeter` genuinely consumable (dropping `emitDeclarationOnly`, emitting real `.js`, fixing
`exports` to a standard `types`/`default` shape) was the larger option on the table and was explicitly
rejected: these packages exist to be replaced or deleted per `TEMPLATE.md`, and investing in a production
build shape for fixtures whose whole purpose is to not survive a fork optimizes for a state they are never
actually in. The smaller fix — delete the two `exports` entries that never resolved, keep the one that
does, document the source-only design in prose — makes the manifest honest about the one working path
without expanding what this template's example packages need to be.

### `.tsbuildinfo` collision: per-project `outDir`, not a shared one

Nx's own `build` executor already writes real output to `dist/packages/<name>/` per project (via each
`project.json`'s `outputPath`) — that path was never the problem. The collision is specifically
`tsconfig.lib.json`'s own `outDir`, which only `tsc -b`/`--noEmit` (the `typecheck` target) and editor
tooling read directly, independent of Nx's executor. Giving each package's `tsconfig.lib.json` its own
`outDir` (`dist/out-tsc/hello`, `dist/out-tsc/greeter`) fixes the collision at its actual source without
touching `project.json`'s already-correct `outputPath`.

### Sed escaping: verified against real `sed` semantics, not assumed

The first version of the escaping helper used a single bracket-expression substitution
(`s/[\/&]/\\&/g`) intended to escape both `/` and `&` in one pass. Testing it against a value already
containing a backslash revealed a bracket-expression subtlety: `[\/&]` also matches a literal backslash
character (the `\` immediately preceding the escaped delimiter `/` is itself a member of the character
set), so a value's already-escaped backslashes were escaped a second time, corrupting the result. The
fix splits into three unambiguous substitutions, each targeting exactly one character, with `/`'s
substitution using `#` as the sed delimiter specifically to avoid needing to escape `/` inside its own
pattern. Verified round-trip against inputs containing `/`, `&`, `\`, and combinations of all three before
and after the fix, and end-to-end through the real script with `--title 'Fixture / Project & Co\Name'`.

### `--owner` validated for the same reason `<new-name>` already is

`template-rename-tooling`'s existing "fails fast instead of leaving a silently inconsistent workspace"
scenario already covers `<new-name>`. `--owner` feeds the identical `sed`-substitution pipeline and was the
one value with no format check at all — extending the same validation style (allowed character set, no
leading/trailing/double hyphen) to `--owner` closes the asymmetry the review named directly, without
introducing a new validation philosophy.

### Dependency advisories: a reviewed allowlist, not a hard fail on every finding

`npm audit` reports one already-known, already-unfixable advisory today; making CI fail on any finding
unconditionally would make every future PR red for a problem nobody can currently act on. The allowlist
(`docs/dependency-advisories.md`, parsed for `GHSA-...` ids) makes today's decision explicit and durable,
while still failing CI the moment a _different_, unreviewed advisory appears — which is the actual gap the
review named ("there'd be no signal today if an actionable advisory appeared"). Kept as a separate CI step,
not part of `scripts/check.sh`, for the same reason `scripts/test-rename.sh` is CI-only: it needs the
registry, and the local gate is deliberately offline.

## Risks

- **A future accepted advisory's GHSA id typo'd in `docs/dependency-advisories.md` silently fails to
  suppress it.** Accepted: the check would then (correctly, if surprisingly) flag it as new, prompting a
  second look rather than silently trusting a broken entry.
- **`npm audit`'s output shape changes in a future npm version.** The extraction only reads
  `vulnerabilities[].via[].url`, a field npm has kept stable across the audit v2 format used since npm 7;
  a shape change would make the script find zero advisories and pass trivially rather than crash, which is
  a silent-pass regression class this same batch fixed elsewhere (`check-dependencies.sh`) — accepted here
  specifically because `npm audit`'s exit code is not itself load-bearing (the script always exits via its
  own logic, not `npm audit`'s), and re-verifying the parse against real `npm audit --json` output is part
  of this change's own verification.
