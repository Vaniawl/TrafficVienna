# Threat Model

The authoritative product trust boundaries and completion gate are maintained in
`SECURITY.md`. They cover fixed Wiener Linien endpoints, in-memory location use, local
preferences and App Group data, typed notification routing, explicit reminders and Live
Activities, and the account-free privacy boundary.

The agent framework adds repository content and local development tools as an additional
boundary. Generated provider policies deny force pushes and sensitive-file reads, and the
project-owned OpenCode configuration remains subject to its stricter existing permission
model. Framework rendering consumes only reviewed repository metadata. PyYAML is pinned as
a development dependency and is not linked into the application.

Any new endpoint, dependency, entitlement, analytics system, authentication flow, or
external service requires a security review and an update to `SECURITY.md`.
