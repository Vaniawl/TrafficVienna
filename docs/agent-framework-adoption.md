# Agent Framework Adoption

TrafficVienna receives the canonical agent framework through a reviewed, path-scoped
installation from iOS starter commit `d036ca7`.

## Provider integration

The root `opencode.json`, `.opencode/opencode.json`, existing OpenCode agents, commands,
models, and sequential workflow remain project-owned. The canonical OpenCode orchestrator
is generated as `af-orchestrator`; existing `orchestrator` behavior is unchanged. Required
deny patterns missing from the root configuration are added without removing or relaxing
any rule. Same-ID generic skills are upgraded to their canonical versions, while
TrafficVienna-only skills remain unmanaged and available.

## Installed scope

The installation includes canonical framework sources and catalogs, provider roles and
skills generated from them, framework render/validate/drift/eval tooling and tests,
project metadata, thin framework entry-point documentation, and additions to the existing
validation and CI gates. It excludes the starter application, package modules, build
configuration, bootstrap scripts, sample product documents, and fixed starter workflow.

The adoption commit's changed-path list is the installation manifest for review and
rollback. Reverting that commit removes the adoption without reconstructing application
files.

## Preservation

The framework was installed on 2026-09-13 in commit `e6eade9a` on top of product
commit `d7d44d5e31e0ed2bd0aaf5e9d26e8eab40bea7d3`. The installed Git tree matches the independently reviewed staging tree.
A pre-install working-tree hash comparison found no unexpected changes to pre-existing
files. Recall's existing uncommitted product work, when present, stays outside this adoption
commit. See `docs/agent-framework-installation.md` for current validation and publication.
