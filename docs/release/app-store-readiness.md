# App Store readiness

Status date: 11 August 2026

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
- A fresh clean generic unsigned Release archive of the premium branch succeeds at
  `/tmp/TrafficVienna-20260811-premium.xcarchive` and packages arm64 app and widget
  executables. Inspection confirms `Traffic Vienna`, version `1.0` build `1`,
  minimum iOS `26.0`, the expected app/widget bundle IDs,
  `ITSAppUsesNonExemptEncryption = NO`, and both privacy manifests. Source/project
  search confirms the current product has no account/auth capability reference.
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
- All 112 tests in the standard scheme pass with zero failures or skips: 110
  unit/integration tests plus deterministic XCUITest smoke journeys for onboarding,
  primary tabs, station search, and station detail. The cleanup migration is
  covered for success, missing-item, and retry-after-failure paths; colour
  regressions enforce 4.5:1 hero and semantic-text contrast.
- A fresh iPhone 17 product-acceptance run exercised every redesigned route and
  inspected high-risk live dashboards/onboarding in dark appearance, maximum
  Accessibility Dynamic Type, and Increase Contrast. It exposed and closed
  contrast and horizontal-wrapping defects before the final CI pass.
- iPhone 17 Pro Max and iPad Pro 13-inch runtime builds complete without
  diagnostics. English, German, location-denied, live-data, Favourites, and
  maximum Accessibility Dynamic Type paths were exercised.
- Xcode detects an available physical `iPhone18,2` on iOS 26.5.2. A Release
  device build selects the expected development identity and widget provisioning
  profile, compiles successfully to the signing phase, and reproduces the same
  non-interactive Keychain error at widget `codesign`.
- Ten localized 6.9-inch screenshots were regenerated from the current premium
  build at 1320×2868 JPEG with no alpha: Nearby, Station Detail, Map, Alerts, and
  Favourites in both `en-US` and `de-AT`. Both isolated capture tests passed and
  every image was visually inspected; no placeholder, overlay, clipping, or stale
  red-design asset remains.
- App Store metadata copy is within Apple’s field limits: subtitles 23/21
  characters, promotional text 129/126, descriptions 1106/1345, and keywords
  80/72 for English/German.
- Release-readiness PR #10 and stacked product PR #9 are merged at release code
  integration commit `52009857a361e0a3c138c4cbded380034dc48f16`. That
  code SHA's push Quality run `30432216226` completed successfully in 8m09s
  with the pinned OpenCode checks, repository validation, build, tests, and
  final diff check. Later evidence-only documentation commits do not alter the
  inspected app sources or binaries.
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
| System-surface acceptance | Simulator coverage cannot prove production Apple signing, physical-device location, widget refresh, Dynamic Island, or Live Activity behavior. | Install a signed/TestFlight build on a supported physical device and complete the release smoke path. |
| Apple processing | No build has been uploaded. | Upload only after explicit release approval; wait for processing, inspect warnings/privacy report, then run internal TestFlight smoke. |

## Repeatable evidence commands

```sh
bash scripts/test.sh

bash scripts/capture-app-store-screenshots.sh

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
