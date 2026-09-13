#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
ROOT="$(cd "$SCRIPT_DIR/.." && pwd -P)"

required_files=(
  "AGENTS.md"
  "CLAUDE.md"
  "README.md"
  "PROJECT.md"
  "BACKLOG.md"
  "project.yaml"
  "requirements-dev.txt"
  ".claude/settings.json"
  "docs/product/product-vision.md"
  "docs/product/pov-scope.md"
  "docs/architecture/overview.md"
  "docs/security/threat-model.md"
  "docs/testing/test-strategy.md"
  "docs/ios-agents.md"
  "docs/CONTEXT.md"
  "docs/REFERENCES.md"
  "memory/DECISIONS.md"
  "memory/JOURNAL.md"
  "TrafficVienna.xcodeproj/project.pbxproj"
  "TrafficVienna.xcodeproj/xcshareddata/xcschemes/TrafficVienna.xcscheme"
  "TrafficVienna/TrafficViennaApp.swift"
  "TrafficViennaTests/TrafficViennaTests.swift"
  "opencode.json"
)

for path in "${required_files[@]}"; do
  if [[ ! -f "$ROOT/$path" ]]; then
    echo "[validate-repository] missing required file: $path" >&2
    exit 1
  fi
done

python3 -m json.tool "$ROOT/opencode.json" >/dev/null
python3 -m json.tool "$ROOT/.opencode/opencode.json" >/dev/null
python3 - <<'PYAML'
from pathlib import Path
try:
    import yaml
except ModuleNotFoundError:
    raise SystemExit("[validate-repository] PyYAML is required; install requirements-dev.txt")
metadata = yaml.safe_load(Path("project.yaml").read_text(encoding="utf-8"))
project = metadata.get("project") if isinstance(metadata, dict) else None
if not isinstance(project, dict) or project.get("name") != "TrafficVienna" or project.get("slug") != "traffic-vienna":
    raise SystemExit("[validate-repository] project.yaml must identify TrafficVienna")
framework = metadata.get("agent_framework", {})
required = {"ios-development", "ios-testing", "ios-quality"}
if not isinstance(framework, dict) or not required.issubset(framework.get("skills", [])):
    raise SystemExit("[validate-repository] project.yaml is missing required iOS skills")
opencode = framework.get("opencode")
if opencode != {"preserve_project_config": True, "role_aliases": {"orchestrator": "af-orchestrator"}}:
    raise SystemExit("[validate-repository] project-owned OpenCode adapter is not pinned")
print("[validate-repository] project metadata passed")
PYAML

if ! grep -q "BlueprintName = \"TrafficVienna\"" "$ROOT/TrafficVienna.xcodeproj/xcshareddata/xcschemes/TrafficVienna.xcscheme"; then
  echo "[validate-repository] missing TrafficVienna scheme wiring" >&2
  exit 1
fi

if ! grep -q "BlueprintName = \"TrafficViennaTests\"" "$ROOT/TrafficVienna.xcodeproj/xcshareddata/xcschemes/TrafficVienna.xcscheme"; then
  echo "[validate-repository] missing TrafficViennaTests scheme wiring" >&2
  exit 1
fi

python3 "$ROOT/scripts/agent-framework/validate.py"
python3 "$ROOT/scripts/agent-framework/check-drift.py"

echo "[validate-repository] OK"
