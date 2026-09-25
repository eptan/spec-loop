#!/bin/sh
# Requires network access to the npm registry; intentionally not part of scripts/check.sh (the local,
# offline gate). Runs from scripts/check-ci-only.sh, in CI and from scripts/pr.sh before a pull request.
# See docs/dependency-advisories.md for the accepted-advisory convention this script enforces.
set -eu

audit_json=$(npm audit --json || true)

found_ids=$(printf '%s' "$audit_json" | node -e "
let data = '';
process.stdin.on('data', (d) => { data += d; });
process.stdin.on('end', () => {
  let json;
  try {
    json = JSON.parse(data);
  } catch {
    process.exit(0);
  }
  const ids = new Set();
  for (const advisory of Object.values(json.vulnerabilities || {})) {
    for (const via of advisory.via || []) {
      if (via && typeof via === 'object' && typeof via.url === 'string') {
        const match = via.url.match(/GHSA-[a-zA-Z0-9-]+/);
        if (match) ids.add(match[0]);
      }
    }
  }
  console.log([...ids].join('\n'));
});
")

if [ -z "$found_ids" ]; then
  printf '%s\n' "Dependency advisory check passed (no advisories reported)"
  exit 0
fi

accepted=$(grep -oE 'GHSA-[a-zA-Z0-9-]+' docs/dependency-advisories.md 2>/dev/null || true)

new_findings=""
for id in $found_ids; do
  if ! printf '%s\n' "$accepted" | grep -qxF "$id"; then
    new_findings="${new_findings}${id}
"
  fi
done

if [ -n "$new_findings" ]; then
  printf '%s\n' "New, unreviewed dependency advisories found:" >&2
  printf '%s' "$new_findings" >&2
  printf '%s\n' "Record a decision in docs/dependency-advisories.md (accept with rationale, or update the dependency) before merging." >&2
  exit 1
fi

printf '%s\n' "Dependency advisory check passed (all findings already reviewed in docs/dependency-advisories.md)"
