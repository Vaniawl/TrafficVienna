# Checkpoint And Recovery

Use repository memory files for durable human-readable context:

- `memory/JOURNAL.md` for task summaries, newest first.
- `memory/DECISIONS.md` for architecture or workflow decisions.

At each meaningful checkpoint, record:

- goal;
- acceptance criteria;
- branch;
- changed files;
- validation evidence;
- blockers;
- next action.

For parallel subagent batches, also record:

- which 2-3 read-only tasks were launched;
- why they were independent;
- the 3-minute timeout start;
- which tasks completed;
- which tasks timed out or stalled;
- the sequential fallback plan and result.

Do not store secrets, tokens, signing material, or generated local state in memory files.
