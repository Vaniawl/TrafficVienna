# Backlog

## Requirement coverage

- [x] **REQ-TV-001 — Core journeys.** The four-tab shell, Discover search/map,
  Alerts, Saved, Station Detail, notification routing, widget, and Live Activity
  flows have automated coverage and Simulator inspection.
- [x] **REQ-TV-002 — Accessible design.** Shared visual hierarchy follows system
  light/dark appearance; key screens reflow at accessibility Dynamic Type sizes.
- [x] **REQ-TV-003 — Focused refactoring.** Changes stay within existing MVVM and
  protocol boundaries and address observed correctness/performance findings.
- [x] **REQ-TV-004 — Failure and localisation.** Stale departure guards, safe
  reminder errors, permission recovery, and German strings are implemented.
- [x] **REQ-TV-005 — Performance.** Requests remain coalesced/cancellable and
  formatter creation was removed from the widget body. Settled iPad Simulator
  sampling measured 0.0% CPU in five observations.
- [x] **REQ-TV-006 — Validation evidence.** App/widget build, 196 tests, static
  analysis, localisation extraction, repository validators, and diff checks
  pass. Hosted Quality run `30780429929` installed the pinned OpenCode CLI and
  completed the full `scripts/ci.sh` wrapper successfully on exact published head
  `740bb48d`; the live draft-PR check remains authoritative for every later
  documentation or workflow commit.
- [x] **REQ-TV-007 — Review-ready state.** Architecture/security findings and
  documentation are resolved; the reviewed branch is maintained in draft PR #15.
- [x] **REQ-TV-008 — Truthful system surfaces.** Reminders are local and
  user-created, stale data cannot start a new countdown, permission delay is
  revalidated, and ActivityKit state is restored across model recreation.
- [x] **REQ-TV-009 — Account-free boundary.** All transport features are
  anonymous; the obsolete optional-account plan is removed from active scope.

## Audit findings and fixes

- [x] Restore the active departure identity from system ActivityKit state before
  updating Station Detail.
- [x] Block new reminders and Live Activities when departures are stale while
  retaining the ability to stop an existing Activity.
- [x] Revalidate a reminder after the notification permission prompt so a
  now-expired plan is rejected.
- [x] Replace raw unexpected reminder errors with safe localised feedback.
- [x] Coalesce repeated reminders for the same station, line, and destination,
  while removing matching legacy duplicates without touching other routes.
- [x] Clear precise coordinates when location authorization is revoked or reset,
  and make Map ignore stale coordinates whenever permission is not authorized.
- [x] Restrict sample widget departures to Widget Gallery previews; an empty
  runtime snapshot now renders the existing truthful empty state.
- [x] Coalesce Saved reloads that overlap an in-flight request, preserve a queued
  forced refresh, and prevent an obsolete route snapshot from reaching UI or the
  widget after the repository changes.
- [x] Serialize a targeted Saved-row retry with the full reload owner so an older
  polling result cannot overwrite its forced response; coalesce duplicate work
  and discard a queued retry when the owner is cancelled.
- [x] Preserve manual force-refresh intent when Station Detail or Alerts polling
  is already active, suppress the obsolete pass, and drop queued work on
  cancellation.
- [x] Preserve forced-refresh intent at the shared `MonitorService` boundary:
  forced station and traffic-info callers behind regular work receive one serial
  successor, equivalent forced callers coalesce, failed regular work cannot
  suppress the successor, and generation-guarded cleanup preserves its cache.
- [x] Serialize Nearby refresh ownership, preserve a queued manual force refresh,
  and hand the latest location request to a surviving caller when SwiftUI cancels
  the previous location task.
- [x] Give every tab an owned navigation path so warm Siri, Shortcuts, widget, and
  deep-link destinations reset only their target stack; notification routing
  replaces Discover with the requested station while ordinary tab changes retain
  navigation history.
- [x] Separate each widget row's countdown projection anchor from the underlying
  transport-source timestamp, preserve the oldest visible freshness across mixed
  cached/live rows, and keep old and rollback payload decoders compatible.
- [x] Serialize ActivityKit updates and ends per system Activity ID so refresh,
  replacement, expiry, and user stop preserve submission order without blocking
  unrelated activities.
- [x] Make ActivityKit end terminal from submission: reject later updates and
  restoration for an ending Activity ID, preserve explicit Station Detail stop
  intent across an in-flight refresh, and clear local tracking after a system end.
- [x] Give reminder management one MainActor state owner, serialize overlapping
  system snapshots, and fence delete/cancel-all so an older snapshot cannot
  restore a removed reminder.
- [x] Scope widget fetch throttling to the canonical selected-route set so one
  widget configuration cannot suppress another configuration's first refresh,
  while empty configurations consume no refresh budget.
- [x] Schedule timeline boundaries for all three departures that widget layouts
  can render, so the third countdown is removed on time instead of lingering at
  zero until the five-minute network refresh.
- [x] Evaluate departure and removal boundaries independently so a cached
  departure already showing `now` still disappears at its future removal entry.
- [x] Replace Home's indefinite authorized-location placeholder with an explicit
  retry state, clear it when a new request starts, and preserve useful retained
  coordinates during a transient refresh failure.
- [x] Reconcile Station Detail station and route favourites from repository truth
  after local toggles and cross-tab change notifications instead of inverting a
  potentially stale cached set.
- [x] Make destructive Saved-route deletion idempotent so a stale visible row
  cannot toggle an already-removed route back into persistence or the widget.
- [x] Keep the Live Activity UI journey meaningful overnight by using the
  24-hour Schwedenplatz hub while retaining independent Stephansplatz search and
  notification-routing coverage.
- [x] Move relative-time formatting out of the widget render body.
- [x] Let reminder destinations/stops grow at accessibility Dynamic Type sizes.
- [x] Add focused regression coverage for each behavioral change.
- [x] Add German catalogue values for new feedback.

## Product inspection

- [x] Exercise Home, Discover, Map, Alerts, Saved, About, reminder management,
  Station Detail, context actions, and reminder failure feedback on iPhone 17.
- [x] Inspect representative Home/About/reminder surfaces in dark appearance and
  accessibility Dynamic Type.
- [x] Inspect adaptive Home layout on a 13-inch iPad Simulator.
- [x] Capture final Home, Station Detail, reminder-management, accessibility, and
  iPad screenshots.
- [x] Reproduce the warm external-route stack defect and capture inspected
  before/after iPhone 17 screenshots proving the Discover-root reset.
- [x] Reproduce the stale-widget freshness defect with a legacy App Group payload
  and capture Home Screen screenshots proving that the corrected widget reports
  source age without breaking its live countdown.
- [x] Capture and inspect the current empty-selection small widget on iPhone 17.
- [x] Capture and inspect a live small widget showing three real N38 countdowns
  after the visible-departure scheduling fix.
- [x] Capture a controlled cached departure showing `now`, observe its removal
  34 seconds later before network refresh, and restore live N38 data afterward.
- [x] Capture paired Schwedenplatz Station Detail screenshots before and after a
  Saved-tab removal, proving the preserved Discover stack clears its stale star.
- [x] Capture and inspect Home's location retry state in light and dark appearance
  plus the recovered live departures after a successful Vienna location request.

## Final validation and handoff

- [x] Full iPhone 17 build and test suite: 191 model/service + 5 UI tests.
- [x] Static analyzer and repository/OpenCode structural validators.
- [x] English/German compiler-extraction catalogue comparison.
- [x] `git diff --check`, security scan, and changed-file review.
- [x] Synchronize `STATUS.md`, root/memory journals, and architectural decisions.
- [x] Run `bash scripts/ci.sh` with the required OpenCode runtime: hosted
  Quality run `30780429929` passed exact published head `740bb48d` in 16m00s.
  The local host still lacks that global CLI, so local wrapper attempts stop at
  the permission matcher and the live protected PR check remains authoritative
  after any later publication.
- [x] Commit reviewed paths, push `codex/system-surfaces-readiness`, and open
  draft PR #15.

## External release acceptance

- [ ] Produce a signed App Store distribution archive with authorized credentials.
- [ ] Process the build in App Store Connect and complete metadata/privacy review.
- [ ] Exercise notifications, widgets, Dynamic Island/Live Activity lifecycle,
  and background behavior through signed physical-device TestFlight acceptance.

These external items gate App Store submission, not completion of the local audit
or draft-PR handoff.
