# Agent framework installation — 2026-09-13

Installed reviewed framework commit `e6eade9a` on product base `d7d44d5e31e0ed2bd0aaf5e9d26e8eab40bea7d3`.
The current task branch is `codex/apple-agent-template`.

The three iOS domain skills are selected. The native OpenCode engine, custom agents, models and policy remain in place; af-orchestrator is the framework alias. Mac support is not added to the product.

## Verified installation

- Installed Git tree exactly matches the previously reviewed adoption tree.
- 248 pre-existing non-cache paths checked against a fresh pre-install snapshot; no
  unexpected changes. Only the reviewed framework integration paths differ.
- `bash scripts/validate-repository.sh`: PASS.
- `python3 -m unittest tests.agent-framework.test_generated_artifacts tests.agent-framework.test_project_opencode tests.agent-framework.test_provider_shims`: 37 tests, OK, one GNU timeout skip.
- Product Swift, tests, Xcode projects, resources, entitlements and signing files are preserved.
- Canonical roles: 19. Tools/providers load the relevant roles for each bounded task;
  installation does not start all agents automatically.

## Native and hosted evidence

Native checks and publication are being recorded in the completion report for this update.
Framework-only checks are not proof of an application build or end-user UI behavior.

## Update boundary

The shared Apple starter's new-profile bootstrap is for new applications only. Do not run
bootstrap or a blanket scaffold updater over this existing product. The installed role/skill
framework is maintained from canonical sources, with `render.py` and `check-drift.py`; product
architecture, build wrappers and provider policy remain owned by this repository.
