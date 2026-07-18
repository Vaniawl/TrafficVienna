# Architectural Decisions

## 2026-07-18 — Motion is shared, purposeful, and accessibility-aware

**Context:** The redesigned journeys mixed local `.snappy`, `.smooth`, linear,
and repeating animations. Live countdown, pulse, and shimmer motion did not all
respond to Reduce Motion, and screen-state transitions lacked one visual rhythm.

**Decision:** Keep four shared animation timings plus reusable state/edge
transitions in `Motion.swift`. Use movement and subtle scale only for spatial
changes; use stable identities for state replacement. When Reduce Motion is on,
remove displacement, scale, pulse, shimmer, and numeric rolling, falling back to
static content or opacity where the state change still needs visual continuity.

**Consequences:** Onboarding, Search, Alerts, Map, offline status, and live
departures share a restrained interaction rhythm without a third-party dependency.
Timing can be tuned centrally, while interactive acceptance remains required before
the motion work is considered visually complete.

## 2026-07-18 — Journey models depend on narrow runtime boundaries

**Context:** Search, Map, Alerts, Favourites, and Station Detail accepted test
boundaries, but Nearby retained concrete store, location, and monitor classes plus
legacy observation, leaving its most important load behaviour untestable.

**Decision:** Inject the smallest station, location, and monitor protocols into
Nearby and own its modern `@Observable` model with SwiftUI `@State`. Keep the real
`LocationManager` observed by the view so permission/location publications continue
to invalidate UI exactly as before.

**Consequences:** Every journey model can now run against focused mocks. Nearby's
location-free and freshness paths have regression coverage without introducing a
container, third-party dependency, coordinate persistence, or alternate runtime.

## 2026-07-18 — Cached transport data carries freshness provenance

**Context:** `MonitorService` could correctly retain usable data during a temporary
outage, but callers received a bare response and rendered it as newly refreshed.
Wall-clock sleeps also made throttle/backoff behaviour impractical to prove.

**Decision:** Return freshness-aware snapshots at the service protocol boundary,
including the last successful timestamp and stale flag, while keeping compatibility
methods for response-only callers. Drive request time through an injected scheduler
and label stale values with text and an icon in every live-departure journey.

**Consequences:** Saved data remains useful without masquerading as live, favourite
widget content survives a temporary outage, and spacing/backoff tests run instantly
and deterministically. Snapshots remain in memory and add no network or storage
boundary.

## 2026-07-18 — Alerts share the monitor request lifecycle

**Context:** Station monitor calls were cached, coalesced, throttled, retried, and
served stale on failure, but `trafficInfoList` bypassed those guarantees. The root
tab badge and Alerts screen could therefore duplicate a burst request.

**Decision:** Keep one in-flight traffic-info task inside `MonitorService`, claim
the same shared request slots, apply bounded rate-limit backoff, and retain only the
last successful in-memory alert list as failure fallback. Journey view models must
ignore responses after their caller task is cancelled.

**Consequences:** Badge and screen refreshes share one request, temporary outages
do not erase usable alert data, and departed screens cannot publish late state. UI
freshness provenance still requires a follow-up API rather than hidden inference.

## 2026-07-18 — App and widget share favourite-route identity

**Context:** App and widget had separate `FavoriteRoute` definitions and ordering,
while the widget rendered the numeric stop identifier as the station title.

**Decision:** Keep one Codable, Hashable, Comparable route value in
`WidgetShared/FavoriteRoute.swift`; both targets use its deterministic order. The
widget decodes the monitor response station title and localises its own strings in
an extension-owned catalogue.

**Consequences:** App and widget cannot silently drift in route identity or sort
order, refreshed widgets show a human-readable stop name, and the extension remains
independently localisable without adding a service or changing App Group scope.

## 2026-07-18 — Station Detail does not own widget content

**Context:** Every successful Station Detail refresh wrote its first returned line
to the shared widget payload, silently replacing the user’s favourite routes.
Refresh failure also replaced already visible departures with a full-screen error.

**Decision:** Keep widget synchronization exclusively in the Favourites boundary.
Project station responses into deterministic line/destination groups in a testable
observable model, retain visible data on refresh failure, and expose ActivityKit
start results as user feedback.

**Consequences:** Visiting a station cannot mutate unrelated widget preferences.
Departure state, filters, favourites, alert navigation, and Live Activity failure
paths are independently testable without adding a dependency or network endpoint.

## 2026-07-18 — Favourite failures stay local to each saved route

**Context:** A failed favourite request was converted into an empty departure row,
the top-level error state was unreachable, and UUID row identity changed on every
refresh.

**Decision:** Keep the existing station and route repositories, use the saved route
as stable row identity, expose availability per route, and exclude unavailable
routes from widget synchronization while keeping them visible for retry.

**Consequences:** One network failure no longer hides the collection or publishes
misleading widget data. Reorder/remove semantics remain owned by the existing
repositories and are independently testable.

## 2026-07-18 — Global alerts follow feed categories, not raw volume

**Context:** The Wiener Linien global feed mixes service disruptions, lift
outages, and hundreds of repeated stop-level notices. Rendering the response as
one list made the badge and service status misleading.

**Decision:** Decode the feed category, default to service disruptions, expose
accessibility and stop changes as explicit filters, and remove only exact content
duplicates. Cache successful alert responses in memory and surface refresh
failure while the view model retains its last visible data.

**Consequences:** The Alerts tab prioritises actionable service impact without
hiding other official information. No data is persisted and no transport API or
dependency changes are required.

## 2026-07-18 — Map projection is testable and location stays ephemeral

**Context:** Map recomputed marker distances in SwiftUI layout, hid catalogue
failure, and opened station sheets immediately on marker selection.

**Decision:** Derive a bounded nearest-marker projection in an injectable state
model, keep Vienna-centre fallback, and show a deliberate material selection card.
Use precise location only in memory and localize the system permission rationale.

**Consequences:** Loading, permission, failure, retry, marker order, selection,
and navigation are explicit without persisting or logging coordinates.

## 2026-07-18 — Search state belongs outside SwiftUI layout

**Context:** Search mixed local filtering, recent persistence, navigation, and
all rendering branches inside one view and silently treated catalogue failure as
no results.

**Decision:** Use an injectable observable Search view model and expose minimal
load/reload state from the local station catalogue. Keep filtering and recent
station history device-local.

**Consequences:** Debounce cancellation, retry, failure, result limits, and
recent ordering are independently testable without changing transport APIs.

## 2026-07-18 — Device-local Apple profile, not a server session

**Context:** Native Apple authentication can establish an Apple credential on
device, but the app has no account backend.

**Decision:** Store only Apple user ID, name, email, and provider in device-only
Keychain; never persist or log tokens. Validate credential state on launch and
clear revoked, missing, transferred, or unknown sessions. Keep anonymous use.

**Consequences:** Apple entry is real and testable without a dependency. Email,
cross-device identity, and remote account deletion wait for a selected provider.

## 2026-07-18 — Single design identity and truthful optional accounts

**Context:** The user asked to remove design selection and add Apple/email login.
The app had ten accent presets but no authentication backend.

**Decision:** Use one adaptive Vienna-red design system that follows system
light/dark. Keep anonymous transport use. Add account methods only behind a real
identity boundary; never treat a locally stored email as authentication.

**Consequences:** UI hierarchy and testing are simpler. Native Apple sign-in is
feasible, while email sign-in needs an explicit backend/provider decision.

## 2026-07-15 — Explicit OpenCode model assignment and state recovery contract

**Context:** The OpenCode workflow needs production-readable model ownership and recovery behavior. Relying on implicit/default model selection makes audits and recovery harder, and long-running autonomous work needs a deterministic state-file contract.

**Decision:** Assign every OpenCode agent an explicit model returned by `opencode models`; record the model inventory, context limits, rationale, and cost class in `docs/opencode/model-matrix.md`. Keep fallback models unconfigured until a verified OpenCode fallback field exists in local config tooling. Define repository-local state responsibilities and checkpoint schema in `docs/opencode/state-files.md`, and enforce the model/state/permission/recovery contract with `tests/opencode-reliability.sh` in CI.

**Consequences:** Agent model resolution is inspectable and testable. Recovery behavior now has explicit acceptance criteria and fixture coverage for valid, invalid, stale, interrupted, compacted, and timeout states. Future model or fallback changes must update both documentation and validation.

## 2026-07-15 — Sequential subagent execution by default

**Context:** The live autonomy audit proved that launching six subagents in parallel can stall the OpenCode run even when some subagents complete. The workflow needs predictable production behavior before broad parallelism.

**Decision:** Run subagents sequentially by default. Allow parallel execution only for 2-3 genuinely independent read-only tasks with documented independence, a 3-minute batch timeout, and automatic fallback to sequential execution for unfinished work. Never parallelize implementation, validation, commit, push, PR handoff, release, or deployment work.

**Consequences:** The MVP favors reliable autonomous completion over maximum concurrency. Parallelism remains available for small safe discovery batches, but stalls become recoverable workflow events instead of indefinite blockers.

## 2026-07-15 — Read-only shell search commands are routine OpenCode operations

**Context:** During the live autonomy audit, OpenCode generated a shell `rg` diagnostic for the controlled sentinel check. The command was read-only and repository-scoped, but it requested permission because only the OpenCode grep tool, not shell `grep`/`rg`, was allowed.

**Decision:** Allow repository-local read-only shell search patterns `grep *` and `rg *` for the orchestrator and root OpenCode configuration. Keep secret path deny rules, destructive commands, protected-branch pushes, force-push, merge, release, and deploy gates unchanged.

**Consequences:** Routine diagnostics and validation can continue without non-interactive permission dead-ends, while secret access and mutation boundaries remain protected.

## 2026-07-14 — OpenCode personal GitHub CLI permission shape

**Context:** Non-interactive OpenCode runs auto-reject permission prompts. The TrafficVienna workflow must use the isolated personal GitHub CLI context (`GH_CONFIG_DIR=/home/skyphoenix/.config/gh-personal`) for status, repository, draft PR, and PR update commands without falling back to the work account.

**Decision:** Allow exact safe personal `GH_CONFIG_DIR=... gh ...` status/repository/draft-PR command shapes and exact read-only compound discovery commands generated during the autonomy audit. Keep direct `main` pushes, force-push, merge, release, deploy, destructive commands, and secret reads denied or approval-gated.

**Consequences:** OpenCode can continue routine autonomous TrafficVienna work without permission dead-ends while preserving repository protection and identity separation.

## 2026-06-29 — Очищення та стандартизація до деплою

**Context:** Аналіз проекту виявив дубльований код, мертвий код, розбіжності в JOURNAL.md та неконсистентні патерни.

**Decisions:**
- **Logger:** `print()` → `os.Logger` з категоріями (`store`, `live-activity`, `favorites`, `location`, `widget-sync`). Локальні `private let log = Logger(...)` в кожному файлі.
- **RouteMatching** — єдине джерело правди для нормалізації напрямків. Видалено дубльовані `normalize()` у FavoritesListViewModel та TrafficViennaWidget.
- **WidgetSync** — видалено дубльований `enum WidgetSync`, залишено протокол `WidgetSyncing` + клас `WidgetSyncManager`.
- **WidgetShared** — додано LineColors.swift та RouteMatching.swift до widget target (через membershipExceptions у pbxproj). Видалено дубльовані `Color(hex:)`, `widgetLineColor()`, `WidgetLineBadge` з widget — тепер використовує `LineColors`.
- **RecentSearchesStore** — виправлено: `UserDefaults.standard` → App Group `UserDefaults(suiteName:)`. Додано graceful fallback.
- **LiveActivityController** — додано методи `update()` та `stopAll()`.
- **Walking speed** — хардкоди `80` у StationCardView та NearbyViewModel замінено на константу `walkingSpeed` з Walking.swift.
- **ConfigurationAppIntent** — видалено безглуздий параметр `favoriteEmoji`, виправлено опис.

**Consequences:**
- +1 файл (Logging.swift — але пізніше видалено на користь inline)
- -40 рядків дубльованого коду (normalize, WidgetCacheEnvelope, widget line colors)
- 0 помилок, 0 попереджень при збірці
- Всі normalization тепер консистентні (diacritic-insensitive, trailing " u"/" s" stripping)
