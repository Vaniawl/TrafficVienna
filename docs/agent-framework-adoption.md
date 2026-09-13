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

The staged baseline is recorded at
`/private/tmp/apple-template-adoption-20260913/baseline.json`. A preservation verifier
compares every pre-existing file and permits changes only to the explicit integration
paths. Product Swift, tests, Xcode project data, resources, entitlements, and signing files
must remain byte-identical.
