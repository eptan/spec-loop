# Tasks

## 1. Fix the TEMPLATE:REPLACE marker check

- [x] 1.1 In `scripts/check-repository-conventions.sh`, replace the unconditional marker assertions with a
      conditional check: pass when both `packages/hello/src/index.ts` and `index.test.ts` carry
      `TEMPLATE:REPLACE`, pass when neither does, fail with an explicit message only when they disagree.
- [x] 1.2 Drop the `add-repository-evolution-markers` roadmap-reference assertion.
- [x] 1.3 Add one sentence to `TEMPLATE.md` step 2 stating the check's conditional behavior.

## 2. Fix rename-time formatting drift

- [x] 2.1 In `scripts/rename-project.sh`, run `npm run format` before the closing `npm install`.
- [x] 2.2 Add `scripts/test-rename.sh`: rename a throwaway `git archive`-based copy of the repository to a
      deliberately different-length name and owner, then assert `prettier --check` passes.
- [x] 2.3 Wire `scripts/test-rename.sh` into `.github/workflows/check.yml` as a separate step after the
      main quality gate, not into `scripts/check.sh`.

## 3. Wire the existing governance fixture suite into the gate

- [x] 3.1 Add `./scripts/test-governance.sh` to `scripts/check.sh`.

## 4. Fix the `apps/` documentation drift

- [x] 4.1 Add `apps/.gitkeep`, matching the existing `packages/.gitkeep` convention.

## 5. Update the contract

- [x] 5.1 Apply the `repository-planning` delta: the onboarding-path scenario's `npm run check` clause and
      the marker-check convention are stated as compatible by contract, not left to imply a contradiction.

## 6. Verification

- [x] 6.1 Conditional marker check: verify all three states directly — both markers present (current
      state) passes, both absent (simulated full replacement) passes, only one present (simulated
      half-finished replacement) fails with the new message.
- [x] 6.2 Rename formatting: using `git write-tree` to capture the current working tree (since
      `test-rename.sh` itself archives `HEAD`, which won't include this change until committed), confirm
      a rename to a different-length name and owner leaves `prettier --check` passing.
- [x] 6.3 Confirm `./scripts/test-governance.sh` and `./scripts/test-rename.sh` each still pass standalone
      after being wired in.
- [x] 6.4 Confirm `apps/` exists and is tracked (`git ls-files apps/`).
- [x] 6.5 Run `openspec validate fix-fork-template-path --strict` and resolve any errors.
- [x] 6.6 Run `npm run check` and record the result in the PR.
