# Journal

## 2026-08-03 - Empty Station Detail snapshots remain truthful

- Reproduced two Station Detail state defects with regression-first coverage. A
  successful response containing no departures was treated like no successful
  snapshot, so a later refresh failure replaced it with an initial error. A
  response containing traffic alerts but no departures entered the departure
  empty state and hid those alerts. The focused suite failed 29/31 before the fix
  on the exact expected state mismatches.
- `StationDetailViewModel` now uses `lastUpdated` as the existing successful
  snapshot identity and enters the loaded list whenever traffic alerts exist.
  Refresh failure retains either a loaded or empty successful snapshot, marks it
  stale, and keeps the refresh error available. This stays inside the existing
  SwiftUI/MVVM, cache, polling, and public protocol boundaries; no migration or
  ADR is required.
- Station Detail now distinguishes current empty data from qualified saved-empty
  data, exposes retry in both cases, and uses complete German copy. An alert-only
  list presents the truthful no-departures message while retaining the service
  alert section instead of suggesting that a transport filter is hiding results.
- The complete focused Station Detail suite passes 31/31. The exact iPhone 17
  build and 217/217 tests (212 model/service plus 5 UI) pass with no failures or
  skips, and Xcode Analyze is clean. Compiler extraction reports 243 app and 29
  widget source keys, all covered by the 272/35 catalogues with no missing or
  empty German values; repository/OpenCode validators, shell syntax, scoped
  boundary review, JSON validation, and `git diff --check` pass.
- Live iPhone 17 acceptance reopened Stephansplatz and verified both service alerts
  remain visible above its live departures with no clipping. The inspected
  368×800 capture is stored at
  `docs/release/screenshots/audit/station-detail-after-empty-state-fix.jpg`;
  deterministic tests provide saved-empty and alert-only state evidence. Local CI
  reaches its passing Python/timeout fixtures and stops only at the known missing
  global `opencode` CLI, so protected exact-head CI remains the publication
  authority.

## 2026-08-03 - Empty Alerts snapshots remain truthful

- Reproduced an Alerts state-identity defect: a successful empty feed was
  indistinguishable from never having loaded, so a later forced refresh replaced
  the known snapshot with loading and then an initial failure. When retained as
  saved data, the view also hid that provenance behind an unconditional live
  `All clear` claim.
- `DisruptionsViewModel` now records whether any snapshot has succeeded. Later
  failures retain an empty loaded snapshot and publish a refresh error; the empty
  view distinguishes current all-clear data from qualified saved-empty data,
  includes explicit retry, and has complete German copy.
- The regression failed before the fix across loading, failure, saved-data, and
  refresh-error assertions. Both new empty-snapshot cases, all 17 disruptions
  model tests, and the exact 215/215 iPhone 17 suite then passed with no failures
  or skips. Exact build, Xcode Analyze, repository/OpenCode validators, shell
  syntax, 240/29 source-key localisation coverage against 270/35 catalogues,
  scoped boundary checks, and whitespace validation pass.
- Live iPhone 17 acceptance reopened Alerts, pulled to refresh, and retained both
  current U3 notices with an unclipped layout. The inspected 368×800 capture is
  stored at `docs/release/screenshots/audit/alerts-live-after-empty-state-fix.jpg`;
  deterministic tests provide the saved-empty state evidence. Local CI still
  stops only at the known missing global `opencode` CLI, so exact-head protected
  CI remains the publication authority.

## 2026-08-03 - App departures expire after the now grace

- Reproduced a truthfulness defect in the shared app projection: a parseable
  timestamp 61 seconds after departure still returned `0`, so stale services could
  remain `now`. Timestamp-free cached countdowns also ignored their source age and
  could remain featured or be re-synced to the widget as newly projected data.
- `DepartureClock` now returns an optional projection, prefers a valid real-time
  then planned timestamp, anchors fallback countdowns to
  `MonitorSnapshot.updatedAt`, preserves `now` for one minute, and expires the
  value afterward. Nearby, Station Detail, Saved, featured selection, and widget
  sync all exclude expired values; network cadence and persistence stay unchanged.
- The regression first failed with `XCTAssertNil failed: "0"`. Six focused
  timestamp/fallback/Saved/Station Detail cases then passed, followed by 208/208
  unit tests. Live iPhone 17 acceptance observed Wiener Linien delay U3 in real
  time, then verified the featured card and accessibility tree advance to U1 when
  U3 left the visible window; the unclipped 368×800 capture is stored at
  `docs/release/screenshots/audit/featured-departure-advanced.jpg`.
- The final exact iPhone 17 `.xcresult` reports 213/213 with zero failures or
  skips. Exact app/widget build, Xcode Analyze, repository/OpenCode validators,
  shell syntax, 238/29 source-key localisation coverage against 268/35 catalogues,
  scoped secret/endpoint/dependency review, and whitespace checks pass. Local CI
  reaches its passing Python/timeout fixtures and stops only at the known missing
  global `opencode` CLI; protected exact-head CI remains required.

## 2026-08-03 - Alerts drop unavailable transport filters

- Reproduced a hidden Alerts filter trap after a successful feed change: a
  selected category could disappear from the menu while remaining active and
  filtering every refreshed result out of the list. The regression first failed
  with the retained `metro` value.
- `DisruptionsViewModel` now clears only a selected category absent from the
  normalized successful snapshot. A still-available category and retained-data
  refresh failures preserve the user's selection. The visible summary also shows
  the active category, closing the runtime-discovered `All Vienna · Service`
  versus `All Vienna · Service · U-Bahn` mismatch without new copy or keys.
- Focused coverage passes 15/15. Live iPhone 17 acceptance selected U-Bahn on the
  current U3 construction alert and verified that the visible
  `For you · Service · U-Bahn` summary, count, and result persist after
  pull-to-refresh; the unclipped 368×800 screenshot is stored in release evidence.
- The authoritative iPhone 17 `.xcresult` reports 207/207 with zero failures or
  skips. Exact build, Xcode Analyze, repository/OpenCode validators, shell syntax,
  238/29 source-key localisation coverage against 268/35 catalogues, scoped
  boundary review, and whitespace checks pass. Local CI still stops only at the
  known missing global `opencode` CLI; protected exact-head CI remains required.

## 2026-08-03 - App sync keeps every widget-selectable route

- Reproduced a shared-cache coverage defect: after four available Saved routes
  loaded, app sync persisted only divas `[1, 2, 3]` instead of
  `[1, 2, 3, 4]`. A fourth route could therefore remain selectable in a separate
  widget configuration but lose cached departures whenever the app refreshed.
- Removed the app-level three-route truncation from the App Group projection.
  The widget still presents one or three routes according to family, each route
  still carries at most three departures, and unavailable Saved routes remain
  excluded. The payload schema, App Group key, endpoints, entitlements, and MVVM
  ownership are unchanged, so no migration or ADR is required.
- The focused regression failed before the fix with the exact three-versus-four
  mismatch and the complete Favorites List suite now passes 19/19. Live iPhone
  17 inspection created four available Saved routes plus one unavailable route;
  the decoded `widget_departure` payload contained all four available routes,
  each with at most three departures, while the Saved screen remained unclipped.
- The authoritative iPhone 17 `.xcresult` reports 205/205 with zero failures or
  skips. Exact build, Xcode Analyze, repository/OpenCode validators, shell syntax,
  238/29 source-key localisation coverage against 268/35 catalogues, scoped
  boundary review, and whitespace checks pass. Local CI still stops only at the
  known missing global `opencode` CLI; protected exact-head CI remains required.

## 2026-08-03 - Station Detail drops unavailable transport filters

- Reproduced a hidden filter trap after a successful refresh: if the selected
  transport category disappeared from the new response, its chip disappeared too
  while the retained selection filtered every departure out of the list.
- `StationDetailViewModel` now reconciles the selection with each successful
  departure snapshot. It clears only a category that is no longer present,
  preserves a still-valid category, and leaves the current selection untouched
  when a refresh fails and existing departures remain visible.
- The invalid-filter regression failed before the fix with the retained `bus`
  selection. The focused Station Detail suite now passes 28/28, including valid
  refresh and retained-data failure paths. Live iPhone 17 inspection selected the
  Bus chip at Stephansplatz and verified that it and four matching directions
  remain synchronized after pull-to-refresh, without clipping or stale empty rows.
- The authoritative iPhone 17 `.xcresult` reports 204/204 with zero failures or
  skips. Exact build, Xcode Analyze, repository/OpenCode validators, shell syntax,
  238/29 source-key localisation coverage against 268/35 catalogues, scoped
  boundary review, and whitespace checks pass. Local CI remains bounded only by
  the missing global `opencode` CLI; protected exact-head CI is still required.

## 2026-08-03 - Connected launches do not flash Offline

- A minimal `NWPathMonitor` reproduction and a matched iPhone 17 cold launch
  proved that `currentPath` begins as `unsatisfied` before its first satisfied
  callback. Home therefore flashed a false Offline banner at about 0.7 seconds
  and removed it by 1.1 seconds on a connected simulator.
- `NetworkMonitor` now keeps its neutral initial state until the first path
  callback; real satisfied/unsatisfied updates, the existing overlay, motion,
  MVVM ownership, endpoints, persistence, and security boundaries are unchanged.
  The focused regression failed before the fix and now passes.
- A symbolicated ETTrace launch capture measured about 1.14 seconds of active
  main-thread work; station catalogue decode/index construction used only about
  22.5 ms, so the considered asynchronous catalogue rewrite was rejected as
  unjustified complexity.
- The authoritative iPhone 17 `.xcresult` reports 202/202 with zero failures or
  skips. Exact build, Xcode Analyze, repository/OpenCode validators, shell syntax,
  238/29 source-key localisation coverage against 268/35 catalogues, scoped
  boundary review, and whitespace checks pass. Matched 1206×2622 screenshots show
  no Offline banner at 0.7 or 1.1 seconds after the fix. Local CI still stops only
  at the known missing global `opencode` CLI boundary.

## 2026-08-03 — Filtered screens avoid repeated render work

- A code-first SwiftUI performance audit found that Alerts recomputed its filtered
  feed three times per render pass, while Alerts transport categories and Station
  Detail categories/departure groups were each derived twice.
- `DisruptionsList` and `StationDeparturesList` now take one immutable snapshot of
  each derived collection at the start of `body`; `DisruptionFilterBar` receives
  the already-derived count and categories. No observable cache, persistence,
  endpoint, dependency, copy, or layout changed.
- Focused filter/detail coverage passes 39/39 and the authoritative iPhone 17
  `.xcresult` reports 201/201 with zero failures or skips. Exact build, Xcode
  Analyze, repository/OpenCode validators, 238/28 source-key localization coverage
  against 268/35 catalogues, scoped boundary review, and whitespace checks pass.
- Fresh 368×800 Simulator captures verify the Alerts count/empty state, the full
  Stephansplatz list, and its U-Bahn-filtered state without clipping or stale rows.
  Local CI still stops only at the known missing global `opencode` CLI boundary;
  protected exact-head CI remains the publication authority.

## 2026-08-03 — Live Activity becomes stale at departure

- Reproduced a suspended-app lifecycle defect: the Lock Screen countdown clamped
  to `0:00 to departure`, while ActivityKit content stayed fresh until the
  two-minute automatic end boundary.
- Live Activity content now becomes stale at the actual departure time and keeps
  the existing two-minute end grace. Lock Screen and Dynamic Island surfaces show
  a localized departed state; signed `T−`/`T+` offset rendering remains truthful
  if a system stale redraw is delayed.
- The lifecycle regression failed before the stale-date policy existed and now
  passes. With the app process stopped, paired iPhone 17 screenshots show
  `T−1 minute` before departure and `Departed` after it, both on one unclipped row.
- The authoritative `.xcresult` reports 201/201 with zero failures or skips.
  Exact build, Xcode Analyze, repository/OpenCode validators, shell syntax,
  238/29 source-key localisation coverage against 268/35 catalogues, scoped
  boundary review, and whitespace checks pass. Local CI still stops only at the
  known missing global `opencode` CLI; protected exact-head CI remains required.

## 2026-08-03 — Station card summaries remain readable at large text

- Reproduced the unbounded fixed route-badge row on compact Home cards; the
  existing five-line Stephansplatz screenshot was already near the width limit,
  and maximum Dynamic Type also squeezed station name and metadata into narrow
  columns.
- Added a deterministic unique-line summary: standard cards show four badges,
  accessibility sizes show two, and both preserve omitted information as a
  localized `+N` accessibility label. Accessibility headers now stack station
  identity above walking/freshness metadata without changing card navigation,
  departures, storage, endpoints, or MVVM ownership.
- The focused regression failed before the summary policy existed and now passes.
  Final iPhone 17 runtime inspection shows `1A 2A 3A U1 +1` at standard size and
  `1A 2A +3` with semantic `Additional lines: 3` at maximum Dynamic Type.
- The authoritative `.xcresult` reports 201/201 with zero failures or skips.
  Exact build, Xcode Analyze, repository/OpenCode validators, shell syntax,
  238/27 source-key localisation coverage against 268/32 catalogues, scoped
  boundary review, and whitespace checks pass. Local CI still stops only at the
  known missing global `opencode` CLI; protected exact-head CI remains required.

## 2026-08-03 — Widget configuration preserves selected route order

- Traced the multi-route AppEntity restoration path and reproduced that converting
  the ordered identifier input to a `Set` returned saved routes in local sort order.
  The focused regression failed with U1/U4 instead of the requested U4/U1 order.
- Added a shared pure resolution policy used by the widget query. It now traverses
  identifiers in order, omits unavailable routes, and leaves deterministic
  suggestion ordering, stable IDs, cache merging, storage, and fetch behavior intact.
- The focused resolution/order suite passes 4/4; the authoritative iPhone 17
  `.xcresult` reports 200/200 with zero failures or skips. Exact app/widget build,
  Xcode Analyze, repository/OpenCode validators, shell syntax, catalogue values,
  scoped security/dependency review, and whitespace checks pass.
- The local CI wrapper still reaches only the missing global `opencode` boundary
  after its Python/timeout fixtures pass. No layout, copy, color, or asset changed,
  so existing inspected widget screenshots remain pixel-representative; the
  published commit still requires its own protected Quality run.

## 2026-08-03 — Cancelled refreshes do not create forced successors

- Reproduced that a cancelled station or traffic-info force-refresh waiting
  behind regular work still started a serial network successor. Both deterministic
  regressions failed before the service fix.
- `MonitorService` now checks caller cancellation before creating tracked network
  work, including the recursive successor, and propagates `CancellationError`
  instead of converting it into stale-cache success. Live forced callers still
  receive exactly one coalesced successor.
- The focused old/new concurrency suite passes 4/4; the authoritative iPhone 17
  `.xcresult` reports 199/199 with zero failures or skips. Exact build, Xcode
  Analyze, repository/OpenCode validators, shell syntax, catalogue values,
  scoped security/dependency review, and whitespace checks pass.
- The local CI wrapper reaches only the known missing global `opencode` CLI
  boundary after its Python/timeout fixtures pass. No pixels or copy changed, so
  existing inspected screenshots remain representative; the published commit
  still requires its own protected Quality run.

## 2026-08-03 - Fresh `now` widget departures leave on time

- Reproduced that both the direct widget API path and app sync can store a fresh
  departure as `0`, while timeline scheduling ignored zero and left the rendered
  `now` value visible until the five-minute network refresh. The deterministic
  regression failed before the fix.
- Timeline scheduling now applies the existing one-minute removal grace to every
  nonnegative visible countdown, including a fresh zero, while negative input
  remains excluded. Projection, persistence, endpoint, layout, and copy are
  unchanged.
- The focused scheduling suite passes 4/4; the authoritative iPhone 17
  `.xcresult` reports 197/197 with zero failures or skips. Exact build, Xcode
  Analyze, repository/OpenCode validators, shell syntax, catalogue values,
  scoped boundary review, and whitespace checks pass.
- The local CI wrapper reaches only the known missing global `opencode` CLI
  boundary after its Python/timeout fixtures pass. No pixels changed, so the
  existing inspected widget screenshots remain representative; the published
  commit still requires its own protected Quality run.

## 2026-08-03 — Saved route removal is idempotent

- Reproduced that deleting a stale Saved route row called `toggle`, so a route
  already removed by another view was silently inserted back into persistence.
  The regression first failed by observing the route restored after deletion.
- Added an explicit idempotent route-removal operation to the existing favourites
  repository and used it for destructive Saved actions. Persistence format, App
  Group key, notification boundary, widget payload, and UI layout are unchanged.
- Focused Saved and Station Detail coverage passes 44/44; an isolated
  `UserDefaults` regression also proves repeated removal remains absent. The
  authoritative iPhone 17 `.xcresult` reports 196/196 with zero failures or skips;
  exact build, Xcode Analyze, repository/OpenCode validators, localisation
  catalogue checks, scoped boundary review, and whitespace checks pass.
- The local CI wrapper reaches only the known missing global `opencode` CLI
  boundary after its Python/timeout fixtures pass. No pixels or copy changed, so
  the existing inspected Saved screenshots remain representative; the published
  commit still requires its own protected Quality run.

## 2026-08-03 — Home location failures are retryable

- Reproduced that `CLError.locationUnknown` released the one-shot request but
  surfaced no error, leaving authorized Home users in an indefinite `Locating
  you...` state with no recovery action. The regression first failed on the
  missing error, and the projected dashboard state did not yet compile.
- Temporary location failures now expose a localized retry card and a new request
  clears the error. Retained coordinates and nearby departures remain useful
  during a later refresh failure instead of being replaced by the fallback.
- Focused coverage passes 14/14; the authoritative iPhone 17 `.xcresult` reports
  194/194 with zero failures or skips. Exact build, Xcode Analyze, and localization
  extraction pass with 237 app and 27 widget source keys fully covered by the
  committed 267/32-key English/German catalogues.
- Inspected iPhone 17 screenshots capture the retry state in light and dark mode
  and live Stephansplatz recovery. No endpoint, dependency, persistence,
  entitlement, or architecture boundary changed; protected CI remains required
  after publication.

## 2026-08-03 — Root audit state is a validated contract

- Found that the tracked root product/audit files were declared active by
  `PROJECT.md` but explicitly described as nonexistent by the OpenCode state
  contract. Structural validation therefore ignored the same `STATUS`, `BACKLOG`,
  and decision snapshots used for continued audit work; they had drifted to 189
  tests, an older CI head, and superseded Apple/OpenCode claims.
- Registered all nine root audit artifacts, added conditional broad-audit routing
  to `AGENTS.md`, and added matching structural and reliability assertions. The
  new validator first failed on the missing routing rule and now passes; narrow
  tasks remain free to load only relevant root artifacts.
- Synchronized active evidence to the authoritative 192/192 iPhone 17 result and
  protected app-code Quality run `30777324747` at `f08662c0`, documented the
  shared forced-refresh invariant, and marked the removed Apple profile plus the
  obsolete global-only OpenCode ownership as superseded.
- Repository/OpenCode validation, shell syntax, root-state existence, and
  whitespace checks pass. The reliability suite's expanded Python and timeout
  fixtures pass before the known local missing-`opencode` boundary. No app,
  widget, UI, copy, localization, endpoint, persistence, entitlement, dependency,
  or screenshot changed; the documentation/workflow commit still requires its
  own protected PR check after publication.

## 2026-08-03 — Forced refresh survives lower-intent in-flight work

- Reproduced the shared-service race for both station monitors and traffic info:
  a forced request behind a regular in-flight request made only one network call
  and returned the older response instead of a post-regular successor.
- `MonitorService` now tracks refresh intent and a generation per in-flight task.
  Regular work remains shareable, equivalent forced callers coalesce, and a
  forced caller behind regular work receives one serial successor even when the
  regular request fails. Snapshot caching completes inside the tracked task and
  generation-guarded cleanup cannot erase a newer successor.
- Three regressions cover station, traffic-info, concurrent forced callers,
  successor cache authority, and failed-normal recovery; each passed five repeated
  runs. The authoritative iPhone 17 `.xcresult` reports 192/192 with zero failures
  or skips; exact build, Xcode Analyze, repository/OpenCode validators, scoped
  security, shell syntax, and whitespace checks pass.
- The local CI wrapper reaches only the known missing global `opencode` CLI
  boundary after its Python/timeout fixtures pass. No UI, copy, endpoint,
  persistence, entitlement, or dependency changed, so the existing inspected
  screenshots remain representative.

## 2026-08-03 — Station Detail favourites follow repository truth

- Reproduced a cross-tab consistency defect: Station Detail cached favourite
  routes at initialization and inverted that stale set after a Saved-tab change,
  allowing its station or route control to disagree with persisted state.
- Station and route favourites now reload from their repositories after local
  toggles and the existing change notifications. Saved station rows also expose
  stable accessibility identifiers for the end-to-end regression.
- Three focused model regressions pass, the new cross-tab UI journey passes, and
  the authoritative iPhone 17 `.xcresult` reports 189/189 with zero failures or
  skips. Paired screenshots show Schwedenplatz filled before external removal and
  cleared after returning to the preserved Discover detail.

## 2026-08-03 — Cached widget departures leave `now` on time

- Reproduced that timeline scheduling discarded both boundaries when a cached
  departure time was already in the past, even if its one-minute removal boundary
  was still in the future. The regression first failed with a direct jump from
  `now` to the five-minute refresh.
- Departure and removal boundaries are now evaluated independently. The existing
  `now` presentation remains intact, but its row receives the pending removal
  entry without changing network cadence, payload, App Group keys, or layout.
- The focused shared suite passes 58/58 and the authoritative iPhone 17
  `.xcresult` reports 185/185 with zero failures or skips. Paired 368×800 Home
  Screen screenshots show cached N38 at `now` and removed 34 seconds later; a
  final screenshot confirms restoration of live N38 data.

## 2026-08-03 — Widget timelines remove every visible departure

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

## 2026-08-03 — Widget refresh throttles stay configuration-scoped

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

## 2026-08-03 — Saved retries cannot be overwritten by polling

- Reproduced a Saved race in which a targeted forced retry ran beside a background
  reload, published the recovered departure, and was then overwritten by the
  older polling response. The deterministic regression failed before the fix.
- Full reloads and targeted retries now share one MainActor owner chain. Route
  retries remain targeted, coalesce by route identity, yield to queued full reloads,
  and are dropped with the owner on cancellation; a forced full pass subsumes
  redundant queued retries.
- Three regressions cover stale overwrite, cancellation, and forced-pass
  coalescing. The focused Saved suite passes 16/16 and the authoritative iPhone 17
  `.xcresult` reports 180/180 with zero failures or skips.
- Exact build, Xcode Analyze, repository/OpenCode validators, scoped security and
  whitespace checks pass. The Python/timeout OpenCode reliability fixtures pass;
  the local wrapper stops only at the known missing global `opencode` CLI boundary.
  A fresh 368×800 Saved screenshot was captured and inspected without layout issues.

## 2026-08-02 — Reminder deletion survives stale system snapshots

- Reproduced a reminder-management race: a system `scheduled()` snapshot started
  before a swipe delete could finish later and restore the removed row. The
  deterministic regression failed before the fix and now passes.
- Added an injectable MainActor `DepartureRemindersViewModel` that serializes
  overlapping reloads, queues one follow-up, fences reminder snapshots by
  destructive revision, clears cancel-all optimistically, and reconciles after
  system removal without publishing cancelled work.
- Five regressions cover exact system-ID cancellation, stale delete, overlapping
  reloads, task cancellation, and cancel-all reconciliation. The adjacent reminder
  suites pass 14/14; the authoritative iPhone 17 `.xcresult` reports 177/177 with
  zero failures or skips.
- Exact build, Xcode Analyze, compiler/catalogue localisation comparison,
  repository/OpenCode validators, scoped security review, and whitespace checks
  pass. No endpoint, persistence, permission, entitlement, dependency, copy, or
  layout changed. A fresh 368×800 reminder-management screenshot was inspected.

## 2026-08-02 — Live Activity stop survives refresh races

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

## 2026-08-02 — Live Activity effects preserve user-action order

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

## 2026-08-02 — Widget freshness reflects the transport source

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

## 2026-08-02 — External destinations replace stale target navigation

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

## 2026-08-02 — Nearby refresh follows the latest location

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

## 2026-08-02 — Manual refresh survives active polling

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

## 2026-08-02 — Saved-route reload consistency

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

## 2026-08-02 — Truthful empty widget snapshots

- Found that the App Intent timeline provider returned sample U1/O departures for
  any empty snapshot, not only a Widget Gallery preview. A runtime widget with no
  real selected or cached items could therefore briefly present fabricated data.
- Added one shared preview/runtime policy used by the widget provider: real items
  take precedence, an empty Gallery preview may use examples, and an empty runtime
  snapshot uses the existing empty state.
- Three focused policy regressions pass 3/3. The authoritative full `.xcresult`
  reports 147/147 tests passing with zero failures or skips, and Xcode static
  analysis succeeds.
- No network, cache format, App Group key, entitlement, dependency, localization,
  or populated-widget layout changed; existing widget screenshots remain valid.

## 2026-08-02 — Location revocation privacy hardening

- Made location authorization authoritative over the cached in-memory coordinate:
  denied, restricted, reset, and unknown states now clear it and release any
  one-shot request in flight.
- Hardened the Map boundary so an unauthorized stale coordinate cannot report a
  located state, choose the marker-search centre, or render the user annotation;
  explicit map exploration continues to work without device location.
- Added two LocationManager regressions plus one stale-coordinate Map regression.
  The focused location/map/dashboard set passes 22/22; the authoritative final
  `.xcresult` reports 144/144 passing with zero failures or skips, and Xcode static
  analysis succeeds.
- No coordinate persistence, logging, endpoint, entitlement, dependency, or
  localization key changed. Manual permission-toggle inspection was not repeated
  because no Simulator was already booted.

## 2026-08-02 — Idempotent departure reminders

- Replaced per-tap UUID notification identifiers with a deterministic identifier
  scoped to station, line, and destination. Repeated scheduling now replaces one
  pending route reminder instead of creating duplicates.
- Added compatibility cleanup for matching legacy UUID reminders without touching
  other routes, and covered stable identity, route separation, and cleanup with
  three focused regressions.
- Focused reminder tests pass 9/9. The authoritative full `.xcresult` reports
  141/141 tests passing on iPhone 17 with zero failures or skips; Xcode static
  analysis, repository/OpenCode validators, scoped scan, and diff checks pass.
- Interactive duplicate inspection remains pending because no Simulator was
  booted and the debugger workflow does not boot one without explicit user input.

## 2026-08-02 — Full product audit and system-countdown hardening

- Audited architecture, SwiftUI performance, accessibility, localisation,
  privacy/security, system surfaces, tests, release evidence, and active
  documentation. No Blocking architecture or security finding remains.
- Restored Station Detail's matching ActivityKit identity across model
  recreation; stale departures can no longer start a new reminder or Live
  Activity, while an existing Activity can still be stopped.
- Revalidated reminder schedulability after notification permission returns,
  replaced unexpected system errors with safe localized feedback, moved
  relative-time rendering out of the widget body, and let reminder rows reflow
  at accessibility Dynamic Type sizes.
- Added focused regressions and German values. The iPhone 17 suite at that
  checkpoint passed without failures or skips, with successful app/widget build
  and successful Xcode static analysis.
- Simulator inspection covered Home, Discover, Map, Alerts, Saved, About,
  reminder management, Station Detail, context/failure feedback, light/dark,
  accessibility Dynamic Type, and a supplementary 13-inch iPad layout. Five
  settled iPad process samples measured 0.0% CPU.
- Compiler extraction reports 267 app and 31 widget keys with zero missing
  catalogue keys or German values. Repository/OpenCode structural validators,
  scoped security/new-endpoint scan, and `git diff --check` pass.
- The reliability script's Python/timeout fixtures pass, then it and the full CI
  wrapper exit 127 because their global `opencode` permission-matcher dependency
  is not installed. Available constituent gates were run separately. App Store
  submission remains gated by signed
  distribution, App Store Connect processing, and physical TestFlight evidence.
- Published reviewed commit `09879b46` on
  `codex/system-surfaces-readiness` and opened draft PR #15 against protected
  `main`. No merge, ready-for-review, release, or deployment action was taken.
- Hosted Quality run `30736703774` installed the pinned OpenCode CLI and passed
  the complete protected `scripts/ci.sh` gate in 12m56s, closing the local
  missing-CLI validation gap for the published change set.

## 2026-07-30 — Final visual, widget, and release-evidence pass

- Inspected every prepared English/German App Store screenshot and the six widget
  families. Reduced the default map projection from 36 markers at 120-metre
  spacing to 24 at 160 metres, then recaptured both localized Map screenshots at
  1320×2868. All ten JPEGs remain alpha-free and visually readable.
- Exercised real small, medium, and large Home Screen widgets in Simulator light
  mode, large in dark mode, a circular Lock Screen widget, and a Lock Screen Live
  Activity. Tightened freshness contrast/copy, added circular and inline previews,
  and verified the one-route adaptive layouts do not clip.
- Fixed departure countdowns lingering at `0:00` by adding bounded timeline
  entries at visible departure boundaries and one minute afterward, while
  retaining the five-minute network refresh budget. Added deterministic
  regression coverage for that schedule.
- The exact iPhone 17 build passes, all 133 XCTest cases pass with no failures or
  skips, both repository validators pass, and a fresh unsigned arm64 Release
  archive contains the app, widget, privacy manifests, version 1.0, and build 1.
  App Store submission remains No-Go only for the documented signing,
  App Store Connect, processed-build, and physical TestFlight evidence gates.

## 2026-07-30 — System-surface readiness and local departure reminders

- Added user-created local departure reminders with contextual notification
  permission, on-device scheduling, delivered/pending cleanup, an About management
  screen, cancellation, Settings recovery, English/German copy, and privacy/store
  documentation. No APNs entitlement, backend, remote push claim, account, or new
  network destination was introduced.
- Persisted the reminder's station ID and extended the typed root router so a
  notification opens the matching Station Detail in Discover during warm or cold
  launch. External navigation now dismisses an open About sheet instead of changing
  tabs invisibly underneath it.
- Made widgets configurable through a saved-route AppEntity collection with
  family-specific limits. Replaced minute-by-minute entries with system-rendered
  countdown dates and a five-minute refresh budget, preserved per-row freshness,
  and added adaptive one-route medium/large layouts.
- Added explicit Live Activity update, replacement, stop, launch cleanup, and
  automatic end lifecycle. UI coverage starts and stops a real Simulator activity;
  unit coverage verifies refresh behavior and the two-minute post-departure policy.
- Simulator acceptance observed the contextual notification prompt, scheduled
  reminder manager, delivered Lock Screen notification, adaptive medium widget,
  Edit Widget route surface, widget-to-Saved deep link, modal dismissal, and direct
  cold reminder routing. A final screenshot audit also replaced the ambiguous
  `Updated in 0 sec.` widget label with clamped minute-level freshness copy. The
  exact iPhone 17 suite passes 132/132 with no failures or skips; repository
  validation and a fresh unsigned arm64 Release archive pass.

## 2026-07-30 — Journey-first product polish and runtime hardening

- Replaced the five-tab shell with four user journeys: Home, Discover, Alerts,
  and Saved. Search and map now share Discover while existing Nearby, Search,
  and Favourites system destinations remain backward-compatible.
- Reworked Home and Saved into compact commute dashboards, personalised Alerts
  from saved line names with an explicit All Vienna scope, added map recovery,
  compact station service-alert navigation, direct Lock Screen tracking actions,
  and complete English/German copy.
- Replaced continuous location tracking with coalesced one-shot requests. A
  regression-first debug pass fixed temporary/empty Core Location callback retry
  paths and prevented location-driven SwiftUI task restarts from becoming an
  implicit request loop.
- Removed the repeating station pulse and 30-second detail refresh cadence.
  Station detail and Home each measured 0.0% CPU across eight settled Debug
  Simulator samples; visible boards use bounded 60-second refreshes.
- Added a first-class XCUITest target and end-to-end coverage for the four tabs,
  Discover map entry, alert filters, Saved, and search-to-station navigation.
  All 117 XCTest cases pass with no failures, skips, warnings, or errors.
- Regenerated and visually inspected all ten `en-US`/`de-AT` App Store
  screenshots at 1320×2868 JPEG without alpha. A final unsigned arm64 Release
  archive packages the expected app/widget IDs, version 1.0 (1), privacy
  manifests, iOS 26.0 minimum, and encryption declaration.
- Security review found no new findings, dependencies, endpoints, entitlements,
  secrets, or persisted personal data. Repository and OpenCode static validators
  pass; the local OpenCode runtime validator remains unavailable because the
  `opencode` CLI is not installed. App Store submission remains No-Go only for
  the documented signing, App Store Connect, processed-build, and physical
  TestFlight evidence gates.

## 2026-07-29 — Protected App Store release integration

- Merged release-readiness PR #10 into the stacked product branch, waited for
  Quality run `30431672501`, then merged PR #9 into `main`. Exact production
  commit `52009857a361e0a3c138c4cbded380034dc48f16` passed its independent push
  Quality run `30432216226` in 8m09s.
- Confirmed the public raw and rendered `main/PRIVACY.md` URLs both return HTTP
  200, closing the production privacy-URL gate.
- Protected `main` with pull requests, strict required `validate`, resolved
  conversations, and admin enforcement. Force pushes and branch deletion are
  disabled; a zero-review PR requirement preserves the repository's current
  single-maintainer workflow without allowing direct pushes.
- GitHub contains no release secrets, variables, or environments. Isolated
  temporary-Keychain tests confirmed automatic provisioning cannot replace the
  inaccessible login private key without also losing the locally stored Xcode
  account. Both empty temporary Keychains were removed and the user search list
  was restored to the login Keychain only.

## 2026-07-29 — App Store distribution access audit

- Re-ran the signed generic archive with Xcode open and automatic provisioning.
  Compilation, bundle identifiers, development identity, and both provisioning
  profiles resolve correctly; widget signing still stops at
  `errSecInternalComponent`.
- Confirmed the certificate's organizational unit, project build settings, and
  profiles all use team ID `KZNP8PH94C`. The separate identifier shown in the
  certificate common name is not the Developer Team ID.
- Added a repeatable App Store validation export configuration. Xcode accepts the
  archive and configuration, but distribution stops before Apple validation
  because no local Xcode account has App Store Connect access for the team.
- A narrowly targeted attempt to add the standard `codesign` key partitions
  correctly requested the login Keychain password and was cancelled without
  changing the key. No browser session, App Store Connect API key, or stored CLI
  credential is available to substitute for the missing authenticated account.

## 2026-07-29 — Supported GitHub Actions runtime

- Updated the Quality workflow from `actions/checkout@v4` and
  `actions/setup-node@v4` to their supported v6 majors after GitHub-hosted CI
  warned that the Node 20 action runtime was deprecated and being force-run on
  Node 24.
- Preserved the explicit Node.js 22 tool version and disabled setup-node's new
  automatic package-manager caching because this workflow installs only the
  pinned global OpenCode CLI and has no project npm install step.
- Rollback is the two-line major-tag revert plus removal of the v6-only cache
  input. Protected Quality CI is the compatibility authority for the hosted
  runner, repository validators, Xcode build, and 108-test suite. Run
  `30426734694` passed the complete workflow in 9m13s with no annotations.

## 2026-07-29 — App Store readiness hardening

- Removed the device-only Sign in with Apple profile surface and entitlement,
  replaced it with an idempotent legacy Keychain cleanup, added in-app/public
  privacy policy content, app/widget privacy manifests, export-compliance
  declaration, complete English/German store metadata, and a physical/TestFlight
  smoke checklist.
- Fixed premature destination truncation and maximum Accessibility Dynamic Type
  disruption/departure layouts. Runtime acceptance covered English and German,
  optional-location behavior, live data, iPhone 17 Pro Max, iPad Pro 13-inch, and
  ten localized 1320×2868 App Store screenshots without alpha.
- All 108 XCTest cases pass with no failures, skips, warnings, or errors. A clean
  unsigned Release archive contains the expected arm64 app/widget, bundle IDs,
  version 1.0 (1), iOS 26.0 minimum, icons, encryption flag, and both privacy
  manifests. Repository and OpenCode static validators pass.
- Current release verdict remains No-Go: non-interactive Keychain access prevents
  the final signed archive at widget `codesign`; App Store Connect, the final
  public privacy URL, processed-build warnings/privacy report, and physical
  TestFlight system-surface smoke remain externally unverified. Local full CI
  stops because `opencode` is not installed; protected GitHub Quality installs the
  pinned version and passed its complete 10-minute workflow on draft PR #10.
- A connected iPhone18,2 on iOS 26.5.2 was detected and targeted with a Release
  device build. Compilation and profile selection succeeded, then widget signing
  reproduced the same `errSecInternalComponent`, confirming the remaining device
  gate is private-key consent rather than source, SDK, device, or provisioning
  compatibility.

## 2026-07-29 — Camera-aware map exploration and widget navigation

- Added an explicit “Search this area” map flow after 250 metres of camera
  movement. Explored centres remain transient, permission messaging stays truthful,
  and the local indexed station projection remains bounded and spatially thinned.
- Interactive testing exposed a MapKit layout feedback loop when the camera action
  changed the map safe area. Moving camera-driven surfaces to a non-resizing overlay
  reduced the reproduced post-action process load from about 70% to 0–0.2% CPU.
- Added one validated shared destination vocabulary and custom URL boundary so the
  favourites widget opens the matching tab on warm and cold launches. Unknown,
  parameterised, credentialed, and non-app URLs are rejected without navigation.
- Debug and Release Simulator builds completed with no diagnostics; all 116 XCTest
  cases passed. The built Info.plist, launch-screen dictionary, URL registration,
  English/German extraction coverage, runtime routing, and map interaction were
  verified. Repository/OpenCode validation passed; standalone reliability reached
  its OpenCode CLI fixture and stopped because that CLI is not installed locally.

## 2026-07-28 — System surfaces, widget cadence, and indexed discovery

- Recovered the latest `main` baseline by removing four unreferenced components
  that did not compile, then added persisted App Intent routing and three App
  Shortcuts for Nearby, Search, and Favourites with English/German metadata.
- Expanded departures to small, medium, large, circular, rectangular, and inline
  widgets. Countdown rows now project locally each minute from their own fetch
  time, automatic network refresh is five-minute, manual refresh bypasses the
  throttle once, and partial failures retain correctly ordered cached routes.
- Added exact-name, bigram, and spatial station indexes plus tappable map-marker
  thinning. The same 100-query benchmark improved text search from about 184 ms
  to about 6.05 ms; 100 spatial queries average about 3.70 ms on iPhone 17 Pro Simulator.
- Clean Debug and Release builds completed with no diagnostics. Full XCTest passed
  112/112 with no skips; cold intent routing, live Search, Map, Alerts, Favourites,
  generated shortcut metadata, localisation bundles, and runtime logs were checked.

## 2026-07-18 — Accessibility-safe Nearby quick access

- Reworked the saved-station quick-access card so decorative symbols keep a fixed
  readable size, the action can wrap, and the maximum accessibility category uses
  a compact text-first layout instead of clipping content below the tab bar.
- VoiceOver now receives one localized station-and-action label, while Voice
  Control has stable station and departure input labels. No repository, network,
  persistence, permission, or navigation boundary changed.
- Fresh iPhone 17 light, dark, and accessibility-extra-extra-extra-large renders
  show complete Stephansplatz and Departures text. Full CI remains warning-free
  with all 100 XCTest cases passing.

## 2026-07-18 — App-level service status dashboard

- Moved the shared disruptions refresh loop to `RootTabView`, so the Alerts badge
  and Nearby dashboard receive current service data before the Alerts tab is opened.
  `DisruptionsView` keeps explicit retry and pull-to-refresh without a second poller.
- Added a compact Service status card with loading, all-clear, active-alert,
  saved-data, and unavailable states plus an existing-tab shortcut. The state model
  is covered by fresh, empty, stale, refresh-failure, and initial-failure tests.
- Fresh iPhone 17 runtime renders showed 10 real service alerts in sync with the tab
  badge. Light, dark, and accessibility-size review passed after constraining only
  decorative symbol scaling. Full CI is warning-free with 100 XCTest cases; no new
  endpoint, storage, permission, dependency, secret, or logging boundary was added.

## 2026-07-18 — Cross-journey next departure

- Centralised favourite station and route loading in `RootTabView`, so Nearby and
  Favourites consume one shared observable model instead of running duplicate
  repositories and refresh loops. Route changes now refresh the shared state.
- Added an adaptive Next departure card to Nearby. It selects the soonest
  non-past available saved route, distinguishes live from saved data, remains
  useful without location permission, and opens the existing Favourites tab.
- Runtime iPhone 17 light, dark, and accessibility-size review caught and fixed a
  dark-mode line-badge contrast defect plus an oversized header layout defect.
  German extraction has no missing key; full CI is warning-free with 99 XCTest
  cases. The simulator route/stations were temporary local acceptance fixtures.

## 2026-07-18 — Location-independent Nearby dashboard

- Kept saved-station quick access visible above every location state, so declining
  or delaying location permission no longer hides device-local favourites. The
  existing App Group repository and station-detail navigation remain authoritative.
- Replaced compressed chips with adaptive, view-aligned cards. Compact layouts show
  one wide card plus a carousel cue, accessibility Dynamic Type gets one full-width
  card, and location/loading/empty states use a separate system content card.
- Five dashboard-state and two Nearby loading regressions pass; full CI is warning-
  free with 95 XCTest cases. Fresh iPhone 17 light/dark renders cover two saved
  stations above an undecided location prompt. Interactive tap, accessibility-size,
  and VoiceOver acceptance remain in the cross-journey gate.

## 2026-07-18 — Optional Apple entry in onboarding

- Added a fourth onboarding step that exposes the existing native Apple boundary,
  confirms a restored profile, or offers a separate explicit anonymous action before
  the app requests location permission. Email remains absent rather than simulated.
- Added German catalogue values, stable four-step sequence coverage, and missing
  Apple cancellation/failure regressions. Eleven account lifecycle plus two
  onboarding tests pass; cancellation stays silent and real failure remains visible.
- Full CI passes warning-free with all 90 XCTest cases. Security review found no
  new secret, token, storage, endpoint, dependency, log, or Critical/High/Important
  issue. Physical-device Apple, interactive onboarding, and real email acceptance
  remain pending their existing external gates.

## 2026-07-18 — Adaptive and understandable departure rows

- Replaced the shared departure row's fixed-column layout at accessibility Dynamic
  Type sizes with a flexible two-level composition, so long destinations and live
  times are no longer forced into compact widths.
- Combined the visual fragments into one localized VoiceOver element covering the
  line, destination, next and following times, real-time prediction, disruption,
  and walking feasibility; all new German catalogue values compile and extraction
  reports no missing key.
- Full CI passes warning-free with all 86 XCTest cases. Interactive VoiceOver and
  accessibility-size visual acceptance remains pending because the host is locked.
  The literal iPhone 17 destination was also ambiguous due to two existing devices,
  so CI used the supported explicit-UUID override without deleting either device.

## 2026-07-18 — Email authentication provider decision packet

- Compared Firebase Authentication and Supabase Auth against the real Apple,
  passwordless email, provider-linking, restore, and delete-account lifecycle.
- Recommended Firebase because its Apple SDK documents passwordless Hosting links,
  linked identities, and authenticated current-user deletion without adding a
  TrafficVienna-owned privileged server. Supabase remains viable if remote Postgres
  sync later justifies a trusted deletion function.
- Added the approval-gated configuration, security, migration, and acceptance plan;
  no SDK, Firebase project, credential, entitlement, domain, or external account was
  created or changed.

## 2026-07-18 — Apple runtime revocation and device signing evidence

- Subscribed the app lifecycle to Apple's credential-revoked notification and
  routed it through `AccountSession`, so an active Apple profile is removed from
  memory and device-only Keychain immediately rather than waiting for next launch.
- Added a focused revocation regression; nine account tests and all 86 XCTest cases
  pass in full CI. Security review found no new secret, token, endpoint, permission,
  dependency, log, or unresolved Critical/High/Important finding.
- Generic Release archive verified the source entitlement, automatic signing team,
  bundle ID, and local signing identity, then failed because the installed profile
  lacks Sign in with Apple. No provisioning update or Apple Developer mutation was
  attempted; the capability/profile change remains external approval work.

## 2026-07-18 — Shared accessible motion polish

- Added one shared motion token set for quick state changes, standard full-screen
  changes, live pulses, shimmer, state replacement, and edge presentation.
- Applied consistent transitions to onboarding/app entry, Search, Alerts, Map
  selection, the offline banner, and live departure countdowns.
- Reduce Motion now removes displacement, scale, shimmer, pulse, and numeric rolling
  instead of leaving live and loading components animated. Full CI passed with zero
  warnings and 85 XCTest cases; interactive timing review remains pending unlock.

## 2026-07-18 — Evidence-backed network boundary cleanup

- Audited production, widget, intent, and test references before changing the
  network boundary; the legacy stop-ID monitor request had declarations and mock
  implementations but no caller.
- Removed only that unused protocol requirement, production method, and two test
  double methods. Active DIVA and traffic-info request paths are unchanged.
- Repository/OpenCode validation, app/widget build, and all 85 XCTest cases passed
  in full CI. TV-CORE-020 remains open for any further journey-proven cleanup.

## 2026-07-18 — Nearby dependency injection and observation modernization

- Replaced Nearby's concrete `StationStore`, `LocationManager`, and
  `MonitorService` dependencies with narrow station, location, and monitor
  protocols while keeping the production objects unchanged.
- Migrated `NearbyViewModel` from legacy `ObservableObject`/`@Published` ownership
  to `@Observable`/`@State` and added focused tests for distance order, freshness,
  and the no-location zero-request path.
- Full CI passed with zero warnings and 85 XCTest cases. Security reread confirmed
  coordinates remain transient and unlogged, with no new endpoint, persistence,
  dependency, or unresolved Blocking/Important finding.

## 2026-07-18 — Localisation and source accessibility audit

- Compared compiler-produced app and widget `.stringsdata` against the committed
  catalogues with `xcstringstool sync`; added every missing format/preview key and
  German value, leaving zero extraction gaps.
- Replaced fixed account/empty-state hero symbol sizes with Dynamic Type scaling,
  removed manual C-style distance formatting, and made Nearby VoiceOver distance
  text locale-aware through `Measurement` formatting.
- Source review found no active design picker, `caption2`, `onTapGesture`,
  `UIScreen.main`, deprecated navigation, or unlabeled icon-only control introduced
  by the redesign. App/widget build remains warning-free.
- Interactive accessibility-size and VoiceOver acceptance is still pending because
  the macOS host remained locked.

## 2026-07-18 — Truthful freshness and deterministic request timing

- Added freshness-aware monitor and traffic-info snapshots that preserve the last
  successful timestamp and distinguish current from stale in-memory responses.
- Station Detail, Alerts, Nearby cards, and favourite routes now label saved data
  with text plus an icon; cached favourite departures remain eligible for the widget.
- Injected a scheduler into `MonitorService` and proved 0.5-second request spacing
  plus bounded 0.8/1.6-second rate-limit backoff without wall-clock sleeps.
- Full CI passed with zero warnings and 83 XCTest cases. Security review found no
  new endpoint, persistence, secret, log, dependency, or unresolved Blocking/
  Important issue. Interactive Simulator inspection is still pending because the
  macOS host remained locked.

## 2026-07-18 — Refresh and network lifecycle hardening

- Routed traffic-alert refreshes through the same coalescing, throttling,
  rate-limit backoff, and in-memory stale fallback as station monitor requests.
- Added cancellation publication guards to Nearby, Favourites, Alerts, and Station
  Detail so a departed screen cannot apply a late response or sync stale widget data.
- Added concurrent refresh, stale fallback, and late-cancellation regressions. Full
  CI passed with zero warnings and 78 XCTest cases; review found no new endpoint,
  persistence, credential, logging, or unresolved Blocking/Important security issue.
- Cache freshness provenance and deterministic clock-based throttle/backoff tests
  remain before TV-CORE-022 can close.

## 2026-07-18 — Onboarding, About, and widget secondary surfaces

- Unified onboarding and About with the adaptive design system, scalable text,
  reduced-motion behaviour, and scrollable accessibility-size layouts.
- Moved `FavoriteRoute` into shared app/widget code with deterministic ordering;
  the widget now decodes and displays the actual station name instead of its DIVA
  identifier and uses safe relative-date rendering.
- Added an embedded German widget catalogue and completed missing German app
  strings. Full CI passed with zero warnings and 75 XCTest cases; security review
  found no unresolved Blocking or Important issue.
- Interactive secondary-surface inspection remains pending because the macOS host
  was still locked; no unlock attempt or permission choice was made.

## 2026-07-18 — Station Detail journey and widget ownership fix

- Rebuilt Station Detail around explicit loading/loaded/empty/failure and
  stale-refresh states with deterministic merged departure groups and filters.
- Made alerts navigable, route/station favourites reactive, and Live Activity an
  explicit accessible action with success and failure feedback.
- Removed the hidden Station Detail write that replaced the favourites widget
  with an arbitrary first station line; widget ownership stays with Favourites.
- Full CI passed with zero warnings and 74 XCTest cases. Interactive detail and
  Dynamic Type inspection remains pending because the host Mac is locked.

## 2026-07-18 — Favourites journey resilience

- Modernised Favourites state ownership, gave route rows stable identity and
  deterministic order, and preserved the existing station/route repositories.
- Added per-route unavailable/retry behaviour, forced pull-to-refresh, cancellable
  polling, modern station navigation, and safe widget exclusion for failed routes.
- Added focused coverage for station load/reorder/remove, route ordering, failure,
  retry, force refresh, and widget behaviour.
- Full CI passed with zero warnings and 65 XCTest cases. Interactive journey and
  accessibility-size inspection remains pending because the host Mac is locked.

## 2026-07-18 — Alerts journey and feed prioritisation

- Split the live feed into service, accessibility, and stop-change categories;
  service alerts are the default and exact station-notice duplicates are removed.
- Added explicit loading, empty, filtered-empty, failure, retry, refresh-error,
  detail, affected-line, and searchable/filterable states with German strings.
- Alert requests now use the existing in-memory cache while forced refresh stays
  observable; no HTML, external link, secret, log, or new network destination was added.
- Full CI passed with zero warnings and 60 XCTest cases. Interactive light/dark
  and accessibility-size inspection remains pending because the host Mac is locked.

## 2026-07-18 — Map journey and location privacy

- Added a testable Map state model for bounded nearest markers, catalogue
  loading/empty/failure/retry, Vienna fallback, and all location permission states.
- Replaced immediate marker sheets with an accessible, reduced-motion-aware
  selection card and explicit departure navigation.
- Location remains memory-only and unlogged. German and English system permission
  rationales are embedded and state that the app does not store location.
- Full CI passed with zero warnings and 49 XCTest cases; Map interaction remains
  pending because the host Mac is locked.

## 2026-07-18 — Search journey refactor

- Added an injectable observable Search view model with explicit idle/loading,
  results, no-results, unavailable, retry, and cancellable debounce behaviour.
- Modernised station navigation and accessible result/recent rows; recent IDs now
  have tested unique ordering, persistence, limits, and clear behaviour.
- Full CI passed with app/widget build, zero warnings, and 43 XCTest cases.
- Simulator interaction remains pending because the host Mac was locked.

## 2026-07-18 — Native Apple account slice

- Added optional native Sign in with Apple from Favourites while preserving
  anonymous transport use.
- Minimal Apple profile data is stored in device-only Keychain; tokens are not
  saved or logged. Credential revocation, transfer, sign-out, restore, and
  storage failures have focused regression coverage.
- App/widget build and 35 XCTest cases pass. Security review found no unresolved
  Blocking or Important finding in the native slice.
- Email authentication remains pending an explicit real backend/provider choice.

## 2026-07-18 — Unified redesign and executable test recovery

- Removed selectable themes and consolidated the app around one adaptive
  Vienna-red visual identity.
- Rebuilt onboarding, added reactive favourite-station quick access, modernised
  the tab API, and fixed recent-search persistence.
- Restored the missing XCTest target; fixed the failures it exposed. Final local
  evidence: app/widget build succeeded with zero warnings and 27 tests passed.
- Email authentication remains blocked on a provider decision; no fake local
  authentication was introduced.

## 2026-07-15 — OpenCode model and recovery readiness audit

- Started from updated `main` at `07894ac1` on fresh branch `codex/reliability-model-audit`.
- Recorded OpenCode CLI `1.17.20` model inventory in `docs/opencode/model-matrix.md` and assigned an explicit model to every OpenCode agent.
- Verified all six configured unique model IDs with minimal `opencode run --pure -m <model> "Reply with exactly: OK"` smoke calls.
- Added `docs/opencode/state-files.md` and `tests/opencode-reliability.sh` for checkpoint schema, duplicate prevention, latest-valid checkpoint selection, invalid checkpoint rejection, timeout fallback, permission safety, personal GitHub CLI context, protected-branch, and draft PR workflow checks.
- Fixed macOS CI portability after GitHub Actions showed GNU `timeout` is unavailable on the runner; the timeout fixture now uses Python `subprocess.TimeoutExpired`.
- Local validation passed: `bash scripts/validate-opencode.sh`, `bash tests/opencode-reliability.sh`, and `TRAFFICVIENNA_ALLOW_XCODEBUILD_SKIP=1 bash scripts/ci.sh`.
- macOS GitHub Actions remains authoritative for real Xcode build/test evidence.

## 2026-07-15 — Sequential subagent execution policy

- After PR #3 was merged, synchronized local `main` with `origin/main`, pruned deleted remote branches, and removed merged local feature branches after ancestry/content checks.
- Configured OpenCode workflow guidance so subagents run sequentially by default. Parallel execution is limited to 2-3 genuinely independent read-only tasks with documented independence, a 3-minute timeout, and automatic fallback to sequential execution.
- Added validation coverage in `scripts/validate-opencode.sh` so the orchestrator prompt and workflow docs must preserve the sequential default and timeout/fallback rules.

## 2026-07-15 — Live OpenCode autonomy audit demo

- Started from updated `main` at `410f0a34` after `git fetch origin --prune` and fast-forward pull. Created fresh branch `codex/live-autonomy-audit-20260715`.
- OpenCode launched real subagent delegation for explorer, architect, test-architect, reviewer, security-reviewer, and release-manager. `test-architect` and `reviewer` completed; the parallel subagent run then stalled, so the audit recovered sequentially and recorded the runtime blocker.
- Created `docs/opencode/live-autonomy-audit-2026-07-15.md` and checkpoint file. Controlled failure used a line-anchored sentinel check: `grep -qx 'AUTONOMY_DEMO_STATUS=PASS' ...` failed with exit 1 before the standalone sentinel existed, then passed after adding it.
- A routine safe shell-search permission prompt occurred during OpenCode's generated `rg` diagnostic. Root cause fixed by allowlisting read-only `grep *` and `rg *` bash patterns in OpenCode permissions and adding permission matcher regression cases.
- Local validation passed: JSON/shell syntax, repository validation, OpenCode validation, permission matcher, `TRAFFICVIENNA_ALLOW_XCODEBUILD_SKIP=1 bash scripts/ci.sh`, and `git diff --check HEAD`.
- Draft PR #3 created: https://github.com/Vaniawl/TrafficVienna/pull/3. macOS GitHub Actions `validate` passed; PR remains draft and unmerged.

## 2026-07-14 — OpenCode routine permission audit fix

- Reproduced a non-interactive OpenCode autonomy blocker: safe routine commands generated by the orchestrator (`git branch/log/status`, OpenCode folder listing, and isolated personal `GH_CONFIG_DIR` GitHub CLI checks) requested permission and were auto-rejected.
- Tightened the OpenCode allowlist with exact safe read/status/PR patterns, kept protected-branch push, force-push, merge, release, deploy, destructive commands, and secrets denied or gated.
- Re-ran the final autonomy audit prompt and found the next safe startup gap: `git fetch origin main 2>&1 && git log --oneline -5 origin/main`. Added the exact allow rule and regression case so updated-main discovery no longer blocks non-interactive runs.
- Re-ran the audit again and found the read-only branch/status bundle variant with `git status --short`. Added the exact allow rule and regression case.
- Re-ran the audit again and confirmed the startup status bundle now passes; the next gap was the read-only fallback `git log --oneline -5 origin/main 2>/dev/null || echo ...`. Added the exact allow rule and regression case.
- Re-ran the audit again and found a pipe/filter prompt (`git branch ... | head -20`). Added safe output-only filter allowances for `head`, `tail`, and `echo`, plus the concrete branch listing regression case.
- Re-ran the audit smoke test again and confirmed it now reaches context loading, personal `gh` verification, open PR listing, and explorer subagent delegation. The next gap was the safe updated-main evidence command with `echo "---FETCH OK---"` between fetch and log; added the exact allow rule and regression case.
- Extended `tests/opencode-permission-matcher.sh` with the real failing command shapes. Local validation passed with repository validation, OpenCode validation, permission matcher, CI wrapper with explicit local Xcode skip, and whitespace diff check.

## 2026-07-09 — Remote SSH as working environment request

- Користувач уточнив, що хоче, аби робота виконувалась на `skyphoenix@192.168.1.179`. Пояснено, що потрібні мережевий дозвіл у Codex і авторизація SSH ключем/паролем на remote host; попередня перевірка показала reachable host, але `Permission denied`.

## 2026-07-09 — SSH remote host connection attempt

- Перевірено SSH до `skyphoenix@192.168.1.179`: host доступний, але авторизація не пройшла (`Permission denied`). Знайдено локальний public key `id_ed25519.pub`, який треба додати на remote host у `~/.ssh/authorized_keys`.

## 2026-07-09 — SSH remote host access guidance

- Пояснено, як підключити remote host через SSH так, щоб Codex міг мати доступ: потрібні host/user/key, запис у SSH config або команда `ssh`, а також мережевий доступ у середовищі.

## 2026-06-29 — Фінальний раунд: баги, дизайн, UX, build ✅

### Виправлено баги
- **UserDefaults(suiteName:)!** — 2 force-unwrap замінено на `?? .standard` (ніколи не крашиться)
- **loadFavorites Task stacking** — `func loadFavorites()` → `async`, `.task` тепер `await` (не накопичує Task)
- **Widget показував DIVA замість назви станції** — додано `stopName` до `FavoriteWithDeparture`, заповнюється з `monitor.locationStop.properties.title`
- **Disruptions опитування на всіх табах** — перенесено `.task` в `DisruptionsView`
- **LiveActivity update() збігалась тільки по лінії** — додано `destination` + `stopName` в матчинг
- **StationStore stations пустий до завершення Task.detached** — синхронне завантаження (локальний JSON)
- **48 stale ключів** в Localizable.xcstrings — видалено

### Дизайн — мінімалістичний, професійний
- **AppColors:** видалено `appRed`/`appDim`/`appIndigo`/`appAmber`/`appDarkBg` (дублікати system кольорів). Замінено `.red`, `.secondary` скрізь.
- **DepartureLineRow:** 7→4 font sizes (caption, subheadline, title3, title2). Спейсинг: 10→8, колонки: 52→48, 62→60.
- **StationCardView:** padding 14→16, vertical 9→8.
- **OnboardingView:** мінімалістичний редизайн. Без hardcoded `Color(hex: 0xE20917)`. Іконка 88→80, шрифт `largeTitle.bold`→`title.semibold`.
- **FilterChips:** spacing 6→4, vertical 3→4, `caption2`→`caption`.
- Усі спейсинги тепер кратні 4 (grid).

### UX — зручність
- **StationCardView — бейджі ліній:** під назвою станції показуються `LineBadge(size: .small)` для кожної лінії, що обслуговує станцію.
- **StationCardView — context menu:** довгий тап → обрали станцію, поділитись, відкрити в Картах (MKMapItem).
- **StationDetailView — FilterChips:** можна фільтрувати департури за категорією (метро/трам/автобус). З'являються автоматично, коли станція має >1 категорію.

**Build: 0 errors, 0 warnings** ✅

## 2026-06-29 — Pre-deploy cleanup: dead code, Logger, DRY, LiveActivity, tests

- **🧹 Dead code:** Видалено `WidgetCacheEnvelope` (не використовувався). Видалено `favoriteEmoji` параметр з ConfigurationAppIntent + виправлено опис ("This is an example widget" → описово).
- **🔊 print() → os.Logger:** Усі `print()` замінено на `Logger(subsystem:category:)` з категоріями (store, favorites, location, live-activity, widget-sync).
- **📐 DRY normalize:** Видалено дубльовані `normalize()` у FavoritesListViewModel та TrafficViennaWidget. Усюди використовується `RouteMatching.normalize()/matches()` з WidgetShared.
- **🔄 WidgetSync:** Видалено дубльований `enum WidgetSync`. StationDetailViewModel тепер використовує `WidgetSyncManager` через протокол.
- **🖼️ Widget colors:** Додано LineColors.swift + RouteMatching.swift до widget target (pbxproj membershipExceptions). Видалено дубльовані `Color(hex:)`, `widgetLineColor()`, `WidgetLineBadge` — тепер через `LineColors`.
- **🏃 Walking speed:** Хардкоди `80` у StationCardView + NearbyViewModel замінено на `walkingSpeed` з Walking.swift.
- **🔴 LiveActivityController:** Додано методи `update()` та `stopAll()`.
- **💾 RecentSearchesStore:** `UserDefaults.standard` → App Group `(suiteName:)` з graceful fallback.
- **🧪 Тести:** Додано 22 тести: RouteMatching (10), DepartureClock (4), MonitorService (3), LineColors/LineCategory (6), WidgetDepartureData (1). MockNetworkManager для тестування MonitorService. Тести компілюються, але test target відсутній у pbxproj — додати через Xcode.
- **📓 DECISIONS.md:** Оновлено — видалено Spatial Transit, додано поточні рішення.
- **Build:** 0 errors, 0 warnings. ✅

## 2026-06-29 — Дизайн: система тем з різними стилями (background + card)

- **ThemePreset розширено:** `backgroundStyle` (.system / .grouped) + `cardStyle` (.flat / .elevated)
- **5 тем зі зміненим стилем:** Vienna, Dashboard, Ocean, Rose — grouped bg + elevated cards. Решта — system bg + flat.
- **StationCardView:** підтримує shadow + corner radius для `.elevated`
- **NearbyView:** фон змінюється залежно від backgroundStyle
- **FavoritesView:** listStyle змінюється на `.insetGrouped` для grouped тем
- **Симулятор:** app запущено, перемикай теми через `paintpalette` в Nearby toolbar
- **Build:** 0 errors, 0 warnings

## 2026-06-29 — Відновлення 10-темного дизайну після Spatial Transit

- **Що сталося:** користувач реалізував Spatial Transit (скляні картки, кастомний tab bar, дизайн-токени), але потім попросив почистити і повернути мій дизайн
- **Видалено зламані файли:** AppColors, DepartureIntent, DepartureReminder, DisruptionsViewModel, FilterChips, DisruptionsView, LineStyle
- **Створено заново:**
  - `Model/Theme.swift` — 10 пресетів (Indigo, Vienna, Dashboard, Twilight, Forest, Ocean, Rose, Monochrome, Amber, Night)
  - `Model/ThemeManager.swift` — ObservableObject singleton + UserDefaults
  - `Model/AppColors.swift` — ShapeStyle extension, appGreen = ThemeManager.shared.preset.accentColor
  - `Model/DisruptionsViewModel.swift` — використовує MonitorService.trafficInfoList()
  - `View/DisruptionsView.swift` — List + FilterChips + empty/error states
  - `View/Components/FilterChips.swift` — Capsule chips
  - `View/Components/LineStyle.swift` — LineBadge + LineColors (без дублів)
- **Додано API:** NetworkManager.fetchTrafficInfoList(), MonitorService.trafficInfoList()
- **Оновлено:** RootTabView (ThemeManager + 5 tabs + NetworkMonitor), NearbyView (paintpalette Menu), LineColors (тільки Color(hex:) + LineCategory + LineColors)
- **Build:** 0 errors, 0 warnings ✅

- **Обраний напрямок:** Spatial Transit (Liquid Glass, visionOS натхнення, глибина)
- **Нові файли:** `Model/DesignTokens.swift` — foundation: спейсинг (xs–xxl), радіуси (sm–xl), типографія (`spatialLargeTitle`, `spatialBody`, `spatialCaption`, etc.), адаптивні кольори (`spatialBackground`, `spatialText`, `spatialAccent`, `spatialAccentGlow`, etc.), `GlassModifier` + `glass()` view extension, `elevation()` shadow modifier
- **Плаваючий Tab Bar:** кастомний `ZStack` + `Capsule` з `.ultraThinMaterial`, замість `TabView`. Анімований `.opacity` перемикання. Badge на Alerts.
- **Скляні картки:** `StationCardView` тепер з `.glass()` модифікатором + `elevation(1)`. Всі списки — `ScrollView` + `LazyVStack` (замість `List`).
- **Оновлені кольори:** `AppColors.swift` тепер мапить на `spatial*` токени. `ThemePreset` скорочено до одного `spatial` (force dark).
- **LineBadge:** новий стиль — `.opacity(0.85)` фон + `.stroke(.white.opacity(0.15))` border, `RoundedRectangle(cornerRadius: 6)` замість `Capsule()`
- **Усі екрани:** NearbyView, StationDetailView, SearchView, FavoritesView, DisruptionsView, MapStationsView — перероблені на `ScrollView + LazyVStack + glass cards`
- **Збірка:** 0 помилок, 0 попереджень (включно з widget extension)

## 2026-06-29 — 10 тем + перемикання однією кнопкою

- **Нові файли:** `Model/Theme.swift`, `Model/ThemeManager.swift`, `Model/AppColors.swift`
- **10 пресетів:** Indigo, Vienna, Dashboard, Twilight, Forest, Ocean, Rose, Monochrome, Amber, Night
- **ThemeManager:** ObservableObject + singleton, зберігає вибір у UserDefaults
- **Кнопка перемикання:** `paintpalette` Menu в toolbar NearbyView (leading side). Кожен пункт меню показує галку для активного + кольорову крапку.
- **Динамічні кольори:** `ShapeStyle` extension читає `appGreen` з `ThemeManager.shared.preset.accentColor`. Решта кольорів — системні.
- **Light/Dark:** `.preferredColorScheme(themeManager.preset.colorScheme)` — 3 теми force dark, 3 force light, 4 system.
- **AppColors.swift** винесено з WidgetShared/LineColors.swift (там залишено тільки `LineCategory` + `LineColors` + `Color(hex:)`)
- **Build:** 0 errors, 0 warnings

## 2026-06-28 — Тематична система (6 тем + пікер у налаштуваннях)

- **🎨 Нова архітектура:** `Model/Theme.swift` — `ThemeID` enum + `Theme` struct з усіма токенами (кольори, типографія, лейаут, фічі). Передається через `@Environment(\.theme)`.
- **⚙️ SettingsView** — пікер тем з іконками, sheet на Favourites вкладці (шестерня).
- **6 тем:**
  - **Standard** — поточний мінімалістичний дизайн
  - **Dark Terminal** — чорний фон, `.monospaced`, зелений акцент, квадратні кути, без іконок
  - **Big Data** — hero 56pt `.ultraLight`, без карток/поверхонь, без follow-up
  - **Editorial** — 17pt body, без карток, великі відступи
  - **Glass** — `.rounded` font, 20pt картки, `.systemFill` blur surface
  - **Industrial** — `.monospaced` скрізь, квадратні кути, сірий акцент
- **Ключові зміни:** `DepartureLineRow` тепер використовує `theme.heroSize/Weight/Design`; `StationCardView` перевіряє `theme.useCards`; усі списки отримали тему-авар; іконки ховаються через `theme.showIcons`.
- **Збірка:** 0 помилок, 0 попереджень (включаючи widget extension — `LineBadge` без залежності від теми).

## 2026-06-28 — Повний мінімалістичний редизайн UI

- **🎨 Філософія:** Data-first. Прибрано декоративні елементи, анімації, зайві кольори. Системні семантичні кольори замість кастомних, типографія зі світлими вагами, базовий спейсинг 8pt.
- **🧹 Shimmer + LivePulse** — видалено анімації повністю (no-op).
- **🔖 LineBadge** — прибрано `.bold()`, зменшено паддинг радіус 6→4, менші відступи.
- **🏷️ FilterChips** — `.thinMaterial` → `.quaternarySystemFill`, менший паддинг, без анімації.
- **🚃 DepartureLineRow** — повний rewrite:
  - Видалено колонку гліфів (figure.walk/run/nosign + LivePulse) та `@ScaledMetric`.
  - Час відправлення: `title2.weight(.semibold)` → `system(size: 24, weight: .light, design: .monospaced)`.
  - "min" під числом (`VStack`), а не поряд.
  - Follow-up справа, без `showFollowUp = false` розділення.
  - Прибрано `.animation(.snappy)` та `.sensoryFeedback`.
- **🗂️ StationCardView** — радіус 16→10, паддінг 14→12, відступи рядків 9→6.
  - Walking текст спрощено з "N min · N m/km" до "N min".
  - Скелетон без `.shimmer()`.
- **📡 NearbyView** — спейсинг LazyVStack 12→8, пом'якшено empty states (іконка 36pt tertiary, `.body` заголовок).
- **🔍 SearchView** — прибрано `bold()` підсвітку пошуку, прибрано іконку `clock.arrow.circlepath` в рецентсах.
- **📱 StationDetailView** — скелетон без `.shimmer()`, freshness bar 5pt коло, 4pt спейсинг.
- **⭐ FavoritesView** — freshness bar 5pt коло.
- **⚠️ DisruptionRow** — зменшено спейсинги, прибрано `.weight(.semibold)` і `.weight(.medium)`.
- **🗺️ MapStationsView** — банер радіус 12→8, 10pt паддінг.
- **👋 OnboardingView** — 3→2 сторінки, прибрано featuresPage та велику іконку. Заголовок `.largeTitle.weight(.light)`.
- **ℹ️ AboutView** — іконка 72→56, радіус 18→14, 26pt font замість 34.
- **🏠 RootTabView** — offline-банер: `VStack` → `.overlay`, компактніший (Capsule, 4pt паддінг).

- Збірка: 0 помилок, 0 попереджень.

## 2026-06-28 — Bugfix round: test target, walking constant, Quick Actions, backoff, translations, force‑unwrap

- **🔴 Test target** — додано `TrafficViennaTests` в pbxproj (PBXNativeTarget, BuildConfigurations, ContainerItemProxy, TargetDependency). Схему TrafficVienna.xcscheme налаштовано з TestTargets. Тести запускаються через `xcodebuild test -scheme TrafficViennaTests`. 9/9 passed.
- **🔴 Quick Action** — `"favorites"` → `"favourites"` (Tab raw value тепер збігається).
- **🟡 `walkingSpeed`** — прибрано `private`, тепер `internal`. Хардкоди `80` замінено на `walkingSpeed` у StationCardView + NearbyViewModel.
- **🟡 NearbyView polling** — замінено 5-секундний poll на 30с (немає локації) / 15с (пусто) / 60с (норма).
- **🟡 StationStore** — додано `@MainActor static let shared` для Siri intent. DepartureIntent більше не декодує JSON при кожному виклику.
- **🟡 Force-unwrap** — `mapsURL` тепер `URL?` з `if let` в StationDetailView. AboutView — `URL(string:)` з `??` fallback.
- **🟡 Переклади** — додано 17 німецьких перекладів у Localizable.xcstrings.
- **🟡 Схема** — очищено мертві посилання з xcschememanagement.plist.
- **Збірка**: 0 помилок, 0 попереджень.
- **Команда для тестів**: `xcodebuild test -scheme TrafficViennaTests -project TrafficVienna.xcodeproj -destination 'platform=iOS Simulator,name=iPhone 17'`

## 2026-06-28 — Final round: features + perfection (notifications, Quick Actions, DI, search)

- **🔔 DepartureReminder** — контекстне меню "Notify me in N min" → `UNNotification` з `.timeSensitive`
- **⚡ Quick Actions** — long-press app icon → Search / Favourites / Nearby (через `UIApplicationShortcutItem` + `AppDelegate`)
- **📱 Dynamic Island** — minimal view → countdown (була статична іконка); expanded bottom → назва станції + напрямок
- **⌨️ SearchView** — `.toolbar` з `Button("Done")` на клавіатурі
- **🎭 Shimmer** — вимкнено при `UIAccessibility.isReduceMotionEnabled`
- **⏭️ Onboarding** — "Skip" на перших 2 сторінках (overlay topTrailing)
- **⭐ Favorites** — `.searchable` фільтр по `lineName` + `destination`
- **🚀 Launch screen** — `INFOPLIST_KEY_UILaunchScreen_ColorName = "wienerLinienRed"`
- **Warnings** — виправлено `@preconcurrency` + `[weak self]` в Task
- Збірка: 0 помилок, 0 попереджень.
- **Продукт готовий до релізу.**

## 2026-06-28 — UI/UX polish marathon (3 rounds of improvements)

- **🔥 Баги:**
  - `RootTabView`: `.constant(!hasOnboarded)` → `Binding(get:set:)` — онбординг тепер закривається
  - `SearchView`: `TapGesture` на `NavigationLink` → `onAppear` — навігація не ламається
  - `DepartureLineRow`: `missed` icon `figure.walk` → `nosign` (колірна сліпота)
- **🗺️ Карта:**
  - DragIndicator на sheet
  - Open in Maps в тулбарі StationDetailView
  - `accessibilityHint` на маркери
- **🔍 Пошук:**
  - Підсвітка тексту пошуку жирним
  - `.autocorrectionDisabled()`
  - `.onSubmit` ховає клавіатуру
  - Clear recents — confirmation alert
  - Анімація результатів `.animation(.default, value: results.map(\.id))`
- **📡 Мережа:**
  - `NetworkMonitor` (`NWPathMonitor`) — offline-банер "No connection" у RootTabView
  - `DisruptionsView` + `FavoritesView` error states — кнопка "Try again"
  - `NearbyView` error banner — tappable для retry
- **🕐 Час відправлення (HH:mm):**
  - `DepartureClock.formattedTime()` — formatter для ISO8601 → "12:47"
  - `DepartureGroup.times` — масив hh:mm, відсортований синхронно з minutes
  - `DepartureLineRow.nextTimeString` — показується під destination
  - StationDetailView ✅, StationCardView ✅, FavoritesView ✅
- **🔴 Live Activity:**
  - `stopAll()` + `isTracking` — кнопка `bell.slash` в тулбарі
  - Haptic feedback при старті
- **🔔 Alerts вкладка:**
  - Badge з кількістю збоїв
  - `.searchable` фільтр за номером лінії
  - ShareLink в контекстному меню
- **🧑‍🦯 Accessibility:**
  - FilterChips: `.accessibilityAddTraits(.isSelected)`
  - DisruptionRow: `.accessibilityHint` для expand
  - LivePulse: `.accessibilityHidden`
- **💄 Onboarding:**
  - 3-сторінковий TabView з page dots
  - Анімовані кнопки Next / Get started
- **Інше:**
  - StationDetailView: `ContentUnavailableView` + retry action
  - StationDetailView: `ShareLink` + `accessibilityLabel` на refresh
  - StationDetailView: ScrollViewReader — scrollTo top при зміні фільтра
  - FavoritesView lines: hh:mm час
  - `DepartureInfo.formattedTime` computed property
- Збірка: 0 помилок, 0 попереджень.

## 2026-06-28 — More polish (dead code, AppIntent, walking, locale, battery)

- **🗑 Dead code:** Видалено `WidgetCacheEnvelope` (не використовувався)
- **🧹 DRY:** `AppIntent.swift` — замінено власний `Stored` struct + ручне декодування на `UserDefaultsFavoritesRepository().getAll()`
- **🧹 DRY:** Створено `Model/Walking.swift` — `CLLocation.walkMinutes(to:)` замість дубльованої формули `distance/80` у SearchView + FavoritesView
- **🧹 StationStore:** `locale: .current` → `Locale(identifier: "de_DE")` (стабільна поведінка діакритики)
- **💄 `FavoriteRoute`:** додано `Identifiable` + `var id: String`
- **💄 LocationManager:** `startUpdatingLocation()` → `requestLocation()` (single-shot, менше батареї)

## 2026-06-28 — Major code improvements (bugs, DRY, polish)

- **🐛 Баги:**
  - `FavoritesView`: `lat/lon ?? 0` → Vienna centre fallback (48.2082, 16.3738)
  - `MonitorService.trafficInfoList`: додано coalescing (був відсутній, на відміну від `fetchCoalesced` для DIVA)
  - `LiveActivityController`: `print()` → `os.Logger`
- **🧹 DRY:**
  - Додано `Model/DTO.swift`, `Model/FavoritesManager.swift`, `Model/NetworkManager.swift`, `View/Components/LineStyle.swift` до widget target через pbxproj exceptions — видалено 100+ рядків дубльованих DTO, `FavoriteRoute`, `fetchMonitorData`, `WidgetLineBadge` з `TrafficViennaWidget.swift`
  - Створено `FilterChips` (View/Components/FilterChips.swift) — shared компонент для StationDetailView + DisruptionsView
  - `Color.wienerLinienRed` — спільна константа замість хардкоду `Color(hex: 0xE20917)` у 7 місцях
- **💄 Поліпшення:**
  - `LineCategory.symbol`: metro → `subway.fill` (був `tram.fill`)
  - `LocationManager`: `DispatchQueue.main.async` → `nonisolated` + `Task { @MainActor }`
  - `Shimmer`: `Color.white.opacity(0.55)` → `Color.primary.opacity(0.12)` (адаптивний до теми)
  - `RecentSearchesStore`: `UserDefaults.standard` → App Group `UserDefaults(suiteName:)`
- Збірка: чиста, 0 помилок, 0 попереджень.

## 2026-06-28 — Fix build, clean scheme

- Виправлено `StationStore.swift:55` — обгорнуто `Self.loadBundledStations` у замикання (default parameter не інферувався як () → [Station]).
- Виправлено `MapStationsView.swift:58` — `if let banner = locationBanner` замінено на пряме використання (`@ViewBuilder` повертає non-optional `some View`).
- Видалено мертвий `TestableReference` зі схеми (TrafficViennaTests target був відсутній у pbxproj, але scheme на нього посилався).
- Збірка чиста: 0 помилок, 0 попереджень.
- Тести через `xcodebuild test` поки не запускаються — target не додано до проєкту; файл `TrafficViennaTests.swift` існує, але не скомпільовано.

## 2026-06-28 — Initial workspace setup

- Налаштовано каркас «мозок агента»: AGENTS.md, docs/CONTEXT.md, docs/REFERENCES.md, memory/JOURNAL.md, memory/DECISIONS.md, opencode.json.
- Проєкт: TrafficVienna — iOS-застосунок для live-відправлень Wiener Linien (SwiftUI + MVVM).
- Стан: A (готовий Xcode-проєкт).
- Збірка: не компілюється — `StationStore.swift:55` помилка (default argument не працює як closure reference).
- Структура: 5 табів (Nearby, Search, Map, Alerts, Favourites), 16 файлів Model, 11 файлів View, WidgetExtension, Unit Tests.
- Чекаю напрямку від Івана.

## 2026-06-28 — UI/UX поліш та рефайн

### Зроблено
- **LineBadge** тепер використовує офіційні кольори Wiener Linien замість `.appGreen` (U1=red, U2=purple, U3=orange, U4=green, U6=brown, tram=red, bus=blue, etc.)
- **DepartureLineRow** використовує `LineBadge` замість inline `[U1]` — кольорові бейджі на всіх екранах
- **"NOW"** — зелений капсульний бейдж замість plain тексту
- **StationCardView** — показує `+ N MORE` коли ліній більше ніж 4
- **FilterChips** — вибраний чіп отримує колір категорії (U-Bahn=blue, Tram=red, etc.), білий текст
- **Tab bar** — повернуто SF Symbols (стандартний iOS UX)
- **Navigation bar** — повернуто `.navigationTitle` + `.toolbar` з SF Symbols
- **Контекстні меню** — `Label` + `systemImage` (стандартний UX)
- **Стандартний back button** замість кастомного `< BACK`

### Рішення
- App має термінальний вайб (темна тема, зелений акцент, моношир), але використовує стандартні iOS патерни навігації
- Лінійні бейджі в офіційних кольорах замість суцільного зеленого — краща сканованість
- Кольори категорій у FilterChips допомагають швидко фільтрувати
- `+ N MORE` уникає перевантаження рядка в StationCardView
