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
Usage: npm run rename -- <new-name> [--owner <owner>] [--title <title>] [--description <description>]

  <new-name>     New kebab-case project name (e.g. my-project).
  --owner        New GitHub owner/org (defaults to the current owner).
  --title        New title-case display name (defaults to Title-Casing <new-name>).
  --description  New package.json description (defaults to leaving it unchanged).
EOF
  exit 1
}

[ $# -ge 1 ] || usage

new_name=""
new_owner=""
new_title=""
new_description=""

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

if [ "$old_name" = "$new_name" ] && [ "$old_owner" = "$new_owner" ]; then
  printf '%s\n' "Already named '$new_name' under owner '$new_owner'; nothing to rename."
  exit 0
fi

printf 'Renaming %s (owner: %s) -> %s (owner: %s)\n' "$old_name" "$old_owner" "$new_name" "$new_owner"

exclude_path() {
  case "$1" in
    openspec/changes/archive/* | node_modules/* | dist/* | .git/*) return 0 ;;
    *) return 1 ;;
  esac
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

printf 's/@%s/@%s/g\n' "$old_name" "$new_name" >> "$rename_sed"
printf 's/%s\/%s/%s\/%s/g\n' "$old_owner" "$old_name" "$new_owner" "$new_name" >> "$rename_sed"
printf 's/%s/%s/g\n' "$old_title" "$new_title" >> "$rename_sed"
printf 's/%s/%s/g\n' "$old_name" "$new_name" >> "$rename_sed"
printf 's/%s/%s/g\n' "$old_owner" "$new_owner" >> "$rename_sed"

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

# Content rewrite: every tracked, non-excluded file gets rewritten in place, preserving its mode.
files=$(git ls-files)
for f in $files; do
  exclude_path "$f" && continue
  [ -f "$f" ] || continue
  if grep -qF -- "$old_name" "$f" 2>/dev/null || grep -qF -- "$old_owner" "$f" 2>/dev/null || grep -qF -- "$old_title" "$f" 2>/dev/null; then
    sed -i.bak -f "$rename_sed" "$f"
    rm -f "$f.bak"
  fi
done

if [ -n "$new_description" ]; then
  node -e "
    const fs = require('fs');
    const p = JSON.parse(fs.readFileSync('package.json', 'utf8'));
    p.description = process.argv[1];
    fs.writeFileSync('package.json', JSON.stringify(p, null, 2) + '\n');
  " "$new_description"
fi

# Filename rewrite, directories first (deepest first) then files, both computed from a fresh
# `git ls-files` snapshot taken right before each pass so a directory rename never leaves a stale
# path queued behind it.
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

# A replacement of different length than the original (in a name, owner, or title) shifts Markdown
# table column widths. Reformat before npm install so the rename's own output is never what makes the
# closing `npm run check` fail.
npm run format >/dev/null

npm install

printf '%s\n' "Rename complete. Run 'npm run check' to verify."
