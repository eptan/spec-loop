#!/bin/sh
set -eu

fail() {
  printf '%s\n' "$1" >&2
  exit 1
}

[ -f docs/dependency-patterns.md ] || fail "Missing dependency pattern documentation"
[ -f plans/roadmap.md ] || fail "Missing roadmap"

grep -q '^## OpenSpec Dependencies$' docs/dependency-patterns.md \
  || fail "Dependency documentation must define the OpenSpec dependency convention"

# TEMPLATE.md tells a fork owner to replace each teaching example's implementation and test, removing the
# TEMPLATE:REPLACE marker from both in the process. This check names no package: it looks at every
# packages/*/src/index.ts and index.test.ts pair, so it needs no edit once packages/hello is replaced or
# removed. It accepts the unforked state (both files carry the marker) and a finished replacement (neither
# does), and fails only on a half-finished one, where the two files of a pair disagree.
pairs=0
for impl in packages/*/src/index.ts; do
  [ -f "$impl" ] || continue
  test_file="${impl%.ts}.test.ts"
  [ -f "$test_file" ] || continue
  pairs=$((pairs + 1))
  package_dir=$(dirname "$(dirname "$impl")")
  impl_has_marker=false
  test_has_marker=false
  grep -q 'TEMPLATE:REPLACE' "$impl" && impl_has_marker=true
  grep -q 'TEMPLATE:REPLACE' "$test_file" && test_has_marker=true
  if [ "$impl_has_marker" != "$test_has_marker" ]; then
    fail "$package_dir's implementation and test disagree on the TEMPLATE:REPLACE marker — finish replacing both, or restore the marker in both, before running this check"
  fi
done

[ "$pairs" -gt 0 ] || fail "No package under packages/ has both src/index.ts and src/index.test.ts; the workspace needs at least one tested library"

printf '%s\n' "Repository convention check passed"
