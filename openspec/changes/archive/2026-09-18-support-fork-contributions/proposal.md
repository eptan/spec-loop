# Support Fork Contributions

## Dependencies

None.

## Why

Contributors who only have read access to this repository cannot contribute through the documented path.
`scripts/pr.sh` — the sanctioned way to open a pull request (`AGENTS.md`, `CONTRIBUTING.md`, the
`pull-request-automation` skill) — pushes with a hardcoded `git push -u origin "$pr_branch"` and opens the
PR with `gh pr create --head "$pr_branch"`. Both assume write access to `origin`. Anyone without it fails
at the push, and `CONTRIBUTING.md` never mentions forks, so nothing tells them what to do instead. For a
public repository whose stated purpose is to be forked and learned from, requiring push access to
contribute back is a dead end.

## What Changes

- Add `scripts/resolve-pr-target.sh`, which reports the repository a PR should target (the upstream, even
  from a clone of a fork), whether the current user can push to `origin` (`viewerPermission` of `WRITE`,
  `MAINTAIN` or `ADMIN`), and who owns the branch being pushed.
- `scripts/pr.sh` uses it: with write access nothing changes; without it, the script forks the repository
  to the user's account when no fork exists, adds a `fork` remote, pushes there (retrying briefly, since a
  new fork can take a few seconds to accept pushes), and opens the PR with `--repo <upstream>` and
  `--head <user>:<branch>`. The existing-PR lookup is scoped to the same repository and head owner.
- Add `scripts/test-pr-fork.sh`, an offline fixture (local bare repositories for upstream and fork, a fake
  `gh`) covering both the maintainer and the read-only-contributor paths, wired into `scripts/check.sh`.
- Add a "Contributing Without Write Access" section to `CONTRIBUTING.md`, including the manual steps for
  people without the GitHub CLI, and update the `pull-request-automation` skill's description of what the
  script does.
- Extend the `workflow-governance` PR-automation requirement with the fork behavior.

## Non-Goals

- No change to the merge path. Branch protection on `main` (required `quality` check, PR required) already
  applies identically to fork PRs, and merging remains a maintainer action.
- No change to CI. `.github/workflows/check.yml` already runs on `pull_request`, which GitHub triggers for
  fork PRs with a read-only token; the workflow needs no secrets. A maintainer may need to approve the
  first workflow run for a first-time contributor, which is GitHub's default and is documented.
- No automatic collaborator invitations or permission changes; this makes the contribution path work
  within the access model the repository already has.
