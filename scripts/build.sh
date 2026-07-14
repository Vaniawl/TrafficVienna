#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")/.." && pwd)"
cd "$ROOT"

bash scripts/validate-repository.sh
bash scripts/validate-opencode.sh

if ! command -v xcodebuild >/dev/null 2>&1; then
  if [[ "${TRAFFICVIENNA_ALLOW_XCODEBUILD_SKIP:-0}" == "1" ]]; then
    echo "[build] xcodebuild unavailable; skipping iOS build by explicit local override"
    exit 0
  fi
  echo "[build] xcodebuild is required for TrafficVienna build" >&2
  exit 127
fi

xcodebuild -scheme TrafficVienna -project TrafficVienna.xcodeproj -destination 'platform=iOS Simulator,name=iPhone 17' build
