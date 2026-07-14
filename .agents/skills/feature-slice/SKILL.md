---
name: feature-slice
description: Define criteria and ownership, implement the smallest end-to-end slice, add tests, run checks, update docs, and report evidence.
---

# Feature Slice

## Trigger

Use for implementation tasks with a bounded user-visible or repository-visible outcome.

## Required Inputs

- Objective.
- Acceptance criteria.
- Owned files.
- Read-only files.
- Required checks.
- Rollback plan.

## Workflow

1. Verify related files and entry points.
2. Confirm ownership and non-overlap.
3. Implement the smallest complete vertical slice.
4. Add or update focused tests and docs.
5. Run required checks.
6. Reopen changed files and verify connections.
7. Report evidence.

## Expected Output

List changed files, behavior, tests/checks, results, limitations, and rollback.

## Acceptance Criteria

- Scope is complete and bounded.
- Tests/docs/config stay synchronized.
- No unrelated refactor or dead code remains.

## Stopping Conditions

- Ownership conflict.
- Missing evidence.
- Architecture change required.
- Unsafe command required.

## Prohibited Actions

- Do not broaden scope.
- Do not change behavior outside acceptance criteria.
- Do not push, merge, release, or deploy.
