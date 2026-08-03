# App Store readiness

Status date: 3 August 2026

Current verdict: **No-Go** until every blocking item below has observed evidence.
This file is intentionally stricter than a successful Simulator build.

## Acceptance boundary

A `Go` requires:

- a clean Release archive for generic iOS with valid app and widget signatures;
- bundle IDs, versions, embedded profiles, and signed entitlements matching the
  App Store records;
- valid privacy manifests in both executable bundles and matching App Privacy
  answers;
- complete metadata, screenshots, privacy/support URLs, review notes, age
  rating, content rights, and export-compliance answers;
- full local tests plus protected CI;
- iPhone and iPad runtime acceptance, including optional-location behavior;
- physical-device or TestFlight evidence for system surfaces that Simulator
  cannot prove;
- a documented rollback path.

## Evidence already observed

- Xcode 26.6 with the iOS 26.5 SDK satisfies Apple’s SDK 26 upload requirement.
- The deployment target is iOS 26.0 for iPhone and iPad.
- A clean generic unsigned Release archive packages an arm64 app and arm64
  widget. Inspection of the built products confirms `Traffic Vienna`, version
  `1.0` build `1`, minimum iOS `26.0`, the expected app/widget bundle IDs, and
  `ITSAppUsesNonExemptEncryption = NO`.
- The app icon contains 1024×1024 light, dark, and tinted RGB assets.
- The packaged 120×120 iPhone and 152×152 iPad icons contain no alpha.
- The app and widget declare their actual App Group entitlement.
- Valid `PrivacyInfo.xcprivacy` files are packaged at the root of both executable
  bundles. They declare UserDefaults required reasons, no tracking, and the
  conservative network-data category.
- Location purpose text is present in English and German.
- The app has an in-app privacy screen, a public policy source, and direct support
  and policy links.
- Only Apple operating-system HTTPS encryption is used, and
  `ITSAppUsesNonExemptEncryption` is `NO`.
- The account-only Apple identity surface and entitlement were removed because
  they provided no cross-device feature and prevented the installed profile from
  archiving. A one-time migration deletes the legacy device-only Keychain item.
- All 194 tests pass with zero failures or skips, including five XCUITest
  journeys through the four-tab shell, Discover map entry, alert filters, Saved,
  search-to-station navigation, and cross-tab favourite reconciliation. Local
  reminder planning/decoding, idempotent
  route replacement and legacy cleanup, notification denial recovery, Live
  Activity update/stop behavior, widget departure-boundary scheduling, stale
  countdown prevention, permission-prompt expiry, and ActivityKit state
  restoration have regression coverage. Location revocation/reset clears cached
  precise coordinates, and Map ignores stale coordinates without authorization.
  An authorized one-shot location failure now exposes a retry action on Home,
  clears the error on the next request, and keeps retained useful coordinates
  visible during a transient refresh failure.
  Widget snapshot policy keeps example departures inside Gallery previews and
  uses the real empty state when a runtime snapshot has no selected or cached data.
  Saved-route reload coverage proves that an overlapping repository change queues
  one current pass even before notification delivery, preserves an explicit forced
  refresh, and blocks an obsolete pass from republishing removed data to the UI or
  widget. Targeted row retries use the same serialized owner, cannot be overwritten
  by an older polling result, and are subsumed by a queued forced full refresh.
  Cancellation still prevents publication and any queued follow-up or retry.
  Station Detail and Alerts also queue one explicit forced refresh behind active
  polling, suppress the obsolete pass and its error, and drop the queued follow-up
  when the owning task is cancelled. Nearby likewise serializes overlapping
  polling, location changes, and pull-to-refresh; the latest location and strongest
  force intent win, cancelled work cannot mark retained departures failed, and a
  surviving location task explicitly takes ownership. Root navigation regression
  coverage proves that external Home, Discover, and Saved destinations clear only
  their target stack, notification routing replaces Discover with one resolved
  station, and ordinary tab changes preserve their paths.
  Station Detail favourite coverage proves that repository changes made from a
  different tab refresh both station and route state and that a stale local route
  cache cannot invert the displayed result after the next toggle. Paired iPhone
  17 screenshots show the filled Schwedenplatz star before Saved removal and the
  cleared star after returning to the preserved Discover stack.
  Shared-service refresh coverage proves that forced station and traffic-info
  requests behind regular work receive exactly one serial successor, concurrent
  forced callers coalesce, a failed regular request cannot suppress manual
  refresh, and the successor remains the authoritative cached result.
  Widget freshness coverage separates countdown projection time from transport
  source time, uses the oldest source across visible mixed rows, persists that
  value through App Group sync, and proves both legacy-payload reads and rollback
  decoding of the optional field. Widget fetch throttling is keyed by the
  canonical selected-route set, so a recent request for one configuration cannot
  suppress another configuration's initial fetch; empty selections do not claim
  refresh budget, and manual refresh still bypasses a recent scoped attempt.
  Timeline scheduling covers all three departures that the widget can render per
  route, including a removal entry one minute after the third departure and
  before the five-minute refresh deadline. Departure and removal boundaries are
  independent, so an older cached departure already projected as `now` still
  receives its future removal entry.
- iPhone 17 Pro Max and iPad Pro 13-inch runtime builds complete without
  diagnostics. English, German, location-denied, live-data, Favourites, and
  maximum Accessibility Dynamic Type paths were exercised.
- iPhone 17 warm-link acceptance reproduced an open Stephansplatz detail surviving
  `trafficvienna://search` on the previous implementation, then verified and
  captured the corrected Discover root after the navigation-path fix.
- iPhone 17 audit screenshots capture Home's retryable location failure in light
  and dark appearance and the recovered live Stephansplatz departures after a
  successful Vienna location request; the inspected cards and controls are not
  clipped at the standard content size.
- Xcode detects an available physical `iPhone18,2` on iOS 26.5.2. A Release
  device build selects the expected development identity and widget provisioning
  profile, compiles successfully to the signing phase, and reproduces the same
  non-interactive Keychain error at widget `codesign`.
- Ten current localized 6.9-inch screenshots are prepared at 1320×2868 JPEG with
  no alpha: Home, Station Detail, Discover Map, Alerts, and Saved in both `en-US`
  and `de-AT`. The final pass reduced map density and recaptured both localized
  Map frames.
- All six widget families compile with explicit previews. Simulator acceptance
  rendered small, medium, and large Home Screen widgets in light mode, large in
  dark mode, a circular Lock Screen widget, and the Lock Screen Live Activity.
  Countdown boundary scheduling, adaptive one-route layouts, and unclipped
  freshness labels were observed; physical/TestFlight acceptance remains a gate.
- A controlled Home Screen fixture reproduced legacy cached departures reporting
  only the recent projection age, then verified that the corrected medium widget
  reported the roughly 23-minute transport-source age while its countdown kept
  updating. This is Simulator evidence only; production background refresh still
  remains in the physical/TestFlight gate.
- A second controlled fixture rendered an older cached N38 departure as `now`,
  then removed it 34 seconds later without waiting for the five-minute network
  refresh. Live N38 data was fetched and visually confirmed after cleanup.
- One-shot coalesced location requests replace continuous tracking. The redesigned
  station detail reaches a settled UI state; eight idle Debug Simulator process
  samples measured 0.0% CPU after removing its repeating pulse and 30-second
  refresh cadence.
- App Store metadata copy is within Apple’s field limits: subtitles 23/21
  characters, promotional text 129/126, descriptions 1125/1355, and keywords
  80/72 for English/German.
- Release-readiness PR #10 and stacked product PR #9 are merged at release code
  integration commit `52009857a361e0a3c138c4cbded380034dc48f16`. That
  code SHA's push Quality run `30432216226` completed successfully in 8m09s
  with the pinned OpenCode checks, repository validation, build, tests, and
  final diff check. Later evidence-only documentation commits do not alter the
  inspected app sources or binaries.
- The continued audit remains unmerged in draft PR #15. Its exact app-code head
  `f08662c0fe5dd5ba380316f2f95fb06c667d3060` passed protected Quality run
  `30777324747` in 14m00s, including the pinned OpenCode CLI, repository
  validation, app/widget build, the 192-test suite, and the final diff check.
  The later local location-recovery slice passes 194/194 tests, Xcode Analyze,
  and compiler extraction with all 237 app and 27 widget source keys covered by
  the committed 267/32-key catalogues; its own protected check remains required
  after publication.
- `main` now requires pull requests and a strict successful `validate` check.
  Conversation resolution is required, admin enforcement is enabled, and force
  pushes and branch deletion are disabled.
- The production privacy policy resolves with HTTP 200 from both the raw
  `main/PRIVACY.md` endpoint and the GitHub-rendered public URL. Support and
  Wiener Linien URLs also return HTTP 200.
- A fresh unsigned archive also reaches Xcode's App Store validation workflow
  through `AppStoreValidationOptions.plist`. Xcode resolves the actual team ID
  `KZNP8PH94C`, then stops before validation because no local Xcode account has
  App Store Connect access for that team.

## Blocking evidence still required

| Gate | Current evidence | Required proof |
| --- | --- | --- |
| Distribution signing | The old Sign in with Apple profile mismatch is gone. Both signed archive and connected-device Release build select the expected identity/profiles and reach widget signing, but the login Keychain rejects non-interactive private-key access with `errSecInternalComponent`. | Grant `codesign` access to the private key in an interactive trusted session, then produce and inspect one clean signed archive. |
| App Store Connect | Xcode provisioning access works for team `KZNP8PH94C`, but its distribution logs report no local account with App Store Connect access for that team. No browser or API-key session is available. | Authenticate an App Store Connect account or API key for the team, then confirm bundle ID registration, app record, agreements, roles, version/build uniqueness, privacy answers, age rating, categories, availability, and review contact. |
| Store assets | Metadata and ten technically valid localized 6.9-inch screenshots are prepared locally. | Attach them to the App Store version and verify the final locale/order in App Store Connect. |
| System-surface acceptance | Simulator coverage cannot prove production Apple signing, physical-device location, notification delivery, widget refresh/configuration, Dynamic Island, or Live Activity behavior. | Install a signed/TestFlight build on a supported physical device and complete the release smoke path, including local departure reminders. |
| Apple processing | No build has been uploaded. | Upload only after explicit release approval; wait for processing, inspect warnings/privacy report, then run internal TestFlight smoke. |

## Repeatable evidence commands

```sh
xcodebuild -scheme TrafficVienna -project TrafficVienna.xcodeproj \
  -destination 'platform=iOS Simulator,name=iPhone 17' test

xcodebuild -scheme TrafficVienna -project TrafficVienna.xcodeproj \
  -configuration Release -destination 'generic/platform=iOS' \
  -archivePath /tmp/TrafficVienna.xcarchive \
  CODE_SIGNING_ALLOWED=NO archive

xcodebuild -scheme TrafficVienna -project TrafficVienna.xcodeproj \
  -configuration Release -destination 'generic/platform=iOS' \
  -archivePath /tmp/TrafficVienna-signed.xcarchive \
  -allowProvisioningUpdates archive

xcodebuild -exportArchive \
  -archivePath /tmp/TrafficVienna-signed.xcarchive \
  -exportPath /tmp/TrafficVienna-validation \
  -exportOptionsPlist docs/release/AppStoreValidationOptions.plist \
  -allowProvisioningUpdates
```

The final two commands must succeed in a trusted signing and App Store Connect
session before this checklist can move to `Go`.

## Rollback

Before upload, rollback is a normal revert of the release-readiness commit or
discarding the feature branch. The one-time legacy Keychain cleanup intentionally
deletes an obsolete device-only profile and is not reversible; it does not touch
favourites, recents, widget data, location, or any server record.

After an App Store upload, do not reuse the same build number. Submit a new build
with a higher `CURRENT_PROJECT_VERSION`; never replace or force-update a processed
binary.

## Release prohibition

Do not merge, mark ready for review, upload, submit for review, or release from
this checklist without the explicit approval required by the repository rules.
