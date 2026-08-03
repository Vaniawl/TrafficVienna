# Checks

Run commands from the repository root. A check counts only when its real exit
code and relevant output are observed; an Xcode skip is diagnostic evidence only.

| Requirement | Exact command | Evidence required |
| --- | --- | --- |
| REQ-TV-001/003/004/005/008/009 | `bash scripts/test.sh` | Full XCTest/XCUITest suite passes on macOS. |
| REQ-TV-002 | `bash scripts/build.sh` | App/widget compile, followed by simulator light/dark and Dynamic Type inspection. |
| REQ-TV-006 | `bash scripts/ci.sh` | Repository, build, test, and whitespace gates exit 0. |
| REQ-TV-007 | `bash scripts/validate-repository.sh && bash scripts/validate-opencode.sh` | Both validators pass and reviews have no unresolved Blocking/Important finding. |

## Supporting checks

```bash
git diff --check
bash scripts/validate-repository.sh
bash scripts/validate-opencode.sh
xcodebuild -scheme TrafficVienna -project TrafficVienna.xcodeproj \
  -destination 'platform=iOS Simulator,name=iPhone 17' analyze
```

Compiler-extracted app/widget string keys must also be compared with their
committed `.xcstrings` catalogues, including non-empty German values.

## Platform evidence

Validation uses the iPhone 17 Simulator. If multiple simulators share that name,
scripts may use the supported `TRAFFICVIENNA_XCODE_DESTINATION` override with
the inspected device UUID while preserving the required scheme and project.

Interactive acceptance includes the four tabs, Discover search/map, Alerts,
Saved, Station Detail, reminder management, relevant failure feedback, system
light/dark appearance, and an accessibility Dynamic Type size. iPad inspection
is supplementary layout evidence.

Unsigned archive evidence can verify packaging but cannot replace distribution
signing, App Store Connect processing, or physical-device TestFlight acceptance.
