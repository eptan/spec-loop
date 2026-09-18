#!/bin/sh
set -eu

usage() {
  cat <<'EOF'
Usage:
  ./scripts/pr.sh --type TYPE --scope SCOPE --message SUMMARY --branch BRANCH [options] --all
  ./scripts/pr.sh --type TYPE --scope SCOPE --message SUMMARY --branch BRANCH [options] -- path/to/file ...

Required:
  --type TYPE        Commit type: feat, fix, docs, test, refactor, chore, ci
  --scope SCOPE      Commit scope, for example repo, greeter, openspec
  --message SUMMARY  Commit summary without the type/scope prefix
  --branch BRANCH    PR branch to create or reuse

Options:
  --base BRANCH      PR base branch. Default: main
  --title TITLE      PR title. Default: commit subject
  --body BODY        PR body text. Default: generated template
  --body-file PATH   Read PR body literally from a file
  --all             Stage all tracked and untracked changes
  --reuse-branch    Reuse an existing local branch instead of requiring a new one
  --skip-checks     Skip ./scripts/check.sh after staging. Use only for documented tool outages.
  -h, --help        Show this help

The script restores the branch that was current at startup after PR creation or failure.
It stays on the PR branch until after `gh pr create` returns.
EOF
}

die() {
  printf '%s\n' "$1" >&2
  exit 1
}

run_checks=true
stage_all=false
reuse_branch=false
base_branch=main
commit_type=
scope=
summary=
pr_branch=
pr_title=
pr_body=
body_inline=false
body_file=
paths=

while [ "$#" -gt 0 ]; do
  case "$1" in
    --type)
      shift
      [ "$#" -gt 0 ] || die "--type requires a value"
      commit_type=$1
      ;;
    --scope)
      shift
      [ "$#" -gt 0 ] || die "--scope requires a value"
      scope=$1
      ;;
    --message)
      shift
      [ "$#" -gt 0 ] || die "--message requires a value"
      summary=$1
      ;;
    --branch)
      shift
      [ "$#" -gt 0 ] || die "--branch requires a value"
      pr_branch=$1
      ;;
    --base)
      shift
      [ "$#" -gt 0 ] || die "--base requires a value"
      base_branch=$1
      ;;
    --title)
      shift
      [ "$#" -gt 0 ] || die "--title requires a value"
      pr_title=$1
      ;;
    --body)
      shift
      [ "$#" -gt 0 ] || die "--body requires a value"
      pr_body=$1
      body_inline=true
      ;;
    --body-file)
      shift
      [ "$#" -gt 0 ] || die "--body-file requires a value"
      body_file=$1
      ;;
    --all)
      stage_all=true
      ;;
    --reuse-branch)
      reuse_branch=true
      ;;
    --skip-checks)
      run_checks=false
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    --)
      shift
      while [ "$#" -gt 0 ]; do
        paths="${paths}${1}
"
        shift
      done
      break
      ;;
    --*)
      die "Unknown option: $1"
      ;;
    *)
      paths="${paths}${1}
"
      ;;
  esac
  shift
done

case "$commit_type" in
  feat|fix|docs|test|refactor|chore|ci) ;;
  *) die "--type must be one of: feat, fix, docs, test, refactor, chore, ci" ;;
esac

[ -n "$scope" ] || die "--scope is required"
[ -n "$summary" ] || die "--message is required"
[ -n "$pr_branch" ] || die "--branch is required"

if [ "$stage_all" = true ] && [ -n "$paths" ]; then
  die "Use either --all or explicit paths, not both"
fi

if [ "$stage_all" = false ] && [ -z "$paths" ]; then
  die "Specify --all or pass file paths after --"
fi

if [ "$body_inline" = true ] && [ -n "$body_file" ]; then
  die "Use either --body or --body-file, not both"
fi

if [ -n "$body_file" ]; then
  case "$body_file" in
    /*) ;;
    *) body_file="$(pwd)/$body_file" ;;
  esac
fi

command -v git >/dev/null 2>&1 || die "git is required"
command -v gh >/dev/null 2>&1 || die "GitHub CLI 'gh' is required"

repo_root=$(git rev-parse --show-toplevel)
cd "$repo_root"

if [ -n "$body_file" ]; then
  [ -f "$body_file" ] || die "PR body file does not exist: $body_file"
  [ -r "$body_file" ] || die "PR body file is not readable: $body_file"
fi

start_branch=$(git branch --show-current)
[ -n "$start_branch" ] || die "Refusing to run from a detached HEAD"

created_branch=false
committed=false

restore_branch() {
  current_branch=$(git branch --show-current || true)
  if [ -n "$current_branch" ] && [ "$current_branch" != "$start_branch" ]; then
    git switch "$start_branch" >/dev/null 2>&1 || true
  fi
  if [ "$committed" != true ]; then
    git reset >/dev/null 2>&1 || true
    if [ "$created_branch" = true ]; then
      git branch -D "$pr_branch" >/dev/null 2>&1 || true
    fi
  fi
}

require_branch() {
  expected_branch=$1
  current_branch=$(git branch --show-current)
  if [ "$current_branch" != "$expected_branch" ]; then
    die "Expected to be on $expected_branch but found $current_branch"
  fi
}

trap restore_branch EXIT INT TERM

gh auth status >/dev/null 2>&1 || die "gh is not authenticated"

if git show-ref --verify --quiet "refs/heads/$pr_branch"; then
  [ "$reuse_branch" = true ] || die "Branch exists. Use --reuse-branch to continue on it."
  git switch "$pr_branch"
else
  git switch -c "$pr_branch"
  created_branch=true
fi

# A change with every task checked must be archived before it can merge (check-openspec-archive.sh
# enforces this already) — archive it here automatically instead of requiring a separate manual step
# before every PR. Uses the same detection scripts/check-openspec-archive.sh itself relies on, so this
# never archives anything that check wouldn't already have blocked the merge over.
completed_changes=$(./scripts/list-completed-changes.sh)
if [ -n "$completed_changes" ]; then
  old_ifs=$IFS
  IFS='
'
  for change_name in $completed_changes; do
    [ -n "$change_name" ] || continue
    printf '%s\n' "Archiving completed OpenSpec change: $change_name"
    npm exec openspec -- archive "$change_name" --yes
  done
  IFS=$old_ifs
fi

if [ "$stage_all" = true ]; then
  git add -A
else
  old_ifs=$IFS
  IFS='
'
  for path in $paths; do
    [ -n "$path" ] || continue
    git add -- "$path"
  done
  IFS=$old_ifs
  # Auto-archiving above can produce files (openspec/changes/archive/**, openspec/specs/**) outside
  # any explicit path the caller passed; those are a mandatory part of this commit once the archive
  # step runs, not optional extras, so stage them regardless of staging mode.
  if [ -n "$completed_changes" ]; then
    git add -- openspec/
  fi
fi

if git diff --cached --quiet; then
  die "No staged changes to commit"
fi

./scripts/check-secrets.sh

if [ "$run_checks" = true ]; then
  ./scripts/check.sh
else
  printf '%s\n' "Skipping checks by explicit request"
fi

subject="${commit_type}(${scope}): ${summary}"
git commit -m "$subject"
committed=true

git push -u origin "$pr_branch"

require_branch "$pr_branch"

existing_pr_url=$(gh pr view "$pr_branch" --json url --jq '.url' 2>/dev/null || true)
if [ -n "$existing_pr_url" ]; then
  printf '%s\n' "$existing_pr_url"
  exit 0
fi

if [ -z "$pr_title" ]; then
  pr_title=$subject
fi

if [ -z "$pr_body" ]; then
  if [ "$run_checks" = true ]; then
    verification_line="./scripts/check.sh (ran during this PR)"
    skipped_line="None"
  else
    verification_line="./scripts/check.sh was skipped with --skip-checks"
    skipped_line="./scripts/check.sh (--skip-checks passed; document why in this PR before merging)"
  fi

  if [ -n "$completed_changes" ]; then
    openspec_line=$(printf 'Auto-archived on this PR: %s' "$(printf '%s' "$completed_changes" | tr '\n' ' ')")
  else
    openspec_line="<!-- Which OpenSpec requirement or change under openspec/changes/ this supports. -->"
  fi

  pr_body=$(printf '## Summary\n\n- %s\n\n## OpenSpec\n\n%s\n\n## Verification\n\n- %s\n\n## Skipped checks\n\n- %s\n\n## Data / reports\n\n<!-- Note if this PR changes data, reports, or experiment outputs, and where. -->\n' \
    "$summary" "$openspec_line" "$verification_line" "$skipped_line")
fi

if [ -n "$body_file" ]; then
  pr_url=$(gh pr create --base "$base_branch" --head "$pr_branch" --title "$pr_title" --body-file "$body_file")
else
  pr_url=$(gh pr create --base "$base_branch" --head "$pr_branch" --title "$pr_title" --body "$pr_body")
fi
require_branch "$pr_branch"
printf '%s\n' "$pr_url"
