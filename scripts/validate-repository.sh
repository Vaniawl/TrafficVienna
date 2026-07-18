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
  "TrafficVienna/Info.plist"
  "TrafficVienna/PrivacyInfo.xcprivacy"
  "TrafficViennaWidget/PrivacyInfo.xcprivacy"
  "TrafficViennaTests/TrafficViennaTests.swift"
  "TrafficViennaUITests/TrafficViennaUITests.swift"
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
plutil -lint "$ROOT/TrafficVienna/Info.plist" >/dev/null
plutil -lint "$ROOT/TrafficVienna/PrivacyInfo.xcprivacy" >/dev/null
plutil -lint "$ROOT/TrafficViennaWidget/PrivacyInfo.xcprivacy" >/dev/null
node "$ROOT/scripts/update-localizations.mjs" --check

if ! plutil -p "$ROOT/TrafficVienna/Info.plist" | grep -q 'trafficvienna'; then
  echo "[validate-repository] missing trafficvienna URL scheme" >&2
  exit 1
fi

if ! grep -q "BlueprintName = \"TrafficVienna\"" "$ROOT/TrafficVienna.xcodeproj/xcshareddata/xcschemes/TrafficVienna.xcscheme"; then
  echo "[validate-repository] missing TrafficVienna scheme wiring" >&2
  exit 1
fi

if ! grep -q "BlueprintName = \"TrafficViennaTests\"" "$ROOT/TrafficVienna.xcodeproj/xcshareddata/xcschemes/TrafficVienna.xcscheme"; then
  echo "[validate-repository] missing TrafficViennaTests scheme wiring" >&2
  exit 1
fi

if ! grep -q "BlueprintName = \"TrafficViennaUITests\"" "$ROOT/TrafficVienna.xcodeproj/xcshareddata/xcschemes/TrafficVienna.xcscheme"; then
  echo "[validate-repository] missing TrafficViennaUITests scheme wiring" >&2
  exit 1
fi

app_privacy="$(plutil -p "$ROOT/TrafficVienna/PrivacyInfo.xcprivacy")"
widget_privacy="$(plutil -p "$ROOT/TrafficViennaWidget/PrivacyInfo.xcprivacy")"
for reason in CA92.1 1C8F.1; do
  if ! grep -q "$reason" <<<"$app_privacy"; then
    echo "[validate-repository] app privacy manifest missing UserDefaults reason: $reason" >&2
    exit 1
  fi
done
if ! grep -q "1C8F.1" <<<"$widget_privacy"; then
  echo "[validate-repository] widget privacy manifest missing App Group UserDefaults reason" >&2
  exit 1
fi

echo "[validate-repository] OK"
