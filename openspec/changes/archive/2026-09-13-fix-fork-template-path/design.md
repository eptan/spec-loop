# Design

## Context

Three independent drifts, all discovered by actually walking `TEMPLATE.md` end to end in a throwaway
clone rather than reading the checklist and the checks separately. Each fix targets the actual invariant
each check exists to protect, rather than relaxing the check generally.

## Decisions

### Conditional marker check, not a second gate or a rename-time strip

The reviewer offered three options: a conditional assertion, a separate template-only check that doesn't
run in `npm run check`, or having `npm run rename` strip the markers itself. The last is wrong for
ordering reasons: `TEMPLATE.md` step 1 (rename) runs _before_ step 2 (replace examples), so stripping
markers at rename time would remove the very signal step 2 depends on to find what to replace. A second,
template-only gate is exactly the kind of parallel-check bloat this repository is trying to avoid — one
script, one meaning, checked once. A conditional assertion keeps `check-repository-conventions.sh` as the
single check both this repository's own CI and every fork's `npm run check` run, and it encodes the
check's actual purpose precisely: catch a half-finished replacement (one file updated, one not), accept
both a fully-replaced and a not-yet-replaced state as valid. This is also literally what the accepted
`repository-planning` spec's "Fork owner follows the guide to a verified, renamed project" scenario
requires — the fix makes the implementation match a spec that already existed.

### Dropping the roadmap-reference assertion instead of updating it

Grepped every accepted spec for `add-repository-evolution-markers`: no requirement names it. The assertion
was an implementation detail of one script referencing this repository's own historical roadmap content,
not something any accepted contract depends on. `TEMPLATE.md` step 4 tells a fork owner to rewrite the
roadmap for their own capabilities via `/roadmap`; keeping an assertion that a specific archived change's
id remain in that file forever would directly contradict step 4's own instruction the moment a fork
completes it. Removing the assertion (rather than replacing it with something else) is correct because it
never protected an invariant — it protected wording that happened to be true when the script was written.

### `npm run format` before `npm install`, reusing the package script

The rename script already calls `npm install` unconditionally at the end (documented rationale: "a broken
rename fails immediately instead of surfacing later as a confusing build error"). Adding `npm run format`
immediately before it extends that same philosophy one step earlier: the rename's own formatting side
effect should also fail immediately (well, succeed immediately — `prettier --write` cannot fail on
well-formed input) rather than surface later as a `prettier --check` failure the user has to diagnose.
Reusing the existing `format` package script (rather than a fresh `prettier --write .` invocation) keeps
one definition of "how this repo formats itself."

### The rename fixture runs in CI, not in `scripts/check.sh`

Benchmarked directly: `scripts/test-rename.sh` takes roughly 5–6 seconds, dominated by the `npm install`
that `rename-project.sh` itself performs inside the fixture's throwaway tree (`git archive HEAD` piped
into a fresh directory, with the parent's `node_modules` symlinked in — `npm install`'s reify step treats
that symlink as a non-directory and replaces it with a real install, so the fixture pays a real install
cost every run). `scripts/check.sh` runs on every local commit via `.githooks/pre-commit`; adding several
seconds there would regress the property the review specifically praised — "genuinely fast enough to run
constantly." `scripts/test-governance.sh`, by contrast, runs in well under a second against pure
filesystem fixtures with no network and no install, which is why it is wired into `check.sh` directly
instead. The rename fixture instead runs once per CI invocation (`.github/workflows/check.yml`), where the
cost is amortized against a job that already performs its own `npm ci` and already takes tens of seconds.

## Risks

- **The rename fixture's `npm install` step reaches the network in CI.** `actions/setup-node`'s npm cache
  is already warm from the job's own `npm ci` a few steps earlier, so this is expected to resolve from
  cache rather than the registry in the common case; a registry outage would fail this step without
  affecting the main quality gate, since it runs after and separately from `npm run check`.
- **A future contributor re-adds a template-only assertion without checking for this precedent.** Mitigated
  by the `TEMPLATE.md` sentence and the `repository-planning` spec scenario added below, both of which
  state the conditional behavior as the intended contract, not an implementation accident.
