#!/bin/sh
set -eu

staged_files=$(git diff --cached --name-only --diff-filter=ACMR)

zero_sha=0000000000000000000000000000000000000000
case "${CHECK_DIFF_RANGE:-}" in
  "$zero_sha"...*)
    printf '%s\n' "CHECK_DIFF_RANGE has no real base commit (zero SHA, e.g. a new branch's first push); skipping documentation freshness check for this push"
    exit 0
    ;;
esac

if [ -z "$staged_files" ] && [ -n "${CHECK_DIFF_RANGE:-}" ]; then
  staged_files=$(git diff --name-only --diff-filter=ACMR "$CHECK_DIFF_RANGE")
fi

if [ -z "$staged_files" ]; then
  printf '%s\n' "No staged or changed files; skipping documentation freshness check"
  exit 0
fi

needs_docs=false
has_docs=false

for file in $staged_files; do
  case "$file" in
    README.md|AGENTS.md|CLAUDE.md|CONTRIBUTING.md|docs/*|openspec/*)
      has_docs=true
      ;;
  esac

  case "$file" in
    src/*|apps/*|packages/*|tools/*|configs/*|scripts/*|.githooks/*|.github/*|.agent/*|.agents|.claude/*|.opencode/*|pyproject.toml|uv.lock|package.json|package-lock.json|pnpm-lock.yaml|yarn.lock|nx.json|tsconfig*.json|next.config.*)
      needs_docs=true
      ;;
  esac
done

if [ "$needs_docs" = true ] && [ "$has_docs" = false ]; then
  if [ "${CHECK_DEPENDABOT:-false}" = true ]; then
    printf '%s\n' "Documentation freshness check passed (Dependabot-only update)"
    exit 0
  fi

  cat >&2 <<'EOF'
Staged implementation or workflow files changed without staged docs/specs.

Add or update at least one relevant file under:
- openspec/
- docs/
- README.md
- AGENTS.md
- CONTRIBUTING.md

Then rerun: ./scripts/check-docs.sh
EOF
  exit 1
fi

printf '%s\n' "Documentation freshness check passed"
