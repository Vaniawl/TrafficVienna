# Agents for native iOS development

The framework already supplies isolated roles with different responsibilities. This template
configures ten of them with iOS expertise; it does not need duplicate roles for each language.
Agents are generated for Codex, Claude Code, Kimi and OpenCode. Available runtime tools depend
on the host; the skills include Xcode CLI fallback and do not require a plugin subscription.

| Role | iOS responsibility | Skills |
| --- | --- | --- |
| orchestrator | Scope, bounded ownership, evidence and handover | all three, selectively |
| software-architect | Module direction, state, concurrency and ADRs | ios-development |
| implementation-engineer | SwiftUI features, async state, focused tests | ios-development |
| code-reviewer | Independent correctness and lifecycle review | ios-development, ios-quality |
| qa-test-engineer | Package, native and UI tests; Simulator evidence | ios-testing |
| accessibility-reviewer | VoiceOver, Dynamic Type, motion and adaptive layout | ios-quality |
| performance-reliability-engineer | Measured rendering, latency, memory and task lifetime | ios-quality, ios-testing |
| security-privacy-reviewer | Entitlements, manifests, data, credentials and logs | ios-quality |
| devops-release-engineer | Builds, signing, archives, CI and authorized delivery | ios-testing, ios-quality |
| ui-ux-designer | Native interactions, navigation and product design tokens | ios-development, ios-quality |

## Use the smallest team

A simple feature normally needs implementation and independent review; add QA for integration
coverage, accessibility when UI changes, and security when a trust boundary changes. Architecture,
profiling, and delivery roles join only when their responsibilities are relevant. Do not launch
all ten agents for every task. Apply the framework task contract with explicit owned files.

Examples: ask the implementation engineer to implement a scoped SwiftUI screen using
`ios-development`; ask QA to reproduce a failed cancellation/retry flow using `ios-testing`;
ask the accessibility reviewer to inspect the changed screen using `ios-quality`.

## Maintain

Edit canonical role inputs and the three canonical skill folders under agent-framework, then run:

```bash
python3 scripts/agent-framework/render.py
python3 scripts/agent-framework/check-drift.py
```

The selected domain skills in project.yaml survive bootstrap. Generated provider files are not
edited by hand. Other domain sources remain available in the framework catalog, but are not
installed or loaded for ordinary iOS work. Review upstream framework updates before applying:
they can replace the local iOS additions. See ADR 0003.

## Existing applications and Mac support

Keep the existing project's schemes, module layout, data and product docs. The three iOS
skills now resolve project-specific paths instead of requiring the starter App/Modules tree.
An existing application adopts the agent tooling separately; do not run new-project bootstrap
or replace its build scripts and provider permissions with the iOS scaffold.

For a project with native macOS or Mac Catalyst scope, add macos-development to
agent_framework.skills in project.yaml and render. The same ten roles load the skill
conditionally for Mac tasks. This preserves 19 roles and keeps the standard starter iOS-only.
Recall's existing Catalyst build can select this skill; an iOS-only project should leave it
unselected until Mac support is approved. No target, entitlement or signing setting is
created by skill selection. See ADR 0004.
