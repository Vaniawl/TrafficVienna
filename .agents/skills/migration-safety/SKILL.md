---
name: migration-safety
description: Plan and validate schema, data, filesystem, config, and runtime migrations with backup, idempotency, observability, rollback, and failure-path checks.
---

# Migration Safety

## Trigger

Use for database, filesystem, configuration, runtime state, model storage, or infrastructure migrations.

## Required Inputs

- Current state and target state.
- Affected data and owners.
- Backup and rollback requirements.
- Validation commands.

## Workflow

1. Identify assets and irreversible operations.
2. Verify backups or recovery points.
3. Design idempotent migration steps.
4. Define preflight, apply, verify, and rollback checks.
5. Test failure and partial-apply paths where feasible.
6. Document manual approval gates.

## Expected Output

Migration plan, risks, checks, rollback, owner approval needs, and release gate.

## Acceptance Criteria

- Destructive steps require approval.
- Rollback is explicit or irreversibility is accepted.
- Verification covers producer and consumer state.

## Stopping Conditions

- No backup/recovery path for important data.
- Unknown production state.
- Required destructive command is not approved.

## Prohibited Actions

- Do not run destructive migrations by default.
- Do not touch production data locally.
- Do not hide irreversible consequences.
