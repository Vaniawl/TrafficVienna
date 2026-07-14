# Git, CI, Release, And Rollback

## Branching

- `main` is the protected base branch.
- Start every task from updated `main`.
- Use `codex/*` feature branches.
- Never push directly to `main`.
- Never force-push.
- Never auto-merge.

## Draft PR Handoff

After validation and local commit, the orchestrator may:

1. verify `gh auth status`;
2. verify repository access with `gh repo view Vaniawl/TrafficVienna`;
3. push the current `codex/*` branch;
4. create or update a draft PR targeting `main`.

The first push and draft PR for this integration must wait for explicit user approval.

## CI

The Quality workflow runs on macOS because TrafficVienna is an iOS app. It validates OpenCode configuration, installs a pinned OpenCode CLI for config tests, and runs the repository CI wrapper.

## Release

No local release or deployment is configured. TestFlight, App Store, signing, notarization, production infrastructure, merge, and ready-for-review transitions require explicit approval.

## Rollback

Rollback for this workflow integration is a normal Git revert of the OpenCode integration commit. App code, Xcode project files, and production infrastructure are not changed by the integration.
