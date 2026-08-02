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
- [x] **REQ-TV-006 — Validation evidence.** App/widget build, 163 tests, static
  analysis, localisation extraction, repository validators, and diff checks
  pass. Hosted Quality run `30761690349` installed the pinned OpenCode CLI and
  completed the previously published full `scripts/ci.sh` wrapper successfully;
  every new published commit still requires its own protected run.
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
- [x] Preserve manual force-refresh intent when Station Detail or Alerts polling
  is already active, suppress the obsolete pass, and drop queued work on
  cancellation.
- [x] Serialize Nearby refresh ownership, preserve a queued manual force refresh,
  and hand the latest location request to a surviving caller when SwiftUI cancels
  the previous location task.
- [x] Give every tab an owned navigation path so warm Siri, Shortcuts, widget, and
  deep-link destinations reset only their target stack; notification routing
  replaces Discover with the requested station while ordinary tab changes retain
  navigation history.
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

## Final validation and handoff

- [x] Full iPhone 17 build and test suite: 159 model/service + 4 UI tests.
- [x] Static analyzer and repository/OpenCode structural validators.
- [x] English/German compiler-extraction catalogue comparison.
- [x] `git diff --check`, security scan, and changed-file review.
- [x] Synchronize `STATUS.md`, root/memory journals, and architectural decisions.
- [x] Run `bash scripts/ci.sh` with the required OpenCode runtime: hosted
  Quality run `30761690349` passed the previously published baseline.
  The local host still lacks that global CLI, so local wrapper attempts stop at
  the permission matcher and protected CI remains authoritative after publication.
- [x] Commit reviewed paths, push `codex/system-surfaces-readiness`, and open
  draft PR #15.

## External release acceptance

- [ ] Produce a signed App Store distribution archive with authorized credentials.
- [ ] Process the build in App Store Connect and complete metadata/privacy review.
- [ ] Exercise notifications, widgets, Dynamic Island/Live Activity lifecycle,
  and background behavior through signed physical-device TestFlight acceptance.

These external items gate App Store submission, not completion of the local audit
or draft-PR handoff.
