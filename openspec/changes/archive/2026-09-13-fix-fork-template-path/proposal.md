# Fix Fork Template Path

## Dependencies

None.

## Why

The stated purpose of this repository is to be forked, renamed, and grown into someone else's project. An
adversarial review (2026-09-13) found that following `TEMPLATE.md` in order — the documented path for
doing exactly that — cannot currently succeed, and reproduced each claim.

1. **`TEMPLATE.md` step 2 and `npm run check` ask for opposite things.** Step 2 tells a fork owner to
   replace `packages/hello`'s implementation and test, which necessarily removes the `TEMPLATE:REPLACE`
   marker. `scripts/check-repository-conventions.sh` unconditionally required the marker to still be
   present in both files, so completing step 2 makes step 3 (`npm run check` must pass) fail. This is not
   only a script bug: the accepted `repository-planning` spec's own "Fork owner follows the guide to a
   verified, renamed project" scenario requires _both_ "no tracked file under `packages/` contains a
   `TEMPLATE:REPLACE` marker" _and_ "`npm run check` passes" simultaneously — the two clauses contradicted
   each other as implemented. The same script also required `plans/roadmap.md` to keep referencing
   `add-repository-evolution-markers` forever, even though `TEMPLATE.md` step 4 tells a fork owner to
   rewrite the roadmap for their own capabilities — and no accepted spec requirement actually depends on
   that specific reference persisting.
2. **After `npm run rename`, Prettier alignment drifts and `npm run check` fails.** `sed`-based renaming
   changes Markdown table column widths whenever the new name/owner/title differs in length from the old
   one; the rename script never reformatted its own output before finishing. Reproduced: renaming to a
   different-length name leaves `docs/repository-orientation.md`'s table failing `prettier --check`, so
   the exact command `TEMPLATE.md` tells the fork owner to run next (`npm run check`) fails on a file they
   never touched.
3. **Docs claim `apps/` exists; it doesn't.** `README.md` and `docs/repository-orientation.md` both
   describe an `apps/` directory in the repository layout, three times combined. `ls apps` returns "No
   such file or directory." `packages/.gitkeep` already establishes the convention for representing an
   intentionally-empty tracked directory.

## What Changes

- `scripts/check-repository-conventions.sh`: replace the unconditional `TEMPLATE:REPLACE` marker
  assertions with a conditional check — pass when both `packages/hello/src/index.ts` and
  `index.test.ts` carry the marker (this repository's own state), pass when neither does (a completed
  fork replacement), fail only when they disagree (a half-finished replacement, the check's actual
  purpose). Drop the `add-repository-evolution-markers` roadmap-reference assertion, which protects no
  accepted requirement and blocks the roadmap rewrite `TEMPLATE.md` itself tells a fork owner to do.
- `TEMPLATE.md`: one added sentence clarifying the convention check's real (conditional) behavior, so a
  reader isn't left guessing why `npm run check` might once have failed here.
- `scripts/rename-project.sh`: run `npm run format` on the whole tree before the closing `npm install`,
  so any Markdown table the rename touched is realigned before the script hands off to `npm run check`.
- Add `scripts/test-rename.sh`: a regression fixture that renames a throwaway copy of the repository to a
  deliberately different-length name and owner, then asserts `prettier --check` passes. Wired into CI
  (`.github/workflows/check.yml`) as a separate step, not into `scripts/check.sh`, because it performs a
  real `npm install` and takes several seconds — see the comment in the script for the reasoning.
- Wire the existing, already-passing `scripts/test-governance.sh` into `scripts/check.sh` (it currently
  runs in well under a second against `mktemp -d` fixtures with no network, and nothing was running it).
- Add `apps/.gitkeep`, matching the existing `packages/.gitkeep` convention, so the documented layout is
  literally true.

## Non-Goals

- No change to the rename script's identity-substitution logic itself, its `sed`-based approach, or its
  argument validation — those are addressed separately (see the shell-hardening finding tracked for a
  later change).
- No new general-purpose "does the docs map match the filesystem" checker — the concrete drift found
  (`apps/`) is fixed directly; a standing structural-doc checker is a larger, separate decision this change
  does not make.
- No change to what `TEMPLATE.md` instructs a fork owner to do, only to what actually happens when they do
  it.
