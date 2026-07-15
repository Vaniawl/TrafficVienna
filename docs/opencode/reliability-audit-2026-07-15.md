# Reliability And Recovery Audit — 2026-07-15

## Scope

This audit verifies the TrafficVienna OpenCode multi-agent system after PR #4.
It covers model assignment, state-file contracts, checkpoint recovery behavior,
timeout fallback, permission stability, GitHub identity isolation, and draft PR
handoff safety.

## Model Findings

- OpenCode CLI observed: `1.17.20`.
- Exact model inventory and assignments are recorded in `docs/opencode/model-matrix.md`.
- All eight agents now have explicit `model:` fields.
- `opencode debug config` resolves the agent `model` fields in the runtime configuration.
- Runtime smoke validation passed for every configured unique model:
  `opencode/big-pickle`, `opencode/deepseek-v4-flash-free`,
  `opencode/hy3-free`, `opencode/mimo-v2.5-free`,
  `opencode/nemotron-3-ultra-free`, and `opencode/north-mini-code-free`.
- Six suitable models are available, so two model IDs are intentionally reused.
- No fallback model is configured because no fallback field is verified in the
  current repository configuration.

## State Findings

- `memory/JOURNAL.md` and `memory/DECISIONS.md` are the durable memory files.
- Checkpoints live under `docs/opencode/checkpoints/`.
- `docs/opencode/state-files.md` defines purposes, required checkpoint fields,
  atomic-write guidance, stale checkpoint handling, and ownership rules.
- The reliability suite validates valid checkpoint restore, invalid checkpoint
  rejection, latest-valid checkpoint selection, duplicate update prevention, and
  secret-pattern exclusion on isolated fixtures.

## Recovery Scenarios

The repeatable reliability suite covers the safe local versions of the requested
recovery scenarios:

| Scenario | Evidence |
|---|---|
| normal checkpoint recovery | valid fixture checkpoint restores once without repeating completed work |
| context compaction | compacted summary fixture preserves goal, constraints, ownership, validation, and next action |
| subagent timeout | timeout fixture returns timeout and records sequential fallback |
| failed implementation | controlled invalid fixture fails, then corrected fixture passes |
| invalid checkpoint | incomplete fixture is rejected and latest valid checkpoint is selected |
| process interruption | temp progress fixture is written before simulated interruption and restored after restart |

## Permission Findings

`tests/opencode-permission-matcher.sh` and `tests/opencode-reliability.sh` verify
that routine operations are allowed, release/ready gates remain ask or deny, and
direct main push, force push, destructive commands, and secret reads remain denied.
GitHub CLI handoff remains scoped to:

```bash
GH_CONFIG_DIR=/home/skyphoenix/.config/gh-personal
```

## Verdict

Conditional Go for autonomous OpenCode workflow use.

Local validation evidence:

```bash
bash scripts/validate-opencode.sh
bash tests/opencode-reliability.sh
TRAFFICVIENNA_ALLOW_XCODEBUILD_SKIP=1 bash scripts/ci.sh
```

Conditions:

- macOS GitHub Actions remains authoritative for Xcode build/test.
- Parallel subagents stay limited to 2-3 independent read-only tasks with
  timeout and sequential fallback.
- Any future model/fallback changes must update `model-matrix.md` and the
  reliability suite.
