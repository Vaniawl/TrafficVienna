# Status

- Product status: **COMPLETE locally / draft-PR ready**.
- Release status: **NO-GO** until the external signing, App Store Connect,
  upload-processing, and physical/TestFlight gates in
  `docs/release/app-store-readiness.md` are observed.
- Workspace: `/Users/ivandovhosheia/Swift/TrafficVienna`.
- Branch: `codex/premium-dashboard-app-redesign`.
- Scope: native SwiftUI app, widget extension, local favourites/recents, public
  Wiener Linien data, location, App Shortcuts, widget, and Live Activity.
- Identity boundary: no account UI, authentication entitlement, backend, or remote
  session. A tested one-time migration removes obsolete device-only Keychain data.
- Validation: repository/OpenCode/reliability and negative scheme-wiring checks,
  app/widget build, and 119/119 standard tests (117 unit/integration plus two
  XCUITest smoke journeys) pass locally on 23 August 2026. Protected remote CI is
  re-observed after the current draft-PR update.
- Visual acceptance: the isolated matrix passed 4/4 standard iPhone journeys plus
  1/1 maximum-accessibility iPhone and 1/1 maximum-accessibility iPad journeys.
  Dark appearance, maximum Accessibility Dynamic Type, Increase Contrast, and
  Reduce Motion covered every primary route. Ten current localized App Store
  screenshots were regenerated on an isolated iPhone 17 Pro Max, validated at
  1320×2868, and visually accepted after waiting for complete MapKit rendering.
- Review: independent SwiftUI, state/CI, and architecture/release audits exposed
  widget contrast, VoiceOver, refresh-loop, fail-open test, screenshot atomicity,
  and developer-tool supply-chain findings. The confirmed local findings are fixed;
  the draft stays No-Go for merge until the current validation and protected CI pass.
- Remaining work: only the external release gates and protected PR/CI lifecycle;
  these do not authorize merge, ready-for-review, upload, submit, or release.
