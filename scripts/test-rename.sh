#!/bin/sh
# Not wired into scripts/check.sh: rename-project.sh's own npm install (needed to regenerate
# package-lock.json for the new package names) makes this fixture take several seconds, unlike every
# other governance fixture here. Running that on every local commit via the pre-commit hook would
# regress this repo's fast-gate property, so this runs from scripts/check-ci-only.sh instead: once per CI
# run, and once per pull request from scripts/pr.sh, not once per commit.
set -eu

repo_root=$(git rev-parse --show-toplevel)
cd "$repo_root"

fixture_root=$(mktemp -d)
trap 'rm -rf "$fixture_root"' EXIT

# RENAME_FIXTURE_TREE lets a contributor test an uncommitted rename script: pass a tree id (for example from
# `git write-tree` against a temporary index) instead of the default HEAD.
git archive "${RENAME_FIXTURE_TREE:-HEAD}" | tar -x -C "$fixture_root"
ln -s "$repo_root/node_modules" "$fixture_root/node_modules"

cd "$fixture_root"
git init -q
git config user.email "fixture@example.com"
git config user.name "fixture"
git add -A
git commit -q -m "fixture" --no-verify

# A name and owner of clearly different length than the original reproduce the Markdown
# table column-width drift a same-length rename would not surface.
expected_upstream=$(node -p "require('./package.json').template.upstream")

./scripts/rename-project.sh a-much-longer-fixture-project-name --owner a-much-longer-fixture-owner --default-branch trunk >/dev/null

if ! npx --no-install prettier --check . --ignore-unknown; then
  printf '%s\n' "rename-project.sh left files that fail 'prettier --check' — its own format step regressed" >&2
  exit 1
fi

# The upstream template URL must survive the rename (a fork's TEMPLATE.md would otherwise tell its owner to
# track the fork itself), while the identity strings around it are still rewritten.
grep -qF -- "$expected_upstream" TEMPLATE.md \
  || { printf '%s\n' "rename-project.sh rewrote the upstream template URL in TEMPLATE.md; it must survive a rename" >&2; exit 1; }
[ "$(node -p "require('./package.json').template.upstream")" = "$expected_upstream" ] \
  || { printf '%s\n' "rename-project.sh rewrote package.json's template.upstream; it must survive a rename" >&2; exit 1; }
case "$(node -p "require('./package.json').repository.url")" in
  *a-much-longer-fixture-owner/a-much-longer-fixture-project-name*) ;;
  *)
    printf '%s\n' "rename-project.sh left package.json's repository.url unrenamed" >&2
    exit 1
    ;;
esac

grep -q '^ *branches: \[trunk\]' .github/workflows/check.yml \
  || { printf '%s\n' "rename-project.sh --default-branch trunk did not rewrite the CI push trigger" >&2; exit 1; }

printf '%s\n' "Rename fixture passed (formatting, upstream URL preserved, CI push trigger rewritten)"
