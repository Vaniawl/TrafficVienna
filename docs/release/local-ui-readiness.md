# Local UI readiness

Status date: 23 August 2026

Verdict: **Go** for the approved local iOS Simulator UI/UX scope.

This verdict does not cover TestFlight, App Store Connect, distribution signing,
upload, or physical-device system surfaces. Those gates were explicitly excluded
from this acceptance pass and remain tracked in `app-store-readiness.md`.

## Verified matrix

| Gate | Result | Evidence |
| --- | --- | --- |
| Standard repository validation | Pass | 119/119 standard tests, zero failures and zero skips; repository/OpenCode and negative scheme-wiring validators pass. |
| Standard iPhone UI acceptance | Pass | iPhone 17 / iOS 26.5: onboarding, primary routes, search, station detail, and full Xcode accessibility audits; 4/4 tests. |
| Maximum iPhone accessibility layout | Pass | iPhone 17 / iOS 26.5: dark appearance, maximum Accessibility Dynamic Type, Increase Contrast, and Reduce Motion; 1/1 test. |
| Maximum iPad accessibility layout | Pass | iPad Pro 13-inch (M5) / iOS 26.5 with the same accessibility configuration; 1/1 test. |
| Release compilation | Pass | Unsigned Release build for generic iOS Simulator completed successfully. |
| Store screenshots | Pass | Ten visually inspected `en-US`/`de-AT` JPEGs, each 1320×2868 and without alpha. |
| Repository hygiene | Pass | Shell syntax, shared-scheme XML, release plist, executable permissions, and `git diff --check` passed. |

The complete Simulator matrix is reproducible with:

```sh
bash scripts/run-local-ui-acceptance.sh
```

Set `TRAFFICVIENNA_ACCEPTANCE_OUTPUT` to keep result bundles at a chosen timestamped
path; otherwise the runner creates `/tmp/TrafficViennaLocalAcceptance-<timestamp>/`.
It creates isolated devices, uses exact UUID destinations, and deletes those
devices on exit.

## Closed findings

- Strengthened hero, semantic text, status, and transport-line badge contrast.
- Made Alerts filters, departure rows, station details, empty states, favourites,
  and freshness/status surfaces scale cleanly at maximum Accessibility Dynamic
  Type.
- Kept required app-owned controls at least 44×44 points and gave station actions
  stable accessibility labels and identifiers.
- Corrected widget line-badge contrast, expanded the refresh target, removed
  duplicate StationCard VoiceOver containers, and hid placeholder rows.
- Made the debug-only UI-test reset write the onboarding state explicitly, so
  reused CI simulators cannot leak a previously completed onboarding journey.
- Replaced system empty-state layouts that did not scale reliably with explicit,
  scroll-safe SwiftUI layouts.
- Regenerated and visually reviewed every localized release screenshot from the
  final premium UI.
- Made screenshot publication staged and all-or-nothing on an isolated Simulator.

## Audit exceptions

The accessibility audit still reports a small set of iOS 26.5 framework findings.
Exceptions are label/type/region-specific and their callbacks remain attached to
the result bundle. They cover the stock searchable text field, MapKit attribution,
iOS floating-tab-bar overlap, SwiftUI section-header classification, and three
contrast samples whose exported crops and numeric colour tests prove compliant.
All other resolvable audit findings fail the suite.

## Remaining scope

No unresolved UI/UX or accessibility blocker is known inside the approved local
Simulator scope. Physical-device, TestFlight, App Store Connect, signing, upload,
and Apple processing remain outside this verdict; they are not evidence of a local
UI defect and were not performed.
