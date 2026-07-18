# Backlog

## Workflow baseline

- [x] Use the global orchestrator, specialist agents, and local model routing.
- [x] Remove obsolete project-local agents, plugins, and Git/PR automation.
- [x] Create the project-specific Markdown state baseline.
- [x] Verify global OpenCode inheritance and permissions.

## Requirement coverage

- [ ] **REQ-TV-001:** preserve and regression-test core journeys through the
  Phase 2 screen slices and TV-VERIFY-031/032.
- [ ] **REQ-TV-002:** complete the shared visual foundation and accessible design
  through TV-UI-001/002 and all Phase 2 slices.
- [ ] **REQ-TV-003:** perform only evidence-backed refactoring through TV-CORE-020.
- [ ] **REQ-TV-004:** complete localised loading, empty, error, retry, and stale
  states through Phase 2 and TV-CORE-021.
- [ ] **REQ-TV-005:** verify cancellation, refresh, throttling, and performance
  through TV-CORE-022.
- [ ] **REQ-TV-006:** collect fresh repository, build, test, widget, UI, and
  accessibility evidence through TV-VERIFY-030/031/032.
- [ ] **REQ-TV-007:** synchronize state and clear independent reviews through
  TV-VERIFY-033/034.
- [ ] **REQ-TV-008:** finish the minimalist redesign, single design identity, and
  evidence-backed favourites improvement through TV-UI-002 and Phase 2.
- [ ] **REQ-TV-009:** implement optional Apple/email accounts after a real email
  identity provider is selected; anonymous transport use must remain available.

## Phase 1 - Recover the shared visual foundation

- [x] **TV-UI-001 - Remove selectable designs and conflicting theme ownership.**
  - Outcome: one adaptive Vienna-red design system follows the device appearance;
    `ThemeEngine`, presets, and the appearance picker are gone.
  - Paths: design token files, `AppColors.swift`, `TrafficViennaApp.swift`.
  - Dependencies: none.
  - Acceptance: no runtime theme/preset owner or design picker remains.
  - Validation: source search, warning-free build, and changed-file reread on
    2026-07-18.
- [x] **TV-UI-002 - Validate appearance behaviour.**
  - Outcome: the single design adapts to system light/dark without user presets.
  - Paths: `RootTabView.swift`, onboarding, design tokens, and affected previews.
  - Dependencies: TV-UI-001.
  - Acceptance: light/dark simulator runs are readable; labels are localised and
    motion respects Reduce Motion.
  - Validation: warning-free build, 27 tests, and light/dark iPhone 17 screenshots.

## Phase 2 - Redesign complete user journeys

- [x] **TV-UI-010 - Nearby journey.**
  - Outcome: clear location/loading/error/empty states and scannable nearby
    station cards with consistent hierarchy.
  - Paths: `NearbyView.swift`, `StationCardView.swift`, related view model/tests.
  - Dependencies: TV-UI-002.
  - Acceptance: location denied and successful station loading are both usable;
    Dynamic Type and VoiceOver do not hide essential data.
  - Validation: focused tests plus simulator accessibility inspection.
- [ ] **TV-UI-011 - Search journey.**
  - Outcome: fast, minimal search with clear idle, no-result, failure, and result
    states.
  - Paths: `SearchView.swift`, its view model and focused tests.
  - Dependencies: TV-UI-002.
  - Acceptance: search, cancellation, selection, retry, and empty result work.
  - Validation: focused tests plus simulator inspection.
  - Completed implementation: explicit idle/loading/searching/results/no-results/
    unavailable states, cancellable debounce, catalogue retry, modern value
    navigation, accessible rows, recent persistence/clear, and German strings.
  - Evidence: nine focused tests and full CI pass; total XCTest count is 43.
  - Pending acceptance: interactive light/dark and accessibility-size Simulator
    inspection after the locked macOS host is available.
- [ ] **TV-UI-012 - Map journey.**
  - Outcome: stations, selection, and navigation remain readable without visual
    clutter or redundant requests.
  - Paths: `MapStationsView.swift` and related map/view-model tests.
  - Dependencies: TV-UI-002.
  - Acceptance: loading, permission failure, annotation selection, and station
    navigation work.
  - Completed implementation: bounded nearest-marker state model, Vienna-centre
    fallback, catalogue loading/empty/failure/retry, permission/denied/locating/
    error banners, accessible selection card, haptics, reduced motion, and value
    navigation to departures.
  - Evidence: six focused tests, embedded German/English permission rationales,
    and full CI pass; total XCTest count is 49.
  - Pending acceptance: interactive light/dark and accessibility-size Simulator
    inspection after the locked macOS host is available.
- [ ] **TV-UI-013 - Disruptions journey.**
  - Outcome: alerts are grouped and prioritised with understandable empty/error
    states.
  - Paths: `DisruptionsView.swift`, `DisruptionRow.swift`, related tests.
  - Dependencies: TV-UI-002.
  - Acceptance: severity, affected lines, details, retry, and empty state remain
    understandable with accessibility labels.
  - Completed implementation: official feed categories split service,
    accessibility, and stop-change information; service alerts drive the badge,
    exact duplicates are removed, and line/search filters, details, explicit
    loading/empty/failure/stale-refresh states, and German strings are present.
  - Evidence: seven focused view-model tests, three feed/cache regressions,
    warning-free full CI, and 60 passing XCTest cases. Security review found no
    unresolved Blocking or Important issue.
  - Pending acceptance: interactive light/dark and accessibility-size Simulator
    inspection after the locked macOS host is available.
- [ ] **TV-UI-014 - Favourites journey and product audit.**
  - Outcome: preserve the existing multiple-station collection and add only the
    missing quick-switch interaction proven useful by code and flow discovery.
  - Paths: `FavoritesView.swift`, `FavoritesListViewModel.swift`, related tests.
  - Dependencies: TV-UI-002.
  - Acceptance: add, remove, reorder, select, and quick-switch behaviour is
    explicit; no duplicate storage model is introduced.
  - Completed implementation: preserved the two existing repositories and Nearby
    quick access; added stable route identity/order, tested station reorder/remove,
    per-route unavailable/retry, forced refresh, cancellable polling, modern
    station navigation, and widget exclusion for failed route data.
  - Evidence: five focused tests and warning-free full CI with 65 passing XCTest
    cases. Security review found no unresolved Blocking or Important issue.
  - Pending acceptance: interactive add/select/quick-switch, light/dark, and
    accessibility-size Simulator inspection after the locked host is available.
- [ ] **TV-UI-015 - Station detail journey.**
  - Outcome: departures, line information, favourites, Live Activity, and errors
    form one coherent detail screen.
  - Paths: `StationDetailView.swift`, `DepartureLineRow.swift`, related models/tests.
  - Dependencies: TV-UI-010 through TV-UI-014 where shared navigation applies.
  - Acceptance: all current actions remain reachable with loading/error feedback.
  - Completed implementation: explicit loading/loaded/empty/initial-failure and
    stale-refresh states, deterministic platform merging, transport filters,
    navigable alerts, reactive station/route favourites, automatic freshness,
    and discoverable Live Activity start with success/failure feedback.
  - Correctness fix: Station Detail no longer overwrites the favourites widget
    with an arbitrary first line from the current station.
  - Evidence: nine focused tests, warning-free full CI, and 74 passing XCTest
    cases. SwiftUI/security review found no unresolved Blocking or Important issue.
  - Pending acceptance: interactive refresh/filter/favourite/Live Activity,
    light/dark, and accessibility-size Simulator inspection after unlock.
- [ ] **TV-UI-016 - Onboarding, settings, and secondary surfaces.**
  - Outcome: onboarding, account/settings, About, widget, and secondary views
    use the same design language without changing product boundaries.
  - Paths: the corresponding SwiftUI views, widget views, assets, localisations.
  - Dependencies: TV-UI-002.
  - Acceptance: no old visual tokens, hard-coded user strings, or inaccessible
    controls remain in active secondary flows.
  - Completed implementation: onboarding and About use the shared adaptive
    design tokens and Dynamic Type; onboarding scrolls at accessibility sizes;
    the app and widget share one deterministic favourite-route model; the widget
    renders the decoded station name, uses safe relative dates, and has a complete
    embedded German catalogue.
  - Evidence: focused route-order regression, localisation/build inspection,
    warning-free full CI, and 75 passing XCTest cases. Security review found no
    unresolved Blocking or Important issue.
  - Pending acceptance: interactive onboarding/account/About/widget inspection
    after the locked macOS host is available.

- [ ] **TV-UI-017 - Optional account access.**
  - Outcome: anonymous use plus native Apple and email account entry with secure
    lifecycle handling.
  - Dependency: explicit email identity provider/backend selection.
  - Completed slice: native Apple entry, minimal device-only Keychain profile,
    restore, cancellation, failure, sign-out, and authorized/revoked/transferred
    credential handling with focused tests. Anonymous use remains unchanged.
  - Pending slice: real email authentication, server session validation, and
    remote delete-account behaviour after provider selection.
  - Acceptance: sign-in, cancellation, failure, restore, sign-out, revocation,
    and delete-account paths are real and tested; no local fake authentication.

## Phase 3 - Focused refactoring and resilience

- [ ] **TV-CORE-020 - Remove proven duplication and dead references.**
  - Outcome: shared UI and state ownership are clear without speculative layers.
  - Paths: only files identified by completed journey work.
  - Dependencies: affected Phase 2 slice.
  - Acceptance: each refactor has a behavioural reason and focused regression test.
  - Validation: focused tests and full `bash scripts/test.sh`.
- [ ] **TV-CORE-021 - Localisation and accessibility audit.**
  - Outcome: user-facing text is localisable; Dynamic Type, VoiceOver, contrast,
    and reduced motion are supported across completed journeys.
  - Paths: views, localisation resources, accessibility tests.
  - Dependencies: Phase 2.
  - Acceptance: no required screen has clipped text or unlabeled controls.
  - Validation: localisation scan and simulator accessibility inspection.
- [ ] **TV-CORE-022 - Refresh and network lifecycle.**
  - Outcome: refresh work cancels correctly, avoids duplicate calls, and handles
    throttling and stale data clearly.
  - Paths: view models, `MonitorService`, network boundary, focused tests.
  - Dependencies: Phase 2 discovery.
  - Acceptance: cancellation, coalescing, throttling, and stale-data tests pass.
  - Validation: focused tests and reproducible timing evidence where applicable.
- [ ] **TV-CORE-023 - Add dependency injection testability**
  - Outcome: enable unit testing of view models and services by injecting mock
    `NetworkManaging` and `MonitorService` instances.
  - Paths: view models (`NearbyViewModel.swift`, `StationDetailViewModel.swift`, etc.) and services (`MonitorService.swift`).
  - Dependencies: Phase 2 journeys.
  - Acceptance: view models accept injected dependencies via initializer; tests can supply mocks without compile errors.
  - Validation: compile with mock implementations; no runtime failures.

## Phase 4 - Verification and handoff

- [x] **TV-VERIFY-030 - Server-side checks.** Run and record
  `git diff --check`, `bash scripts/validate-repository.sh`, and
  `bash scripts/validate-opencode.sh` after each coherent batch. Last run:
  2026-07-18, all exited 0.
- [x] **TV-VERIFY-031 - macOS build and tests.** Run `bash scripts/ci.sh` on a
  suitable macOS/Xcode host, including the app and widget targets.
  - Evidence: full CI exited 0 on iPhone 17 simulator; app/widget build succeeded,
    the post-hardening focused run passed, and all 74 XCTest cases pass.
- [ ] **TV-VERIFY-032 - Product inspection.** Exercise every Phase 2 journey in
  light/dark appearance, accessibility text sizes, and relevant failure states.
- [ ] **TV-VERIFY-033 - Independent reviews.** Resolve every Blocking/Important
  reviewer and security-reviewer finding, then rerun affected checks.
- [ ] **TV-VERIFY-034 - State synchronization.** Make `PROJECT.md`, `SPEC.md`,
  `BACKLOG.md`, `STATUS.md`, `CHECKS.md`, `DECISIONS.md`, `JOURNAL.md`, and
  `SECURITY.md` agree with observed evidence.

## Completion

- [ ] Every requested requirement has fresh evidence in `JOURNAL.md` and its
  executable backlog item is checked only after that evidence exists.
- [ ] No mandatory check is skipped or masked.
- [ ] No required TODO, placeholder, broken flow, or unresolved important finding
  remains.
- [ ] `STATUS.md` is `COMPLETE` only after the preceding items pass.
