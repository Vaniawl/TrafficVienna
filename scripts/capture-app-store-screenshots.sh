#!/usr/bin/env bash
set -euo pipefail

root="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")/.." && pwd)"
cd "$root"

for command_name in jq sips xcodebuild xcrun; do
  if ! command -v "$command_name" >/dev/null 2>&1; then
    printf 'error: %s is required\n' "$command_name" >&2
    exit 127
  fi
done

trafficvienna_temp_dir="$(mktemp -d /tmp/trafficvienna-screenshots.XXXXXX)"
trafficvienna_screenshot_device="${TRAFFICVIENNA_SCREENSHOT_SIMULATOR_ID:-}"
trafficvienna_created_device=0

cleanup() {
  if [[ "$trafficvienna_created_device" == "1" ]]; then
    xcrun simctl shutdown "$trafficvienna_screenshot_device" >/dev/null 2>&1 || true
    xcrun simctl delete "$trafficvienna_screenshot_device" >/dev/null 2>&1 || true
  else
    xcrun simctl status_bar "$trafficvienna_screenshot_device" clear >/dev/null 2>&1 || true
  fi
  /bin/rm -rf -- "$trafficvienna_temp_dir"
}
trap cleanup EXIT

if [[ -z "$trafficvienna_screenshot_device" ]]; then
  trafficvienna_screenshot_device="$(
    xcrun simctl create \
      "TrafficVienna App Store Screenshots $$" \
      com.apple.CoreSimulator.SimDeviceType.iPhone-17-Pro-Max \
      com.apple.CoreSimulator.SimRuntime.iOS-26-5
  )"
  trafficvienna_created_device=1
fi

xcrun simctl boot "$trafficvienna_screenshot_device" >/dev/null 2>&1 || true
xcrun simctl bootstatus "$trafficvienna_screenshot_device" -b
xcrun simctl ui "$trafficvienna_screenshot_device" appearance light
xcrun simctl ui "$trafficvienna_screenshot_device" content_size large
xcrun simctl ui "$trafficvienna_screenshot_device" increase_contrast disabled
xcrun simctl status_bar "$trafficvienna_screenshot_device" override \
  --time 09:41 \
  --dataNetwork wifi \
  --wifiMode active \
  --wifiBars 3 \
  --cellularMode active \
  --cellularBars 4 \
  --batteryState charged \
  --batteryLevel 100
xcrun simctl location "$trafficvienna_screenshot_device" set 48.2082,16.3738

trafficvienna_destination="platform=iOS Simulator,id=$trafficvienna_screenshot_device"
trafficvienna_derived_data="$trafficvienna_temp_dir/DerivedData"

xcodebuild \
  -scheme TrafficVienna \
  -project TrafficVienna.xcodeproj \
  -destination "$trafficvienna_destination" \
  -derivedDataPath "$trafficvienna_derived_data" \
  build

trafficvienna_app_path="$trafficvienna_derived_data/Build/Products/Debug-iphonesimulator/TrafficVienna.app"
xcrun simctl install "$trafficvienna_screenshot_device" "$trafficvienna_app_path"
xcrun simctl privacy "$trafficvienna_screenshot_device" grant location wellbe.TrafficVienna

capture_locale() {
  local locale_directory="$1"
  local test_method="$2"
  local result_bundle="$trafficvienna_temp_dir/$locale_directory.xcresult"
  local attachments_directory="$trafficvienna_temp_dir/$locale_directory-attachments"
  local output_directory="docs/release/screenshots/$locale_directory"

  xcodebuild \
    -scheme TrafficViennaScreenshots \
    -project TrafficVienna.xcodeproj \
    -destination "$trafficvienna_destination" \
    -derivedDataPath "$trafficvienna_derived_data" \
    -resultBundlePath "$result_bundle" \
    test \
    "-only-testing:TrafficViennaUITests/TrafficViennaAppStoreScreenshotTests/$test_method"

  xcrun xcresulttool export attachments \
    --path "$result_bundle" \
    --output-path "$attachments_directory" >/dev/null

  mkdir -p "$output_directory"
  for screenshot_name in \
    01-nearby \
    02-station-detail \
    03-map \
    04-alerts \
    05-favourites
  do
    local exported_file
    exported_file="$(
      jq -r --arg name "$screenshot_name" \
        '[.[] | .attachments[] | select(.suggestedHumanReadableName | startswith($name)) | .exportedFileName][0] // empty' \
        "$attachments_directory/manifest.json"
    )"

    if [[ -z "$exported_file" ]]; then
      printf 'error: missing screenshot attachment %s for %s\n' \
        "$screenshot_name" "$locale_directory" >&2
      exit 1
    fi

    sips \
      -s format jpeg \
      -s formatOptions 95 \
      "$attachments_directory/$exported_file" \
      --out "$output_directory/$screenshot_name.jpg" >/dev/null
  done
}

capture_locale en-US testCaptureEnglishScreenshots
capture_locale de-AT testCaptureGermanScreenshots

for screenshot in docs/release/screenshots/{en-US,de-AT}/*.jpg; do
  width="$(sips -g pixelWidth "$screenshot" | awk '/pixelWidth/ { print $2 }')"
  height="$(sips -g pixelHeight "$screenshot" | awk '/pixelHeight/ { print $2 }')"
  alpha="$(sips -g hasAlpha "$screenshot" | awk '/hasAlpha/ { print $2 }')"

  if [[ "$width" != "1320" || "$height" != "2868" || "$alpha" != "no" ]]; then
    printf 'error: invalid App Store screenshot %s (%sx%s, alpha=%s)\n' \
      "$screenshot" "$width" "$height" "$alpha" >&2
    exit 1
  fi
done

printf 'Captured 10 current App Store screenshots in docs/release/screenshots/.\n'
