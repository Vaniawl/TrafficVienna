# App Store readiness

Status date: 29 July 2026

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
- All 108 XCTest cases pass with zero failures or skips. The cleanup migration is
  covered for success, missing-item, and retry-after-failure paths.
- iPhone 17 Pro Max and iPad Pro 13-inch runtime builds complete without
  diagnostics. English, German, location-denied, live-data, Favourites, and
  maximum Accessibility Dynamic Type paths were exercised.
- Xcode detects an available physical `iPhone18,2` on iOS 26.5.2. A Release
  device build selects the expected development identity and widget provisioning
  profile, compiles successfully to the signing phase, and reproduces the same
  non-interactive Keychain error at widget `codesign`.
- Ten localized 6.9-inch screenshots are prepared at 1320×2868 JPEG with no
  alpha: Nearby, Station Detail, Map, Alerts, and Favourites in both `en-US`
  and `de-AT`.
- App Store metadata copy is within Apple’s field limits: subtitles 23/21
  characters, promotional text 129/126, descriptions 1106/1345, and keywords
  80/72 for English/German.
- Draft PR #10 runs the protected GitHub Quality workflow. Run `30426734694`
  completed successfully with `actions/checkout@v6` and
  `actions/setup-node@v6`, including the pinned OpenCode checks, repository
  validation, build, tests, and final diff check, with no annotations.

## Blocking evidence still required

| Gate | Current evidence | Required proof |
| --- | --- | --- |
| Distribution signing | The old Sign in with Apple profile mismatch is gone. Both signed archive and connected-device Release build select the expected identity/profiles and reach widget signing, but the login Keychain rejects non-interactive private-key access with `errSecInternalComponent`. | Grant `codesign` access to the private key in an interactive trusted session, then produce and inspect one clean signed archive. |
| App Store Connect | No browser/account session is available, so no app record or agreement state has been inspected or changed. | Confirm bundle ID registration, app record, agreements, roles, version/build uniqueness, privacy answers, age rating, categories, availability, and review contact. |
| Public privacy URL | Support and Wiener Linien links return HTTP 200. The proposed `main/PRIVACY.md` URL returns HTTP 404 until this branch is merged. | Confirm the final privacy URL returns HTTP 200 before attaching it to the App Store version. |
| Store assets | Metadata and ten technically valid localized 6.9-inch screenshots are prepared locally. | Attach them to the App Store version and verify the final locale/order in App Store Connect. |
| System-surface acceptance | Simulator coverage cannot prove production Apple signing, physical-device location, widget refresh, Dynamic Island, or Live Activity behavior. | Install a signed/TestFlight build on a supported physical device and complete the release smoke path. |
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
```

The final command must succeed in the trusted signing session before this
checklist can move to `Go`.

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
