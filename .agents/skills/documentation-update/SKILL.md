---
name: documentation-update
description: Update documentation from verified code/config evidence, remove stale claims, maintain links, and record limitations.
---

# Documentation Update

## Trigger

Use when behavior, commands, config, architecture, security, testing, release, or workflow docs need updates.

## Required Inputs

- Documentation files to update.
- Code/config source of truth.
- Acceptance criteria.
- Required validation.

## Workflow

1. Read existing documentation in full.
2. Read code/config it describes.
3. List stale or incorrect descriptions.
4. Update intent, workflow, commands, and limitations.
5. Validate links and referenced files.
6. Run relevant checks.

## Expected Output

Changed docs, stale content removed, evidence checked, commands run, and remaining gaps.

## Acceptance Criteria

- Docs match current code/config.
- No large copied code blocks unless necessary.
- Links and commands are valid.

## Stopping Conditions

- Code/config source cannot be verified.
- Documentation would require inventing missing behavior.
- Required target audience or scope is ambiguous.

## Prohibited Actions

- Do not document aspirational behavior as current behavior.
- Do not copy secrets or environment values.
- Do not widen scope into unrelated docs cleanup.
