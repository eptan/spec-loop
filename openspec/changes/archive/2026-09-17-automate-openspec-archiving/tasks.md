# Tasks

## 1. Extract shared detection

- [x] 1.1 Add `scripts/list-completed-changes.sh`, printing the name of every active change with a fully
      checked `tasks.md`, one per line.
- [x] 1.2 Refactor `scripts/check-openspec-archive.sh` to call it instead of duplicating the Python block.

## 2. Wire auto-archiving into pr.sh

- [x] 2.1 Before staging, call `scripts/list-completed-changes.sh` and run
      `npm exec openspec -- archive <name> --yes` for each name it lists.
- [x] 2.2 When the caller staged explicit paths (not `--all`), also stage `openspec/` after archiving, so
      the archive output is never left uncommitted.
- [x] 2.3 State which changes were auto-archived in the generated default PR body's `## OpenSpec` section.

## 3. Document the automation

- [x] 3.1 Note it in `AGENTS.md` next to the existing archive-only-when-complete rule.
- [x] 3.2 Note it in the `pull-request-automation` skill's list of what `scripts/pr.sh` is responsible for.

## 4. Update the contract

- [x] 4.1 Apply the `workflow-governance` delta describing the automated archiving behavior and its
      failure mode.

## 5. Verification

- [x] 5.1 Positive path: in an isolated fixture (not this session's real active work), create a change
      with every task checked and a valid spec delta; confirm `scripts/list-completed-changes.sh` finds
      it and the real archive-step logic archives it successfully. Also confirmed against the real
      `pr.sh` run for this change itself — see 5.1a.
- [x] 5.1a Running the complete, real `pr.sh` end to end (not a smaller reproduction) surfaced a case the
      isolated fixture test above did not: the original pipe-into-`while` form of the archive loop ran
      zero iterations against this repository's actual working tree despite a correctly non-empty input,
      confirmed via explicit debug tracing added directly to the script. Replaced with the `for`-with-
      newline-`IFS` form already used elsewhere in this codebase, confirmed it archives correctly on the
      real run, and converted the pre-existing, structurally identical explicit-path staging loop the
      same way since it is the same construct in the same file.
- [x] 5.2 Negative path: confirm a failing `openspec archive` call (an invalid spec delta) correctly
      aborts the whole script under `set -eu`, verified under both this system's `/bin/sh` and `dash`
      (CI's `/bin/sh`) directly, not assumed. (Verified against the isolated fixture and the standalone
      pattern; the in-situ failure found in 5.1a was a silent no-op, not a failure to abort — `set -e`
      itself was never the problem.)
- [x] 5.3 Confirm `./scripts/check-openspec-archive.sh` still passes after the refactor, using the same
      detection script the auto-archive step now shares.
- [x] 5.4 Run `openspec validate automate-openspec-archiving --strict` and resolve any errors.
- [x] 5.5 Run `npm run check` and record the result in the PR.
