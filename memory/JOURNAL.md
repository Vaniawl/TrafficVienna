# Journal

## 2026-07-19 — User-controlled local data export

- Added a system JSON file export from Privacy & data for the current profile, safe appearance/Home/App Lock preferences, ordered favourite stations/routes, commute routines, and recent station identifiers.
- Defined a versioned explicit allowlist rather than dumping UserDefaults, excluding password verifiers, authentication tokens, the Apple provider identifier, runtime caches, widget internals, and location history.
- Kept generation fully on device and in memory until the user chooses a destination through the system exporter, with clear localized disclosure and failure feedback.
- Added deterministic ISO-8601/field-order encoding coverage, forbidden-secret assertions, and end-to-end Account discoverability coverage in English, German, and Ukrainian.

## 2026-07-19 — Grace-period app lock

- Added user-selectable immediate, one-minute, and five-minute identity-verification delays for the optional app lock.
- Continued replacing the signed-in hierarchy with a privacy shield as soon as the app becomes inactive, so the app-switcher snapshot never exposes departures or saved travel data during a grace period.
- Measured elapsed background time with monotonic system uptime rather than wall-clock dates, preventing manual clock changes from extending the grace period.
- Persisted only the selected timeout, retained cold-launch locking, localized the complete setting in English, German, and Ukrainian, and added exact 59/60-second boundary coverage.

## 2026-07-19 — State-preserving app lock

- Moved heavy dashboard owners into a signed-in-session `RootTabState` so prepared station indexes, cached view models, preferences, and selected-tab state survive lock/unlock.
- Continued replacing the complete signed-in view hierarchy with the lock screen, guaranteeing that sheets, full-screen covers, interaction, accessibility content, and polling disappear while locked.
- Scoped retained state to the active auth session so signing out still discards transient dashboard state instead of leaking it into a later session.
- Avoided a visually hidden overlay architecture after review showed that independently presented SwiftUI modals could otherwise remain above the lock layer.

## 2026-07-19 — Optional biometric app lock

- Added an opt-in Account security control for Face ID, Touch ID, or Optic ID and a dedicated lock screen that hides the signed-in interface after the app leaves the foreground.
- Required successful system authentication before enabling protection, persisted only the device-level preference, and kept biometric data entirely inside LocalAuthentication.
- Used device-owner authentication so a system passcode remains available after biometric lockout or enrollment changes, avoiding an unrecoverable local lock.
- Added the Face ID purpose string, privacy disclosure, English/German/Ukrainian copy, deterministic state/failure/fallback tests, and Account discoverability coverage.

## 2026-07-19 — Local email password changes

- Added a Change password destination for signed-in email accounts while keeping the option hidden for Apple ID sessions.
- Required the current password, an eight-character replacement, and matching confirmation before updating the device-local verifier.
- Replaced the Keychain record only after current-password verification, retained the active session, and preserved the old credential when storage fails.
- Localized the complete flow in English, German, and Ukrainian and added credential-rotation, failure-path, and Account discoverability coverage.

## 2026-07-19 — Typo-safe email registration

- Added a required password-confirmation field for new email accounts while keeping existing-account sign-in to one password field.
- Added live matching feedback and kept account creation disabled until email, password length, and confirmation are all valid.
- Updated keyboard navigation to move from email to password to confirmation and submit with Go, including end-to-end UI coverage.
- Localized the new field and validation message in English, German, and Ukrainian and added deterministic form-validation tests.

## 2026-07-19 — User-distance map-list ordering

- Sorted visible-stop rows by straight-line distance from the current user whenever location is available, aligning the “Closest first” label with each displayed walking estimate.
- Preserved the map's existing viewport order when location is unavailable instead of fabricating a user-relative ranking from Vienna centre.
- Kept equal-distance stations stable in their incoming order and applied local name search after sorting so filtered results retain the same proximity ranking.
- Limited the work to the existing 60-marker cap with no new polling or network calls and added exact location, tie, and no-location ordering coverage.

## 2026-07-19 — Walking context in the map list

- Added straight-line walking estimates from the current user location to each visible-stop row, while omitting the estimate when location is unavailable.
- Kept the status and walking context on separate compact lines so station names and favourite controls remain usable at larger text sizes.
- Centralized minute and metre/kilometre formatting in `WalkingEstimate` and reused it in Nearby station cards plus the existing `CLLocation` helper, removing duplicated formulas.
- Kept the feature fully local with no routing or network claim and added exact coverage for metre, kilometre, negative-distance, and shared-minute behavior.

## 2026-07-19 — Searchable visible-stop map list

- Added native search to the visible-stop sheet so users can narrow the current map area without leaving Map or starting another network request.
- Matched station names case- and diacritic-insensitively, supported whitespace-separated search terms, and preserved the existing nearest-first order.
- Added a query-specific empty state while retaining the favourites-only recovery action when a search has no saved matches.
- Localized the search prompt in German and Ukrainian and added deterministic coverage for diacritics, multiple terms, blank queries, and order preservation.

## 2026-07-19 — Inline map-list favourites

- Added a dedicated 44-point star control to every visible-stop row so a station can be saved or removed without leaving the map list.
- Reused the root-owned favourites view model, keeping map markers, the favourites-only filter, Home, Search, and the Favourites tab synchronized through the existing persistence boundary.
- Made removal update the favourites-only list immediately, including its actionable empty state when the last visible favourite is removed.
- Reused the localized add/remove accessibility labels and verified shared-state toggling together with map-filter ordering.

## 2026-07-19 — Browseable visible-stop map list

- Added a compact List control to Map that presents every currently rendered stop in the same nearest-first order as its markers.
- Made each row a direct Station Detail destination with live-versus-schedule context and a distinct saved-station star treatment.
- Kept the sheet synchronized with the favourites-only filter and added an actionable empty state that can restore all visible stops without dismissing the sheet.
- Localized the complete flow in German and Ukrainian, retained the viewport marker cap, and removed the map-centre concurrency warning with an explicitly nonisolated value initializer.

## 2026-07-19 — Personalized favourite-station map

- Highlighted saved stations with yellow star markers while retaining the standard tram treatment for other visible stops.
- Added a compact map control to switch between every nearby stop and favourites only, with the visible-stop count following the active filter.
- Shared the root favourites state across both Map entry paths so updates stay synchronized without duplicate persistence or loading.
- Preserved the viewport's distance ordering and marker cap, localized the controls in German and Ukrainian, and added deterministic filter coverage.

## 2026-07-19 — Viewport-aware station map

- Updated map markers around the visible camera centre after each completed pan instead of leaving the original location's stations on screen.
- Reused the spatial station index with a roughly 100-metre centre bucket and `.onEnd` camera updates, avoiding marker queries during every animation frame or small camera jitter.
- Centred on the first available user location once while preserving subsequent manual exploration, and retained Vienna centre as the location-free fallback.
- Added a localized visible-stop count for immediate map feedback and kept deterministic distance ordering plus the 60-marker rendering cap covered by tests.

## 2026-07-19 — Navigable saved-route cards

- Turned each resolvable saved route in Favourites into a direct Station Detail link while retaining native swipe deletion, Edit-mode deletion, and reordering.
- Added the resolved stop name beneath live departure times so route cards communicate both destination and boarding stop.
- Required canonical StationStore resolution for navigation, leaving malformed or obsolete DIVA records visible and removable without inventing coordinates or station identities.
- Added resolver regressions and extended the end-to-end flow to save a live line, open its Favourites route card, and return to the correct station.

## 2026-07-19 — In-place favourites management

- Completed Favourites Edit mode for both saved stations and saved routes with native reorder and delete controls in the same list.
- Added a prominent destructive card with explicit confirmation for clearing every saved station and route without affecting authentication, routines, or unrelated travel data.
- Batched route deletion through ordered persistence and a single widget synchronization instead of repeatedly toggling and refreshing shared state.
- Localized the management flow in German and Ukrainian and extended the end-to-end Search → Favourites flow through confirmed clearing and the empty state.

## 2026-07-19 — Resolved favourite-station coordinates

- Replaced the synthetic `0,0` Station Detail destination from Favourites with canonical station data resolved through the shared StationStore.
- Persisted optional station coordinates with new favourites as a backward-compatible fallback while continuing to decode existing coordinate-free saved data.
- Hid Apple Maps walking actions when neither canonical nor stored coordinates are available, preventing an invalid handoff near the Gulf of Guinea.
- Added canonical-precedence and legacy-decoding regressions plus end-to-end coverage for Search → Favourites → Station Detail directions.

## 2026-07-19 — Walking directions from Station Detail

- Added a persistent walking-directions toolbar action to every Station Detail state, including schedule-only, loading, empty, and failed live-data states.
- Added a prominent neobank-style directions card when live departures are visible so the Apple Maps handoff is discoverable from Search, Favourites, Home, and Map entry paths.
- Centralized the MKMapItem name, exact station coordinates, and walking launch mode without introducing or claiming an in-app A-to-B routing engine.
- Localized the action in German and Ukrainian and added unit plus end-to-end discoverability coverage.

## 2026-07-19 — User-managed recent searches

- Added a visible per-station remove action to Search history without changing the station's favourite state or the order of remaining recents.
- Replaced immediate bulk clearing with an explicit destructive confirmation that explains the on-device scope.
- Made recent-search persistence injectable for isolated verification while retaining the production App Group boundary and removing the stored key when history becomes empty.
- Localized the management flow in German and Ukrainian and added persistence regressions for middle-item and final-item removal.

## 2026-07-19 — Shareable live departures

- Added a visible system Share action to every Station Detail departure group alongside reminder, Lock Screen tracking, and favourite controls.
- Shared the line, destination, station, and nearest live countdown with a dedicated departing-now message instead of exposing internal API data or identifiers.
- Reused the same deterministic share content in the row context menu, with a 44-point target, route-aware VoiceOver label, and stable accessibility identifier.
- Localized share labels and messages in German and Ukrainian and added exact formatter regressions for future and departing-now states.

## 2026-07-19 — Discoverable privacy and app information

- Added a localized Privacy & data destination in Account covering on-device identity, optional transient location, local travel preferences, Wiener Linien HTTPS requests, and the absence of ads, analytics, and tracking SDKs.
- Kept every user-facing privacy statement aligned with the repository privacy notes and avoided implying that the still-pending public privacy-policy URL is complete.
- Made About discoverable from Account while retaining the existing source, provider, licence, version, and live-data caveat presentation.
- Added stable accessibility identifiers and end-to-end Account navigation coverage for both Privacy & data and About.

## 2026-07-19 — Preference-aware Home polling

- Replaced unconditional Home refresh loops with a deterministic polling plan derived from tab activity, location availability, saved-route visibility, and saved-route existence.
- Stopped the five-second Nearby wake-up loop while no user location exists and restarted it automatically when a location becomes available.
- Skipped favourite-route monitor work when its Home module is hidden or no routes exist, while preserving city-alert refreshes for the global personalized tab badge.
- Added matrix coverage for inactive, no-location, hidden-route, empty-route, and fully active polling states.

## 2026-07-19 — Reorderable Home modules

- Added Edit-mode drag reordering for saved stations, saved routes, and Smart insight while retaining each module's independent visibility toggle.
- Persisted a duplicate-safe module order, appended newly introduced modules during forward migration, and restored both order and visibility with the existing default-layout action.
- Rendered the shared ordered module list in every Nearby state and added the previously missing Smart insight to the live-departures dashboard.
- Localized the reordering guidance and added persistence, corrupted/future-value normalization, and Account discoverability coverage.

## 2026-07-19 — User-configurable Home modules

- Added a localized Account destination for independently showing or hiding saved stations, saved routes, and the contextual Smart insight on Home.
- Persisted layout preferences locally with default-on migration behavior and a one-tap default-layout restore that never deletes the underlying travel data.
- Applied preferences consistently to permission, empty, and live Nearby dashboards while retaining the existing root-owned data and network stores.
- Added isolated persistence/reset coverage and an end-to-end toggle → hidden Home module → restored module regression.

## 2026-07-19 — Discoverable visual appearance presets

- Added an Account destination with a visual two-column chooser for all existing color/card/color-scheme presets and an immediate selected-state preview.
- Adapted the chooser to a single column at accessibility text sizes, preserved 44-point card controls, and exposed localized selected state to VoiceOver.
- Made ThemeManager persistence injectable so selection and invalid-value fallback are covered without touching the user's real defaults.
- Localized the complete appearance flow and preset names in German and Ukrainian and added end-to-end Night-to-Vienna selection coverage.

## 2026-07-19 — Live saved routes on Home

- Added a Revolut-style Saved routes module to every Nearby dashboard state with the first three user-prioritized line/destination favourites, realtime countdowns, stop context, retained errors, and direct Station Detail navigation.
- Reused the root-owned Favourites view model and its cached/coalesced monitor pipeline instead of introducing another persistence or network owner.
- Added a deterministic O(1) station-by-DIVA index so saved route cards resolve their station without scanning the bundled dataset.
- Split nearby-location polling from 60-second favourites/alerts dashboard refreshes, keeping contextual Home cards current without the five-second empty-location cadence.
- Localized the section in German and Ukrainian and added DIVA-index regression coverage.

## 2026-07-19 — User-managed Live Activities

- Added an Account destination that lists TrafficVienna Live Activities chronologically with line, destination, stop, scheduled departure time, and realtime status.
- Added swipe-to-end for one tracked departure plus a confirmed end-all action independent from the destructive travel-data reset.
- Reloaded the system-owned activity snapshot when the management screen becomes active and kept targeted ending scoped to the selected ActivityKit identifier.
- Localized the flow in German and Ukrainian and added deterministic ordering plus end-to-end Account navigation coverage.

## 2026-07-19 — Time-relevant Smart Home routines

- Limited Smart Home routine selection to a two-hour window around the saved commute time instead of surfacing the nearest routine throughout its entire active weekday.
- Preserved circular minute handling around midnight and weekday filtering while making the relevance boundary explicit and deterministic.
- Changed the active-routine insight from opening routine settings to opening that station's live departures directly, with a bundled-station lookup and safe saved-station fallback.
- Added exact before/after boundary regression coverage and a stable accessibility identifier for the contextual home action.

## 2026-07-19 — Discoverable and duplicate-safe Live Activities

- Added a visible Lock Screen tracking action to every Station Detail departure row instead of leaving Live Activity creation inside the context menu only.
- Reused and updated an existing activity for the same line, destination, and stop while ending any older matching duplicates before they consume another system activity slot.
- Unified Station Detail feedback so reminders and Live Activity start, update, unavailable, and failure outcomes all produce clear localized confirmation.
- Added a deterministic reconciliation regression and stable accessibility identifiers; localized the complete flow in German and Ukrainian.

## 2026-07-19 — Weekday-aware travel routines

- Added a localized seven-day picker to routine creation and editing, with 44-point controls, locale-aware ordering, VoiceOver selection state, and validation that keeps at least one active day.
- Persisted normalized weekday selections while decoding older routine payloads as every day and keeping the added field safe for rollback to older builds.
- Limited Smart Home's current-routine choice to enabled routines scheduled for the current weekday, so weekday commutes no longer surface on weekends.
- Added persistence, legacy migration, edit, and weekday-selection regressions with deterministic calendar and timezone coverage.

## 2026-07-19 — Saved-station quick access on Nearby

- Added a compact horizontal home strip for the first four saved stations in the user's chosen order across permission, empty, live, and departures Nearby states.
- Added direct Station Detail cards plus a “See all” action that routes to Favourites while reusing the root-owned station index and favourites state without extra network or persistence work.
- Localized the new controls in German and Ukrainian and kept the cards accessible with stable identifiers, a 52-point minimum height, and bounded Dynamic Type growth.
- Extended the end-to-end search-save regression to verify that the saved station appears on Nearby and opens its Station Detail screen directly.

## 2026-07-19 — Quick station favourites from Search

- Added a visible 44-point star action to station search results and recent stations so saving no longer requires opening Station Detail.
- Kept navigation and recents recording on the main card while the independent star updates the root-owned favourites state and repository immediately.
- Reflected saved state with a filled yellow star, localized VoiceOver actions, the station-name hint, and stable Search/Favourites accessibility identifiers.
- Added an end-to-end registration → Search → quick-save → Favourites regression that also handles pre-existing local favourite state deterministically.

## 2026-07-19 — Bigram-indexed station search

- Built a normalized two-character inverted index together with the off-main station snapshot and retained the complete scan only for one-character queries.
- Reduced ordinary multi-character searches to a deterministic subset while preserving the existing exact, whole-name prefix, word-prefix, embedded-match ranking, and stable station order.
- Kept every index immutable between snapshot publications and added coverage proving common matches remain present while the candidate set falls below half of the complete dataset.
- Reduced the existing 100-query search performance test from about 1.06 seconds in the preceding full run to 0.41 seconds in the final full indexed run.

## 2026-07-19 — Off-main station dataset preparation

- Moved bundled station JSON I/O, decoding, name normalization, search sorting, DIVA indexing, and spatial bucketing off the main actor for the production Root flow.
- Added an explicit readiness boundary so dependent tabs are created only after a complete snapshot is available instead of observing partially built indexes.
- Kept deterministic synchronous construction available for isolated tests and previews while the app shows a short localized preparation state.
- Added an asynchronous-load regression that verifies the store starts empty, reaches readiness, and publishes a usable ID index with the station array.

## 2026-07-19 — User-managed departure reminders

- Added an Account destination that lists pending TrafficVienna departure reminders with route, stop, and scheduled fire time.
- Sorted reminders chronologically, ignored unrelated or malformed system notifications, and kept notification-center reads on demand instead of adding another polling store.
- Added swipe-to-cancel for individual reminders and a confirmed cancel-all action scoped to the existing `departure.` identifier boundary.
- Localized the complete management flow in German and Ukrainian and added request mapping/filtering plus profile-navigation UI coverage.

## 2026-07-19 — Discoverable and timing-safe departure reminders

- Added a visible bell action to every Station Detail departure group so reminders no longer depend on discovering the row context menu.
- Moved reminder lead-time calculation into a deterministic plan that rejects departures too close to notify before requesting notification permission.
- Localized notification-disabled, departure-too-soon, scheduled-confirmation, notification-title, and notification-body copy in German and Ukrainian.
- Added boundary coverage for one- and three-minute lead times and too-soon departures.

## 2026-07-19 — Device-local profile display name

- Added an editable profile alias for email and Apple sessions without changing the authentication identity, provider, or Keychain boundary.
- Normalized repeated whitespace, capped names at 40 characters, allowed an empty value to restore the provider fallback, and persisted the non-secret session value.
- Updated Account and the Nearby dashboard to show the personalized name immediately while retaining the email address in profile details.
- Added German and Ukrainian localization plus persistence, normalization-boundary, and end-to-end registration UI coverage.

## 2026-07-19 — User-controlled favourite route priority

- Added Edit-mode drag reordering for saved line/destination routes alongside the existing favourite-station ordering.
- Persisted the new route order through the existing App Group repository while normalizing duplicate inputs and retaining rollback-compatible JSON.
- Reordered loaded cards immediately, invalidated older in-flight batches, and synchronized widget top-three priority without waiting for another network refresh.
- Added real-repository persistence/compatibility coverage plus UI-state and widget-order regressions.

## 2026-07-19 — Non-destructive Favourites route failures

- Preserved each route's last useful stop name, departures, and freshness when a later Favourites refresh fails instead of replacing the card with empty countdowns.
- Reused the existing per-card localized warning while keeping first-load failures explicit and free of invented departure data.
- Kept widget output useful during a failed refresh and cleared the route warning after the next successful recovery.
- Added regressions for success-to-cache-clear-to-failure-to-recovery behavior and the first-load failure boundary.

## 2026-07-19 — Visible non-destructive Alerts refresh failures

- Kept the loaded city-wide alert list and personalized relevance count intact when a later refresh fails after the service cache is unavailable.
- Surfaced the localized network failure as a compact warning card above existing alerts instead of silently hiding the failed update.
- Cleared the warning after a successful recovery while preserving the blocking first-load error when no useful alert data exists.
- Added regressions for success-to-failure-to-recovery behavior and the empty first-load failure boundary.

## 2026-07-19 — Non-destructive Station Detail refresh failures

- Kept already loaded departures visible when a later manual or polling refresh fails instead of replacing the station screen with a blocking error state.
- Added a compact inline network warning inside the existing departure list while preserving the full-screen error for first-load failures with no useful data.
- Prevented failed refreshes from rewriting widget data and cleared the warning after the next successful recovery refresh.
- Added a regression covering success, cache removal, network failure, retained groups, widget write count, and recovery.

## 2026-07-19 — Race-safe Station Detail refresh ownership

- Added request ownership to Station Detail so routine polling cannot overlap and a manual refresh can supersede active work without doubling coalesced monitor traffic.
- Split initial loading from in-place refreshing and disabled the toolbar refresh action while existing departures are being updated.
- Injected the existing `WidgetSyncing` boundary so only the newest accepted response may update both the screen and widget, with isolated test storage.
- Added regressions for monitor-cache bypass, overlapping polling, forced takeover, busy-state presentation, and single-winner widget synchronization.

## 2026-07-19 — Race-safe Alerts refresh ownership

- Added independent Alerts request ownership so background polling cannot overlap after content is already visible and forced refreshes alone supersede active work.
- Allowed only the newest alert response to publish while retaining `MonitorService` traffic-info coalescing and true manual cache bypass.
- Added a visible refreshing state that disables the toolbar refresh action without replacing already useful alert content with a loader.
- Verified favourite-line changes made during an in-flight request control the published relevance; regressions cover cache, polling, takeover, busy state, and personalization races.

## 2026-07-19 — Race-safe Nearby refresh ownership

- Versioned Nearby load batches so a manual refresh can supersede active polling and only the newest batch may update cards or loading state.
- Kept ordinary overlapping polls suppressed while allowing forced refreshes to reuse `MonitorService` in-flight request coalescing without doubling API traffic.
- Preserved real cache bypass after completed loads and reset loading/refreshing state safely when no nearby stations remain.
- Added regressions for cache bypass, overlapping-poll suppression, concurrent response loading, and manual-refresh takeover during active polling.

## 2026-07-19 — Race-safe Favourites refresh ownership

- Made pull-to-refresh bypass the monitor cache all the way through each favourite-route request instead of presenting cached data as a manual refresh.
- Prevented routine polling from starting a second batch while one is active and versioned forced loads so only the newest batch can publish.
- Invalidated active batches when routes are toggled, removed, or cleared, preventing an older response from restoring deleted favourites.
- Added regressions for force-refresh cache bypass, overlapping-poll suppression, and removal during an in-flight load.

## 2026-07-19 — Concurrent ordered Favourites loading

- Replaced sequential favourite-route response waits with concurrent child tasks while keeping request starts governed by `MonitorService`.
- Reassembled completed results by their saved-route index so the Favourites screen and widget top-three retain the user's chosen order.
- Cancelled remaining child work with the parent load and avoided publishing partial results after cancellation.
- Added a delayed-network regression proving response overlap, stable card order, and stable widget order.

## 2026-07-19 — Overlapped Nearby monitor loading

- Replaced sequential Nearby response waits with concurrent tasks while leaving request-start cadence under the shared `MonitorService` throttle.
- Preserved distance-sorted card identity and order by applying each completed result through its station ID.
- Cancelled remaining child work with the parent load and kept individual station failures isolated to their own card.
- Added a regression proving multiple delayed monitor responses overlap and every nearby card still populates.

## 2026-07-18 — Keyboard-complete authentication flow

- Added explicit SwiftUI focus ownership for email and password fields with a Next action from email and a Go action from password.
- Allowed a valid form to register or sign in directly from the keyboard while guarding the same shared validation boundary as the visible CTA.
- Kept password focus when toggling visibility and dismissed focus before secure authentication work begins.
- Cleared stale presentation errors when the user edits either field or switches auth mode; UI regressions cover keyboard registration and error recovery.

## 2026-07-18 — Localized authentication errors

- Localized all five `AuthError` descriptions at the domain boundary instead of exposing fixed English strings through `LocalizedError`.
- Added complete German and Ukrainian catalog entries for invalid email, weak password, existing account, invalid credentials, and temporary unavailability.
- Added localized VoiceOver values to live email/password validation requirements so satisfied state is announced rather than conveyed by color and icon alone.
- Added a Ukrainian sign-in UI regression that submits an unknown account and verifies the exact localized invalid-credentials message through a stable error identifier.

## 2026-07-18 — Proactive email registration validation

- Promoted email normalization and password-length checks into shared nonisolated `AuthStore` validation helpers used by both business logic and SwiftUI.
- Added live email/password requirement rows with accessible identifiers and disabled email submit until both requirements are satisfied.
- Localized the new validation guidance in German and Ukrainian while keeping account-exists and credential errors on the secure submit boundary.
- Added unit coverage for exact validation boundaries and updated UI regressions for disabled invalid input, scrolling to the CTA, and successful registration.

## 2026-07-18 — Accessible localized authentication

- Reproduced email and Apple authentication in Ukrainian at the largest iOS Dynamic Type size on an iPhone 17 simulator.
- Replaced runtime raw-value auth labels with localized SwiftUI keys so Create account, Sign in, and the primary email CTA follow the app language.
- Capped only the dense auth hero and card at `xxxLarge`, keeping the outer ScrollView and system accessibility setting while making every email and Apple action reachable.
- Added a Ukrainian UI regression that switches auth modes and verifies the primary action label; visual QA confirmed the complete auth card remains legible.

## 2026-07-18 — Coalesced city-wide alert requests

- Extended `MonitorService` request coalescing from station monitors to the city-wide traffic-info endpoint used by Nearby and Alerts.
- Routed traffic-info network work through the shared throttle so alert refreshes no longer bypass the Wiener Linien request-spacing boundary.
- Cancelled and cleared traffic-info in-flight work together with the rest of the monitor cache during travel-data reset.
- Added concurrency, failure cleanup, cancellation, retry, and cache regression tests; concurrent forced refreshes now produce one network call.

## 2026-07-18 — Cached Alerts relevance

- Replaced repeated full-list relevance counts with a cached set of relevant traffic-info IDs rebuilt only after alert refreshes or favourite-line changes.
- Made tab-badge reads and per-row relevance checks constant-time while keeping the complete city-wide alert list available.
- Replaced comparator-based relevance sorting with a stable linear partition that preserves API order inside personalized and general groups.
- Added regression coverage for initial load, favourite-line changes, badge count, stable priority ordering, and repository-read behavior.

## 2026-07-18 — Localized reusable UI component boundaries

- Audited reusable SwiftUI components for runtime `String` parameters that bypass automatic string-catalog lookup.
- Changed shared neobank headers, Search empty states, onboarding feature rows, and station failure labels to accept `LocalizedStringKey`.
- Kept runtime station names explicit at the single dynamic `NeoHeader` call site instead of weakening localization for all static headings.
- Verified every string-catalog entry has both German and Ukrainian values and the complete app target builds successfully.

## 2026-07-18 — Fully localized Nearby actions and insights

- Reproduced the redesigned Nearby dashboard in the Night theme with the Ukrainian app language on an iPhone 17 simulator.
- Fixed quick actions that stayed English because their reusable component accepted runtime `String` values instead of localized keys.
- Localized the default, favourite-line, favourite-station, and scheduled-routine Smart Insight copy in German and Ukrainian.
- Confirmed the hero, quick actions, insight card, and system tab bar render coherently in Ukrainian dark mode without clipping or contrast regressions.

## 2026-07-18 — Accessible Nearby dashboard scaling

- Reproduced the Nearby dashboard at the largest iOS Dynamic Type size on an iPhone 17 simulator.
- Fixed clipped avatar initials, an oversized account heading, a hero card extending behind the tab bar, and an unreachable location CTA.
- Capped scaling only for the dense dashboard header, hero, quick actions, and insight card at `xxxLarge`; the surrounding scroll view and system accessibility setting remain intact.
- Confirmed the complete hero and CTA remain visible at the maximum accessibility size in a freshly installed simulator build.

## 2026-07-18 — Personalized Alerts tab badge

- Completed an iPhone 17 visual QA pass of the redesigned Nearby dashboard after the recent feature slices.
- Replaced the city-wide traffic-info count on the Alerts tab with the count relevant to the user's favourite lines.
- Removed the distracting three-digit badge for users without matching saved lines while preserving the full city-wide Alerts list.
- Confirmed the corrected tab bar in a freshly installed simulator build; full shared-scheme tests and repository validations pass.

## 2026-07-18 — Complete allowlisted travel-data reset

- Added a confirmed “Clear travel data” action that preserves authentication, theme, onboarding, permissions, and the bundled station dataset.
- Clears line/station favourites, commute routines, shared recent searches, widget data/timestamps, pending and delivered departure reminders, TrafficVienna Live Activities, and in-memory/disk departure caches.
- Promoted recent searches to root-owned shared state so an already-created Search tab updates immediately after reset.
- Added repository/store clear APIs and an allowlisted auxiliary reset service; deletion is idempotent and does not use broad UserDefaults domain removal.
- Added UI-state/repository, allowlist preservation, routine persistence, and monitor-cache regression tests; security review found no Critical/High issues, full shared-scheme tests and repository validations pass.

## 2026-07-18 — Provider-aware local account removal

- Added a destructive, confirmed Account action with explicit provider-aware explanations and localized German/Ukrainian copy.
- Email removal deletes the exact hashed-account password verifier from Keychain before clearing the local session; a Keychain failure leaves the session active for safe retry.
- Apple removal clears only TrafficVienna’s local sign-in session and explicitly does not claim to delete or revoke the user’s Apple ID.
- Clarified that favourites and routines are device-local travel preferences and remain after removing the sign-in identity.
- Added email success, Keychain failure, and Apple-boundary regression tests; security review found no Critical/High issues, full shared-scheme tests and repository validations pass, and no auth secrets are logged.

## 2026-07-18 — Editable commute routines

- Added a visible pencil action for every commute routine and a focused edit form for name, station, hour, and minute.
- Preserved the routine UUID and enabled state during edits, so Smart Home identity and toggles remain stable.
- Kept a routine’s current station available in the editor even if it was later removed from Favourites, preventing accidental data loss.
- Added validation that blocks empty names or missing stations and supports cancellation without mutation.
- Localized the editing flow in German and Ukrainian and added persistence regression coverage; full shared-scheme tests, a final app/widget build, and repository validations pass.

## 2026-07-18 — Partial-failure-safe widget refresh

- Added shared deterministic widget merge logic that follows selected favourite order, prefers fresh route data, and falls back to cached data only for routes whose refresh failed.
- Prevented all-request failures from overwriting a useful widget cache with an empty array.
- Kept removed favourites out of fallback results and explicitly clears the widget when the selected route list becomes empty.
- Updated the global “last updated” timestamp only after a complete refresh; partial refreshes retain the conservative previous timestamp.
- Added order, partial-failure fallback, and removed-route regression tests; full app/widget/UI tests pass without new compiler warnings and all repository validations pass.

## 2026-07-18 — Cached and deterministic map markers

- Replaced Map’s render-time computed spatial query with cached marker state refreshed only when its coarse location key changes.
- Quantized the location key to roughly 100-metre buckets so normal GPS jitter does not rebuild and reorder all map annotations.
- Calculated each candidate distance once, added station-ID tie-breaking for deterministic order, and retained the 1.5-km/60-marker product limits.
- Kept station selection and detail-sheet navigation on the cached result, avoiding a second spatial query when a marker is tapped.
- Added distance-order, radius/limit, and jitter-key regression tests; full shared-scheme tests and repository validations pass.

## 2026-07-18 — Ordered and shared line favourites

- Replaced unordered Set-based line-favourite persistence with an insertion-ordered, duplicate-normalized array while retaining the same JSON object shape.
- Updated the widget decoder to preserve the app’s order, making the selected top routes stable across timeline refreshes.
- Made the root-owned `FavoritesListViewModel` the shared in-memory owner for line hearts and favourite routes, eliminating repeated JSON decoding for every Station Detail row.
- Synchronized route changes into personalized Alerts immediately and removed the duplicate line-favourite repository from `StationDetailViewModel`.
- Added insertion-order, rollback-compatibility, legacy-duplicate, shared-state, and repeated-read regression coverage; full app/widget/UI tests and repository validations pass.

## 2026-07-18 — Minute-accurate commute routines

- Preserved the DatePicker’s selected minutes in routine persistence instead of silently rounding every schedule to the hour.
- Added backward-compatible decoding that assigns `minute = 0` to existing records while retaining the legacy `hour` field for rollback compatibility.
- Switched routine selection to circular minute-of-day distance so the correct schedule is chosen around midnight.
- Replaced hard-coded `HH:00` labels with locale-aware short time formatting in Routines and Smart Home.
- Added legacy migration, minute round-trip, and midnight-boundary regression tests; full shared-scheme tests and repository validations pass.

## 2026-07-18 — Contextual Smart Insight navigation

- Turned the Smart Home insight card from a decorative chevron into a real contextual action.
- Routed relevant disruption insights to Alerts, active commute insights to Routines, saved-station insights to Favourites, and the empty default state to Search.
- Added an explicit in-app `AppRouter.navigate(to:)` API so UI actions reuse the same tab-routing path as deep links without manufacturing URLs.
- Connected `RoutinesView` to the shared favourite-station state, removing another direct UserDefaults read and keeping its station picker current.
- Added router regression coverage; full shared-scheme tests and all repository validations pass.

## 2026-07-18 — Unified favourite-station UI state

- Made the root-owned `FavoritesListViewModel` the single UI owner for favourite-station state across Nearby, Search, Map, Favourites, Station Detail, and deep-linked station sheets.
- Removed the duplicate station repository and published favourite flag from `StationDetailViewModel`; its star now updates the same shared state rendered by the dashboard and Favourites tab.
- Loaded persisted stations once when the shared view model is created and removed redundant initial reads from Nearby and Favourites polling tasks; pull-to-refresh still supports an explicit reload.
- Preserved the existing repository format, ordering, widget boundary, and line-favourite behavior, so no data migration or ADR was required.
- Full shared-scheme tests, repository validation, OpenCode validation, and whitespace checks pass.

## 2026-07-18 — Immediate favourite-station state updates

- Routed Nearby context-menu station favourites through the existing shared `FavoritesListViewModel` instead of constructing and decoding a new UserDefaults repository for every menu.
- Updated the published station list immediately after toggle and removal, keeping the dashboard count and Favourites tab consistent without a follow-up storage read.
- Preserved ordered persistence and existing widget/line-favourite boundaries; no new global state was introduced.
- Added a regression proving add, remove, and toggle operations stay synchronized while storage is loaded only once.
- Full shared-scheme tests, repository validation, OpenCode validation, and whitespace checks pass.

## 2026-07-18 — Ranked station search and lookup optimization

- Ranked station matches by exact name, name prefix, word prefix, then embedded match so the most likely Vienna stop appears first.
- Sorted and tokenized the search index once at station-load time, avoiding per-keystroke result sorting and repeated word splitting.
- Added a normalized-name DIVA index so exact monitor lookups no longer rescan and renormalize the full station dataset.
- Added a visible in-card progress state during the search debounce instead of briefly showing a false “No matching stops” result.
- Added regression coverage for exact and prefix ranking plus diacritic-insensitive DIVA lookup; full shared-scheme tests and repository validations pass.

## 2026-07-18 — Stable authentication UI smoke tests

- Moved the DEBUG UI-test session reset into `AuthStore` initialization so persisted authentication is cleared before it can be loaded.
- Preserved production Password AutoFill while disabling the system Strong Password sheet only for isolated UI-test launches.
- Made authentication form submission reliable by dismissing the keyboard and tapping the submit control at a deterministic in-element coordinate.
- Migrated the five-tab root navigation from legacy `tabItem`/`tag` configuration to the typed SwiftUI `Tab` API for the iOS 26 deployment target.
- Added a unit regression for persisted-session reset and aligned the registration smoke test with its purpose by verifying the complete main tab bar after successful registration.
- Full shared-scheme tests pass on iPhone 17 Simulator; repository and OpenCode validations pass.

## 2026-07-18 — App Store metadata and review pack

- Added validated English, German, and Ukrainian App Store names, subtitles, promotional text, descriptions, and keyword sets based only on implemented features.
- Added reviewer instructions for local email registration, optional location, Sign in with Apple, widget, Live Activity, notifications, provider outages, and stale-data behavior.
- Defined a seven-frame localized screenshot story with Apple's current 6.9-inch iPhone and 13-inch iPad sizes.
- Added byte-aware metadata validation to repository checks and explicit pending gates for public privacy/support URLs, Wiener Linien API privacy and content rights, distribution capability, legal fields, and release-candidate screenshots.

## 2026-07-18 — App Store privacy manifest readiness

- Audited required-reason API usage against the app and widget source: the app uses app-only and App Group UserDefaults, while the widget uses App Group UserDefaults.
- Added valid app and widget `PrivacyInfo.xcprivacy` files with `CA92.1` and/or `1C8F.1`, tracking disabled, no tracking domains, and no collected-data entries for the current developer-controlled on-device architecture.
- Extended repository validation to require and lint both manifests, verify their reason codes, and preserve unit/UI scheme wiring.
- Added `docs/PRIVACY.md` as privacy-policy source text and documented the required public hosting step.
- Recorded an explicit App Store label condition: Wiener Linien public material discusses IP logging for online services, but API-specific `ogd_realtime` retention terms still need confirmation.
- An unsigned generic iOS archive succeeds and contains valid privacy manifests at both the app root and embedded widget root.

## 2026-07-18 — Auth and navigation UI automation

- Added a native `TrafficViennaUITests` target to the shared scheme and kept it non-parallel to avoid shared simulator state races.
- Added stable accessibility identifiers for email, password, and submit controls.
- Added UI smoke coverage for email registration through main-tab navigation and invalid-email validation feedback.
- Added a DEBUG-only `-ui-testing-reset` launch path that clears the session, skips onboarding, and uses an isolated in-memory Keychain substitute; production storage remains unchanged.
- Removed the obsolete CI escape hatch that treated a missing XCTest bundle as success now that both unit and UI targets are explicitly wired.
- Updated README, troubleshooting, and release evidence to match the verified test configuration.
- The full shared scheme passes on iPhone 17 Simulator with unit, performance, and UI tests.

## 2026-07-18 — Explicit offline and stale-data UX

- Added typed service freshness metadata for network, fresh memory cache, and stale fallback results without removing the existing response APIs.
- Preserved disk URLCache fallback across cold launches while attaching its original storage date and reporting it as stale instead of incorrectly presenting it as live network data.
- Propagated freshness through Nearby, Favourites, Alerts, and Station Detail view models.
- Added localized saved-data banners, compact stale badges, orange freshness status, and inline per-favourite network errors while retaining useful cached departures.
- Localized offline, stale-cache, and rate-limit explanations in German and Ukrainian.
- Added regression tests for network-to-cache provenance, stale fallback metadata, persistent URLCache provenance, and rate-limit behavior without cache.
- Full XCTest suite and a Ukrainian simulator smoke launch pass on iPhone 17 Simulator.

## 2026-07-18 — Polling and rendering energy optimization

- Bound Nearby, Favourites, Alerts, and Station Detail polling to the active app scene; background/inactive transitions now cancel their polling tasks.
- Added cancellation checkpoints inside sequential Nearby and Favourites request queues so a tab or scene transition stops remaining work promptly.
- Replaced refresh-generated UUID identities with route/time-derived stable IDs, avoiding full SwiftUI list churn on every Favourites update.
- Cached favourite line names in the Alerts view model and replaced per-comparison UserDefaults reads plus temporary Set allocations with direct membership checks.
- Added regression tests proving favourite item identity remains stable and repeated alert relevance checks do not repeatedly read persistent storage.
- Full XCTest suite passes on iPhone 17 Simulator after the performance and energy changes.

## 2026-07-18 — Dark mode and VoiceOver pass

- Added concise VoiceOver labels and hints for password visibility, Apple sign-in, station refresh, and favourite-line controls.
- Combined each departure row into one meaningful accessibility element with localized line, destination, next-departure, and follow-up values.
- Added expanded/collapsed semantics and an accessibility activation action to long disruption descriptions; decorative shared icons are hidden from the accessibility tree.
- Departure-row numeric transitions now respect Reduce Motion.
- Completed missing German and Ukrainian localization for all dynamically generated dashboard states and the new accessibility copy.
- Verified the Ukrainian home in dark mode with accessibility-extra-large text and increased contrast on iPhone 17 Simulator; full XCTest and repository validations pass.

## 2026-07-18 — Ukrainian localization and accessibility polish

- Completed German and Ukrainian translations for the current UI catalog and added a deterministic localization updater/check to repository validation.
- Localized runtime-generated home dashboard states so badges, greetings, titles, subtitles, and actions do not fall back to mixed-language English.
- Adapted the Nearby header and location hero for accessibility text sizes; shimmer and live-pulse animation now respect Reduce Motion.
- Hardened departure countdown parsing for ISO 8601 timestamps with and without fractional seconds and rounded remaining minutes consistently upward.
- Corrected stale-cache regression setup and added fractional-timestamp coverage; the full XCTest suite, repository validation, OpenCode validation, and whitespace checks pass.
- Verified the redesigned home visually on iPhone 17 Simulator at accessibility-extra-large text, increased contrast, and Ukrainian locale.

## 2026-07-18 — Authentication hardening and working deep links

- Upgraded device-local email verifiers to PBKDF2-HMAC-SHA256 with 120,000 iterations, random salts, timing-safe comparison, and transparent migration of legacy SHA-256 Keychain records after successful login.
- Added an explicit app Info.plist and registered the `trafficvienna://` URL scheme while preserving location, Live Activity, scene, launch, and orientation metadata.
- Verified the URL type in the built app bundle and confirmed the simulator recognizes `trafficvienna://search`; router unit tests cover destination parsing.
- Full XCTest suite passes on iPhone 17 Simulator after the security and plist changes.

## 2026-07-18 — Routines, widget optimization, docs, and release audit

- Added persisted commute routines tied to favourite stations and time; routines are managed from Account and surfaced by Smart Home.
- Optimized widget requests by grouping favourite routes by DIVA, added request timeout, and restored real stop names from the widget monitor response.
- Added routine persistence and deep-link parser regression tests.
- Updated README/context to match actual authentication, routines, reminders, offline, tests, and distribution limitations.
- Security review found no Critical/High issues in the local-only boundary; release verdict is Conditional Go pending Apple capability, URL association, backend identity, GTFS routing source, CI, and device QA.

## 2026-07-18 — Neobank system and smart travel slice

- Added reusable neobank design tokens/components and migrated Search, Favourites, Alerts, Map accents, and Station Detail to shared rounded surfaces, headers, icons, and grouped backgrounds.
- Added Smart Home insight data from favourites and relevant disruptions; service alerts affecting saved lines are now sorted first and explicitly labelled.
- Added time-sensitive local departure reminders from Station Detail context actions and modernized deprecated Live Activity update/end calls.
- Added explicit URLCache stale fallback across launches and an `AppRouter` foundation with tested `trafficvienna://station/<id>` parsing; URL-scheme registration remains a distribution configuration task.
- Full XCTest suite passes cleanly on iPhone 17 Simulator.

## 2026-07-18 — Test foundation and first performance pass

- Restored the missing `TrafficViennaTests` native target referenced by the shared scheme; the full XCTest suite now builds and runs on iPhone 17 Simulator.
- Added performance baselines for indexed station-name search and nearby spatial queries, plus regression coverage for station ID lookup and traffic-info caching.
- Added StationStore ID/search/spatial indexes so repeated search, recent lookup, Nearby, and Map queries avoid repeated normalization and full-dataset location scans.
- Limited Nearby, Alerts, and Favourites polling to the active tab and guarded Nearby against overlapping refreshes.
- Added cached/stale fallback behavior for traffic alerts, configured URLSession timeouts/cache policy, removed new Swift Sendable warnings, and migrated Maps opening to the iOS 26 API.
- Validation: `xcodebuild ... test` passes cleanly on iPhone 17 Simulator.

## 2026-07-18 — Authentication redesign

- Reworked the home screen again after user feedback into an original neobank-style experience inspired by Revolut's interaction principles: personal avatar header, large blue-violet live card, high-contrast primary action, circular quick actions, and modular information cards. Transport behavior and navigation remain native to TrafficVienna.
- Replaced the legacy Nearby screen with a full Vienna-branded home experience: custom traffic identity header, time-aware greeting, editorial hero typography, material live-location card, status metrics, integrated account/theme controls, refreshed departure-list header, and material tab bar.
- Started from clean local `main` and created `codex/auth-redesign`; remote refresh was blocked by the machine's missing GitHub SSH authorization.
- Added a redesigned auth gate with a Vienna-inspired gradient, registration/sign-in switcher, accessible email/password fields, native Sign in with Apple, validation, and clear device-local privacy copy.
- Switched the default app theme for new installs from Indigo to the branded Vienna preset, carrying the new red accent, grouped surfaces, and elevated cards into the main experience while preserving existing users' saved theme.
- Added `AuthStore`: multiple local email accounts use per-account Keychain records with random salt and SHA-256 password digest; sessions persist without storing passwords in UserDefaults.
- Added Apple credential handling, launch-time revoked credential validation, the Sign in with Apple entitlement, and an account sheet with provider details and sign-out.
- Added focused auth regression tests to the existing test source. The app build passes with no new auth warnings (two pre-existing MapKit deprecation warnings remain); XCTest remains unavailable because the repository's scheme has no configured test bundle.

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
