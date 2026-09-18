#!/bin/sh
set -eu

unarchived=$(./scripts/list-completed-changes.sh)

if [ -n "$unarchived" ]; then
  printf '%s\n' "Completed OpenSpec changes must be archived before merge:" >&2
  printf '%s\n' "$unarchived" >&2
  exit 1
fi

printf '%s\n' "OpenSpec archive-completeness check passed"
