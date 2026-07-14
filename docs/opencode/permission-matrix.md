# OpenCode Permission Matrix

## Defaults

| Capability | Default | Reason |
|---|---|---|
| read/list/glob/grep | allow except secrets | Agents need evidence, but secrets stay blocked. |
| edit | ask globally | Ordinary chat remains approval-gated by default. |
| orchestrator/implementer edit | allow | Autonomous task execution needs local repository edits. |
| task delegation | deny globally; orchestrator allowlist | Prevent recursive or uncontrolled delegation. |
| bash | ask by default | Unknown commands can mutate state. |
| validation/build/test | allow when explicit | Routine quality gates should run without repeated prompts. |
| dependency install | `npm ci`/`npm install` allow; adding packages ask | Existing manifests are allowed; supply-chain changes are gated. |
| Git local add/commit | allow | Local commits are part of the autonomous workflow. |
| feature branch push and draft PR | allowed for orchestrator only | Completed work can be handed off for review. |
| direct `main`/`master` push | deny | Protect base branches. |
| force push, reset hard, clean, destructive remove | deny | Protect history and local data. |
| release/deploy/App Store tooling | ask or deny | Production and release actions require explicit approval. |

## Secret Deny Patterns

Denied read patterns include `.env`, `.env.*`, `*.env`, nested env files, `secrets/**`, `credentials/**`, private key names, `*.pem`, and `*.key`.

## TrafficVienna-Specific Gates

- Location, App Group storage, Live Activities, Widget, and Wiener Linien API changes require security/privacy review.
- Xcode project and entitlement changes require architecture review and release-readiness review.
- Release, TestFlight, App Store, signing, notarization, and deployment commands require explicit approval.
