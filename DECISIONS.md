# Decisions

## 2026-08-03 - Root audit state is conditional and validated

The tracked root audit set (`PROJECT.md`, `SPEC.md`, `STATUS.md`, `BACKLOG.md`,
`CHECKS.md`, `RESTRICTIONS.md`, `SECURITY.md`, `DECISIONS.md`, and `JOURNAL.md`)
supplements durable memory and the reusable `docs/opencode/` workflow contract.
Broad product, audit, and release work reads the set as a group; narrow tasks load
only relevant root artifacts so short runs do not inherit unnecessary context.

OpenCode structural validation requires every registered artifact, the routing rule in
`AGENTS.md`, and its entry in `docs/opencode/state-files.md`. Observed source,
command, rendered, and external-service evidence remains authoritative over an
older narrative snapshot. Rollback is a normal revert with no app migration.

## 2026-08-03 - Forced refresh intent survives shared service coalescing

Each `MonitorService` in-flight station or traffic-info request carries its
regular/forced intent and a generation. Regular callers may reuse active network
work; forced callers reuse equivalent forced work. A forced caller behind regular
work waits without cancelling existing callers, then starts or joins exactly one
serial forced successor even when the regular request failed.

The tracked task publishes its cache before resolving. Cleanup clears an entry
only when its generation still matches, preventing an older waiter from deleting
a newer successor. Existing throttle, retry, stale fallback, endpoints, public
provider protocols, and storage remain unchanged.

## 2026-08-02 - Widget projection time is not source freshness

Widget rows persist two compatible timestamps with separate ownership. `fetchedAt`
is the anchor for projecting minute countdowns between WidgetKit entries;
`dataUpdatedAt` is the MonitorService or widget-network source time shown to the
user. The optional source field preserves decoding of existing App Group payloads,
and older widget binaries ignore it while continuing to use `fetchedAt`.

For multiple visible rows, freshness is the oldest available per-row source so a
single cached route cannot be hidden behind newer data. A legacy row falls back to
its projection anchor, then to the existing global timestamp only when required.
No eager migration or new App Group key is needed. App and widget producers both
write the projection anchor, current network responses also write source time,
and app sync propagates the MonitorService snapshot time. Rollback is a normal
revert; the additional JSON field is safely ignored.

## 2026-08-02 - External destinations reset only their owned navigation stack

Each top-level tab owns a bound `NavigationPath` at the root. Ordinary tab
selection changes only the selected tab and preserves every path. An external
Home, Discover, or Saved destination clears its target path before selection,
without discarding navigation history in unrelated tabs. A notification station
route replaces the Discover path with exactly the resolved station, or the
Discover root when the station is unavailable.

Value-based links represent all root-relevant Home and Discover pushes in those
paths. This keeps Siri, Shortcuts, widgets, deep links, and local notifications
deterministic during warm and cold launch without adding a global coordinator or
changing the validated URL grammar. Path state remains transient and rollback is
a normal revert with no migration.

## 2026-08-02 - System countdowns require current departures

Departure reminders and new Live Activities may start only from a successful
current Station Detail snapshot. A stale fallback remains readable, but the app
asks the user to refresh before creating a new system countdown. Stopping an
already active Live Activity remains available during stale-data fallback.

ActivityKit is authoritative for active tracking across view-model recreation:
Station Detail restores the matching system activity identity before updating it.
Reminder plans are revalidated after a potentially long notification permission
prompt so an expired plan cannot be scheduled as an immediate misleading alert.

## 2026-07-18 - Map derives bounded markers and keeps location ephemeral

Map rendering consumes a bounded, distance-sorted station projection from an
injectable view model rather than recomputing it in SwiftUI `body`. Catalogue and
location states are explicit. Without permission or a valid fix, the map remains
useful around Vienna centre and explains the fallback instead of blocking use.

Precise location remains ephemeral: it is used in memory for local station
filtering and the system user annotation, and is neither persisted nor logged.
The permission rationale is localized in `InfoPlist.xcstrings`. Marker selection
uses an accessible material card and explicit value navigation to departures.

## 2026-07-18 - Search owns a cancellable view model and local catalogue state

Search query state, debouncing, results, retry, and recent-history projection are
owned by an injectable `SearchViewModel`; the SwiftUI view only renders states and
routes selected `Station` values. The local `StationStore` exposes a minimal
loading/loaded/failed state plus reload so a missing or invalid bundled catalogue
is visible and recoverable instead of silently becoming an empty search.

Filtering remains local and anonymous. Recent station identifiers remain in the
existing App Group defaults because they are non-sensitive UI history, while the
store protocol makes ordering, limits, persistence, and clearing testable.

## 2026-07-18 - Store only a minimal device-local Apple profile (superseded)

This historical decision was superseded on 2026-07-29. The optional Apple UI,
session model, tests, and entitlement were removed because they unlocked no
cross-device feature and expanded signing/account obligations. A bounded,
idempotent launch migration deletes only the known legacy Keychain item. The
current release is anonymous and account-free.

## 2026-07-18 - One adaptive visual identity; accounts require a real identity boundary

TrafficVienna uses one minimalist Vienna-red visual system and follows the
device's light/dark appearance. Runtime accent presets and user-selectable design
themes are removed because they fragment hierarchy, complicate testing, and now
conflict with the explicit product request.

All transport data and local favourites work without registration. Do not
represent `UserDefaults`, a locally stored email, or an unverified token as
authentication. Identity may return only for an approved cross-device feature
with a real backend/provider, secure token validation, migration, and complete
sign-out/delete-account behaviour.

## 2026-07-16 - Use native OpenCode with a repository-local contract

TrafficVienna uses OpenCode as the native agent engine without a custom
orchestrator runtime. Repository-local configuration, agent roles, permissions,
skills, workflow docs, state rules, and reliability tests define project
behaviour; the configured global local-model provider supplies execution. Pinned
hosted Quality remains authoritative for the complete runtime validation.

## 2026-07-16 - Local implementation with explicit Git boundaries

Autonomous work may read and edit the active workspace and run defined local
checks. Local feature branches and commits must contain only task-owned files.
Completed work is handed off by pushing the `codex/*` branch and creating or
updating a draft PR. Direct `main` pushes, force pushes, merge, ready-for-review,
release, deployment, and production-infrastructure changes remain prohibited
without explicit approval. Durable `memory/`, the conditional root audit set,
and `docs/opencode/` have the ownership recorded in the state-file contract.

## 2026-07-17 - Native conversational workflow

Agents infer technical acceptance criteria from evidence and ask the user only
about material product ambiguity. A direct request to build, redesign, refactor,
fix, or continue authorizes routine local implementation. Project Markdown
preserves context and progress but does not act as an authorization database.

## 2026-07-17 - Adopt minimalist UI redesign and new feature set (superseded)

The user requested a clean, minimalist visual style with a unified colour
palette and consistent typography, plus multi-favourite selection and an
explicit theme mode control. Preserve core journeys and MVVM boundaries; deliver
the work as small, testable product slices.

Superseded on 2026-07-18 by the user's request to remove design selection.

## 2026-07-17 - Use one runtime theme owner (superseded)

`TrafficViennaApp` owns and injects one `ThemeEngine`. It persists appearance
mode and accent preset. Views consume semantic SwiftUI colours and the shared
environment instead of polling `UITraitCollection` or creating local theme
singletons. Obsolete theme owners and empty compatibility files are removed.

Superseded on 2026-07-18: runtime theme ownership was removed entirely.

## Existing product architecture

Preserve SwiftUI, async/await, the MVVM-style view/view-model split,
`MonitorService` actor, protocol-based network boundary, and shared widget logic
unless discovery proves a concrete reason to change them and the current plan
records the migration and regression coverage.
