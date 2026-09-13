# Agent framework installation — 2026-09-13

Installed reviewed framework commit `e6eade9a` on product base `d7d44d5e31e0ed2bd0aaf5e9d26e8eab40bea7d3`.
The current task branch is `codex/apple-agent-template`.

The three iOS domain skills are selected. The native OpenCode engine, custom agents, models and policy remain in place; af-orchestrator is the framework alias. Mac support is not added to the product.

## Verified installation

- Installed Git tree exactly matches the previously reviewed adoption tree.
- 248 pre-existing non-cache paths checked against a fresh pre-install snapshot; no
  unexpected changes. Only the reviewed framework integration paths differ.
- `bash scripts/validate-repository.sh`: PASS.
- `python3 -m unittest tests.agent-framework.test_generated_artifacts tests.agent-framework.test_project_opencode tests.agent-framework.test_provider_shims`: 37 tests, OK, one GNU timeout skip before the cache regression extension.
  The updated gate passes 45 tests, including eight cache/security regressions (one GNU timeout skip).
- Product Swift, tests, Xcode projects, resources, entitlements and signing files are preserved.
- Canonical roles: 19. Tools/providers load the relevant roles for each bounded task;
  installation does not start all agents automatically.

## Native and hosted evidence

- iOS Debug build: PASS.
- Native tests: 217/217 (212 unit/service and 5 UI), zero failures or skips.
- Existing OpenCode permission matcher and reliability/timeout checks: PASS with isolated
  OpenCode 1.17.20; no global installation, login or model inference.
- Draft handoff: https://github.com/Vaniawl/TrafficVienna/pull/17 , stacked on the existing
  system-surfaces-readiness branch. Hosted CI is recorded on the PR.
- The first hosted run exposed a framework scanner false positive after OpenCode installed
  ignored runtime dependencies. The scoped fix excludes only Git-ignored untracked runtime dependency files, with eight regression tests;
  it does not dismiss the separate pre-existing tracked-node_modules E18 finding.

Native outputs were checked via xcresult summaries. Initial verifier harness file-size limits
caused XCBuild service failures; correcting only the harness resolved them. No product or
global system configuration was changed. Distribution and real-device acceptance were not
performed. Exact commands and logs are retained in the task installation report.

## Update boundary

The shared Apple starter's new-profile bootstrap is for new applications only. Do not run
bootstrap or a blanket scaffold updater over this existing product. The installed role/skill
framework is maintained from canonical sources, with `render.py` and `check-drift.py`; product
architecture, build wrappers and provider policy remain owned by this repository.

## Provider cache regression gate

The security-reviewed validator and portable regression tests are synchronized with the shared
Apple starter. Tracked/unignored provider files remain covered; Git inspection errors and
nested repository directory entries fall back to full scanning. The separate E18 diagnostic
and existing provider permission gates remain unchanged.
