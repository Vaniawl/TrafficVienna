---
name: release-readiness
description: Verify criteria, tests, security, compatibility, migrations, install, upgrade, rollback, observability, docs, notices, and limitations; return Go/Conditional Go/No-Go.
---

# Release Readiness

## Trigger

Use after implementation, review, and security review are complete or when deciding whether a change can move to PR, staging, or release.

## Required Inputs

- Acceptance criteria.
- Diff summary.
- Validation evidence.
- Review and security-review results.
- Migration, deployment, and rollback notes.

## Workflow

1. Verify criteria and changed files.
2. Check local validation and CI status when available.
3. Confirm security review and no unresolved Critical/High findings.
4. Check compatibility, migration, install, upgrade, rollback, observability, docs, and notices.
5. Verify release commands are safe adapter points, not fake production deployment.
6. Return verdict.

## Expected Output

Return exactly one verdict: `Go`, `Conditional Go`, or `No-Go`, with evidence and required follow-up.

## Acceptance Criteria

- Verdict is tied to observed evidence.
- Missing checks are explicit blockers or conditions.
- Rollback path is documented.

## Stopping Conditions

- Missing validation evidence.
- Unresolved Blocking/Critical/High finding.
- Production deployment path lacks protected CI.

## Prohibited Actions

- Do not push, merge, tag, deploy, or release by default.
- Do not bypass CI.
- Do not claim readiness with unknown rollback.
