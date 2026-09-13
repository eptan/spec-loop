#!/bin/sh
set -eu

diff_range=""
files=$(git diff --cached --name-only --diff-filter=ACMR)

if [ -z "$files" ] && [ -n "${CHECK_DIFF_RANGE:-}" ]; then
  diff_range="$CHECK_DIFF_RANGE"
  zero_sha=0000000000000000000000000000000000000000
  case "$diff_range" in
    "$zero_sha"...*)
      # No real base commit (zero SHA, e.g. a new branch's first push). Unlike documentation
      # freshness, "scan nothing" is the wrong default for a secret scan — fall back to the
      # conservative choice and scan from the repository's root commit instead.
      root_sha=$(git rev-list --max-parents=0 HEAD | tail -1)
      diff_range="${root_sha}...${diff_range#*...}"
      ;;
  esac
  files=$(git diff --name-only --diff-filter=ACMR "$diff_range")
fi

if [ -z "$files" ]; then
  exit 0
fi

blocked_paths=""

# Split only on newlines, not spaces/tabs, so a path containing a space is one entry, not several.
# Also collect the same list as positional parameters ("$@") for safe, unsplit use with `git diff --`
# below, since an unquoted `-- $files` would re-split on whitespace a second time.
old_ifs=$IFS
IFS='
'
set --
for file in $files; do
  set -- "$@" "$file"
  case "$file" in
    .env|.env.*|*.tmp|*.tmp.*|runs/*|coverage/*|dist/*|.nx/*)
      if [ "$file" != ".env.example" ]; then
        blocked_paths="${blocked_paths}${file}
"
      fi
      ;;
  esac
done
IFS=$old_ifs

if [ -n "$blocked_paths" ]; then
  printf '%s\n' "Refusing to commit local secrets or transient artifacts:" >&2
  printf '%s\n' "$blocked_paths" >&2
  exit 1
fi

if command -v gitleaks >/dev/null 2>&1; then
  if [ -n "$diff_range" ]; then
    gitleaks detect --source . --no-banner --redact --log-opts="$diff_range"
  else
    gitleaks protect --staged --no-banner --redact
  fi
  printf '%s\n' "Secret check passed (engine: gitleaks)"
else
  printf '%s\n' "gitleaks not found; falling back to a narrow secret pattern check. This fallback is a review guard, not a guarantee — it matches only a fixed list of keyword-style assignments. Install gitleaks for full coverage: https://github.com/gitleaks/gitleaks#installing" >&2

  if [ -n "$diff_range" ]; then
    secret_matches=$(git diff --text --name-only -G'(API_KEY|SECRET|TOKEN|PASSWORD)[[:space:]]*=[[:space:]]*["'"''][^"'"'']{8,}' "$diff_range" -- "$@")
  else
    secret_matches=$(git diff --cached --text --name-only -G'(API_KEY|SECRET|TOKEN|PASSWORD)[[:space:]]*=[[:space:]]*["'"''][^"'"'']{8,}' -- "$@")
  fi

  if [ -n "$secret_matches" ]; then
    printf '%s\n' "Staged changes may contain a secret or long token. Review before committing." >&2
    printf '%s\n' "$secret_matches" >&2
    exit 1
  fi
  printf '%s\n' "Secret check passed (engine: fallback pattern, not gitleaks)"
fi
