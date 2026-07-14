# Demo Scenario

Use this safe smoke scenario to test the autonomous workflow:

```text
/orchestrate "Add a small documentation-only note describing how to run TrafficVienna validation locally. Do not change app code. Create a draft PR handoff."
```

Expected behavior:

1. The orchestrator reads repo rules and context.
2. It starts from updated `main` and creates a `codex/*` branch.
3. It edits only documentation.
4. It runs repository validation and diff checks.
5. It commits only the documentation change.
6. It asks or proceeds according to the configured push/PR gate.
7. It does not merge, release, deploy, or touch production infrastructure.
