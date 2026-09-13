# Fix Governance Check Correctness

## Dependencies

None.

## Why

The same adversarial review (2026-09-13) found five correctness gaps in the governance check scripts
themselves — the scripts a fork inherits and runs on every commit. Each was reproduced.

1. **`check-docs.sh` lets a harness-only change satisfy its own doc-freshness requirement.** Harness paths
   (`.agent/*`, `.agents`, `.claude/*`, `.opencode/*`) appeared in both the `needs_docs` and `has_docs`
   case patterns, so editing a skill file counted as documenting itself. Reproduced:
   `.agent/skills/nx-plugins/SKILL.md` alone passed the check, while the same edit to
   `scripts/check-harness.sh` (correctly) failed. Nothing in `docs/doc-freshness.md`'s stated model
   mentions this exemption either, and the failure message's own list of acceptable companions never
   named the harness paths as one — a sign the overlap was accidental, not designed.
2. **`check-dependencies.sh` crashes instead of failing cleanly when the archive doesn't exist.** Both
   `archive.iterdir()` and `changes.iterdir()` were unguarded. Reproduced: pointing `REPOSITORY_ROOT` at a
   fresh directory with only empty `openspec/` and `plans/` raised `FileNotFoundError` with a stack trace
   naming a temp path — exactly what a fork looks like right after clearing inherited history.
   `check-plan-freshness.sh` already handles the identical case correctly one file over.
3. **`CHECK_DIFF_RANGE` has no defined behavior for the zero-SHA case.** When `github.event.before` is all
   zeros (a new branch's first push, or a repository's very first push after a template is generated), the
   computed range is `0000...0...HEAD`, which both `check-docs.sh` and `check-secrets.sh` pass straight to
   `git diff`, which fails with `fatal: Invalid symmetric difference expression`. Reproduced for both
   scripts. The fix needs to differ per script: a documentation check can safely skip when it has no real
   base to diff against; a secret check cannot — reviewed with `git rev-list --max-parents=0 HEAD` as the
   conservative "scan from the beginning" fallback.
4. **`check-agent-attribution.sh` asserts a bare substring, not the policy it names.** `grep -q 'platform'
docs/agent-attribution.md` passes for any document containing that word anywhere, in any sense, and
   doesn't verify the actual neutral-attribution claim.
5. **The roadmap's `Foundation` row is silently exempt from every governing-change rule.** Its
   `Governing changes` cell is blank; `check-plan-freshness.sh`'s regex extraction returns an empty list
   for a blank cell, and the script's logic skips all further checks — including "Complete requires
   archived" — whenever the extracted name list is empty. This exemption is directionally correct (the
   initial foundation predates the OpenSpec workflow and has no single governing change to point at) but
   was never made explicit, so it cannot be distinguished from an accidentally blank cell. Fixing this
   surfaced a second, identical latent gap: the same empty-names fall-through was silently exempting the
   Markdown table's own GFM header-separator row (`| --- | --- | --- |`) from every rule too.

## What Changes

- `scripts/check-docs.sh`: remove harness paths from the `has_docs` pattern (they remain in `needs_docs`),
  so a harness-only change requires an actual companion doc, matching how `scripts/*` already behaves.
- `scripts/check-dependencies.sh`: guard both `iterdir()` calls exactly as `check-plan-freshness.sh`
  already does for the archive case.
- `scripts/check-docs.sh` and `scripts/check-secrets.sh`: detect the zero-SHA `CHECK_DIFF_RANGE` case.
  `check-docs.sh` skips with an explicit message (safe default: nothing to compare against).
  `check-secrets.sh` substitutes the repository's root commit as the range's base instead (safe default:
  scan from the beginning rather than nothing).
- `.github/workflows/check.yml`: add `timeout-minutes: 15` to the `quality` job so a hung step fails
  instead of running to the GitHub Actions org default (6 hours).
- `scripts/check-agent-attribution.sh`: assert the `## Platform Boundary` heading exists rather than the
  bare word `platform` anywhere in the file.
- `scripts/check-plan-freshness.sh`: require every roadmap data row to either reference a governing change
  or state `None` explicitly (reusing the same `None` convention OpenSpec change proposals already use for
  their `## Dependencies` section); explicitly skip the GFM header-separator row rather than relying on it
  falling through the same gap. `plans/roadmap.md`'s `Foundation` row now states `None` explicitly.

## Non-Goals

- No general-purpose provider-name or generated-by-watermark scanner for repository content. Building one
  that doesn't false-positive on legitimate technical mentions (this repository's own policy explicitly
  permits naming a provider "when necessary to describe a real configuration or integration boundary") is
  a separate, larger decision than tightening one existing structural assertion.
- No change to `check-secrets.sh`'s or `rename-project.sh`'s word-splitting or quoting; that is tracked
  separately as a shell-hardening pass.
- No change to how Dependabot's documentation-freshness exception works.
