#!/usr/bin/env bash
set -euo pipefail

root="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")/.." && pwd)"
cd "$root"

for command_name in xcodebuild xcrun; do
  if ! command -v "$command_name" >/dev/null 2>&1; then
    printf 'error: %s is required\n' "$command_name" >&2
    exit 127
  fi
done

acceptance_output="${TRAFFICVIENNA_ACCEPTANCE_OUTPUT:-/tmp/TrafficViennaLocalAcceptance-$(date +%Y%m%d-%H%M%S)}"
mkdir -p "$acceptance_output"

created_devices=()
created_device=""

cleanup() {
  for device in "${created_devices[@]}"; do
    xcrun simctl shutdown "$device" >/dev/null 2>&1 || true
    xcrun simctl delete "$device" >/dev/null 2>&1 || true
  done
}
trap cleanup EXIT

create_device() {
  local label="$1"
  local device_type="$2"
  created_device="$(
    xcrun simctl create \
      "TrafficVienna Local Acceptance $label $$" \
      "$device_type" \
      com.apple.CoreSimulator.SimRuntime.iOS-26-5
  )"
  created_devices+=("$created_device")
}

configure_device() {
  local device="$1"
  local appearance="$2"
  local content_size="$3"
  local contrast="$4"
  local reduce_motion="$5"

  xcrun simctl boot "$device" >/dev/null 2>&1 || true
  xcrun simctl bootstatus "$device" -b
  xcrun simctl ui "$device" appearance "$appearance"
  xcrun simctl ui "$device" content_size "$content_size"
  xcrun simctl ui "$device" increase_contrast "$contrast"
  xcrun simctl location "$device" set 48.2082,16.3738
  xcrun simctl spawn "$device" defaults write com.apple.Accessibility \
    ReduceMotionEnabled -bool "$reduce_motion"
}

run_scenario() {
  local label="$1"
  local device="$2"
  shift 2

  local result_bundle="$acceptance_output/$label.xcresult"
  local derived_data="$acceptance_output/DerivedData"

  printf '[local-ui-acceptance] %s\n' "$label"
  xcodebuild \
    -scheme TrafficViennaLocalAcceptance \
    -project TrafficVienna.xcodeproj \
    -destination "platform=iOS Simulator,id=$device" \
    -derivedDataPath "$derived_data" \
    -resultBundlePath "$result_bundle" \
    test \
    "$@"
}

create_device iPhone com.apple.CoreSimulator.SimDeviceType.iPhone-17
iphone="$created_device"
configure_device "$iphone" light large disabled false
run_scenario \
  iphone-standard \
  "$iphone" \
  -only-testing:TrafficViennaUITests/TrafficViennaSmokeTests \
  -only-testing:TrafficViennaUITests/TrafficViennaAccessibilityAuditTests

configure_device \
  "$iphone" \
  dark \
  accessibility-extra-extra-extra-large \
  enabled \
  true
run_scenario \
  iphone-accessibility \
  "$iphone" \
  -only-testing:TrafficViennaUITests/TrafficViennaAdaptiveLayoutTests

create_device \
  iPad \
  com.apple.CoreSimulator.SimDeviceType.iPad-Pro-13-inch-M5-12GB
ipad="$created_device"
configure_device \
  "$ipad" \
  dark \
  accessibility-extra-extra-extra-large \
  enabled \
  true
run_scenario \
  ipad-accessibility \
  "$ipad" \
  -only-testing:TrafficViennaUITests/TrafficViennaAdaptiveLayoutTests

printf '[local-ui-acceptance] OK — results: %s\n' "$acceptance_output"
