---
name: repository-discovery
description: Discover stack, structure, commands, rules, entry points, dynamic wiring, public exports, and blockers without edits.
---

# Repository Discovery

## Trigger

Use at the start of broad work or when stack, commands, ownership, or rules are uncertain.

## Required Inputs

- Objective.
- Repository root.
- Specific focus areas, if any.

## Workflow

1. Read mandatory rules and current-work files.
2. Inventory files and technology markers.
3. Identify install, format, lint, typecheck, test, integration-test, build, start, validate, and deploy commands from existing files.
4. Trace relevant entry points, dependencies, dynamic wiring, and exports.
5. Report blockers and unknowns.

## Expected Output

Structured report with files read, stack, commands, entry points, risks, blockers, and suggested next checks.

## Acceptance Criteria

- No commands are invented.
- Claims cite direct file or command evidence.
- Read-only behavior is preserved.

## Stopping Conditions

- Required files are missing.
- Command cannot be inferred reliably.
- Discovery would require secret access.

## Prohibited Actions

- Do not edit files.
- Do not install dependencies.
- Do not run destructive or deployment commands.
