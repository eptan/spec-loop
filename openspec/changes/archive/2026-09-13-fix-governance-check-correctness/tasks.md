# Tasks

## 1. Fix check-docs.sh's harness overlap

- [x] 1.1 Remove `.agent/*|.agents|.claude/*|.opencode/*` from the `has_docs` case pattern; leave them in
      `needs_docs`.

## 2. Fix check-dependencies.sh's unguarded iterdir

- [x] 2.1 Guard `archive.iterdir()` and `changes.iterdir()` with `if archive.is_dir() else set()` /
      `if changes.is_dir() else []`, mirroring `check-plan-freshness.sh`.

## 3. Fix the zero-SHA CHECK_DIFF_RANGE case

- [x] 3.1 In `check-docs.sh`, detect a zero-SHA base and skip with an explicit message.
- [x] 3.2 In `check-secrets.sh`, detect a zero-SHA base and substitute the repository's root commit as the
      range's base.
- [x] 3.3 Add `timeout-minutes: 15` to the `quality` job in `.github/workflows/check.yml`.

## 4. Strengthen the attribution structural check

- [x] 4.1 Replace `grep -q 'platform'` with `grep -q '^## Platform Boundary$'` in
      `check-agent-attribution.sh`.

## 5. Fix the roadmap row exemption

- [x] 5.1 In `check-plan-freshness.sh`, require every non-separator data row to reference a governing
      change or state `None`; explicitly skip GFM header-separator rows.
- [x] 5.2 Update `plans/roadmap.md`'s `Foundation` row to state `None` in its governing-changes cell.

## 6. Update the contract

- [x] 6.1 Apply the `spec-loop-governance` delta covering the doc-freshness harness scope and the zero-SHA
      handling for both `check-docs.sh` and `check-secrets.sh`.
- [x] 6.2 Apply the `workflow-governance` delta covering `check-dependencies.sh`'s guarded directory
      traversal.
- [x] 6.3 Apply the `agent-attribution` delta covering the structural heading assertion.
- [x] 6.4 Apply the `repository-planning` delta covering the explicit-`None` roadmap-row requirement.

## 7. Verification

- [x] 7.1 Reproduce and confirm fixed: a harness-only staged change now fails `check-docs.sh` (previously
      passed); the `scripts/*` control case still fails as before.
- [x] 7.2 Reproduce and confirm fixed: `REPOSITORY_ROOT` pointed at a fresh directory with empty
      `openspec/`/`plans/` no longer crashes `check-dependencies.sh`.
- [x] 7.3 Reproduce and confirm fixed: `CHECK_DIFF_RANGE` with an all-zero base no longer crashes
      `check-docs.sh` (skips cleanly) or `check-secrets.sh` (scans from the root commit instead).
- [x] 7.4 Confirm `check-agent-attribution.sh` still passes against the real
      `docs/agent-attribution.md`.
- [x] 7.5 Confirm `check-plan-freshness.sh` passes against the real `plans/roadmap.md` after the
      `Foundation` row edit; confirm a genuinely blank governing-changes cell now fails with the new
      message; confirm the GFM separator row is not flagged.
- [x] 7.6 Run `npm run check` and record the result in the PR.
