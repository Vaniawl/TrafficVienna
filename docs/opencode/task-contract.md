# Task Contract

Every autonomous task must define:

- objective;
- acceptance criteria;
- owned files;
- read-only files;
- forbidden files;
- expected checks;
- rollback plan;
- draft PR handoff notes.

## Ownership

Do not edit app code, widget code, Xcode project files, docs, or memory files unless they are explicitly task-owned. Keep unrelated findings out of scope and record them as follow-up notes only when useful.

## Definition Of Done

A task is done only when:

- changed files are limited to the task scope;
- repository validation passes;
- relevant build/test commands pass or an unavailable platform is clearly documented;
- review and security/privacy checks have no unresolved blocking findings;
- staged files are explicit and clean;
- a local commit exists on a `codex/*` branch;
- the branch is ready for draft PR handoff.
