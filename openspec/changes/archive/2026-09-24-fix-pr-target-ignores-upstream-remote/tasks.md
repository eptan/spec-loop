# Tasks

## 1. Resolver

- [x] 1.1 Resolve the repository from `git remote get-url origin` when no argument is given, pass it to
      `gh repo view` explicitly, and fail with a message when there is no `origin`.
- [x] 1.2 Explain in the script header why the choice is not left to `gh`.

## 2. Fixture

- [x] 2.1 Add an `upstream` remote to each fixture checkout, backed by a third bare repository.
- [x] 2.2 Make the fake `gh` answer as a read-only `template/tmpl` unless the repository argument equals
      `origin`'s URL.
- [x] 2.3 Assert the maintainer PR targets `acme/proj` and that no case pushes a branch to `template.git`.

## 3. Docs and contract

- [x] 3.1 `TEMPLATE.md`: the `upstream` remote is only for pulling and never redirects pull requests.
- [x] 3.2 Apply the `workflow-governance` delta.

## 4. Verification

- [x] 4.1 `./scripts/test-pr-fork.sh` fails against the unfixed resolver with the new fixture and passes
      with the fix.
- [x] 4.2 `./scripts/resolve-pr-target.sh` in this checkout, with an `upstream` remote present, prints
      this repository as the target; `gh repo view` accepts both `git@github.com:owner/name.git` and
      `https://github.com/owner/name.git`.
- [x] 4.3 `npm exec openspec -- validate fix-pr-target-ignores-upstream-remote --strict` passes.
- [x] 4.4 `npm run check` and `./scripts/check-ci-only.sh` pass.
- [x] 4.5 Record the output of 4.4 in the pull request.
