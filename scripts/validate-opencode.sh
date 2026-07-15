#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")/.." && pwd)"

python3 - "$ROOT" <<'PY'
from __future__ import annotations

import json
import sys
from pathlib import Path

root = Path(sys.argv[1])
cfg = json.loads((root / "opencode.json").read_text(encoding="utf-8"))

required = [
    "AGENTS.md",
    "docs/CONTEXT.md",
    "docs/REFERENCES.md",
    "memory/DECISIONS.md",
    "memory/JOURNAL.md",
    "docs/opencode/multi-agent-workflow.md",
    "docs/opencode/task-contract.md",
    "docs/opencode/permission-matrix.md",
    "docs/opencode/git-ci-release.md",
    "docs/opencode/model-matrix.md",
    "docs/opencode/state-files.md",
    "docs/opencode/reliability-audit-2026-07-15.md",
    ".opencode/agents/orchestrator.md",
    ".opencode/agents/explorer.md",
    ".opencode/agents/architect.md",
    ".opencode/agents/implementer.md",
    ".opencode/agents/test-architect.md",
    ".opencode/agents/reviewer.md",
    ".opencode/agents/security-reviewer.md",
    ".opencode/agents/release-manager.md",
    ".opencode/commands/orchestrate.md",
    "scripts/validate-repository.sh",
    "scripts/validate-opencode.sh",
    "scripts/build.sh",
    "scripts/test.sh",
    "scripts/ci.sh",
    "tests/opencode-permission-matcher.sh",
    "tests/opencode-reliability.sh",
]

missing = [p for p in required if not (root / p).exists()]
if missing:
    raise SystemExit(f"[validate-opencode] missing files: {', '.join(missing)}")

if cfg.get("$schema") != "https://opencode.ai/config.json":
    raise SystemExit("[validate-opencode] invalid opencode schema")

plugins = cfg.get("plugin", [])
if "opencode-mobile" not in plugins:
    raise SystemExit("[validate-opencode] opencode-mobile plugin is not preserved")

instructions = set(cfg.get("instructions", []))
for instruction in ["AGENTS.md", "docs/CONTEXT.md", "memory/JOURNAL.md"]:
    if instruction not in instructions:
        raise SystemExit(f"[validate-opencode] missing instruction: {instruction}")

permission = cfg.get("permission", {})
read_rules = permission.get("read", {})
for pattern in [".env", ".env.*", "*.env", "**/*.env", "secrets/**", "credentials/**", "**/*.pem", "**/*.key"]:
    if read_rules.get(pattern) != "deny":
        raise SystemExit(f"[validate-opencode] secret read deny missing: {pattern}")

bash = permission.get("bash", {})
required_bash = {
    "git push origin main": "deny",
    "git push origin HEAD:main": "deny",
    "git push --force*": "deny",
    "git reset --hard*": "deny",
    "git switch -c codex/*": "allow",
    "bash scripts/ci.sh": "allow",
    "xcodebuild -scheme TrafficVienna -project TrafficVienna.xcodeproj -destination 'platform=iOS Simulator,name=iPhone 17' build": "allow",
    "xcodebuild -scheme TrafficVienna -project TrafficVienna.xcodeproj -destination 'platform=iOS Simulator,name=iPhone 17' test": "allow",
    "gh pr create --draft *": "allow",
    "gh pr merge *": "deny",
}
for command, expected in required_bash.items():
    if bash.get(command) != expected:
        raise SystemExit(f"[validate-opencode] bash rule {command!r} expected {expected!r}")

agent_text = (root / ".opencode/agents/orchestrator.md").read_text(encoding="utf-8")
for phrase in [
    "explorer: allow",
    "implementer: allow",
    "orchestrator: deny",
    "Run subagents sequentially by default",
    "3-minute maximum wait for a parallel batch",
    "Never merge, release, deploy, or push to `main`",
]:
    if phrase not in agent_text:
        raise SystemExit(f"[validate-opencode] orchestrator missing phrase: {phrase}")

workflow_text = (root / "docs/opencode/multi-agent-workflow.md").read_text(encoding="utf-8")
for phrase in [
    "Subagents run sequentially by default",
    "2-3 subagents maximum",
    "3 minutes per parallel batch",
    "reruns unfinished work sequentially",
]:
    if phrase not in workflow_text:
        raise SystemExit(f"[validate-opencode] workflow missing phrase: {phrase}")

combined = "\n".join(
    p.read_text(encoding="utf-8")
    for p in [
        root / "opencode.json",
        root / "AGENTS.md",
        root / "docs/opencode/multi-agent-workflow.md",
        root / "docs/opencode/git-ci-release.md",
    ]
)
for forbidden in [
    "ivan" + "dovhosheia",
    "skyphoenix" + "-website",
    "ubuntu" + "-ai-amd-stack",
    "github" + "-work",
]:
    if forbidden in combined:
        raise SystemExit(f"[validate-opencode] forbidden work-specific token found: {forbidden}")

print("[validate-opencode] OK")
PY
