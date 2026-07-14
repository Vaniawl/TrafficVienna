---
name: incident-response
description: Triage incidents with evidence capture, impact assessment, containment, mitigation, communication, recovery, and post-incident follow-up.
---

# Incident Response

## Trigger

Use for outages, suspected compromise, data exposure, broken deployment, failed rollback, or severe regression.

## Required Inputs

- Symptom and start time.
- Affected systems/users.
- Recent changes.
- Available logs or monitoring evidence.

## Workflow

1. Capture evidence without destroying state.
2. Assess severity and blast radius.
3. Contain safely.
4. Identify likely cause.
5. Mitigate or rollback through approved path.
6. Verify recovery.
7. Record follow-up actions.

## Expected Output

Timeline, impact, actions taken, evidence, recovery status, and follow-up.

## Acceptance Criteria

- User/data safety is prioritized.
- Recovery evidence is observed.
- Follow-up is actionable.

## Stopping Conditions

- Action requires credentials or production access not available.
- Containment would be destructive without approval.
- Legal/privacy escalation may be required.

## Prohibited Actions

- Do not delete evidence.
- Do not expose secrets in reports.
- Do not run unapproved production changes.
