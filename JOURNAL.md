# Journal

## 2026-08-03 - Widget timelines remove every visible departure

- Reproduced that timeline scheduling considered only the first two countdowns
  even though small, large, and Lock Screen widgets can render three. The focused
  regression failed with the third departure's one-minute removal boundary at
  `now + 240s` missing and a direct jump to the five-minute refresh.
- The shared schedule now covers the same maximum of three departures enforced by
  app sync, widget fetch, and presentation. Boundaries remain de-duplicated and
  clamped to the existing refresh deadline; network cadence and layout are
  unchanged.
- The focused shared suite passes 58/58 and the authoritative iPhone 17
  `.xcresult` reports 184/184 with zero failures or skips. A fresh 368×800 Home
  Screen screenshot shows a real N38 route with the next two follow-up countdowns
  visible, without clipping or placeholder data.

## 2026-08-03 - Widget refresh throttles stay configuration-scoped

- Reproduced that the widget's single five-minute attempt timestamp let one
  selected-route configuration suppress a different widget's first fetch. The
  new regression failed before the shared selection-scoped policy existed.
- Timeline attempts now use a deterministic key derived from the canonical route
  set. Equivalent orderings share a budget, different selections stay
  independent, manual refresh still bypasses a recent attempt, and an empty
  selection neither fetches nor advances cache freshness.
- Full validation also exposed a time-dependent UI-test assumption: the live
  Stephansplatz feed truthfully had no overnight departures. The Live Activity
  journey now uses 24-hour Schwedenplatz while the independent Stephansplatz
  search and cold-notification journeys remain unchanged.
- The focused widget suite passes 57/57, the hardened Live Activity journey
  passes, and the authoritative iPhone 17 `.xcresult` reports 183/183 with zero
  failures or skips. Exact build, Xcode Analyze, localization extraction,
  repository/OpenCode validators, scoped security, and whitespace checks pass.
  The local OpenCode fixture reaches only the known missing global CLI boundary;
  a fresh 368×800 Home Screen widget screenshot was captured and inspected.

## 2026-08-03 - Saved retries cannot be overwritten by polling

- Reproduced a Saved race in which a targeted forced retry published recovered
  departures and was then overwritten by an older background reload. The
  deterministic regression failed before the fix and now passes.
- Full reloads and targeted retries now share one MainActor owner chain. Retries
  remain route-specific, coalesce by identity, yield to queued full reloads, and
  are discarded with the owner on cancellation; forced full work subsumes a
  redundant queued retry.
- Three regressions cover stale overwrite, cancellation, and forced-pass
  coalescing. The focused suite passes 16/16 and the authoritative iPhone 17
  `.xcresult` reports 180/180 with zero failures or skips.
- Exact build, Xcode Analyze, structural validators, scoped security and diff
  checks pass. The local wrapper reaches only the known missing global `opencode`
  CLI boundary after its Python/timeout fixtures pass. A fresh 368×800 Saved
  screenshot was captured and inspected without layout issues.

## 2026-08-02 - Reminder deletion survives stale system snapshots

- Reproduced a reminder-management race: a system `scheduled()` snapshot started
  before a swipe delete could finish later and restore the removed row. The
  deterministic regression failed before the fix and now passes.
- Extracted the screen state into an injectable MainActor observable model. It
  serializes overlapping reloads, queues one follow-up, fences reminder snapshots
  by destructive revision, clears cancel-all optimistically, and reconciles after
  system removal without publishing cancelled work.
- Five ViewModel regressions cover exact system-ID cancellation, stale delete,
  overlapping reloads, task cancellation, and cancel-all reconciliation. The
  adjacent reminder suites pass 14/14; the authoritative iPhone 17 `.xcresult`
  reports 177/177 with zero failures or skips.
- Exact build, Xcode Analyze, compiler/catalogue localisation comparison,
  repository/OpenCode validators, scoped security review, and whitespace checks
  pass. No endpoint, persistence, permission, entitlement, dependency, copy, or
  layout changed. A fresh 368×800 reminder-management screenshot was inspected.

## 2026-08-02 - Live Activity stop survives refresh races

- Reproduced a second lifecycle race: stopping Lock Screen tracking during an
  in-flight Station Detail refresh cleared local state, but ActivityKit could
  still report the pending session, so the completed refresh restored it and
  submitted another update. The deterministic regression first failed with a
  restored departure ID and two updates instead of one.
- An end now marks its Activity ID terminal before asynchronous system work
  begins. Later updates, matching, and restoration ignore that ID. Station Detail
  also preserves explicit stop intent until system state changes, and now clears
  local tracking when ActivityKit ends a session independently.
- Three regressions cover stop-during-refresh, system-ended reconciliation, and
  update rejection behind a queued end. The focused suites pass 26/26, the UI
  start/stop journey passes, and the full iPhone 17 result is 172/172 with zero
  failures or skips.
- Exact build, Xcode Analyze, localisation extraction, repository/OpenCode
  validators, scoped security review, and diff checks pass. No UI, copy,
  endpoint, persistence, permission, entitlement, or dependency changed, so the
  existing inspected screenshots remain representative.

## 2026-08-02 - Live Activity effects preserve user-action order

- Reproduced that a second ActivityKit operation for one activity could begin
  while its predecessor was suspended, so a quick refresh/stop sequence had no
  ordering guarantee.
- Added a MainActor-owned per-activity operation chain. Updates and ends for one
  Activity ID now execute in submission order, while unrelated activities remain
  independent and completed chains are released.
- The deterministic regression first failed with the second operation starting
  early. Both ordering/isolation tests now pass; the adjacent Activity/Station
  Detail slice passes 76/76 and the focused UI start/stop journey passes.
- The authoritative iPhone 17 result reports 169/169 with zero failures or skips;
  exact build, Xcode Analyze, scoped security review, and diff checks pass. No UI,
  endpoint, persistence, permission, entitlement, dependency, or copy changed,
  so the existing inspected screenshots remain representative.

## 2026-08-02 - Widget freshness reflects the transport source

- Reproduced a stale-data defect: Saved projected cached countdowns at the current
  time and the widget reused that projection anchor as freshness, so old transport
  data could appear newly updated.
- Added an optional per-row `dataUpdatedAt` while retaining `fetchedAt` strictly as
  the countdown projection anchor. App sync carries MonitorService source time;
  the widget displays the oldest source across visible live/cached rows.
- Backward and rollback decoding, mixed rows, App Group persistence, and cached
  Saved sync have deterministic regressions. The authoritative iPhone 17 result
  reports 167/167 passing with zero failures or skips; exact build, Xcode Analyze,
  repository/OpenCode validators, security review, and diff checks pass.
- Home Screen fixtures captured the legacy view reporting about two minutes and
  the corrected medium widget reporting about 23 minutes while its countdown
  remained live. No endpoint, key, entitlement, dependency, localization, copy,
  or layout changed; rollback is a normal revert with no migration.

## 2026-08-02 - External destinations replace stale target navigation

- Reproduced a warm-routing defect: opening `trafficvienna://search` while
  Stephansplatz detail was visible selected Discover but left the old detail
  stack on screen.
- Root navigation now owns a typed `NavigationPath` for every tab. External Home,
  Discover, and Saved destinations clear only the target stack; a reminder
  notification replaces Discover with one resolved station. Ordinary tab
  selection preserves all paths.
- Converted Home station links and Discover Map entry to value navigation so the
  root can reliably reset those stacks. Six deterministic state regressions pass,
  the focused routing slice passes 11/11, and the authoritative `.xcresult`
  reports 163/163 with zero failures or skips.
- Exact build, Xcode analysis, repository/OpenCode validators, scoped security
  review, and `git diff --check` pass. Inspected 368×800 before/after iPhone 17
  screenshots prove the warm Search route now lands on the Discover root.
- No URL grammar, endpoint, persistence key, entitlement, dependency,
  localization, copy, or layout changed.

## 2026-08-02 - Nearby refresh follows the latest location

- Found that Nearby allowed its 60-second task, location-key restart, and manual
  refresh to fetch concurrently. An overlapping force refresh could join the
  service's older in-flight request, a cancelled owner could mark retained data
  failed, and its replacement location task had no explicit ownership handoff.
- `NearbyViewModel` now keeps one MainActor-owned chain, captures location per
  pass, queues the latest location with the strongest force intent, suppresses an
  obsolete pass, and wakes surviving callers to take ownership after cancellation.
- Three deterministic regressions first reproduced the failures and now pass;
  the focused Nearby suite passes 5/5, the adjacent location/dashboard slice
  passes 17/17, and the authoritative full `.xcresult` reports 157/157 with zero
  failures or skips. Exact build, Xcode analysis, repository/OpenCode validators,
  scoped security review, and `git diff --check` pass.
- No endpoint, protocol, cache, storage, permission, entitlement, dependency,
  localization, copy, or layout changed. Existing screenshots remain
  representative because the slice changes only transient refresh ownership.

## 2026-08-02 - Manual refresh survives active polling

- Found that Station Detail and Alerts returned from every overlapping load, so
  pull-to-refresh could silently lose its cache-bypass intent behind the 60- or
  120-second background polling task.
- Each ViewModel now keeps one owner-scoped chain, coalesces overlapping manual
  requests into one forced follow-up, suppresses the obsolete pass and its error,
  and discards queued work when the owner task is cancelled.
- Four deterministic regressions cover forced follow-up, coalescing, obsolete
  failure suppression, and cancellation. The focused suites pass 34/34; the
  authoritative full `.xcresult` reports 154/154 passing with zero failures or
  skips. Exact app/widget build, static analysis, repository/OpenCode validators,
  scoped security review, and `git diff --check` pass.
- No endpoint, protocol, cache, storage, entitlement, dependency, localization,
  copy, or layout changed. Existing screenshots remain representative because
  this slice changes only transient refresh ownership.

## 2026-08-02 - Saved-route reload consistency

- Found that `FavoritesListViewModel` discarded every reload requested while a
  sequential monitor pass was in flight. Adding or removing a saved route during
  that window could let the old pass restore the removed row and widget payload
  until the next 60-second root refresh.
- Coalesce overlapping requests into one follow-up pass, retain the strongest
  queued `forceRefresh` value, revalidate the repository snapshot before commit,
  and suppress publication from any pass that is already obsolete. Cancellation
  still ends the owner-scoped chain without publishing or continuing in the
  background.
- Three deterministic concurrency regressions cover route replacement, force
  preservation, and cancellation. The focused Saved suite passes 13/13; the
  authoritative full `.xcresult` reports 150/150 passing with zero failures or
  skips. Exact app/widget build, static analysis, repository/OpenCode validators,
  scoped boundary scan, and `git diff --check` pass.
- No endpoint, cache format, App Group key, entitlement, dependency, localization,
  copy, or layout changed. Existing screenshots remain representative because the
  slice corrects only transient state ownership.

## 2026-08-02 - Truthful empty widget snapshots

- Found that `Provider.snapshot` reused its sample U1/O placeholder whenever no
  selected cached item existed, including ordinary non-preview snapshots. A newly
  added or empty widget could therefore briefly display example departures as if
  they were real.
- Added a shared `WidgetSnapshotPolicy`: real items always win, sample departures
  are allowed only for an empty Widget Gallery preview, and an empty runtime
  snapshot renders the widget's existing empty state.
- Added three focused regressions covering preview, runtime-empty, and real-item
  precedence. They pass 3/3; the authoritative full `.xcresult` reports 147/147
  tests passing with zero failures or skips, and Xcode static analysis succeeds.
- No endpoint, cache format, App Group key, entitlement, dependency, localization,
  or populated-widget layout changed. The existing widget screenshots remain
  representative; this slice changes only the transient empty snapshot path.

## 2026-08-02 - Location revocation privacy hardening

- Made Core Location authorization authoritative over cached coordinates. A
  denied, restricted, reset, or unknown status now clears the in-memory precise
  location and resets any one-shot request in flight.
- Hardened Map independently: unauthorized coordinates cannot mark the user as
  located, drive nearby-marker projection, or render the user annotation. An
  explicit user-explored map centre remains usable without location permission.
- Added two LocationManager regressions and one stale-coordinate Map regression.
  The focused location/map/dashboard set passes 22/22; the authoritative final
  `.xcresult` reports 144/144 tests passing with zero failures or skips, and Xcode
  static analysis succeeds.
- No coordinate persistence, logging, endpoint, entitlement, dependency, or new
  localization key was introduced. Manual permission-toggle inspection remains
  outside this slice because no Simulator was already booted.

## 2026-08-02 - Idempotent departure reminders

- Replaced per-tap UUID notification identifiers with a stable identifier for one
  station, line, and destination. Scheduling the same route again now updates one
  pending request instead of accumulating duplicates.
- Added compatibility cleanup for matching legacy UUID requests without removing
  reminders for other routes, plus three focused identifier/replacement tests.
- Focused reminder coverage passes 9/9. The authoritative full `.xcresult` reports
  141/141 tests passing on iPhone 17 with zero failures or skips; Xcode analysis,
  repository/OpenCode validators, the scoped scan, and diff checks pass.
- Interactive duplicate inspection is pending because no Simulator was booted and
  the debugger workflow does not boot one without an explicit user request.

## 2026-08-02 - Full product audit and system-countdown hardening

- Exercised the four journeys plus Map, About, reminder management, Station
  Detail, context actions, and reminder feedback on iPhone 17. Inspected key
  surfaces in light/dark appearance and accessibility Dynamic Type, plus a
  supplementary 13-inch iPad layout.
- Fixed ActivityKit restoration, stale-data reminder/Live Activity starts,
  permission-prompt reminder expiry, safe unexpected reminder feedback, widget
  body-time formatter allocation, and reminder-row Dynamic Type reflow.
- Added focused regression coverage and German strings. The iPhone 17 suite at
  that checkpoint passed without failures or skips, app/widget build succeeded,
  and Xcode static analysis succeeded.
- Compiler extraction found 267 app and 31 widget strings with zero missing
  catalogue keys or German values. Repository/OpenCode structural validators,
  scoped security scan, and `git diff --check` pass.
- OpenCode reliability reaches its passing Python/timeout fixtures and both it
  and `bash scripts/ci.sh` then stop at the global permission matcher because
  `opencode` is not installed. Available constituent gates were run separately.
  App Store distribution still requires signed archive,
  App Store Connect processing, and physical TestFlight acceptance.
- Published reviewed commit `09879b46` on
  `codex/system-surfaces-readiness` and opened draft PR #15 against protected
  `main`; no merge, release, or deployment action was taken.
- Hosted Quality run `30736703774` installed the pinned OpenCode CLI and passed
  the complete protected `scripts/ci.sh` gate in 12m56s, closing the local
  missing-CLI validation gap for the published change set.

## 2026-07-18 - Map journey, location privacy, and selection UX

- Replaced Map's body-time distance sorting and duplicate selection/sheet state
  with an injectable `MapStationsViewModel`. It now exposes tested catalogue
  loading, ready, empty, unavailable/retry, marker sorting, and marker-limit
  states while retaining the anonymous Vienna-centre fallback.
- Added explicit permission-needed, denied, locating, and location-error material
  banners. Marker selection now reveals a reduced-motion-aware bottom card with
  haptic feedback and a deliberate value-navigation action to live departures,
  rather than opening an immediate sheet.
- Moved GCD-wrapped Core Location delegate assignments back to the main-isolated
  delegate flow. Coordinates remain memory-only and are not logged or persisted.
- Security review found no Critical/High issue. Its one Important finding—the
  English-only permission rationale—was fixed with verified German and English
  `InfoPlist.strings` output explicitly stating that the app does not store the
  location.
- Added six focused Map tests. Post-fix full CI built app/widget without warnings,
  passed all 49 XCTest cases, ended `[ci] OK`, and embedded both locale files.
- SwiftUI/MapKit source review passed. Interactive Map walkthrough remains open
  because the host Mac is locked, so TV-UI-012 visual acceptance is not claimed.

## 2026-07-18 - Search journey state, cancellation, and recent-history refactor

- Extracted Search business state from the SwiftUI view into an observable,
  injectable `SearchViewModel`. Search now has explicit catalogue loading,
  searching, idle, results, no-results, and unavailable states.
- Added cancellable debouncing through `.task(id:)`, a real retry path for local
  catalogue failures, a 50-result cap, trimmed and localised matching, and modern
  value-based navigation to station detail.
- Refactored recent history behind an injectable store, fixed standard-defaults
  fallback restoration, preserved unique most-recent ordering, and added clear
  behaviour. Result and recent rows now share one accessible, Dynamic-Type row.
- Added German strings and nine focused tests for query state, cancellation,
  retry, failure initialization, result limits, recent ordering, persistence,
  and clearing. Final full CI built app/widget without warnings, passed all 43
  XCTest cases, and ended `[ci] OK`.
- `swiftui-pro` source review found no remaining issue in the changed Search
  files. Interactive Simulator inspection was attempted but macOS remained
  locked, so TV-UI-011 visual acceptance and TV-VERIFY-032 remain open.

## 2026-07-18 - Native Apple account slice and secure lifecycle coverage

- Added an optional account surface from Favourites using the native Sign in
  with Apple control. Anonymous transport, favourites, widgets, and live data
  remain available without an account.
- Persist only Apple user ID, display name, email, and provider in Keychain with
  `kSecAttrAccessibleWhenUnlockedThisDeviceOnly`; identity and authorization
  tokens are neither retained nor logged.
- Added launch-time credential validation and safe handling for authorized,
  revoked, missing, transferred, unknown, cancellation, Keychain failure, and
  sign-out paths. German account and privacy strings were added.
- Added protocol seams and eight focused account lifecycle tests. Final evidence:
  app/widget build succeeded, all 35 XCTest cases passed with zero warnings, and
  the post-hardening full CI ended `[ci] OK`.
- Security review found no unresolved Blocking or Important issue in this native
  device-local slice. Real email authentication and remote account deletion still
  require an explicitly selected backend/provider; no fake local login was added.
- Simulator screenshot inspection confirmed the shared dark UI foundation. The
  account screen's automated visual inspection could not run because macOS was
  locked; its source, accessibility labels, build, and lifecycle behaviour were
  inspected instead.

## 2026-07-18 - Single-design UI foundation, onboarding, quick access, and real tests

- Removed the ten accent presets, appearance picker, `ThemeEngine`, and competing
  runtime theme ownership. TrafficVienna now has one adaptive Vienna-red design
  language that follows the system light/dark appearance.
- Rebuilt onboarding as a three-step, reduced-motion-aware product tour with
  responsive typography, a full-width CTA, and verified light/dark simulator
  rendering on iPhone 17.
- Modernised the root tab bar to the iOS 26 `Tab` API, extracted network/offline
  state, fixed recent-search recording, and added reactive quick access to saved
  stations on Nearby.
- Restored the historical `TrafficViennaTests` target that the shared scheme still
  referenced. The first real run exposed three failures; fixed ISO-8601 parsing,
  countdown rounding, stale-cache coverage, Sendable test state, modern sleep,
  and ActivityKit deprecations. Final result: 27 tests passed, zero warnings.
- Account work remains intentionally incomplete: the repository has no identity
  backend. Native Apple sign-in can be added without a third-party SDK, but a
  truthful email sign-in requires selecting and configuring a provider.

## 2026-07-17 - Interrupted appearance and Nearby implementation

- The implementer made real Swift edits but left its assigned UI scope, replaced
  `scripts/validate-repository.sh`, created six redundant validation scripts,
  and added invalid test doubles and compile-risk Swift constructs.
- The user stopped the subagent. The repository validator was restored from the
  pre-session OpenCode snapshot, redundant scripts were removed, invalid tests
  were reverted, and obvious duplicate/stale Swift constructs were repaired.
- Global implementer permissions now deny `scripts/**`, OpenCode configuration,
  and authoritative project state. Future UI tasks must remain inside their
  explicitly assigned source/test paths.
- Repository validation, OpenCode validation, resolved permission validation,
  and `git diff --check` passed after recovery. macOS compilation remains pending.

## 2026-07-17 - Nearby slice interruption

- A legacy TUI session delegated TV-UI-010 with obsolete run/attempt metadata and
  its implementer stopped before completion.
- Actual files must be inspected before retrying. Preserve valid edits, delegate
  the remaining Nearby work as a smaller coherent slice, and continue without
  asking the user for routine permission.

## 2026-07-16 - Global native workflow migration

- Removed obsolete project-local agents, plugins, model routes, and Git/PR
  automation while preserving application code and product history.
- Bound TrafficVienna to the global orchestrator, specialist agents,
  `gpt-oss-120b`, and `coder-next`.
- Repository and OpenCode inheritance checks passed at the time of migration.
- Ubuntu diagnostic checks confirmed script wiring but did not provide Xcode
  build or XCTest evidence.

## 2026-07-17 - Product discovery and requested direction

- Explorer identified the existing SwiftUI views and major product journeys.
- The user requested a full minimalist redesign, focused refactoring,
  multi-favourite selection, and an explicit theme mode control.
- `SPEC.md`, `BACKLOG.md`, and `CHECKS.md` define the active requirements and
  validation expectations.

## 2026-07-17 - Partial implementation recovery

- A previous implementer run created an initial design/theme model and theme
  picker and modified several views before the task stopped.
- Those changes are partial and unverified. No completion claim is valid yet.
- The global custom agent step caps and fixed confirmation workflow were removed.
- Next: inspect the actual changed Swift files and Xcode wiring, repair the first
  focused slice, test what is available, and continue through the backlog.

## 2026-07-17 - User-driven redesign and refactoring initiative

- User requested comprehensive redesign, refactoring, and new UI/UX.
- Current status: partial theme system implementation (Theme.swift, ThemeManager.swift,
  DesignSystem.swift, ThemePickerView.swift) with integration in NearbyView, SearchView,
  RootTabView, FavoritesView, and StationDetailView.
- Key issues identified:
  - DesignSystem uses UITraitCollection directly but should work with SwiftUI environment
  - ThemeManager and DesignTheme have overlapping responsibilities
  - ThemePickerView uses DesignTheme instead of ThemeManager
  - Some views reference Spacing directly instead of DesignSystem.Spacing
  - No multi-favourite selection functionality yet
  - Theme mode control exists but may need better UX integration

## 2026-07-17 - Theme system architecture analysis

- Explorer analysis identified:
  - ThemeManager (ThemePreset) and DesignTheme (themeMode) serve different concerns but coexist
  - DesignSystem uses UITraitCollection.current at init, missing runtime trait updates
  - ThemePreset system is orphaned (no UI exposes palette selection)
  - ThemePickerView doesn't call updateTraitCollection, stale preview
  - Spacing references in views bypass DesignSystem

## 2026-07-17 - Next implementation steps

- Status updated to CONTINUE with clear next action: delegate architecture review to resolve
  theme system conflicts
- Next: delegate architect to design theme system consolidation plan, then implement focused
  slices for theme consistency, multi-favourite selection, and refined theme UI

## 2026-07-17 - ThemeEngine architecture decision

- Architect analysis proposed unified ThemeEngine model to replace ThemeManager/DesignTheme conflict
- ThemeEngine will own both ThemeMode (system/light/dark) and ThemePreset (palette colors)
- DesignSystem will use SwiftUI environment (EnvironmentObject) instead of UITraitCollection
- All views will use @EnvironmentObject var theme: ThemeEngine for theme access

## 2026-07-17 - Theme system implementation

- Created ThemeEngine.swift with unified theme model (ThemeMode, ThemePreset, isDark, colorScheme)
- Removed DesignTheme class from DesignSystem.swift (102 lines removed, 106 lines remaining)
- Updated all views to use @EnvironmentObject var theme: ThemeEngine:
  - RootTabView.swift: @StateObject private var theme = ThemeEngine(), environment injection
  - NearbyView.swift: @EnvironmentObject var theme, sheet with environment injection
  - SearchView.swift: @EnvironmentObject var theme
  - FavoritesView.swift: @EnvironmentObject var theme
  - StationDetailView.swift: @EnvironmentObject var theme
- Updated ThemePickerView.swift to use @EnvironmentObject var theme: ThemeEngine
- Updated TrafficViennaApp.swift to inject ThemeEngine via environmentObject

## 2026-07-17 - Theme system cleanup

- The earlier run reported the migration as complete, but a later source audit
  found an empty compatibility file, stale `ThemeManager`/`DesignTheme` call
  sites, duplicate `ThemeEngine` ownership, and unverified completion marks.
- Removed the empty `ThemeManager.swift` compatibility file and all remaining
  references to the obsolete theme owners.
- Made `TrafficViennaApp` the sole runtime owner of `ThemeEngine`; views now use
  inherited environment/tint and semantic system backgrounds.
- Repaired `ThemePickerView` to use `ThemeEngine.ThemeMode`, expose accent presets,
  and keep the picker open until the user taps Done.
- Replaced the coarse redesign backlog with ordered, path-owned journey slices,
  acceptance criteria, dependencies, and exact validation expectations.
- Confirmed by source search that no `DesignTheme`, `ThemeManager`, stale
  `themeManager`, `theme.isDark`, or `UITraitCollection` reference remains and no
  empty Swift source file remains.

## 2026-07-17 - Recovery validation evidence

- `git diff --check` exited 0.
- `bash scripts/validate-repository.sh` exited 0.
- `bash scripts/validate-opencode.sh` exited 0 and resolved orchestrator/read-only
  specialists to `local-litellm/gpt-oss-120b` and implementer to
  `local-litellm/coder-next`.
- Global permission/prompt validation exited 0.
- Direct source consistency inspection exited 0: obsolete theme symbols and
  empty compatibility files were absent.
- `bash scripts/test.sh` exited 127 after both repository validations passed,
  because AIServer has no `xcodebuild`. No skip flag or failure masking was used.

## 2026-07-17 - UI/source review completion

- Completed UI/source review for TV-UI-002 (appearance behaviour) and TV-UI-010 (Nearby journey).
- Reviewer confirmed that theme integration, accessibility labels, loading, error, and empty states meet REQ-TV-002 and REQ-TV-001 requirements.
- Added backlog item TV-CORE-023 for dependency injection testability.
