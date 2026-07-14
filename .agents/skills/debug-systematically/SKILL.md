---
name: debug-systematically
description: Reproduce, minimize, trace evidence, rank hypotheses, test one at a time, fix root cause, add regression coverage, and validate adjacent failure paths.
---

# Debug Systematically

## Trigger

Use for failing tests, runtime errors, CI failures, regressions, flaky behavior, or unclear root cause.

## Required Inputs

- Error output or failing command.
- Expected behavior.
- Recent diff or relevant files.
- Known environment constraints.

## Workflow

1. Reproduce the failure once.
2. Minimize the failing path.
3. Trace inputs, state, outputs, and boundaries.
4. Rank hypotheses.
5. Test one hypothesis at a time.
6. Fix root cause, not symptoms.
7. Add or update regression coverage when useful.
8. Validate adjacent failure paths.

## Expected Output

Summarize root cause, evidence, fix, checks run, and residual risk.

## Acceptance Criteria

- Reproduction and fix are evidenced.
- Regression coverage exists or a precise reason is documented.
- Same failure no longer reproduces.

## Stopping Conditions

- Failure cannot be reproduced and no evidence path remains.
- Same command fails twice with identical output after a fix attempt.
- Debugging requires unsafe operation or missing credentials.

## Prohibited Actions

- Do not guess root cause.
- Do not weaken tests.
- Do not erase logs or state needed for diagnosis.
