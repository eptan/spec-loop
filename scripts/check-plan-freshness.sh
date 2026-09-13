#!/bin/sh
set -eu

plan="plans/roadmap.md"

if [ ! -f "$plan" ]; then
  printf '%s\n' "OpenSpec plan-freshness check passed (no roadmap found)"
  exit 0
fi

python3 <<'PY'
import re
from pathlib import Path

plan = Path("plans/roadmap.md").read_text(encoding="utf-8")
changes = Path("openspec/changes")
archive = changes / "archive"
archived = {
    re.sub(r"^\d{4}-\d{2}-\d{2}-", "", entry.name)
    for entry in archive.iterdir()
    if entry.is_dir()
} if archive.is_dir() else set()

findings = []
for row in re.findall(r"^\|.*\|$", plan, re.MULTILINE):
    cells = [cell.strip() for cell in row.strip("|").split("|")]
    if len(cells) != 3 or cells[0] == "Phase":
        continue
    if all(re.fullmatch(r"[-: ]+", cell) for cell in cells):
        continue  # GFM header-separator row (e.g. | --- | --- | --- |), not data
    phase, governing, status = cells
    names = re.findall(r"`([a-z0-9-]+)`", governing)
    if not names and governing.lower().rstrip(".") != "none":
        findings.append(f"- {phase} must reference a governing change or state None")
        continue
    for name in names:
        if not (changes / name).is_dir() and name not in archived:
            findings.append(f"- {phase} references missing change `{name}`")
    if names and status.lower().rstrip(".") == "complete" and not all(
        name in archived for name in names
    ):
        findings.append(f"- {phase} is marked complete but its change is not archived")

if findings:
    print("Possible roadmap drift:")
    print("\n".join(findings))
    raise SystemExit(1)

print("OpenSpec plan-freshness check passed")
PY
