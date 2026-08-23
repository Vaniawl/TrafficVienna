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

if [[ -n "${TRAFFICVIENNA_XCODE_DESTINATION:-}" ]]; then
  destination="$TRAFFICVIENNA_XCODE_DESTINATION"
else
  simulator_id="$(bash scripts/resolve-simulator-id.sh)"
  destination="platform=iOS Simulator,id=$simulator_id"
fi

xcodebuild_arguments=(
  -scheme TrafficVienna
  -project TrafficVienna.xcodeproj
  -destination "$destination"
)

if [[ -n "${TRAFFICVIENNA_TEST_RESULT_BUNDLE_PATH:-}" ]]; then
  if [[ -e "$TRAFFICVIENNA_TEST_RESULT_BUNDLE_PATH" ]]; then
    echo "[test] result bundle path already exists: $TRAFFICVIENNA_TEST_RESULT_BUNDLE_PATH" >&2
    exit 64
  fi
  xcodebuild_arguments+=(
    -resultBundlePath "$TRAFFICVIENNA_TEST_RESULT_BUNDLE_PATH"
  )
fi

xcodebuild "${xcodebuild_arguments[@]}" test
