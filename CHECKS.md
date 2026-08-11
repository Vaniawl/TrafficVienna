# Checks

Run commands from the repository root and observe their real exit status. The test
script resolves an exact available `iPhone 17` UUID, preferring an already booted
device when duplicate names exist.

```sh
bash scripts/validate-repository.sh
bash scripts/validate-opencode.sh
bash scripts/ci.sh
bash scripts/capture-app-store-screenshots.sh
git diff --check
```

`scripts/ci.sh` covers repository/OpenCode/reliability validation, the app and
widget build, the standard test scheme, and final diff validation. The standard
scheme contains 110 unit/integration tests and two deterministic XCUITest smoke
journeys. The two live-data App Store capture methods are intentionally isolated
in `TrafficViennaScreenshots` and run only through the screenshot script.

Direct test equivalents are:

```sh
simulator_id="$(bash scripts/resolve-simulator-id.sh)"

xcodebuild -scheme TrafficVienna -project TrafficVienna.xcodeproj \
  -destination "platform=iOS Simulator,id=$simulator_id" test
```

## Current evidence

- 11 August 2026: full `scripts/ci.sh` exited 0 and ended `[ci] OK`.
- Standard test result: 112 passed, 0 failed, 0 skipped: 110 unit/integration
  tests and two XCUITest smoke journeys.
- Ten current premium App Store screenshots were generated on an isolated iPhone
  17 Pro Max in `en-US` and `de-AT`. Both capture tests passed, every JPEG is
  1320×2868 without alpha, and all ten were visually inspected.
- Simulator acceptance covered every redesigned route plus light/dark, maximum
  Accessibility Dynamic Type, Increase Contrast, live data, location, empty state,
  and tested failure-state boundaries.
- `DesignColorContrastTests` enforces WCAG AA 4.5:1 for white hero text and
  appearance-aware semantic text colours.
- An unsigned generic Release archive is the repeatable local packaging gate.
  Distribution signing, App Store Connect, upload, and physical/TestFlight
  acceptance remain separate release gates.

An Xcode skip, a Simulator-only build, or an unsigned archive must never be
presented as App Store release evidence.
