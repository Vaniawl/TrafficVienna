# OpenCode State Files

## Purpose

TrafficVienna state is repository-local, human-readable, and reviewable in Git.
No state file may contain secrets, credentials, private keys, tokens, signing
material, production data, or copied global memory.

## Responsibilities

| File | Purpose | Update rule |
|---|---|---|
| `PROJECT.md` | product, audience, architecture, and scope boundaries | update when product boundaries change |
| `SPEC.md` | active requirements and definition of done | update before or with a scope change |
| `BACKLOG.md` | requirement/slice completion and remaining gates | keep evidence-based; separate product from release work |
| `STATUS.md` | concise current product and release verdict | never call Simulator success App Store readiness |
| `CHECKS.md` | exact repeatable validation commands and latest evidence | update when commands or host constraints change |
| `SECURITY.md` | current trust boundaries and review result | update for every new data/service boundary |
| `RESTRICTIONS.md` | repository, Git, publication, and release limits | keep aligned with `AGENTS.md` |
| `DECISIONS.md` | concise root decision mirror | add newest decisions and mark superseded claims |
| `JOURNAL.md` | concise root task evidence | add newest-first after each task |
| `memory/JOURNAL.md` | detailed newest-first task evidence required by `AGENTS.md` | prepend one dated entry per meaningful task |
| `memory/DECISIONS.md` | durable architecture and workflow decisions required by `AGENTS.md` | prepend only real decisions |
| `docs/opencode/checkpoints/*.md` | recovery checkpoints for long unfinished tasks | one owner per task; update atomically |
| `docs/opencode/task-contract.md` | reusable task/definition-of-done contract | update when workflow contract changes |
| `docs/opencode/git-ci-release.md` | GitHub handoff, CI, release, and rollback rules | update when handoff rules change |
| `docs/opencode/permission-matrix.md` | permission expectations and safety gates | update when repository permissions change |
| `docs/opencode/model-matrix.md` | supported OpenCode model inventory | update after verified inventory changes |

Current source, Git state, and observed command results override older narrative
claims. Root state provides the concise active view; project-local `memory/` keeps
the detailed evidence and decisions mandated by `AGENTS.md`. Neither is an
authorization database, and global Codex memory must not be copied or modified.

## Checkpoint Schema

Each unfinished long-running task checkpoint records:

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

Completed tasks are not restored as active. Concurrent subagents must not write
the same checkpoint.

## Recovery rules

- Resume only from the newest valid checkpoint and current Git state.
- Invalid or incomplete checkpoints are rejected.
- Reject cross-project state.
- Do not duplicate journal headings or decisions when retrying an update.
- Preserve finished work and unrelated user changes.
- Never use state files to bypass branch, review, credential, or release gates.
