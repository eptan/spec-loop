#!/bin/sh
# Not wired into scripts/check.sh: rename-project.sh's own npm install (needed to regenerate
# package-lock.json for the new package names) makes this fixture take several seconds, unlike every
# other governance fixture here. Running that on every local commit via the pre-commit hook would
# regress this repo's fast-gate property, so this runs as a separate CI step instead
# (.github/workflows/check.yml) — once per push, not once per commit.
set -eu

repo_root=$(git rev-parse --show-toplevel)
cd "$repo_root"

fixture_root=$(mktemp -d)
trap 'rm -rf "$fixture_root"' EXIT

git archive HEAD | tar -x -C "$fixture_root"
ln -s "$repo_root/node_modules" "$fixture_root/node_modules"

cd "$fixture_root"
git init -q
git config user.email "fixture@example.com"
git config user.name "fixture"
git add -A
git commit -q -m "fixture" --no-verify

# A name and owner of clearly different length than the original reproduce the Markdown
# table column-width drift a same-length rename would not surface.
./scripts/rename-project.sh a-much-longer-fixture-project-name --owner a-much-longer-fixture-owner >/dev/null

if ! npx --no-install prettier --check . --ignore-unknown; then
  printf '%s\n' "rename-project.sh left files that fail 'prettier --check' — its own format step regressed" >&2
  exit 1
fi

printf '%s\n' "Rename formatting fixture passed"
