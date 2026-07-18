# Release readiness — 2026-07-18

## Verdict: Conditional Go

The branch is suitable for draft-PR and simulator QA. It is not ready for App Store release until the external identity and distribution conditions below are completed.

## Evidence

- `xcodebuild ... test` passes on the iPhone 17 Simulator with the app, widget extension, unit/performance target, and UI smoke target covering email registration plus primary navigation.
- Live API access is HTTPS-only, rate-limited, cached, coalesced, time-bounded, and has stale-response fallback.
- Password verifiers are kept in Keychain; non-secret session metadata alone is kept in UserDefaults.
- Polling is limited to the active tab and overlapping Nearby refreshes are rejected.

## Security findings

- **Low, local-only identity limitation:** local email authentication now uses PBKDF2-HMAC-SHA256 with 120,000 iterations, a random salt, timing-safe comparison, and transparent migration of legacy Keychain records. It still must not be promoted as a server account; a backend-controlled adaptive KDF and recovery flow are required for cross-device identity.
- **Medium, backend Apple condition:** the app checks Apple credential state locally but does not send and verify the identity token on a server. Server verification is required when backend identity is introduced.
- **Low:** favourite line and destination values are public diagnostic strings. Do not add email, precise location, tokens, or credentials to logs.

No Critical or High findings were observed in the reviewed local-only threat boundary.

## Required external follow-up

1. Enable Sign in with Apple for `wellbe.TrafficVienna` and regenerate provisioning profiles.
2. Configure Associated Domains only if universal HTTPS links are required; the custom `trafficvienna://` scheme is registered and simulator-verified.
3. Select a backend before password recovery or cross-device account claims.
4. Select a licensed GTFS/routing source before implementing A→B journeys.
5. Run protected macOS CI and device-level notification, Apple ID, widget, and offline QA.

## Compatibility and rollback

- Existing favourites remain in the same App Group keys.
- New routine data is additive under `commute_routines`.
- No destructive data migration is required.
- Rollback is a revert of the feature commits.
