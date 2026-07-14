#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")/.." && pwd)"

required_files=(
  "AGENTS.md"
  "README.md"
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

if ! grep -q "BlueprintName = \"TrafficVienna\"" "$ROOT/TrafficVienna.xcodeproj/xcshareddata/xcschemes/TrafficVienna.xcscheme"; then
  echo "[validate-repository] missing TrafficVienna scheme wiring" >&2
  exit 1
fi

if ! grep -q "BlueprintName = \"TrafficViennaTests\"" "$ROOT/TrafficVienna.xcodeproj/xcshareddata/xcschemes/TrafficVienna.xcscheme"; then
  echo "[validate-repository] missing TrafficViennaTests scheme wiring" >&2
  exit 1
fi

echo "[validate-repository] OK"
