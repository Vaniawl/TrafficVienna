# Git, CI, Release, And Rollback

## Branching

- Start code/doc tasks from updated protected `main`.
- Work on one focused `codex/*` feature branch.
- Never push directly to `main`.
- Never force-push.
- Never auto-merge or rewrite shared history.
- Stage and commit only task-owned files with explicit paths.

## Draft PR handoff

After local validation and an intentional commit:

1. if the host provides a repository-specific GitHub CLI context, set
   `GH_CONFIG_DIR` to that already configured path; do not hard-code a path from
   another machine or inspect credential contents;
2. run `gh auth status` and `gh repo view Vaniawl/TrafficVienna` without exposing
   credential contents;
3. push the current `codex/*` branch;
4. create or update a draft PR targeting `main`;
5. report the branch, commit, PR URL, validation evidence, and remaining gates.

The task-authorized handoff stops at a **draft** PR. Ready-for-review, merge, tag,
release, upload, submit, or production-infrastructure actions require explicit
approval.

## CI

Local `scripts/ci.sh` validates repository/OpenCode configuration, reliability
fixtures, the app/widget build, XCTest, and diff hygiene. The protected GitHub
Quality workflow runs the same repository contract on macOS. A local pass does not
replace the required protected check before merge.

## Release

Simulator tests and an unsigned archive prove source and packaging only. A release
additionally requires a clean signed distribution archive, App Store Connect
access/metadata, approved upload, Apple processing inspection, and physical or
TestFlight acceptance. `docs/release/app-store-readiness.md` is the checklist.

## Rollback

Before merge or upload, rollback is a normal Git revert of the focused feature
commit or closing the draft PR. After a processed App Store build, publish a new
higher build number; never force-replace a processed binary. Data migrations must
document their own rollback or intentional irreversibility.
