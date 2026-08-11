# Checks

Run commands from the repository root and observe their real exit status. The host
currently has two simulators named `iPhone 17`, so local evidence uses one explicit
UUID instead of the ambiguous name-only destination.

```sh
export TRAFFICVIENNA_XCODE_DESTINATION='platform=iOS Simulator,id=6B367A70-5FF5-4C39-B479-F27457824C34'

bash scripts/validate-repository.sh
bash scripts/validate-opencode.sh
bash scripts/ci.sh
git diff --check
```

`scripts/ci.sh` covers repository/OpenCode/reliability validation, the app and
widget build, XCTest, and final diff validation. Direct equivalents are:

```sh
xcodebuild -scheme TrafficVienna -project TrafficVienna.xcodeproj \
  -destination "$TRAFFICVIENNA_XCODE_DESTINATION" build

xcodebuild -scheme TrafficVienna -project TrafficVienna.xcodeproj \
  -destination "$TRAFFICVIENNA_XCODE_DESTINATION" test
```

## Current evidence

- 11 August 2026: full `scripts/ci.sh` exited 0 and ended `[ci] OK`.
- XCTest result: 110 passed, 0 failed, 0 skipped.
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
