# Restrictions

- Work only in `/Users/ivandovhosheia/Swift/TrafficVienna`; do not read unrelated
  projects, `.env`, private keys, tokens, SSH material, or credential contents.
- Start code/doc tasks from updated `main` on a focused `codex/*` branch. Never
  push directly to `main`, force-push, auto-merge, or rewrite shared history.
- Commit only task-owned files with explicit paths; never stage caches, screenshots,
  secrets, DerivedData, or unrelated worktree changes.
- After checks pass, push the feature branch and create or update a **draft** PR.
  Merge, ready-for-review, tag, signing configuration, App Store Connect mutation,
  upload, submit, release, deploy, and production infrastructure require explicit
  approval.
- Use OpenCode as the native agent engine. Do not add a custom orchestrator runtime
  or change global models, prompts, permissions, or global memory from this project.
- Do not add an external dependency, service, analytics SDK, backend, identity,
  payment, or network destination unless explicitly requested.
- Preserve SwiftUI/MVVM, the widget target, Xcode structure, and useful product
  journeys unless the active task explicitly changes them.
- Do not mask failures with forced success, ignored exit codes, or Xcode skips
  presented as completion evidence.
- “Product complete” and “App Store ready” are distinct. External release gates
  remain open until they have observed evidence.
