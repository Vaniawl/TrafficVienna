---
name: dependency-update
description: Safely assess and perform dependency updates with compatibility, security, lockfile, test, rollback, and release evidence.
---

# Dependency Update

## Trigger

Use for package, image, runtime, or toolchain updates.

## Required Inputs

- Target dependency and desired version/range.
- Package manager or image source.
- Security advisory or business reason.
- Required compatibility checks.

## Workflow

1. Verify current dependency source and lockfiles.
2. Review changelog/security notes from primary sources.
3. Define rollback.
4. Update the smallest necessary files.
5. Run lockfile, lint/typecheck/test/build/security checks available in the repo.
6. Document compatibility and residual risk.

## Expected Output

Changed dependency files, reason, compatibility notes, checks, and rollback.

## Acceptance Criteria

- Lockfiles stay synchronized.
- No unrelated dependency churn.
- Tests/checks pass or blockers are precise.

## Stopping Conditions

- Required registry/source unavailable.
- Update requires unapproved migration or license change.
- Tests cannot run and risk is material.

## Prohibited Actions

- Do not install global tools silently.
- Do not ignore lockfile changes.
- Do not update production images without release review.
