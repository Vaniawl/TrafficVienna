# OpenCode State Files

## Purpose

OpenCode state is repository-local and human-readable. Git history, explicit
checkpoint files, and memory files are the source of truth. State files must not
contain secrets, credentials, private keys, tokens, signing material, or
production data.

## State File Responsibilities

| File | Purpose | Update rule |
|---|---|---|
| `memory/JOURNAL.md` | newest-first task summaries and validation evidence | append one dated entry per meaningful task; do not duplicate an existing heading |
| `memory/DECISIONS.md` | durable architecture and workflow decisions | append one dated decision per decision; update only to correct stale evidence |
| `docs/opencode/checkpoints/*.md` | durable recovery checkpoints for long tasks | write a new checkpoint or update the current task checkpoint atomically |
| `docs/opencode/task-contract.md` | required task contract fields and definition of done | update when workflow contract changes |
| `docs/opencode/git-ci-release.md` | GitHub handoff, CI, release, and rollback rules | update when handoff rules change |
| `docs/opencode/permission-matrix.md` | permission expectations and safety gates | update when permissions change |
| `docs/opencode/model-matrix.md` | exact model inventory and agent assignments | update after model inventory changes |

`STATUS.md`, `CHECKS.md`, `DECISIONS.md`, `JOURNAL.md`, `BACKLOG.md`, `SPEC.md`,
and `RESTRICTIONS.md` are not root-level TrafficVienna state files today. Their
responsibilities are covered by `memory/`, `AGENTS.md`, and `docs/opencode/`.
If any of those root-level files are introduced later, they must be added to this
table and to the reliability suite.

## Checkpoint Schema

Each active-task checkpoint must include:

- `Task ID`
- `Goal`
- `Acceptance Criteria`
- `Completed Work`
- `Remaining Work`
- `Changed Files`
- `Commands And Results`
- `Current Blockers`
- `Decisions`
- `Next Action`
- `Definition Of Done Status`

Checkpoint writes should be atomic where practical: write a temporary file in the
same directory, validate it, then move it into place. Concurrent subagents must
not write the same checkpoint. The orchestrator owns checkpoint files unless a
task contract explicitly delegates a unique checkpoint path.

## Recovery Rules

- Completed tasks must not be restored as active.
- Unfinished tasks resume from the latest valid checkpoint only.
- Invalid or incomplete checkpoints are rejected.
- Stale checkpoints remain distinguishable by task ID and timestamp.
- Re-running the same update must not duplicate journal or decision entries.
- Project state must never mix TrafficVienna with another repository or OpenCode
  project.
