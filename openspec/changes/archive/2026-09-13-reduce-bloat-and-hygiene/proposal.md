# Reduce Bloat And Hygiene

## Dependencies

None.

## Why

The final group from the 2026-09-13 adversarial review: a correctness gap in the example packages'
manifests, secret-check observability and supply-chain gaps, four skills unrelated to anything in this
workspace, several latent shell-scripting weaknesses, and no visibility into dependency advisories. The
user's stated goal for this repository — easy to rename, low bloat, stays mergeable with upstream after a
fork — decided two judgment calls the review itself flagged as ambiguous: the example packages stay
source-only teaching fixtures (not invested in as production-consumable libraries, since `TEMPLATE.md`
already tells a fork owner to replace or delete them), and the four unused skills are removed rather than
kept "in case" a future package needs that stack.

1. **`exports` maps promised what the build never emits.** `tsconfig.base.json` sets
   `emitDeclarationOnly: true` (only `.d.ts` output), but both packages' `exports` maps also declared
   `types`/`default` entries pointing at `dist/index.d.ts` / `dist/index.js` paths that don't resolve — only
   the custom `@spec-loop/source` condition actually works. Reproduced: `node --input-type=module -e
"import('@spec-loop/hello')"` fails with `ERR_MODULE_NOT_FOUND`. Separately, both packages'
   `tsconfig.lib.json` shared one `outDir` (`../../dist/out-tsc`), so their `.tsbuildinfo` incremental-build
   caches collided at the same path — reproduced: only one file exists after building both.
2. **The secret check's engine and CI download were both unverifiable at a glance.** A passing run never
   stated whether `gitleaks` or the narrow fallback pattern actually ran, and CI downloaded gitleaks over
   HTTPS with no checksum verification.
3. **Four skills describe technology absent from this workspace.** `monitor-ci` depends on Nx Cloud (no
   `nxCloudId` anywhere in `nx.json` or the CI workflow); `react-best-practices` and `next-best-practices`
   describe frameworks not present; `nx-import` covers adopting Nx into an existing repository, the
   opposite direction from a template meant to be forked outward. Combined, these were the majority of
   `.agent/skills/`'s footprint.
4. **Three latent shell-scripting weaknesses in code this batch already touches or that touches forks
   directly.** Unquoted `for x in $var` loops in `check-docs.sh`, `check-secrets.sh`, and
   `rename-project.sh` word-split on spaces/tabs, not just the intended newlines. `check-secrets.sh` also
   passed an unquoted `-- $files` to `git diff`, which could silently narrow what gets scanned.
   `rename-project.sh` validates `<new-name>` as kebab-case but never validated `--owner` at all, and
   interpolated `--title`/`--description`-derived title text into `sed` substitutions without escaping —
   reproduced: a title containing `/`, `&`, or `\` corrupted the rewrite before this fix (verified against
   the actual `sed` behavior, not assumed).
5. **No visibility into dependency advisories.** `npm audit` currently reports one high-severity advisory
   (`GHSA-7w5x-hrqm-74c2`, transitively through `nx`) with no available non-regressive fix, and nothing in
   this repository records that as a reviewed, accepted decision or would flag a _different_, actionable
   advisory landing later.

## What Changes

- Trim `packages/hello` and `packages/greeter`'s `exports` maps to only the `@spec-loop/source` condition
  that actually resolves; reword `README.md`'s `build` target description and add one explanatory paragraph
  stating the source-only design and how in-workspace consumption actually works.
- Give each package's `tsconfig.lib.json` its own `outDir` so their `.tsbuildinfo` files never collide.
- `check-secrets.sh`: print which engine ran on a passing result; state the fallback's real, narrow
  coverage in its warning text (already a review guard per `SECURITY.md`, now stated at the point of use).
- `.github/workflows/check.yml`: checksum the gitleaks download against its published SHA-256 (verified
  against the actual artifact before embedding).
- Document gitleaks in `README.md`'s Quick Start and `CONTRIBUTING.md`'s Local Setup, with the "review
  guard, not a guarantee" caveat carried into `README.md` alongside it.
- Remove `.agent/skills/{monitor-ci,react-best-practices,next-best-practices,nx-import}` and `monitor-ci`'s
  `.opencode/` adapter pair; update `README.md`'s skill table to match.
- Fix word-splitting in `check-docs.sh`, `check-secrets.sh` (including the unquoted `-- $files` pathspec),
  and `rename-project.sh`'s content-rewrite loop.
- Validate `--owner` in `rename-project.sh` to the same rigor as `<new-name>`; escape every value
  interpolated into a `sed` pattern or replacement (not only the ones that could plausibly carry a
  metacharacter today).
- Add `docs/dependency-advisories.md` recording today's one accepted advisory with rationale, and
  `scripts/check-dependency-advisories.sh` (wired into CI, not the local gate, since it needs the
  registry) that fails on any advisory not listed there.

## Non-Goals

- No change to the example packages' build shape beyond manifest/config correctness — they remain
  deliberately source-only teaching fixtures, per explicit direction; making them production-consumable
  (dropping `emitDeclarationOnly`, real `.js` output) was considered and rejected for this repository's
  stated purpose.
- No word-boundary anchoring on the rename substitutions (a very short `--owner` like `nx` or `js` could
  still rewrite that substring inside unrelated words). Portable word-boundary matching across both BSD and
  GNU `sed` is a meaningfully larger, separate piece of work than this batch's other fixes; documented here
  as an accepted, narrow-blast-radius limitation rather than silently left unmentioned.
- No macOS/multi-platform CI runner addition. The review noted this as a fragility (scripts use
  `sed -i.bak`, `sed -E`, which already differ between BSD and GNU userlands, currently used correctly for
  both), not a present bug; adding a second CI platform is a standing-cost decision, not a fix.
- No general provider-name/watermark scanner, no automated skill catalog beyond removing the four
  identified — both out of scope here as they were in the prior governance-correctness change.
