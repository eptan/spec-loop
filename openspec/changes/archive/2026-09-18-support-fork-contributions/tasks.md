# Tasks

## 1. Resolve the push target

- [x] 1.1 Add `scripts/resolve-pr-target.sh`, printing the target repository, push remote, head owner and
      whether a fork is needed.
- [x] 1.2 Confirm it against the real GitHub API for a repository with write access, a read-only
      non-fork, and a read-only fork.

## 2. Use it in pr.sh

- [x] 2.1 Resolve the target after `gh` authentication and derive the PR `--head` (`branch` or
      `owner:branch`).
- [x] 2.2 When no write access: create the fork if missing, add a `fork` remote, push to it with a bounded
      retry, and print what is happening.
- [x] 2.3 Open the PR with `--repo <upstream>` and scope the existing-PR lookup to that repository and
      head owner.
- [x] 2.4 Mention the behavior in `pr.sh --help`.

## 3. Test it offline

- [x] 3.1 Add `scripts/test-pr-fork.sh` covering a maintainer and a read-only contributor with local bare
      repositories and a fake `gh`.
- [x] 3.2 Wire it into `scripts/check.sh`.

## 4. Document it

- [x] 4.1 Add "Contributing Without Write Access" to `CONTRIBUTING.md`, including manual steps without the
      GitHub CLI.
- [x] 4.2 Update the `pull-request-automation` skill's list of what `pr.sh` is responsible for.

## 5. Update the contract

- [x] 5.1 Apply the `workflow-governance` delta covering fork-based PR creation.

## 6. Verification

- [x] 6.1 `scripts/test-pr-fork.sh` passes; a mutation that restores the hardcoded `origin` push makes it
      fail, and restoring the fix makes it pass again.
- [x] 6.2 Confirm the real `gh repo fork` call is the one path not exercised end to end and record why.
- [x] 6.3 Run `openspec validate support-fork-contributions --strict` and resolve any errors.
- [x] 6.4 Run `npm run check` and record the result in the PR.
