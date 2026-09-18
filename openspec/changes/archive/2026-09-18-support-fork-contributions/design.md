# Design

## Context

Two things were hardwired to "the user can push to `origin`": the push, and the PR's `--head`. The fix is
to decide both from the user's actual permission, not to assume it.

## Decisions

### A resolver script, separate from `pr.sh`

Where a branch goes and where the PR points is a pure question about the repository and the user, with four
small answers. Keeping it in `scripts/resolve-pr-target.sh` gives it a seam that can be tested against the
real GitHub API without pushing anything: `github/gitignore` (read-only for this account, not a fork) and
`tpw123789/gitignore` (read-only, a fork of it) are genuine "no write access" cases, and this repository is
the "write access" case. All three resolved correctly.

### Permission decides, not "is this a fork"

Cloning your own fork is the most common contributor setup, and there you _can_ push to `origin` — the
right move is to push there and target the parent. Cloning the upstream directly is the other common setup,
and there you cannot push. `viewerPermission` distinguishes them; `isFork`/`parent` only determine the PR's
target repository. Testing "is `origin` a fork" alone would mishandle one of the two.

### Ask before forking? No — the script already means "open a PR"

Creating a fork writes to the contributor's account, which is an outward-facing action. It is the direct,
necessary consequence of the command the contributor chose to run to open a pull request, `pr.sh` already
requires explicit authorization to run at all (`AGENTS.md`), and the script says what it is doing before it
does it. An extra confirmation prompt would also break the non-interactive use the script is built for.

### Existence check before `gh repo fork`

`pr.sh` checks whether the fork exists before creating one rather than relying on how `gh repo fork`
behaves when it already does, so the re-run of a failed attempt is a no-op for that step.

### Bounded retry on the push to a fork only

A fork created moments earlier can reject pushes for a few seconds. The push retries up to five times, three
seconds apart, only when pushing to `fork`; a push to `origin` still fails immediately, as before.

### An offline fixture, wired into the gate

`scripts/test-pr-fork.sh` uses local bare repositories as upstream and fork so `git push` is real, and a
fake `gh` that records what the script asked for. It runs in about 1.5 seconds with no network, so it goes in
`scripts/check.sh` (unlike the rename fixture, which needs `npm install`). To confirm it can fail, the
push line in `pr.sh` was temporarily reverted to the old hardcoded `origin`; the fixture failed with "branch
was not pushed to the fork", then passed again once restored.

## Risks

- **The real `gh repo fork` call is not exercised end to end.** Forking this account's own repository is not
  possible, and creating a throwaway fork of someone else's repository would leave a real fork on the
  maintainer's account. The fork step is covered by the fixture (the fake `gh` records the `repo fork` call against the upstream) and the resolver by the real API; the one untested seam is `gh repo fork` itself, whose
  documented invocation (`--clone=false`) is used unchanged.
- **The fork keeps its original repository name.** A contributor who renamed their fork will not be found
  by the existence check, which would attempt a second fork and let `gh` report the conflict. Rare; the
  manual steps in `CONTRIBUTING.md` cover it.
