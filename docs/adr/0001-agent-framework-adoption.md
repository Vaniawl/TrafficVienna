# ADR 0001: Add the agent framework beside the existing OpenCode workflow

- **Status:** Accepted
- **Date:** 2026-09-13
- **Owner:** TrafficVienna project owner

## Context

TrafficVienna already has a production-tested OpenCode workflow with fixed local models,
explicit secret and destructive-command denials, sequential delegation, recovery rules, and
repository validators. The canonical framework generates a root `opencode.json` and an
`.opencode/agents/orchestrator.md`, which would collide with and weaken that existing
provider contract if adopted blindly.

The starter build pipeline also assumes `App.xcodeproj` and `Modules`, while TrafficVienna
uses `TrafficVienna.xcodeproj`, an MVVM application, a widget, and existing build/test scripts.

## Decision

1. Install the canonical framework and all 19 roles without replacing product code, Xcode
   files, resources, product history, or existing build/test behavior.
2. Preserve `.opencode/opencode.json`, original OpenCode agents, commands, models, and the
   sequential workflow byte-for-byte. Preserve every existing root `opencode.json` rule and
   add only any canonical mandatory deny pattern that is currently missing.
3. Use the framework's explicit OpenCode adapter configuration to leave the project-owned root
   config unmanaged and emit the canonical orchestrator as
   `.opencode/agents/af-orchestrator.md`. All other canonical role names are non-conflicting;
   markerless existing agents remain project-owned and drift checking reports them only as
   documented additions.
4. Upgrade same-ID generic `.agents/skills` to the canonical framework versions. Preserve
   TrafficVienna-only skills and select `ios-development`, `ios-testing`, and
   `ios-quality` in `project.yaml`.
5. Extend existing validation and CI wrappers with framework validation, drift checking, and
   the shared generated-artifact, project-owned OpenCode, and provider-shim tests. Retain
   TrafficVienna's existing OpenCode, permission, reliability, build, and XCTest gates. The
   complete framework eval suite remains a manual diagnostic while the preserved repository
   tracks `node_modules`, which truthfully fails sensitive-config eval E18. No pipeline may
   assume `App.xcodeproj` or `Modules`.
6. Record the exact starter source commit, collision mapping, and installed path list in the
   adoption report. Future updates must preserve this adapter configuration.

## Alternatives

- **Overwrite existing OpenCode configuration:** rejected because it removes explicit models,
  secret-read denials, protected-branch rules, and the proven sequential workflow.
- **Omit OpenCode framework roles:** rejected because the 19-role framework would be incomplete
  on TrafficVienna's primary provider.
- **Rename the existing orchestrator:** rejected because it would break documented commands,
  validators, and established operator behavior.
- **Run the starter updater with blanket adoption:** rejected because it cannot distinguish
  product scaffold from framework payload at this boundary.

## Consequences

TrafficVienna keeps its current OpenCode operating contract while gaining the canonical role
set on every provider. The framework OpenCode orchestrator is available explicitly as
`af-orchestrator`; the existing `orchestrator` remains the project default.

## Security and rollback

The adapter is strictly preservation-oriented: it cannot relax project OpenCode permissions.
Adding a missing canonical deny pattern is permitted tightening, never replacement.
Framework provider profiles retain their own destructive-operation denials. No credentials or
personal provider configuration are installed.

Rollback is a normal revert of the adoption commit using the exact paths in
`docs/agent-framework-adoption.md`. Existing product and OpenCode files are verified against
the staging baseline and are not reconstructed from the starter.
