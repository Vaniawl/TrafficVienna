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
- Validation: `bash scripts/ci.sh` exited 0 with repository/OpenCode/reliability
  checks, app/widget build, 110/110 tests, and `[ci] OK` on 11 August 2026.
- Visual acceptance: all redesigned routes were exercised on iPhone 17. Dark,
  maximum Accessibility Dynamic Type, and Increase Contrast checks covered the
  highest-risk live dashboards and onboarding. The run exposed and closed hero
  contrast plus Station/Departure/Disruption wrapping defects.
- Review: SwiftUI and security/release audits found no unresolved
  Critical/High/Blocking/Important code finding after the fixes.
- Remaining work: only the external release gates and protected PR/CI lifecycle;
  these do not authorize merge, ready-for-review, upload, submit, or release.
