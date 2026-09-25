#!/bin/sh
# Renames every tracked identity string (kebab-case project name, npm scope, GitHub owner,
# repository URLs, title-case name) and every tracked file/directory whose name contains the old
# kebab-case project name. See openspec/specs/template-rename-tooling/spec.md for the contract.
set -eu

fail() {
  printf '%s\n' "Error: $1" >&2
  exit 1
}

usage() {
  cat >&2 <<'EOF'
Usage: npm run rename -- <new-name> [--owner <owner>] [--title <title>] [--description <description>] [--default-branch <branch>]

  <new-name>     New kebab-case project name (e.g. my-project).
  --owner        New GitHub owner/org (defaults to the current owner).
  --title        New title-case display name (defaults to Title-Casing <new-name>).
  --description  New package.json description (defaults to leaving it unchanged).
  --default-branch  Branch to name in the CI workflow's push trigger (defaults to leaving it unchanged).
EOF
  exit 1
}

[ $# -ge 1 ] || usage

new_name=""
new_owner=""
new_title=""
new_description=""
new_default_branch=""

while [ $# -gt 0 ]; do
  case "$1" in
    --owner)
      [ $# -ge 2 ] || fail "--owner requires a value"
      new_owner="$2"
      shift 2
      ;;
    --title)
      [ $# -ge 2 ] || fail "--title requires a value"
      new_title="$2"
      shift 2
      ;;
    --description)
      [ $# -ge 2 ] || fail "--description requires a value"
      new_description="$2"
      shift 2
      ;;
    --default-branch)
      [ $# -ge 2 ] || fail "--default-branch requires a value"
      new_default_branch="$2"
      shift 2
      ;;
    -h | --help)
      usage
      ;;
    -*)
      fail "Unknown flag: $1"
      ;;
    *)
      if [ -n "$new_name" ]; then
        fail "Unexpected extra argument: $1"
      fi
      new_name="$1"
      shift
      ;;
  esac
done

[ -n "$new_name" ] || usage

case "$new_name" in
  [a-z0-9]*)
    case "$new_name" in
      *[!a-z0-9-]* | *--* | *-)
        fail "New name '$new_name' must be lowercase kebab-case (letters, digits, single hyphens, no leading/trailing hyphen)"
        ;;
    esac
    ;;
  *)
    fail "New name '$new_name' must be lowercase kebab-case (letters, digits, single hyphens)"
    ;;
esac

if [ -n "$new_owner" ]; then
  case "$new_owner" in
    [A-Za-z0-9]*)
      case "$new_owner" in
        *[!A-Za-z0-9-]* | *--* | *-)
          fail "New owner '$new_owner' must be alphanumeric with single hyphens (no leading/trailing/double hyphen)"
          ;;
      esac
      ;;
    *)
      fail "New owner '$new_owner' must be alphanumeric with single hyphens (no leading/trailing/double hyphen)"
      ;;
  esac
fi

if [ -n "$new_default_branch" ]; then
  case "$new_default_branch" in
    [A-Za-z0-9]*)
      case "$new_default_branch" in
        *[!A-Za-z0-9._/-]* | *..* | */ | *.lock)
          fail "New default branch '$new_default_branch' must be a plain git branch name (letters, digits, '.', '_', '/', '-'; no '..', no trailing '/', no '.lock')"
          ;;
      esac
      ;;
    *)
      fail "New default branch '$new_default_branch' must start with a letter or digit"
      ;;
  esac
fi

[ -f package.json ] || fail "Must be run from the repository root (package.json not found)"

if [ -n "$(git status --porcelain)" ]; then
  fail "Working tree is not clean. Commit or stash changes before renaming."
fi

old_name=$(node -p "require('./package.json').name")
old_owner=$(node -p "(require('./package.json').repository && require('./package.json').repository.url || '').match(/github\.com[:/]+([^/]+)\//)?.[1] || ''")
[ -n "$old_owner" ] || fail "Could not determine current GitHub owner from package.json's repository.url"

old_title=$(node -e "const n=process.argv[1]; console.log(n.split('-').map(w=>w.charAt(0).toUpperCase()+w.slice(1)).join(' '))" "$old_name")

new_owner="${new_owner:-$old_owner}"
new_title="${new_title:-$(node -e "const n=process.argv[1]; console.log(n.split('-').map(w=>w.charAt(0).toUpperCase()+w.slice(1)).join(' '))" "$new_name")}"

identity_changed=true
if [ "$old_name" = "$new_name" ] && [ "$old_owner" = "$new_owner" ]; then
  identity_changed=false
  if [ -z "$new_default_branch" ]; then
    printf '%s\n' "Already named '$new_name' under owner '$new_owner'; nothing to rename."
    exit 0
  fi
fi

if [ "$identity_changed" = true ]; then
  printf 'Renaming %s (owner: %s) -> %s (owner: %s)\n' "$old_name" "$old_owner" "$new_name" "$new_owner"
fi

exclude_path() {
  case "$1" in
    openspec/changes/archive/* | node_modules/* | dist/* | .git/*) return 0 ;;
    *) return 1 ;;
  esac
}

# --title and --description are free text (unlike <new-name> and --owner, which are validated to a
# safe character set), so a value containing a sed delimiter or backreference character would
# otherwise break or silently corrupt the substitution below. Escape every value going into a sed
# pattern or replacement, not only the ones that could plausibly carry one today.
sed_escape() {
  printf '%s' "$1" | sed -e 's/\\/\\\\/g' -e 's/&/\\\&/g' -e 's#/#\\/#g'
}

# Archived OpenSpec change ids (directory name minus its date prefix) are historical identifiers
# that can legitimately embed the old project name (e.g. `improve-agentic-boiler-governance`).
# Living files that reference such an id by name (roadmap rows, dependency sections) must keep
# pointing at the archived directory's real, unrenamed name. Protect each one with a placeholder
# before the generic substitution below, then restore it afterward. Everything is combined into one
# sed script applied with a single in-place `sed -i` per file so file permissions (an executable
# script's +x bit) survive the rewrite instead of being reset by an intermediate temp-file copy.
rename_sed=$(mktemp)
trap 'rm -f "$rename_sed"' EXIT

# The upstream template URL (package.json's template.upstream, quoted verbatim in TEMPLATE.md's
# upstream-tracking recipe) names the repository this one was forked from, so it must survive a rename even
# though it contains the old owner and name. Protect it with a placeholder on every line that names
# `upstream`, and restore it after the identity substitutions. package.json's own repository, bugs, and
# homepage lines never name `upstream`, so they are still rewritten.
template_upstream=$(node -p "((require('./package.json').template || {}).upstream) || ''")
if [ -n "$template_upstream" ]; then
  printf '/upstream/s/%s/RENAME_PROTECT_UPSTREAM_TOKEN/g\n' "$(sed_escape "$template_upstream")" >> "$rename_sed"
fi

if [ -d openspec/changes/archive ]; then
  idx=0
  for entry in openspec/changes/archive/*/; do
    [ -d "$entry" ] || continue
    base=$(basename "$entry")
    id=$(printf '%s' "$base" | sed -E 's/^[0-9]{4}-[0-9]{2}-[0-9]{2}-//')
    [ -n "$id" ] || continue
    idx=$((idx + 1))
    placeholder="RENAME_PROTECT_${idx}_TOKEN"
    printf 's/%s/%s/g\n' "$id" "$placeholder" >> "$rename_sed"
  done
fi

esc_old_name=$(sed_escape "$old_name")
esc_new_name=$(sed_escape "$new_name")
esc_old_owner=$(sed_escape "$old_owner")
esc_new_owner=$(sed_escape "$new_owner")
esc_old_title=$(sed_escape "$old_title")
esc_new_title=$(sed_escape "$new_title")

printf 's/@%s/@%s/g\n' "$esc_old_name" "$esc_new_name" >> "$rename_sed"
printf 's/%s\/%s/%s\/%s/g\n' "$esc_old_owner" "$esc_old_name" "$esc_new_owner" "$esc_new_name" >> "$rename_sed"
printf 's/%s/%s/g\n' "$esc_old_title" "$esc_new_title" >> "$rename_sed"
printf 's/%s/%s/g\n' "$esc_old_name" "$esc_new_name" >> "$rename_sed"
printf 's/%s/%s/g\n' "$esc_old_owner" "$esc_new_owner" >> "$rename_sed"

if [ -d openspec/changes/archive ]; then
  idx=0
  for entry in openspec/changes/archive/*/; do
    [ -d "$entry" ] || continue
    base=$(basename "$entry")
    id=$(printf '%s' "$base" | sed -E 's/^[0-9]{4}-[0-9]{2}-[0-9]{2}-//')
    [ -n "$id" ] || continue
    idx=$((idx + 1))
    placeholder="RENAME_PROTECT_${idx}_TOKEN"
    printf 's/%s/%s/g\n' "$placeholder" "$id" >> "$rename_sed"
  done
fi

if [ -n "$template_upstream" ]; then
  printf 's/RENAME_PROTECT_UPSTREAM_TOKEN/%s/g\n' "$(sed_escape "$template_upstream")" >> "$rename_sed"
fi

# Content rewrite: every tracked, non-excluded file gets rewritten in place, preserving its mode.
# Split only on newlines, not spaces/tabs, so a tracked path containing a space is one entry.
if [ "$identity_changed" = true ]; then
  old_ifs=$IFS
  IFS='
'
  files=$(git ls-files)
  for f in $files; do
    exclude_path "$f" && continue
    [ -f "$f" ] || continue
    if grep -qF -- "$old_name" "$f" 2>/dev/null || grep -qF -- "$old_owner" "$f" 2>/dev/null || grep -qF -- "$old_title" "$f" 2>/dev/null; then
      sed -i.bak -f "$rename_sed" "$f"
      rm -f "$f.bak"
    fi
  done
  IFS=$old_ifs
fi

if [ -n "$new_description" ]; then
  node -e "
    const fs = require('fs');
    const p = JSON.parse(fs.readFileSync('package.json', 'utf8'));
    p.description = process.argv[1];
    fs.writeFileSync('package.json', JSON.stringify(p, null, 2) + '\n');
  " "$new_description"
fi

# The CI workflow's push trigger is the one place the default branch is named literally (the pre-commit
# hook and scripts/pr.sh detect it through scripts/default-branch.sh), so it is the one place a fork that
# uses another default branch has to change.
if [ -n "$new_default_branch" ]; then
  workflow=.github/workflows/check.yml
  [ -f "$workflow" ] || fail "--default-branch: $workflow not found"
  old_default_branch=$(sed -n -E 's/^ *branches: \[([^]]+)\] *$/\1/p' "$workflow" | sed -n '1p')
  [ -n "$old_default_branch" ] || fail "--default-branch: no 'branches: [...]' push trigger found in $workflow"
  if [ "$old_default_branch" != "$new_default_branch" ]; then
    sed -i.bak "s/^\( *branches: \)\[$(sed_escape "$old_default_branch")]/\1[$(sed_escape "$new_default_branch")]/" "$workflow"
    rm -f "$workflow.bak"
    printf 'CI push trigger: %s -> %s\n' "$old_default_branch" "$new_default_branch"
  fi
fi

# Filename rewrite, directories first (deepest first) then files, both computed from a fresh
# `git ls-files` snapshot taken right before each pass so a directory rename never leaves a stale
# path queued behind it. Skipped when only --default-branch changed: no tracked name contains a
# different old name then, and `git mv` refuses to move a path onto itself.
if [ "$old_name" != "$new_name" ]; then
dirs_to_rename=$(git ls-files | while IFS= read -r f; do dirname "$f"; done | sort -u | grep -F -- "$old_name" || true)
if [ -n "$dirs_to_rename" ]; then
  printf '%s\n' "$dirs_to_rename" | awk -F/ '{ print NF, $0 }' | sort -rn | cut -d' ' -f2- | while IFS= read -r dir; do
    exclude_path "$dir/" && continue
    [ -d "$dir" ] || continue
    parent=$(dirname "$dir")
    base=$(basename "$dir")
    case "$base" in
      *"$old_name"*)
        new_base=$(printf '%s' "$base" | sed "s/${old_name}/${new_name}/g")
        git mv "$dir" "$parent/$new_base"
        ;;
    esac
  done
fi

files_to_rename=$(git ls-files | while IFS= read -r f; do
  exclude_path "$f" && continue
  base=$(basename "$f")
  case "$base" in (*"$old_name"*) printf '%s\n' "$f" ;; esac
done)
if [ -n "$files_to_rename" ]; then
  printf '%s\n' "$files_to_rename" | while IFS= read -r path; do
    [ -f "$path" ] || continue
    dir=$(dirname "$path")
    base=$(basename "$path")
    new_base=$(printf '%s' "$base" | sed "s/${old_name}/${new_name}/g")
    git mv "$path" "$dir/$new_base"
  done
fi
fi

# A replacement of different length than the original (in a name, owner, or title) shifts Markdown
# table column widths. Reformat before npm install so the rename's own output is never what makes the
# closing `npm run check` fail.
npm run format >/dev/null

npm install

printf '%s\n' "Rename complete. Run 'npm run check' to verify."
