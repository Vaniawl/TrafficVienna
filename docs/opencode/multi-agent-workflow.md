# OpenCode Multi-Agent Workflow

## Purpose

TrafficVienna uses OpenCode as the native agent engine for autonomous repository work. The workflow is intentionally repository-local and preserves the existing SwiftUI iOS app, widget target, Xcode project, docs, and memory files.

## Lifecycle

1. Start from an updated `main`: fetch `origin`, switch to `main`, and pull with `--ff-only`.
2. Create a focused `codex/<short-goal>` feature branch before edits.
3. Read `AGENTS.md`, `docs/CONTEXT.md`, `docs/REFERENCES.md`, `memory/DECISIONS.md`, and `memory/JOURNAL.md`.
4. Clarify only missing acceptance criteria that cannot be safely inferred.
5. Discover the repository evidence before changing files.
6. Delegate only bounded, non-overlapping work.
7. Implement the smallest complete slice.
8. Run validation directly.
9. Review correctness, security/privacy, and release readiness.
10. Commit only task-owned files.
11. Push only the feature branch and create or update a draft PR targeting `main`.
12. Stop after draft PR handoff. Merge, ready-for-review, release, deploy, and production infrastructure actions require explicit approval.

## Agents

| Agent | Role | Edits | Delegates |
|---|---|---:|---:|
| orchestrator | Owns workflow, criteria, delegation, checks, reviews, commit, and draft PR handoff. | yes | selected agents |
| explorer | Read-only repository discovery. | no | no |
| architect | Boundaries, contracts, compatibility, rollback. | no | no |
| implementer | Assigned vertical slice in owned files. | yes | no |
| test-architect | Test and validation strategy. | no | no |
| reviewer | Independent correctness and maintainability review. | no | no |
| security-reviewer | Security and privacy review. | no | no |
| release-manager | Draft PR readiness and release gate review. | no | no |

## Subagent Execution

Subagents run sequentially by default. The orchestrator starts one subagent,
waits for its result, records useful evidence, and then starts the next
subagent. This keeps prompts small, avoids hidden dependencies, and prevents
stalled parallel batches from blocking the whole run.

Parallel execution is allowed only for a small read-only batch:

- 2-3 subagents maximum;
- all tasks are read-only;
- no shared writable files;
- no ordering dependency;
- no subagent output is required to shape another subagent prompt;
- each task has an independent definition of done.

Before launching a parallel batch, the orchestrator must record the owned files,
forbidden files, independence proof, timeout, and fallback plan. The timeout is
3 minutes per parallel batch. If any subagent has no useful progress by then,
the orchestrator records the timeout/blocker, stops waiting for the batch, and
reruns unfinished work sequentially.

Implementation, validation, commit, push, draft PR handoff, release, and
deployment tasks are never parallelized.

## TrafficVienna Commands

Repository validation:

```bash
bash scripts/validate-repository.sh
bash scripts/validate-opencode.sh
```

Build:

```bash
bash scripts/build.sh
```

Test:

```bash
bash scripts/test.sh
```

Set `TRAFFICVIENNA_XCODE_DESTINATION` to override the simulator destination
when a runner does not provide `iPhone 17`.

CI wrapper:

```bash
bash scripts/ci.sh
```

Diff whitespace:

```bash
git diff --check HEAD
```

On non-macOS hosts where `xcodebuild` is unavailable, local scripts may be run with `TRAFFICVIENNA_ALLOW_XCODEBUILD_SKIP=1` to validate repository and OpenCode wiring only. GitHub Actions must run the full Xcode build and test job on macOS.

If the Xcode project reports `There are no test bundles available to test`, or
the CI runner has no concrete `iPhone 17` simulator and no destination override,
`scripts/test.sh` records an explicit XCTest skip for the current runner wiring
while keeping repository and OpenCode checks mandatory. Other Xcode test
failures still fail CI.

## Stopping Conditions

The orchestrator may stop only when the goal and acceptance criteria are satisfied with validation evidence, or when a real blocker is proven: missing access, required user decision, unavailable platform, destructive operation, deployment/release gate, or repeated root-cause failure after materially different attempts.

A failed check is not completion. Diagnose, fix, and re-run.
