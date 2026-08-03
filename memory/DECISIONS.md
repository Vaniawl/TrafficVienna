# Architectural Decisions

## 2026-08-03 — App departures expire from their source snapshot

**Context:** The app projected parseable departure timestamps with a nonnegative
`Int`, so every past timestamp collapsed to `0` and could remain visible as
`now`. Timestamp-free departures kept the response's fallback countdown without
accounting for the age of a cached snapshot. A stale service could consequently
remain the featured commute, stay in Station Detail/Nearby/Saved rows, and be
re-synced to the widget as if its countdown had just started. Widget projection
already retained `now` for one minute and then removed the departure.

**Decision:** Make the shared app departure projection optional: prefer a
parseable real-time timestamp, then the planned timestamp, and otherwise derive
an absolute departure boundary from `MonitorSnapshot.updatedAt` plus the fallback
countdown. Keep `0` visible for the same one-minute `now` grace as the widget and
return `nil` at or after the removal boundary. Pass the snapshot timestamp through
Station Detail, Nearby, Saved, featured-commute selection, and app-to-widget sync;
drop expired values and omit widget rows that no longer contain a visible
departure.

**Consequences:** Cached and timestamp-free services age truthfully without new
network work, timers, persistence, or payload fields. Existing 60-second screen
refresh ownership remains unchanged, valid current rows preserve their layout and
copy, and the widget receives only still-visible countdowns anchored at sync time.
Endpoints, request budgets, cache schema, App Group keys, entitlements,
dependencies, and localization are unchanged. Rollback is a normal revert with
no migration.

## 2026-08-03 — Root audit state is conditionally routed and validated

**Context:** TrafficVienna tracks a root product/audit set (`PROJECT.md`,
`SPEC.md`, `STATUS.md`, `BACKLOG.md`, `CHECKS.md`, `RESTRICTIONS.md`,
`SECURITY.md`, `DECISIONS.md`, and `JOURNAL.md`), but the OpenCode state contract
still said those files did not exist and its validators did not require them.
The root snapshots consequently drifted to 189 tests and an older CI head after
the published branch had 192 tests and newer exact-head Quality evidence. Loading
the whole set unconditionally would also spend substantial context on narrow work.

**Decision:** Register every root audit artifact in
`docs/opencode/state-files.md`, require its presence and registration in both the
structural validator and reliability suite, and route the set through `AGENTS.md`
only for broad product, audit, or release work. Narrow tasks load only the root
artifacts relevant to their scope. Current source, configuration, command output,
rendered artifacts, and external-service state override stale narrative.

**Consequences:** Broad reviews receive the complete active requirements and
evidence contract, missing or silently unregistered state fails validation, and
short implementation tasks avoid unnecessary context. This changes no app,
widget, persistence, endpoint, permission, entitlement, or dependency boundary.
Rollback is a normal revert with no migration.

## 2026-08-03 — Forced monitor refreshes receive an intent-aware successor

**Context:** `MonitorService` coalesced every request for the same station, and
every traffic-info request, into whichever task was already running. A manual
forced refresh arriving behind older background work therefore completed with
the pre-gesture response and never performed its promised cache-bypassing fetch.
Coordinating individual view models cannot cover callers in other tabs or app
journeys that share the service.

**Decision:** Keep refresh ownership in `MonitorService` and make each in-flight
entry carry a generation token and forced/regular intent. A regular caller may
join any active request; a forced caller may join an active forced request. When
a forced caller encounters a regular request, it awaits that request without
cancelling its waiters, then starts or joins exactly one serial forced successor,
even if the regular request failed. Complete the cache write inside the tracked
task before publishing its snapshot, and clear an entry only when its generation
still matches so an older waiter cannot erase a newer successor. Check caller
cancellation before creating any new tracked request, including the serial
successor, and propagate `CancellationError` past stale-cache fallback.

**Consequences:** Manual refresh can no longer be satisfied by lower-intent
background work: it either joins equivalent forced work or receives a successor
initiated after the regular request. Concurrent forced callers still coalesce,
requests do not run in parallel, and an abandoned caller cannot spend request
budget on a successor or receive stale data as a successful cancellation result.
The existing shared throttle, retry, stale-cache policy for real failures, and
request-budget policies remain authoritative. Public provider protocols,
endpoints, cache schemas, persistence, dependencies, and UI stay unchanged.
Rollback is a normal revert with no migration.

## 2026-08-03 — Station Detail favourite state is repository-derived

**Context:** A Station Detail view can remain alive in one tab while the same
station or route is removed from Saved. Its view model loaded route favourites
only at initialization and locally inverted that cached set after a toggle. The
display could therefore remain stale and then become the opposite of the actual
repository state.

**Decision:** Keep the existing station and route repositories as the source of
truth. Re-read them after every local toggle, and let Station Detail subscribe to
the existing station/route change notifications so a preserved view reconciles
mutations made elsewhere. Do not inject the root favourites view model or create
a second shared state owner.

**Consequences:** Cross-tab changes update the Station Detail controls without
resetting navigation or coupling feature view models. Duplicate repository reads
are small local UserDefaults reads, no storage schema or notification contract
changes, and rollback is a normal revert with no migration.

## 2026-08-03 — Widget removal boundaries survive delayed timeline generation

**Context:** Countdown projection deliberately retains zero for one minute so a
departure can render as `now`. Timeline scheduling previously required the
departure boundary itself to be in the future before adding either that boundary
or its one-minute removal entry. A cached timeline generated after departure but
before removal therefore had no entry to remove `now` until the five-minute
network refresh.

**Decision:** Evaluate each stored departure boundary and its one-minute removal
boundary independently. Insert either date only when it lies strictly between the
timeline's current date and existing refresh deadline; keep de-duplication and the
three-departure presentation limit unchanged.

**Consequences:** A delayed cached timeline preserves the intended `now` state
and removes it at the first valid future boundary. Expired boundaries remain
ignored, the timeline stays bounded, and network cadence, payloads, App Group
keys, endpoint, entitlement, dependency, localization, copy, and layout do not
change. Rollback is a normal revert with no migration.

## 2026-08-03 — Widget timelines cover every rendered departure

**Context:** App Group sync and direct widget fetch both persist at most three
departures per route, and several widget families render all three. Timeline
scheduling created removal boundaries for only the first two. If the third
departure fell before the five-minute refresh deadline, its system countdown
could reach zero and remain visible until the network refresh.

**Decision:** Schedule departure and one-minute-post-departure entries for the
first three stored countdowns per route, matching the presentation and storage
limit. Continue de-duplicating dates and ignore boundaries outside the existing
five-minute refresh window.

**Consequences:** Every rendered countdown is projected away on time without
increasing network frequency or changing the widget payload, cache, App Group
keys, endpoint, entitlement, localization, copy, or layout. The maximum timeline
remains bounded by three routes times three departures, and rollback is a normal
revert with no migration.

## 2026-08-03 — Widget refresh budgets are scoped by route selection

**Context:** Every widget timeline used one App Group timestamp for the most
recent network attempt. A timeline for one configured route therefore consumed
the shared five-minute budget before another widget instance with a different
route could perform its first fetch. The second instance could remain empty or
stale even though its own selection had not been requested. An empty selection
also recorded an attempt and could advance the global cache timestamp.

**Decision:** Derive the attempt key from the canonical sorted set of selected
route stable IDs and evaluate the refresh policy through one shared pure helper.
Selections with the same routes share a budget regardless of display order;
different selections remain independent. Keep the manual-refresh timestamp
global so one explicit refresh request is observed by every scoped timeline, and
never fetch or record an attempt for an empty selection.

**Consequences:** One widget configuration cannot suppress another
configuration's initial fetch, while equivalent configurations still avoid
duplicate work. The old global attempt timestamp is deliberately ignored, so an
upgrade may perform one additional safe fetch per active selection; no eager
migration or cleanup is required. Existing cached departures, route storage,
endpoint, entitlement, dependency, localization, copy, and layout remain
unchanged. Rollback is a normal revert; stale scoped timestamps are harmless.

## 2026-08-02 — ActivityKit effects are serialized per Activity ID

**Context:** `LiveActivityController` owned its timer bookkeeping on the main
actor but launched every ActivityKit `update` and `end` in an independent
unstructured task. Swift concurrency does not guarantee that those tasks reach
the system in call order. A refresh that updates a tracked departure and a quick
user stop could therefore overlap or complete out of order. Serialization alone
does not make a submitted end immediately visible: while `Activity.end` awaits
the system, `Activity.activities` may still report that session, allowing an
in-flight Station Detail refresh to restore it and submit a later update.

**Decision:** Route every ActivityKit mutation through one MainActor-owned
operation chain keyed by the system Activity ID. A new operation awaits only the
previous operation for the same ID. Different IDs remain independent, and a
generation token removes a completed chain without deleting a newer successor.
Automatic expiry uses the same boundary as refresh, replacement, and user stop.
Submitting an end synchronously marks that ID terminal until the end completes;
later updates and controller matching/restoration reject terminal IDs. Station
Detail separately remembers an explicit stop until ActivityKit no longer reports
the stopped departure, then resumes normal system reconciliation. It also clears
local tracking when the authoritative system activity disappears.

**Consequences:** System updates and ends preserve application submission order
without globally serializing ActivityKit or moving lifecycle work outside the
existing controller. A slow system operation delays only later work for that same
activity, and no work can revive an activity after its end is submitted. A rapid
restart creates or adopts a non-ending system activity and clears the old stop
intent. No endpoint, persisted state, permission, entitlement, dependency,
localization, copy, or UI changes; rollback is a normal revert with no migration.

## 2026-08-02 — Widget projection time is not source freshness

**Context:** Saved converts MonitorService snapshots into current countdown
minutes before App Group sync. The widget previously used the new sync time for
both countdown projection and its Updated label, so a stale fallback could be
presented as freshly sourced. Reusing the old source time as the projection anchor
would instead subtract the cache age twice.

**Decision:** Keep `fetchedAt` as the per-row countdown projection anchor and add
an optional `dataUpdatedAt` for transport-source freshness. App sync propagates
the MonitorService snapshot time; direct widget network results set both to the
same captured instant. The displayed timestamp is the oldest source across all
visible rows. Legacy rows use their projection anchor, then the existing global
fallback when a row has no timestamp.

**Consequences:** Mixed cached/live content cannot hide its oldest source, while
countdowns remain correctly projected. Existing payloads decode because the new
field is optional, and legacy decoders ignore it, so no eager migration or new
App Group key is required. No endpoint, entitlement, dependency, localization,
copy, or layout changes. Rollback is a normal revert.

## 2026-08-02 — External destinations reset only their owned navigation stack

**Context:** Root external routing selected a tab, but Home and Saved stacks were
unbound and Discover's destination-style pushes were not represented in its
bound path. A warm Siri, Shortcuts, widget, deep-link, or notification route could
therefore select the correct tab while leaving a stale Station Detail or Map on
screen. Clearing every tab would fix the symptom but destroy unrelated user
navigation history.

**Decision:** Own one `NavigationPath` per tab in a testable root state. Ordinary
tab selection changes only `selectedTab`. An external Home, Discover, or Saved
destination resets only its target path before selection. A notification station
route replaces Discover with exactly one resolved station, or the Discover root
when no current station matches. Use value-based links for Home station pushes and
the Discover Map entry so root-relevant navigation is represented in those paths.

**Consequences:** Warm and cold system entry reaches a deterministic root or
station without invalidating unrelated tab history or adding a shared navigation
coordinator. URL validation, stored router keys, persistence, endpoints,
permissions, entitlements, dependencies, copy, and layout are unchanged. Path
state is transient; rollback is a normal revert and needs no migration.

## 2026-08-02 — Nearby refresh ownership follows the latest location

**Context:** Nearby can be loaded by a 60-second screen task, a new task when the
location key changes, and pull-to-refresh. The view model previously let those
calls run concurrently. Because the service coalesces a request for the same stop,
an overlapping forced refresh could reuse the older normal fetch instead of
guaranteeing a cache-bypassing pass. SwiftUI also cancels the former location task
when its key changes, so a simple queued bit owned only by that task would discard
the replacement request and leave the new location waiting for the next poll.

**Decision:** Keep one MainActor-owned cooperative load chain in
`NearbyViewModel`. Capture the location at the start of each pass, coalesce a
same-location normal request, and otherwise queue the latest location while OR-ing
all force-refresh intent. Stop publishing from a pass as soon as a newer request
is queued. Overlapping callers await the merged chain. If SwiftUI cancels the
current owner, resume those waiters as unfulfilled so a surviving caller captures
the current location and becomes the next owner. Treat cancellation as lifecycle
control, never as a station failure, and do not move work into an unstructured or
detached task.

**Consequences:** Nearby issues at most one monitor request at a time, manual
refresh intent reaches one sequential follow-up, and a superseded location cannot
overwrite the current list. Ownership still follows SwiftUI cancellation, while
the handoff occurs after the active service await unwinds. No protocol, endpoint,
cache, persistence, permission, dependency, localization, or migration changes.
Rollback is a normal revert.

## 2026-08-02 — Manual refresh intent survives background polling

**Context:** Station Detail polls every 60 seconds and Alerts every 120 seconds,
while both screens also expose a forced pull-to-refresh. Each ViewModel previously
returned immediately from any load requested during an active pass, so a user
refresh could be acknowledged by the gesture without ever bypassing the cache.

**Decision:** Keep one MainActor-owned load chain inside each existing ViewModel.
An overlapping non-forced load remains coalesced away; any overlapping forced load
sets one follow-up bit, and repeated requests cannot create parallel calls. Do not
publish a response or failure from a pass when that forced follow-up is pending.
If the owner task is cancelled, clear the bit and do not start or publish queued
work.

**Consequences:** Pull-to-refresh reaches the service with `forceRefresh = true`
even when polling won the race, without introducing a shared coordinator, new
protocol, endpoint, cache, persistence, or background task. The original task owns
the follow-up and cancellation lifecycle. Rollback is a normal revert and requires
no migration.

## 2026-08-02 — Saved-route reloads preserve the newest repository state

**Context:** Saved routes refresh sequentially while the root receives repository
change notifications. The view model previously returned immediately from any
reload requested during an active pass. A user mutation could therefore be lost
as a reload signal, allowing the older route snapshot to repopulate both Saved and
the widget until the periodic root task ran again. An explicit pull-to-refresh
could also lose its cache-bypass intent behind the active pass.

**Decision:** Keep one owner-scoped load chain in `FavoritesListViewModel`. Queue
at most one follow-up pass while it is active, combine queued requests so any
`forceRefresh` wins, re-read the route repository before commit, and do not
publish a completed pass when its captured route set is no longer current. If the
owner task is cancelled, discard the queued pass and publish nothing from the
cancelled request.

**Consequences:** Saved and the widget converge on the newest repository state
without parallel route fetches or a 60-second inconsistency window. User refresh
intent is preserved, while cancellation, repository format, App Group storage,
network throttling, and existing MVVM/notification ownership remain unchanged.
Rollback is a normal revert and requires no migration.

## 2026-08-02 — Widget examples stay inside Gallery previews

**Context:** WidgetKit uses `placeholder` for gallery presentation, but the
timeline provider also returned that sample entry from every empty `snapshot`.
Outside the gallery, a widget with no selected or cached route could briefly show
example U1/O departures that were not user data or a live response.

**Decision:** Resolve empty snapshot presentation through a shared, testable
policy. Real selected items always take precedence. Only an empty snapshot whose
WidgetKit context explicitly reports `isPreview` may use example departures; an
empty runtime snapshot must use the existing empty widget state.

**Consequences:** Gallery previews remain informative without allowing fabricated
departures to escape into a runtime surface. App and widget targets compile the
same policy, and the change adds no storage, cache migration, network, entitlement,
dependency, localization, or populated-layout boundary.

## 2026-08-02 — Location authorization owns coordinate lifetime

**Context:** Location is intentionally memory-only, but `LocationManager` retained
its last precise coordinate when permission changed to denied or restricted. Map
also treated any non-nil coordinate as located before checking authorization, so a
stale value could hide permission recovery and continue influencing station
projection after access was revoked.

**Decision:** Treat `.authorizedWhenInUse` and `.authorizedAlways` as the only
states permitted to retain or consume the device coordinate. Clear the cached
location and release any in-flight one-shot request when authorization is revoked,
reset, or unknown. Map independently validates authorization before using a
coordinate for status, projection, or user annotation; a user-chosen exploration
centre remains valid because it is not device-location data.

**Consequences:** Revoking permission immediately returns Home and Map to truthful
permission/fallback behavior and removes the precise coordinate from app memory.
Reauthorization can start a fresh one-shot request. No persistence, logging,
network, entitlement, or dependency boundary changes.

## 2026-08-02 — System countdowns require current departures

**Context:** Station Detail can display an in-memory stale snapshot after a
refresh failure. Starting a reminder or Live Activity from that snapshot could
publish an inaccurate system countdown. View-model recreation also forgot an
ActivityKit session that remained active, and a notification permission prompt
could outlive the originally planned reminder fire time.

**Decision:** Treat ActivityKit as the authoritative source for restoring the
active departure identity. Permit a user to stop an existing activity at any
time, but require a current departure snapshot before starting a new reminder or
Live Activity. Revalidate reminder schedulability after notification permission
returns and present a safe localised error for unexpected scheduling failures.

**Consequences:** Readable stale departure fallback is preserved without creating
misleading Lock Screen state. Activity controls remain consistent across
view-model recreation, and delayed permission handling cannot turn an expired
plan into an immediate alert. The change adds no endpoint, entitlement, account,
or persistence boundary.

## 2026-07-30 — System surfaces use local ownership and typed destinations

**Context:** Widgets exposed an empty configuration intent, one-route large layouts
wasted space, and five one-minute timeline entries duplicated countdown work that
the system can render. Live Activities lacked an explicit end lifecycle. The app
also had no notification feature; truthful remote service-alert push would require
an owned backend and APNs provider that do not exist.

**Decision:** Support only explicit, user-created local departure reminders through
UserNotifications and ask for permission at the first reminder action. Persist the
station ID in notification metadata and route taps through the existing durable
root router to that Station Detail in Discover. Configure widgets from saved-route
AppEntities with family-specific limits, use system-rendered countdown dates with
a five-minute refresh budget, and schedule only bounded entries at visible
departure boundaries and one minute afterward so departed rows do not linger at
`0:00`. Derive visible freshness from the selected rows. Update, replace, stop,
clean up, and automatically end Live Activities two minutes after departure. This
supersedes the 2026-07-28 decision to create five one-minute widget timeline
entries.

**Consequences:** Notifications remain on-device and add no server, account, token,
push entitlement, or transport-data collection boundary. Widget configuration and
countdowns respect WidgetKit's scheduling budget while removing elapsed departures
promptly and retaining a deterministic five-minute refresh fallback. Warm/cold
system entry points dismiss stale modal UI and open owned destinations. Remote
disruption push remains out of scope until a separately reviewed backend/APNs
architecture exists; production notification, widget, Dynamic Island, and
automatic-end behavior still require signed physical TestFlight acceptance.

## 2026-07-30 — Journey-first shell keeps external routes compatible

**Context:** Five equal tabs made nearby departures, search, and map compete for
attention, while network-wide alerts were noisy for people who cared about only
their saved lines. Continuous location updates and repeating station-detail
animation also spent runtime resources without improving the next action.

**Decision:** Use four top-level journeys: Home, Discover, Alerts, and Saved.
Discover owns search and map; the existing Nearby, Search, and Favourites external
destination enum remains stable and maps to Home, Discover, and Saved. Personalise
Alerts in memory from saved route line names, with an explicit All Vienna scope.
Request location once per user or refresh action and coalesce overlapping requests.
Keep station detail live through bounded 60-second refreshes, not repeating visual
animation. Add an XCUITest target for the public journeys.

**Consequences:** The shell has a clearer information hierarchy without breaking
widgets, deep links, Siri, Shortcuts, or Spotlight. Alert personalisation adds no
new persistence, account, endpoint, or privacy category. Map and location recovery
remain explicit, and the new end-to-end tests make navigation ownership observable.

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
an extension-owned catalogue. Suggestions use deterministic saved-route order;
when App Intents restores an explicit identifier collection, resolve in that
identifier order and omit identifiers whose saved route is no longer available.

**Consequences:** App and widget cannot silently drift in route identity or sort
order, a restored multi-route configuration retains the user's presentation order,
refreshed widgets show a human-readable stop name, and the extension remains
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
