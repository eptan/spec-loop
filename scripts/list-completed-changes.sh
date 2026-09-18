#!/bin/sh
# Prints the name of every active (unarchived) OpenSpec change whose tasks.md is fully checked, one per
# line. Shared by scripts/check-openspec-archive.sh (fails the gate if any print) and scripts/pr.sh
# (archives each one automatically before staging), so both use one detection rule.
set -eu

npm exec openspec -- list --json | python3 -c '
import json, sys

data = json.load(sys.stdin)
for change in sorted(data["changes"], key=lambda item: item["name"]):
    if change["totalTasks"] > 0 and change["completedTasks"] == change["totalTasks"]:
        print(change["name"])
'
