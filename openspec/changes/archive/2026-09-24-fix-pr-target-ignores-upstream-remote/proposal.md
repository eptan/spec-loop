# Fix PR Target Ignores Upstream Remote

## Dependencies

None.

## Why

`scripts/resolve-pr-target.sh` decides which repository a pull request targets by running `gh repo view`
with no repository argument (`scripts/resolve-pr-target.sh:11`), which leaves the choice of remote to the
GitHub CLI. The CLI prefers a remote named `upstream` over `origin`. `TEMPLATE.md`'s upstream-tracking
section tells every fork owner to add exactly that remote, pointing at this template. Once they do,
`scripts/pr.sh` resolves the template as the target repository, sees the owner has no write access to it,
pushes the branch to a fork of the template (creating one if needed), and opens the pull request against
the template. GitHub rejects the pull request because the two histories share no commits, but by then a
branch of the project's code sits on a fork of the template under the owner's account. A fork that
followed both `TEMPLATE.md` and `CONTRIBUTING.md` verbatim hit this on its first `scripts/pr.sh` run
after adding the remote.

`scripts/test-pr-fork.sh` did not catch it because its fixture checkouts have only `origin`, and its fake
`gh` ignores the repository argument.

## What Changes

- `scripts/resolve-pr-target.sh` passes the repository to `gh` explicitly: the optional argument when
  given, otherwise the URL `origin` points at (`git remote get-url origin`; `gh` accepts SSH and HTTPS
  URLs). A checkout with no `origin` fails with a message rather than letting `gh` guess.
- `scripts/test-pr-fork.sh` adds an `upstream` remote (a third bare repository) to each fixture checkout,
  makes its fake `gh` answer as a different read-only repository unless asked about `origin`'s URL
  explicitly, and asserts that the maintainer's pull request still targets `origin`'s repository and that
  neither case pushes a branch to `upstream`.
- `TEMPLATE.md` says the `upstream` remote is only for pulling and never redirects pull requests.
- The `workflow-governance` PR-automation requirement gains the rule and a scenario.

## Non-Goals

- No change to how the target is derived once the repository is known: `origin`'s parent when `origin` is
  a fork, `origin` itself otherwise, with the push remote decided by permission, all as before.
- No change to the manual fork workflow in `CONTRIBUTING.md`, which already names the repository
  explicitly.
