#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")/.." && pwd)"

required_files=(
  "AGENTS.md"
  "README.md"
  "docs/CONTEXT.md"
  "docs/app-store/metadata.json"
  "docs/app-store/SUBMISSION.md"
  "docs/REFERENCES.md"
  "memory/DECISIONS.md"
  "memory/JOURNAL.md"
  "TrafficVienna.xcodeproj/project.pbxproj"
  "TrafficVienna.xcodeproj/xcshareddata/xcschemes/TrafficVienna.xcscheme"
  "TrafficVienna/TrafficViennaApp.swift"
  "TrafficVienna/Info.plist"
  "TrafficVienna/TrafficVienna.entitlements"
  "TrafficVienna/TrafficViennaPersonal.entitlements"
  "TrafficVienna/PrivacyInfo.xcprivacy"
  "TrafficViennaWidgetExtension.entitlements"
  "TrafficViennaWidgetExtensionPersonal.entitlements"
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
plutil -lint "$ROOT/TrafficVienna/TrafficVienna.entitlements" >/dev/null
plutil -lint "$ROOT/TrafficVienna/TrafficViennaPersonal.entitlements" >/dev/null
plutil -lint "$ROOT/TrafficViennaWidgetExtension.entitlements" >/dev/null
plutil -lint "$ROOT/TrafficViennaWidgetExtensionPersonal.entitlements" >/dev/null
plutil -lint "$ROOT/TrafficVienna/PrivacyInfo.xcprivacy" >/dev/null
plutil -lint "$ROOT/TrafficViennaWidget/PrivacyInfo.xcprivacy" >/dev/null
node "$ROOT/scripts/update-localizations.mjs" --check
node "$ROOT/scripts/validate-app-store-metadata.mjs"

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

project_settings="$(<"$ROOT/TrafficVienna.xcodeproj/project.pbxproj")"
for setting in \
  "CODE_SIGN_ENTITLEMENTS = TrafficVienna/TrafficViennaPersonal.entitlements;" \
  "CODE_SIGN_ENTITLEMENTS = TrafficVienna/TrafficVienna.entitlements;" \
  "CODE_SIGN_ENTITLEMENTS = TrafficViennaWidgetExtensionPersonal.entitlements;" \
  "CODE_SIGN_ENTITLEMENTS = TrafficViennaWidgetExtension.entitlements;" \
  "PRODUCT_BUNDLE_IDENTIFIER = com.ivandovhosheia.TrafficVienna.dev;" \
  "PRODUCT_BUNDLE_IDENTIFIER = com.ivandovhosheia.TrafficVienna.dev.widget;" \
  "PRODUCT_BUNDLE_IDENTIFIER = wellbe.TrafficVienna;" \
  "PRODUCT_BUNDLE_IDENTIFIER = wellbe.TrafficVienna.TrafficViennaWidget;"
do
  if ! grep -Fq "$setting" <<<"$project_settings"; then
    echo "[validate-repository] missing signing configuration: $setting" >&2
    exit 1
  fi
done

if plutil -p "$ROOT/TrafficVienna/TrafficViennaPersonal.entitlements" | grep -q "=>" ||
   plutil -p "$ROOT/TrafficViennaWidgetExtensionPersonal.entitlements" | grep -q "=>"; then
  echo "[validate-repository] Personal Team entitlement files must stay capability-free" >&2
  exit 1
fi

app_entitlements="$(plutil -p "$ROOT/TrafficVienna/TrafficVienna.entitlements")"
widget_entitlements="$(plutil -p "$ROOT/TrafficViennaWidgetExtension.entitlements")"
if ! grep -q "com.apple.developer.applesignin" <<<"$app_entitlements" ||
   ! grep -q "group.wellbe.TrafficVienna" <<<"$app_entitlements" ||
   ! grep -q "group.wellbe.TrafficVienna" <<<"$widget_entitlements"; then
  echo "[validate-repository] production Sign in with Apple/App Group entitlements are incomplete" >&2
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
