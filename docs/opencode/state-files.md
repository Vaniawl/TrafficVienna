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
| `PROJECT.md` | product scope, architecture, boundaries, and evidence precedence | update when product scope or source ownership changes |
| `SPEC.md` | active product-audit requirements and definition of done | update when audit requirements change |
| `STATUS.md` | concise current evidence, limitations, branch, and handoff snapshot | update after each published audit slice |
| `BACKLOG.md` | requirement coverage, resolved findings, inspection, and external gates | update when coverage or gate evidence changes |
| `CHECKS.md` | exact validation commands and required evidence | update when checks or acceptance platforms change |
| `RESTRICTIONS.md` | repository, architecture, mutation, and release boundaries | update only when an approved boundary changes |
| `SECURITY.md` | current product trust boundaries and required review areas | update when data, system, or network boundaries change |
| `DECISIONS.md` | concise active/superseded decision summary for the current audit | update when a current decision changes; keep durable detail in `memory/DECISIONS.md` |
| `JOURNAL.md` | concise newest-first audit progress and validation evidence | add one entry per meaningful audit slice; keep full history in `memory/JOURNAL.md` |

The root audit set supplements the default memory and workflow instructions. Read
it as a group for broad product, audit, or release work; route only the relevant
artifacts into a narrow task so short runs do not pay the full context cost.
Current source, configuration, command output, rendered artifacts, and external
service state override stale narrative. Synchronize affected root snapshots after
verification instead of treating an older checked box as current evidence.

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
