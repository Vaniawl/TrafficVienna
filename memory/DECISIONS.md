# Architectural Decisions

## 2026-08-11 — Deterministic UI acceptance remains a debug-only boundary

**Context:** Unit coverage did not prove complete onboarding, tab navigation, or
the release screenshots. The committed screenshots showed a superseded design,
two local Simulators shared the documented `iPhone 17` name, and live-data capture
could expose transient loading UI or flaky tab taps.

**Decision:** Add a dedicated XCUITest target with debug-only launch preparation;
production launches retain their existing state, animations, and location flow.
The standard scheme runs two seeded smoke journeys and skips the two live App Store
capture methods. A separate `TrafficViennaScreenshots` scheme creates localized
attachments, while the repository script owns an isolated iPhone 17 Pro Max,
stable status bar/location settings, image export, and technical validation. Build
and test scripts resolve an exact available Simulator UUID instead of a name-only
destination.

**Consequences:** Standard validation now proves 110 unit/integration tests plus
two UI journeys without depending on live screenshot generation. Release assets
are reproducible and visually reviewable, while signing, App Store Connect, and
physical/TestFlight behavior remain explicit external gates.

## 2026-08-11 — Contrast-safe premium colour roles

**Context:** The premium redesign reused a bright mint/green brand colour for
white-on-gradient heroes and semantic text. Runtime inspection showed that the
white hero content and some dark-mode statuses could not both satisfy readable
contrast with one static colour. Maximum Dynamic Type also exposed horizontal
card layouts that shrank or clipped essential transport content.

**Decision:** Separate decorative brand fills, dark hero endpoints, and
appearance-aware semantic text colours. Require at least 4.5:1 for white hero text
and semantic text against their supported backgrounds. At accessibility sizes,
station, departure, disruption, and favourite-card content wraps or stacks instead
of relying on minimum scale factors or Dynamic Type clamps.

**Consequences:** The premium mint identity remains visible without being used in
roles it cannot support. `DesignColorContrastTests` prevents palette regressions,
and Simulator acceptance remains required for layout behaviour that numeric colour
tests cannot prove.

## 2026-07-29 — Protected main is the release integration boundary

**Context:** Quality CI covered pull requests and `main` pushes, but the default
branch itself was unprotected. A maintainer or automation error could therefore
bypass the exact Xcode validation used as App Store evidence, rewrite release
history, or delete the branch.

**Decision:** Require pull requests and a strict successful `validate` check for
`main`, require conversation resolution, enforce the policy for administrators,
and disable force pushes and branch deletion. Keep the required approval count
at zero while the repository has one maintainer; CI and the PR boundary remain
mandatory without creating an impossible self-approval requirement.

**Consequences:** Every future release commit must be tested against the latest
`main` before merge, and the production branch cannot be rewritten. Adding
maintainers should trigger a follow-up decision to require independent approval.

## 2026-07-29 — Release without a non-functional identity surface

**Context:** Optional Sign in with Apple stored only a name/email profile in the
device Keychain. It did not sync favourites, unlock functionality, or create a
Traffic Vienna server account. The entitlement blocked a signed archive because
the installed app profile lacked the capability, while keeping it would also add
account-deletion and credential-revocation review obligations without product
value.

**Decision:** Remove the Apple sign-in UI, session model, tests, and entitlement
from the App Store release. Preserve anonymous access to every transport feature.
Run one idempotent launch migration that deletes the known legacy Keychain item
and records completion only after success or an item-not-found result.

**Consequences:** Signing and privacy scope are smaller, onboarding has three
product-focused steps, and no contact identity is collected. The legacy profile
deletion is intentionally irreversible but does not affect favourites or widget
data. Identity can return only with a real cross-device feature, complete deletion
lifecycle, approved backend/provider boundary, and fresh release/security review.

## 2026-07-29 — Widget deep links share the system destination vocabulary

**Context:** Widget taps opened the app generically, while App Shortcuts already
used a persisted typed destination handoff. Adding a second widget-only router
would let external entry points disagree and malformed custom URLs could become an
unvalidated navigation boundary.

**Decision:** Keep Nearby, Search, and Favourites in one shared, Sendable destination
value used by both app and widget targets. Register the `trafficvienna` URL scheme,
accept only a known host with no path, credentials, query, port, or fragment, then
hand the validated destination to the existing persisted root router. The favourites
widget opens Favourites and onboarding remains authoritative.

**Consequences:** Warm and cold widget launches use the same tab ownership as Siri,
Shortcuts, and Spotlight. The URL boundary cannot trigger arbitrary actions or carry
user data; adding another external destination requires an explicit enum case.

## 2026-07-29 — Map exploration is explicit and does not resize the viewport

**Context:** The map projected stations only around the initial location or Vienna
fallback, so panning could leave stale markers. A camera-driven button placed in a
safe-area inset also changed the map frame, retriggered camera updates, and produced
a measured high-CPU layout feedback loop.

**Decision:** Offer “Search this area” after the user moves the camera at least
250 metres from the last search centre. Keep the explored centre transient and
separate from location-permission state. Present camera-driven controls as overlays
so appearing or disappearing UI never changes MapKit's viewport geometry.

**Consequences:** People control when marker results change, explored areas remain
truthfully labelled, and location is still neither persisted nor logged. Camera
search and permission behavior stay independently testable; interactive Simulator
acceptance guards the MapKit layout boundary.

## 2026-07-28 — System navigation uses a persisted typed handoff

**Context:** `RootTabView` listened for an untyped notification that no production
caller posted. App Intents can launch the process cold, before a SwiftUI observer is
ready, so an in-memory event alone can be lost.

**Decision:** Represent supported system destinations as an `AppEnum`, persist one
pending value in standard preferences, and let the root tab owner consume it after
selecting the matching tab. App Shortcuts invoke one foreground `OpenIntent`; they
do not bypass onboarding or introduce a second navigation hierarchy.

**Consequences:** Siri, Shortcuts, and Spotlight can reliably open Nearby, Search,
or Favourites during warm and cold launches. The persisted value contains only a
closed enum and is removed after use; future destinations must be added explicitly.

## 2026-07-28 — Widget time advances locally between bounded refreshes

**Context:** The widget requested network data every minute even though departure
countdowns can be derived from an existing response. Partial refresh failure also
discarded usable rows, and only Home Screen small/medium families were available.

**Decision:** Store a fetch timestamp with each widget row, create five one-minute
timeline entries by subtracting elapsed whole minutes, and request network data at
most every five minutes unless the user explicitly taps Refresh. Group routes by
station and merge fresh rows over cached rows in the user-visible route order.

**Consequences:** Countdown labels remain minute-accurate with fewer API requests,
partial outages retain truthful cached content, and the same data model supports
large plus Lock Screen families. Cached payloads remain backward-compatible because
the added timestamp is optional.

## 2026-07-28 — Station discovery is indexed and map density is bounded

**Context:** Every search keystroke re-normalized all 1,959 station names, exact
lookup and radius queries scanned the full catalogue, and 60 overlapping map pins
made central Vienna difficult to use.

**Decision:** Build exact-name, bigram, and fixed spatial-cell indexes when the
bundled catalogue loads. Preserve catalogue order, verify final substring and
distance matches, and thin sorted map candidates by a minimum physical separation
before applying the marker limit.

**Consequences:** Search and nearby queries are substantially faster without
changing the `StationStoring` boundary or persistence. Map pins remain tappable;
the complete station catalogue is still available through Search and is never
deleted by visual thinning.

## 2026-07-18 — Cross-tab service summaries refresh at the app root

**Context:** The shared `DisruptionsViewModel` drove the tab badge, but its polling
lived inside `DisruptionsView`. Until that tab appeared, the badge and any dashboard
summary remained at their initial loading values; keeping another Nearby poller
would duplicate lifecycle ownership.

**Decision:** Run the cancellable two-minute disruptions refresh loop from
`RootTabView` while the onboarded tab hierarchy is active. Let Alerts remain the
interactive presentation and manual-refresh surface, while Nearby and the badge
read a small freshness-aware dashboard projection from the same observable model.

**Consequences:** Service status is available across tabs without a second request
loop, and existing MonitorService cache/coalescing remains authoritative. This adds
no persistence, background execution entitlement, or alternate navigation path.

## 2026-07-18 — Favourite lifecycle belongs to the app root

**Context:** Favourites loaded routes only while its tab view was active, while
Nearby independently read station favourites from a concrete repository. A
cross-journey next-departure surface would otherwise duplicate requests and could
show state that disagreed with the Favourites tab.

**Decision:** Own one `FavoritesListViewModel` in `RootTabView`, run its cancellable
refresh lifecycle once for the onboarded app, and observe station and route change
notifications at that boundary. Nearby and Favourites receive the same observable
instance; the featured departure is derived once when route items change.

**Consequences:** Saved stations, saved routes, widget synchronization, and the
Nearby feature card share one source of truth with immediate cross-tab updates and
no additional service, persistence format, credential, or network destination.

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
