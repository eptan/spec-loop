#!/bin/sh
set -eu

fail() {
  printf '%s\n' "$1" >&2
  exit 1
}

[ -f docs/dependency-patterns.md ] || fail "Missing dependency pattern documentation"
[ -f plans/roadmap.md ] || fail "Missing roadmap"
[ -f packages/hello/src/index.ts ] || fail "Missing current example implementation"
[ -f packages/hello/src/index.test.ts ] || fail "Missing current example test"

grep -q '^## OpenSpec Dependencies$' docs/dependency-patterns.md \
  || fail "Dependency documentation must define the OpenSpec dependency convention"

# TEMPLATE.md tells a fork owner to replace packages/hello's implementation and test, removing the
# TEMPLATE:REPLACE marker in the process. This check must tolerate that finished state (neither file
# carries the marker) as well as this repository's own unforked state (both carry it) — it exists only
# to catch a half-finished replacement, where one file was updated and the other was not.
impl_has_marker=false
test_has_marker=false
grep -q 'TEMPLATE:REPLACE' packages/hello/src/index.ts && impl_has_marker=true
grep -q 'TEMPLATE:REPLACE' packages/hello/src/index.test.ts && test_has_marker=true

if [ "$impl_has_marker" != "$test_has_marker" ]; then
  fail "packages/hello's implementation and test disagree on the TEMPLATE:REPLACE marker — finish replacing both, or restore the marker in both, before running this check"
fi

printf '%s\n' "Repository convention check passed"
