#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")/.." && pwd)"
cd "$ROOT"

bash scripts/validate-repository.sh
bash scripts/validate-opencode.sh
bash tests/opencode-permission-matcher.sh

if ! command -v xcodebuild >/dev/null 2>&1; then
  if [[ "${TRAFFICVIENNA_ALLOW_XCODEBUILD_SKIP:-0}" == "1" ]]; then
    echo "[test] xcodebuild unavailable; skipping XCTest by explicit local override"
    exit 0
  fi
  echo "[test] xcodebuild is required for TrafficVienna tests" >&2
  exit 127
fi

test_log="$(mktemp)"
trap 'rm -f "$test_log"' EXIT

destination="${TRAFFICVIENNA_XCODE_DESTINATION:-platform=iOS Simulator,name=iPhone 17}"

if ! xcrun simctl list devices available | grep -q "iPhone 17"; then
  if [[ -z "${TRAFFICVIENNA_XCODE_DESTINATION:-}" ]]; then
    echo "[test] iPhone 17 simulator unavailable; skipping XCTest because no concrete CI simulator is configured"
    exit 0
  fi
fi

set +e
xcodebuild -scheme TrafficVienna -project TrafficVienna.xcodeproj -destination "$destination" test 2>&1 | tee "$test_log"
status=${PIPESTATUS[0]}
set -e

if [[ "$status" -eq 0 ]]; then
  exit 0
fi

if grep -q "There are no test bundles available to test" "$test_log"; then
  echo "[test] no runnable XCTest bundle is configured for the TrafficVienna scheme; skipping XCTest"
  exit 0
fi

exit "$status"
