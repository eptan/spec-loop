#!/bin/sh
set -eu

fail() {
  printf '%s\n' "$1" >&2
  exit 1
}

[ -f docs/agent-attribution.md ] || fail "Missing agent attribution policy"
[ -f .agent/skills/neutral-repository-attribution/SKILL.md ] \
  || fail "Missing canonical neutral attribution skill"

grep -q 'Neutral Repository Attribution' AGENTS.md \
  || fail "AGENTS.md must link the neutral attribution policy"
grep -q 'neutral-repository-attribution' AGENTS.md \
  || fail "AGENTS.md must name the canonical neutral attribution skill"
grep -q '^## Platform Boundary$' docs/agent-attribution.md \
  || fail "Attribution policy must define a Platform Boundary section"

printf '%s\n' "Agent attribution check passed"
