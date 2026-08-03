# Restrictions

- Work only in `/Users/ivandovhosheia/Swift/TrafficVienna`.
- Do not read `.env`, private keys, credentials, tokens, SSH configuration,
  GitHub CLI configuration, or unrelated project data.
- Start code/doc work from updated `main`, then use a focused `codex/*` branch.
  Preserve the configured identity and remote.
- Commit only explicit task-owned paths. A feature-branch push and draft PR are
  the normal handoff; never push to `main`, force-push, auto-merge, mark ready,
  release, deploy, or modify production infrastructure without explicit approval.
- Do not run nested OpenCode or reconfigure global models, prompts, or permissions
  from this project.
- Do not add an external dependency, service, analytics SDK, backend, entitlement,
  or network destination unless explicitly requested.
- Do not replace the existing SwiftUI/MVVM architecture, widget target, Xcode
  structure, or a user journey without an explicit scoped decision.
- Do not mask failures with forced success, ignored exit codes, or an Xcode skip
  presented as completion evidence.
- Report signing, App Store Connect, processed-build, and physical TestFlight gates
  as external limitations; do not infer release readiness from a Simulator alone.
