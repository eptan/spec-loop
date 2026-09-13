# repository-planning Specification

## MODIFIED Requirements

### Requirement: Roadmap entries establish dependency order

The roadmap MUST list planned capabilities in execution order and link each capability to its governing
OpenSpec change. When a capability depends on another change, the predecessor MUST appear earlier in the
roadmap milestone or in an earlier milestone. A change is dependency-ready only when every listed predecessor
is archived and its required verification evidence is recorded. Every roadmap data row MUST either
reference at least one governing change or state `None` explicitly in its governing-changes cell; a row
with neither MUST fail the roadmap freshness check rather than being silently treated as exempt from every
governing-change rule. The check MUST recognize and skip the table's own GFM header-separator row rather
than relying on that row's shape to satisfy the same fall-through as a genuinely empty cell.

#### Scenario: Later work waits for an unfinished predecessor

- GIVEN a roadmap milestone lists change A before change B
- AND change A has incomplete tasks or is not archived
- WHEN an agent selects the next change
- THEN it selects A rather than B
- AND B is not treated as dependency-ready

#### Scenario: A blank governing-changes cell fails, an explicit None does not

- GIVEN a roadmap row's governing-changes cell is blank
- WHEN the roadmap freshness check runs
- THEN it reports that row as missing a governing change or explicit `None`
- AND a row whose cell states `None` passes without requiring any archived change
