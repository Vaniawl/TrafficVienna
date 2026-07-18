# Status

- Status: CONTINUE
- Workspace: `/Users/ivandovhosheia/Swift/TrafficVienna`
- Stack: native SwiftUI iOS application and widget extension.
- Current phase: unified design/onboarding, native Apple account, Search, Map,
  Alerts, Favourites, Station Detail, and secondary-surface implementation slices
  complete; continue visual inspection, remaining resilience work, and email
  account integration.
- Verified: app and widget build successfully on iPhone 17 simulator with zero
  warnings; the restored test target runs 86 passing XCTest cases.
- Verified CI: repository/OpenCode/reliability checks, build, tests, and diff
  validation completed with `[ci] OK`.
- Verified visually: the new onboarding renders correctly in system light and
  dark appearances and respects Reduce Motion in source.
- Verified security: native Apple profile data is minimised, device-only Keychain
  protected, never logged, and revoked/transferred credential states clear it.
  Runtime Apple revocation notifications now clear the session immediately.
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
- Verified network lifecycle: alert requests are coalesced, throttled, retried
  with bounded shared backoff, and fall back to in-memory stale data; cancelled
  journey tasks cannot publish late responses. Freshness snapshots preserve the
  real successful-update time and label saved data in Station Detail, Alerts,
  Nearby, and Favourites. Deterministic timing regressions and full CI pass.
- Verified localisation source audit: app and widget compiler extraction has no
  missing catalogue key or German value; new hero symbols scale with Dynamic Type,
  distance speech is locale-aware, and saved-data status is not color-only.
  Interactive accessibility-size and VoiceOver acceptance remains open while the
  macOS host is locked.
- Verified dependency injection: every journey model now accepts narrow test
  boundaries; Nearby uses modern observable state and its station/location/monitor
  behaviour passes focused mocks without persisting or logging coordinates.
- Verified refactoring audit: repository-wide references proved the legacy stop-ID
  monitor request unreachable, so it was removed from production and test protocol
  conformers; active DIVA/traffic-info behaviour still passes full CI.
- Verified motion source audit: one shared motion system now coordinates onboarding,
  screen-state, map-card, offline, shimmer, live-pulse, and countdown transitions;
  Reduce Motion disables movement, scale, pulse, shimmer, and numeric rolling.
  Interactive timing acceptance remains open while the macOS host is locked.
- Remaining work: select and configure an email identity provider; enable Sign in
  with Apple for `wellbe.TrafficVienna` and regenerate its provisioning profile;
  complete remaining journey and accessibility inspection.
- Next action: run the cross-journey completion/accessibility audit while visual
  inspection waits for an unlocked host; email still needs a real provider choice.
