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
  "TrafficViennaUITests/TrafficViennaSmokeTests.swift"
  "opencode.json"
  "tests/repository-validation-regressions.sh"
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

scheme="${TRAFFICVIENNA_SCHEME_PATH:-$ROOT/TrafficVienna.xcodeproj/xcshareddata/xcschemes/TrafficVienna.xcscheme}"
smoke_tests="${TRAFFICVIENNA_SMOKE_TESTS_PATH:-$ROOT/TrafficViennaUITests/TrafficViennaSmokeTests.swift}"

if ! grep -q "BlueprintName = \"TrafficViennaUITests\"" "$scheme"; then
  echo "[validate-repository] missing TrafficViennaUITests scheme wiring" >&2
  exit 1
fi

for method in testOnboardingPages testPrimaryTabsAndStationSearch; do
  if ! grep -q "func $method()" "$smoke_tests"; then
    echo "[validate-repository] missing standard UI smoke test: $method" >&2
    exit 1
  fi
  if grep -q "TrafficViennaSmokeTests/$method()" "$scheme"; then
    echo "[validate-repository] standard UI smoke test is skipped in the shared scheme: $method" >&2
    exit 1
  fi
done

tracked_node_modules="$(git -C "$ROOT" ls-files node_modules)"
if [[ -n "$tracked_node_modules" ]]; then
  echo "[validate-repository] node_modules must not be tracked" >&2
  exit 1
fi

sync_unit_tests="$({ grep -R -nE '^[[:space:]]+func test.*\)( throws)? \{' "$ROOT/TrafficViennaTests" --include='*.swift' || true; })"
if [[ -n "$sync_unit_tests" ]]; then
  echo "[validate-repository] unit tests must stay async while default actor isolation is MainActor:" >&2
  echo "$sync_unit_tests" >&2
  exit 1
fi

echo "[validate-repository] OK"
