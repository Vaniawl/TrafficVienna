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

<!-- AGENT-FRAMEWORK:BEGIN — GENERATED from agent-framework/canonical/. Do not edit inside this block; edit canonical sources and run: python3 scripts/agent-framework/render.py -->
## Agent entrypoint

Framework v1.1.0 — generated from `agent-framework/canonical/core-instructions.md`.
Edit canonical sources and run `python3 scripts/agent-framework/render.py`.

Before any work, read `agent-framework/canonical/operating-instructions.md`.
Its scope, authority, security, evidence and independent-review rules remain mandatory.
Read the project's `CONTEXT.md` when present for component and setup/status routing;
use `agent-framework/CONTEXT.md` to select the smallest relevant execution workflow.
Act as orchestrator: load `agent-framework/canonical/skills/apple-team/SKILL.md`
and `agent-framework/canonical/roles/orchestrator.yaml`. Work directly by default;
invoke specialists only when needed. Explicit implementation authorizes execute
within that outcome; advice stays in conversation unless saving is requested.

For native Apple product work, use
`agent-framework/canonical/policies/apple-product-engineering.md`;
framework-only work skips the Apple-domain audit.
For authorized task artifacts, use `docs/tasks/CONTEXT.md` and the task-folder template.
On resume, verify the latest relevant handover against the checkout revision.
Never infer tool access from a role. Preserve project-specific instructions below.

Check framework integrity with `python3 scripts/agent-framework/validate.py`
and `python3 scripts/agent-framework/check-drift.py`.
<!-- AGENT-FRAMEWORK:END -->

## Codex Apple-team entrypoint

For a Codex session, the main chat agent follows the managed Apple-team coordinator
entrypoint above. The existing OpenCode autonomous workflow applies when OpenCode
is selected, including its sequential limit, permissions and draft-PR handoff.
This adds role configuration; it does not introduce a custom orchestrator runtime.

Five existing project methods remain discoverable under `traffic-architecture-review`,
`traffic-debug-systematically`, `traffic-feature-slice`, `traffic-release-readiness`
and `traffic-security-review`. Their method text is preserved; standard canonical
skill IDs now provide the shared Apple contracts. Other project skills are unchanged.
Custom native OpenCode agents/config remain authoritative in OpenCode. Generated
`apple-team-*` aliases do not automatically widen their delegation allowlist;
new-role native reachability is NOT RUN. Use the original workflow or validate an
explicit approved provider integration before claiming the new native route works.
