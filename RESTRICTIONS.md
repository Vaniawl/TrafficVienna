# Restrictions

- Work only in `/home/skyphoenix/projects/TrafficVienna`.
- Do not read `.env`, private keys, credentials, tokens, SSH configuration,
  GitHub CLI configuration, or unrelated project data.
- Local `codex/*` feature branches and task-owned commits are allowed after
  checks pass. Keep the existing personal identity and `origin` unchanged.
- Never commit on `main`, push, create or edit a PR or issue, merge, rebase,
  reset, tag, release, deploy, or modify production infrastructure.
- Do not run nested OpenCode or reconfigure global models, prompts, or
  permissions from this project.
- Do not add an external dependency, service, analytics SDK, backend, or network
  destination unless the user explicitly requests it.
- Do not replace the existing architecture, remove a user journey, or widen
  product scope beyond the current request without asking the user.
- Do not mask failures with `|| true`, forced success, ignored exit codes, or an
  Xcode skip presented as completion evidence.
- Do not declare `COMPLETE` while any requested backlog item, required test,
  review finding, TODO, placeholder, or validation gap remains.
