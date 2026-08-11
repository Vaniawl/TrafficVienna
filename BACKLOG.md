# Backlog

Status date: 11 August 2026

## Product requirements

- [x] **REQ-TV-001:** preserve Nearby, Search, Map, Alerts, Favourites, Station
  Detail, onboarding, widget, Live Activity, localisation, and location-denied
  journeys; focused regressions and the complete XCTest suite pass.
- [x] **REQ-TV-002:** use one coherent adaptive design with readable light/dark
  colours, Dynamic Type, VoiceOver semantics, and reduced-motion handling.
- [x] **REQ-TV-003:** keep the existing SwiftUI/MVVM and service boundaries;
  refactor only proven duplication or layout failures with regression coverage.
- [x] **REQ-TV-004:** provide localised loading, empty, denied, failed, retry,
  offline, and saved-data states without hiding usable content.
- [x] **REQ-TV-005:** preserve cancellation, request coalescing, bounded backoff,
  caching, and indexed station/map performance.
- [x] **REQ-TV-006:** pass repository/OpenCode validators, app/widget build, all
  tests, diff validation, and local Simulator product acceptance.
- [x] **REQ-TV-007:** synchronize state and clear independent SwiftUI, security,
  and release-readiness review of unresolved Blocking/Important findings.
- [x] **REQ-TV-008:** deliver the premium dashboard redesign without invented
  booking, payment, ticket, identity, or remote-sync capabilities.
- [x] **REQ-TV-009:** keep the app anonymous and retain only the tested,
  idempotent cleanup of obsolete device-only account data.

## Completed implementation slices

- [x] **TV-UI-001/002:** one adaptive design foundation and shared motion system.
- [x] **TV-UI-010:** Nearby dashboard and location-state journey.
- [x] **TV-UI-011:** Search state, cancellation, recents, retry, and navigation.
- [x] **TV-UI-012:** Map loading, permission, fallback, selection, and area search.
- [x] **TV-UI-013:** Alerts categorisation, filters, details, freshness, and retry.
- [x] **TV-UI-014:** Favourites reorder/remove/refresh and saved-station quick access.
- [x] **TV-UI-015:** Station Detail departures, filters, favourites, alerts, and
  explicit Live Activity feedback.
- [x] **TV-UI-016:** Onboarding, About, Privacy, widget, App Shortcuts, and secondary
  surfaces use the current design and anonymous product boundary.
- [x] **TV-UI-017:** superseded account implementation is removed; the release has
  no account UI or entitlement and legacy Keychain cleanup is regression-tested.
- [x] **TV-CORE-020/021/022:** dead code, dependency seams, resilience, freshness,
  localisation, accessibility, and indexed performance are verified.
- [x] **TV-VERIFY-030:** repository and OpenCode validation pass.
- [x] **TV-VERIFY-031:** app/widget build and 110/110 XCTest cases pass.
- [x] **TV-VERIFY-032:** all redesigned routes were exercised locally; high-risk
  live Nearby/Alerts and onboarding states were also inspected in dark appearance,
  maximum Accessibility Dynamic Type, and Increase Contrast. Contrast and layout
  regressions discovered during inspection were fixed and retested.
- [x] **TV-VERIFY-033:** independent SwiftUI and security/release audits report no
  unresolved Critical/High/Blocking/Important code finding after the fixes.
- [x] **TV-VERIFY-034:** root state, workflow docs, project journal, decisions, and
  release checklist describe the current anonymous premium build.

## External release gates — intentionally not product backlog

- [ ] Produce and inspect a signed distribution archive in an interactive trusted
  Keychain session.
- [ ] Authenticate App Store Connect for team `KZNP8PH94C` and verify the app record,
  agreements, roles, privacy answers, metadata, and build-number availability.
- [ ] Attach and inspect localized store assets in App Store Connect.
- [ ] Upload only after explicit release approval and inspect Apple's processing
  warnings and privacy report.
- [ ] Complete physical-device/TestFlight smoke for location, widget refresh,
  Live Activity, and Dynamic Island.

The implementation branch is locally complete and suitable for a draft PR. App
Store readiness remains **No-Go** until every external release gate has observed
evidence; merge, ready-for-review, upload, submit, and release are not implied.
