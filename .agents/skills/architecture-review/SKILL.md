---
name: architecture-review
description: Review scope, boundaries, state, failure modes, reuse, security, testability, compatibility, migration, rollback, and ADR needs.
---

# Architecture Review

## Trigger

Use before broad design, public contracts, persistence, migrations, release-impacting changes, or when implementation would change architecture.

## Required Inputs

- Objective and acceptance criteria.
- Files and modules already read.
- Proposed change or diff.
- Known constraints and rollback expectations.

## Workflow

1. Verify current structure from files.
2. Identify boundaries, data flow, state, dependencies, and dynamic wiring.
3. Prepare at least two options when a meaningful design choice exists.
4. Check compatibility, migration, rollback, observability, security, and testability.
5. Decide whether an ADR is needed.

## Expected Output

Return `Blocking`, `Important`, and `Optional` findings plus a recommendation and required validation.

## Acceptance Criteria

- Findings cite evidence.
- Recommendation preserves existing architecture unless change is justified.
- ADR need is explicit.

## Stopping Conditions

- Missing evidence for current architecture.
- Material ambiguity in requirements.
- Required destructive or production action.

## Prohibited Actions

- Do not implement code.
- Do not approve unverified assumptions.
- Do not introduce dependencies silently.
