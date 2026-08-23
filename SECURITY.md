# Security

## Product trust boundaries

- The app consumes only the fixed public Wiener Linien HTTPS endpoints used by
  departures, alerts, and the widget. Server text is decoded as plain data; no
  HTML or arbitrary server-provided URL is executed.
- Precise location is used in memory for Nearby, map filtering, and the system
  user annotation. Coordinates are neither persisted nor logged.
- Favourites, recent station identifiers, widget rows, onboarding completion,
  and closed-enum navigation handoffs are local `UserDefaults` or App Group data.
- The App Group `group.wellbe.TrafficVienna` is shared only by this app and its
  widget. Failed route responses are excluded from widget synchronization.
- Live Activity starts only after explicit user action. Its transport details
  become system-managed Lock Screen/Dynamic Island content; failures are shown
  without logging those details.
- The current product has no account UI, auth entitlement, backend session,
  analytics SDK, payment path, or credential storage. A one-time migration deletes
  the known obsolete device-only Keychain profile and retries after real failures.
- App and widget privacy manifests declare their current `UserDefaults` reasons,
  no tracking, and the conservative network-data category.

## Required review areas

- Location rationale, denied/restricted/fallback states, and data minimisation.
- Fixed URL construction, decoding, throttling, coalescing, caching, and stale-data
  disclosure.
- App Group scoping and absence of sensitive values in logs.
- Localisation of privacy, permission, saved-data, and failure messages.
- ActivityKit availability/failure handling and prevention of unrelated widget
  mutation.
- Any future dependency, network destination, analytics, identity, ticket, or
  payment boundary requires explicit scope approval and a fresh security review.

## Agent and publication boundary

Local repository work may not read secrets, `.env`, private keys, SSH material, or
unrelated projects. The project workflow may inspect Git metadata, verify the
configured GitHub CLI account without exposing credentials, push a validated
`codex/*` branch, and create/update a draft PR. Merge, ready-for-review, signing-key
changes, App Store Connect mutation, upload, submit, release, and deployment require
explicit approval.

## Current review result

The native app changes introduce no new endpoint, secret, entitlement, command
execution, or tenancy boundary. The 23 August repository audit found that the
unused `opencode-mobile` developer plugin had committed its vulnerable dependency
tree, tunnel executables, and a test key fixture. The plugin, manifests, and tracked
`node_modules` tree are removed, `node_modules/` is ignored, and repository
validation now rejects any tracked copy. The remaining OpenCode configuration has
no project-local Node dependency. This is not a claim of App Store compliance;
release evidence remains governed by the release checklist.
