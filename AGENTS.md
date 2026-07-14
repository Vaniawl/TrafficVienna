# TrafficVienna — Agent rules

- Build: `xcodebuild -scheme TrafficVienna -project TrafficVienna.xcodeproj -destination 'platform=iOS Simulator,name=iPhone 17' build`
- Run tests: `xcodebuild -scheme TrafficVienna -project TrafficVienna.xcodeproj -destination 'platform=iOS Simulator,name=iPhone 17' test`
- Memory: on start read `memory/JOURNAL.md` and `memory/DECISIONS.md` for context. After each task, append a short summary to `memory/JOURNAL.md` (newest first). Record architectural decisions in `memory/DECISIONS.md`.

## OpenCode autonomous workflow

- Use OpenCode as the native agent engine. Do not add a custom orchestrator runtime.
- Start every code/doc task from an updated `main`, then create a focused `codex/*` feature branch before editing.
- Keep `main` protected: never push directly to `main`, never force-push, never auto-merge.
- Commit only task-owned files with explicit paths. Do not stage unrelated changes, caches, secrets, or generated local state.
- Completed work is handed off by pushing the feature branch and creating or updating a draft PR. Merge, ready-for-review, release, deploy, and production infrastructure actions require explicit approval.
- Preserve the current SwiftUI/MVVM architecture, widget target, Xcode project structure, local docs, and memory files unless the active task explicitly changes them.
- Use `docs/opencode/` for the reusable workflow contract, permissions, Git/CI handoff, and recovery rules.
