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

xcodebuild -scheme TrafficVienna -project TrafficVienna.xcodeproj -destination 'platform=iOS Simulator,name=iPhone 17' test
