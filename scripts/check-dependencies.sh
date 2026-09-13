#!/bin/sh
set -eu

repo_root=${REPOSITORY_ROOT:-.}

REPOSITORY_ROOT="$repo_root" python3 <<'PY'
import os
import re
from pathlib import Path

root = Path(os.environ["REPOSITORY_ROOT"])
changes = root / "openspec" / "changes"
archive = changes / "archive"

archived = {
    re.sub(r"^\d{4}-\d{2}-\d{2}-", "", item.name)
    for item in archive.iterdir()
    if item.is_dir()
} if archive.is_dir() else set()
active = [
    item for item in changes.iterdir() if item.is_dir() and item.name != "archive"
] if changes.is_dir() else []
findings = []
dependencies = {}

for change in active:
    sections = []
    for filename in ("proposal.md", "design.md"):
        path = change / filename
        if not path.is_file():
            continue
        text = path.read_text(encoding="utf-8")
        match = re.search(r"^## Dependencies\s*$", text, re.MULTILINE)
        if match:
            end = re.search(r"^##\s+", text[match.end() :], re.MULTILINE)
            section = text[match.end() : match.end() + end.start()] if end else text[match.end() :]
            sections.append(section)
    if not sections:
        findings.append(f"- {change.name} is missing a ## Dependencies section")
        continue
    section = sections[0]
    if re.search(r"^\s*None\.?\s*$", section, re.MULTILINE):
        dependencies[change.name] = []
        continue
    names = re.findall(r"`([a-z0-9-]+)`", section)
    dependencies[change.name] = names
    for name in names:
        if not (changes / name).is_dir() and name not in archived:
            findings.append(f"- {change.name} names missing dependency `{name}`")

roadmap = root / "plans" / "roadmap.md"
order = {}
statuses = {}
if roadmap.is_file():
    for index, row in enumerate(re.findall(r"^\|.*\|$", roadmap.read_text(encoding="utf-8"), re.MULTILINE)):
        cells = [cell.strip() for cell in row.strip("|").split("|")]
        if len(cells) != 3 or cells[0] == "Phase":
            continue
        names = re.findall(r"`([a-z0-9-]+)`", cells[1])
        for name in names:
            order[name] = index
            statuses[name] = cells[2].lower().rstrip(".")

for change, names in dependencies.items():
    if change not in order:
        continue
    unready = [name for name in names if name not in archived]
    if unready and statuses.get(change) != "blocked":
        findings.append(f"- {change} has unready dependencies but roadmap status is not Blocked")
    for name in names:
        if name in order and order[name] > order[change]:
            findings.append(f"- {change} appears before dependency `{name}` in the roadmap")

if findings:
    print("Dependency governance check failed:")
    print("\n".join(findings))
    raise SystemExit(1)

print("Dependency governance check passed")
PY
