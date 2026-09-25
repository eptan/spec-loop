#!/bin/sh
# Prints the repository's default branch name. Shared by .githooks/pre-commit (which refuses commits made
# on it) and scripts/pr.sh (which uses it as the pull request's base), so neither hard-codes `main`: a
# fork whose default branch is `master`, or anything else, gets the same guardrails without editing either
# script. The CI workflow's push trigger is the one place that still names the branch literally; the
# rename command's --default-branch option rewrites it.
#
# Resolution order, first hit wins:
#   1. origin's HEAD, as recorded by `git clone` or `git remote set-head origin -a`
#   2. a remote-tracking or local branch named main, then master
#   3. main
set -eu

head_ref=$(git symbolic-ref -q --short refs/remotes/origin/HEAD 2>/dev/null || true)
case "$head_ref" in
  origin/?*)
    printf '%s\n' "${head_ref#origin/}"
    exit 0
    ;;
esac

for candidate in main master; do
  if git show-ref --verify --quiet "refs/remotes/origin/$candidate" \
    || git show-ref --verify --quiet "refs/heads/$candidate"; then
    printf '%s\n' "$candidate"
    exit 0
  fi
done

printf '%s\n' main
