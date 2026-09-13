# Design

## Context

Five independent gaps, each in a different check script, unified by one theme: a governance check that
silently passes or crashes ungracefully in a state a fork legitimately reaches, rather than reporting an
explicit, actionable result — the same "checks cannot silently disappear" property `spec-loop-governance`
already states and this session has fixed for the harness-adapter check, the secret-scan fallback, and the
workspace-link preflight.

## Decisions

### `check-docs.sh`: remove the overlap rather than document it

The reviewer offered both framings — maybe intentional (SKILL.md files are prose), maybe accidental. The
tie-breaker is the check's own failure message, which lists exactly five acceptable companions
(`openspec/`, `docs/`, `README.md`, `AGENTS.md`, `CONTRIBUTING.md`) and never mentions the harness paths —
if the overlap were designed, the message that tells a contributor how to fix a failure would say so.
Removing harness paths from `has_docs` (keeping them in `needs_docs`) makes harness-only edits behave
exactly like `scripts/*` edits already do, which is the more conservative and more consistent reading.

### Zero-SHA: different defaults for different risk

A documentation check and a secret check have opposite failure costs when the diff range is unknowable.
Skipping a documentation-freshness check on an unusual push event costs nothing but a missed reminder; a
secret check with the same "skip" default could let a real credential through on exactly the kind of push
(a repository's first, right after generating it from this template) most likely to contain one, since
that push often carries the fork owner's initial real configuration. `git rev-list --max-parents=0 HEAD`
gives the conservative "scan the whole history" fallback for the secret check without needing to know what
the "real" base commit should have been.

### `check-dependencies.sh`: mirror the existing pattern, don't invent a new one

`check-plan-freshness.sh` already has the exact guard needed
(`... if archive.is_dir() else set()`). Copying it (and adding the matching guard for `changes.iterdir()`,
which had the identical bug) keeps one idiom for "a directory that might not exist yet" across both
scripts, rather than two.

### Attribution check: a heading, not a watermark scanner

The reviewer's suggested full fix — "scanning new docs and reports for provider names and generated-by
watermarks" — was considered and rejected for this change specifically because this repository's own
attribution policy carves out a legitimate exception ("technical documentation may mention a provider when
the name is necessary to describe a real configuration or integration boundary"), and a scanner precise
enough to honor that exception without false-positiving on this very document (which names Claude,
Anthropic, GitHub, and OpenCode throughout, all in exactly the permitted technical sense) is a
meaningfully larger, separate piece of work. Asserting the `## Platform Boundary` heading exists is a
small, real improvement over a bare substring match — coincidental satisfaction requires the exact heading
text, not any incidental use of the word "platform" — without taking on that larger scope.

### Roadmap rows: reuse the `None` convention already in this repository

OpenSpec change proposals already use an explicit `None` to mark "no dependency" in their `## Dependencies`
section (`check-dependencies.sh` already recognizes this literal). Requiring the same word for "no
governing change" in a roadmap row reuses vocabulary a contributor already knows from writing changes,
rather than inventing a second convention for the same concept. Making the roadmap's `Foundation` row say
`None` explicitly, instead of leaving the cell blank, turns an accidental exemption into a reviewable,
intentional one.

### The GFM separator-row exclusion was found by fixing the row check, not read for separately

Making the "no governing change" case an explicit finding (rather than a silent skip) immediately
surfaced that the same fall-through had been silently exempting the table's own `| --- | --- | --- |`
separator row from every rule too — every roadmap has exactly one such row, so this was live on every run,
just never visible because nothing needed the exemption to be an error before now. Skipped explicitly by
checking whether every cell in a row matches `[-: ]+` (the GFM header-separator syntax), rather than by
special-casing an empty second cell, so the exclusion is about the row's shape, not about any specific
column's content.

## Risks

- **A future roadmap row with a governing change that resolves to an empty match list for some other
  reason (e.g., a change name with characters outside `[a-z0-9-]`) would now fail with the new message
  instead of the old silent pass.** This is the intended behavior change — every change name observed in
  this repository is already lowercase kebab-case, matching the existing extraction pattern used
  elsewhere in this same script.
