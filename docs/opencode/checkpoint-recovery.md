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

Do not store secrets, tokens, signing material, or generated local state in memory files.
