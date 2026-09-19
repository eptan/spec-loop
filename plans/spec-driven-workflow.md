# Spec-Driven Workflow

This file is a teaching guide, not a second requirements source. The accepted contract lives under
`openspec/specs/`; proposed work lives under `openspec/changes/`. The goal is to make decisions reviewable,
implementation incremental, and verification reproducible.

## The Four Artifacts

1. `proposal.md` explains why the change exists, what it changes, and what it explicitly does not do.
2. `design.md` records architecture and decisions grounded in the current repository.
3. `tasks.md` turns the design into ordered, verifiable work.
4. `specs/<capability>/spec.md` states MUST-level behavior with Given/When/Then scenarios.

Every proposal or design also includes a `## Dependencies` section. Write `None` for a standalone change;
otherwise name each predecessor change and its readiness condition. Dependency names are exact OpenSpec
change directory names, not branches or pull requests.

## Lifecycle

1. Read accepted specs and the current code before drafting.
2. Create an active change and validate it strictly.
3. Review the proposal and design before implementation.
4. Implement only the accepted contract and record evidence in tasks.
5. Run focused tests, the changed-path command, and `npm run check`.
6. Make a final documentation pass after implementation.
7. Verify the change without changing task status.
8. Archive only after every task and verification requirement is complete. `scripts/pr.sh` archives a fully
   checked change automatically when its pull request is created.

Roadmap order is dependency order: a predecessor must be archived with recorded verification before a later
change can be selected. See [`docs/dependency-patterns.md`](../docs/dependency-patterns.md) for the status
and declaration conventions.

Try the agent commands through the shared harness: `/spec-audit`, `/verify-change`, and `/archive-change`.
Use `/pr` only after explicit authorization to create a pull request.
