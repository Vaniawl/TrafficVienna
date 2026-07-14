---
name: security-review
description: Review authentication, authorization, tenancy, input, injection, files, SSRF, secrets, logs, dependencies, webhooks, command execution, migrations, and failures.
---

# Security Review

## Trigger

Use for any change touching inputs, secrets, permissions, command execution, dependencies, network, files, deployment, CI, or release.

## Required Inputs

- Diff or proposed change.
- Threat model.
- Data and trust boundaries.
- Validation evidence.

## Workflow

1. Identify assets, actors, and trust boundaries.
2. Check secret exposure and generated artifacts.
3. Check authorization, validation, injection, file, SSRF, dependency, command execution, log, CI, and deployment risks.
4. Classify findings by severity.
5. Define mitigations and release blockers.

## Expected Output

Findings with severity, evidence, impact, mitigation, and release-blocking status.

## Acceptance Criteria

- Critical/High findings block release.
- No secrets are read or exposed.
- Mitigations are concrete and testable.

## Stopping Conditions

- Review requires secret access.
- Threat boundary is unknown.
- Evidence is missing for a claimed control.

## Prohibited Actions

- Do not read `.env`, credentials, private keys, or production data.
- Do not edit code.
- Do not approve unsafe defaults.
