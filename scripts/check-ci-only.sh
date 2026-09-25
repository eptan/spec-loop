#!/bin/sh
# The checks CI runs in addition to scripts/check.sh, defined once so CI and scripts/pr.sh run the same
# list and it cannot drift. Both checks need the network or take several seconds, which is why they stay
# out of the local, offline, per-commit gate (each script's own header says why). scripts/pr.sh runs this
# after committing and before pushing: a pull request is the moment the network is required anyway, and a
# branch that is green locally but red in CI on a check it never ran is the surprise this file prevents.
set -eu

./scripts/test-rename.sh
./scripts/check-dependency-advisories.sh

printf '%s\n' "CI-only checks passed"
