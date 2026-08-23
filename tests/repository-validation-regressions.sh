#!/usr/bin/env bash
set -euo pipefail

root="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")/.." && pwd)"
temp_dir="$(mktemp -d /tmp/trafficvienna-repository-validation.XXXXXX)"
trap '/bin/rm -rf -- "$temp_dir"' EXIT

scheme="$root/TrafficVienna.xcodeproj/xcshareddata/xcschemes/TrafficVienna.xcscheme"
smoke_tests="$root/TrafficViennaUITests/TrafficViennaSmokeTests.swift"
skipped_scheme="$temp_dir/TrafficVienna-skipped-smoke.xcscheme"
missing_smoke="$temp_dir/TrafficVienna-missing-smoke.swift"

sed '/<SkippedTests>/a\
               <Test Identifier = "TrafficViennaSmokeTests/testOnboardingPages()">\
               </Test>' "$scheme" > "$skipped_scheme"

if TRAFFICVIENNA_SCHEME_PATH="$skipped_scheme" \
  bash "$root/scripts/validate-repository.sh" >/dev/null 2>&1; then
  echo "[repository-validation-regressions] skipped standard smoke test was accepted" >&2
  exit 1
fi

sed '/func testOnboardingPages()/d' "$smoke_tests" > "$missing_smoke"

if TRAFFICVIENNA_SMOKE_TESTS_PATH="$missing_smoke" \
  bash "$root/scripts/validate-repository.sh" >/dev/null 2>&1; then
  echo "[repository-validation-regressions] missing standard smoke test was accepted" >&2
  exit 1
fi

echo "[repository-validation-regressions] OK"
