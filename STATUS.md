# Status

- Status: CONTINUE
- Workspace: `/Users/ivandovhosheia/Swift/TrafficVienna`
- Stack: native SwiftUI iOS application and widget extension.
- Current phase: unified design/onboarding, native Apple account, Search, Map,
  Alerts, Favourites, Station Detail, and secondary-surface implementation slices
  complete; continue visual inspection, remaining resilience work, and email
  account integration.
- Verified: app and widget build successfully on iPhone 17 simulator with zero
  warnings; the restored test target runs 78 passing XCTest cases.
- Verified CI: repository/OpenCode/reliability checks, build, tests, and diff
  validation completed with `[ci] OK`.
- Verified visually: the new onboarding renders correctly in system light and
  dark appearances and respects Reduce Motion in source.
- Verified security: native Apple profile data is minimised, device-only Keychain
  protected, never logged, and revoked/transferred credential states clear it.
- Verified Search: explicit state machine, cancellable debounce, retry, recent
  persistence, value navigation, and German strings pass focused tests and full
  CI. Interactive visual acceptance remains open because macOS is locked.
- Verified Map: bounded sorted markers, catalogue retry, Vienna fallback,
  permission/error states, selection navigation, ephemeral location handling,
  and localized permission rationale pass focused tests and build inspection.
  Interactive visual acceptance remains open because macOS is locked.
- Verified Alerts: the live feed is categorised and deduplicated, service alerts
  drive the badge, searchable line/type filters and details are explicit, and
  loading/empty/failure/refresh states pass focused tests. Security review found
  no unresolved Blocking or Important issue; interactive visual acceptance is open.
- Verified Favourites: saved stations and routes keep their existing repositories;
  reorder/remove, stable order, route failure/retry, force refresh, cancellation,
  and widget filtering pass focused tests. Interactive visual acceptance is open.
- Verified Station Detail: deterministic merged departures, filters, stale refresh,
  alert navigation, favourites, and Live Activity feedback pass focused tests;
  station visits no longer overwrite the favourites widget. Visual acceptance is open.
- Verified secondary surfaces: onboarding/About use shared adaptive tokens and
  Dynamic Type, favourite-route ordering is shared by app and widget, the widget
  shows decoded station names, and app/widget German catalogues are complete.
  Interactive acceptance is open because macOS remains locked.
- Verified network lifecycle slice: alert requests are coalesced, throttled,
  retried with shared backoff, and fall back to in-memory stale data; cancelled
  journey tasks cannot publish late responses. Focused regressions and full CI pass.
- Remaining work: select and configure an email identity provider, verify the
  physical-device provisioning capability, and complete remaining journey and
  accessibility inspection.
- Next action: add explicit cache-freshness provenance and deterministic timing
  coverage while visual inspection waits for an unlocked host; email still needs
  a real provider choice.
