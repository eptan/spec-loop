# Design

## Context

The resolver asked `gh` about "the current repository" and trusted whichever remote `gh` chose. That is
correct only while `origin` is the sole GitHub remote. The rest of the template assumes it is not: the
upstream-tracking recipe adds a second one.

## Decisions

### Pass `origin`'s URL, not a parsed owner/name

`gh repo view` accepts a full remote URL in either SSH or HTTPS form, so the resolver hands it
`git remote get-url origin` unchanged. Parsing owner and name out of the URL would add a second place
that has to understand every URL shape `gh` already understands, for no gain.

### `origin` is the rule, not "the remote that is not `upstream`"

Any rule that inspects remote names has to decide what to do with `fork`, `github`, or a lone `upstream`.
`origin` is what `git clone` creates, what `scripts/pr.sh` pushes to for maintainers, and what
`CONTRIBUTING.md` and `TEMPLATE.md` describe; making it the one input keeps the resolver's answer
predictable from the checkout alone. A checkout without `origin` is unusual enough that failing with a
message and the explicit-argument escape hatch beats guessing.

### The fixture must be able to tell the two apart

A fake `gh` that ignores its repository argument cannot prove the fix. It now keys its answer on that
argument: `origin`'s URL gets `origin`'s repository, anything else gets a read-only stranger. With an
`upstream` remote present in every case, the unfixed resolver takes the fork path in the maintainer case
and the assertions on `--repo` and on `template.git` fail, which was confirmed by running the new fixture
against the old script before the fix.
