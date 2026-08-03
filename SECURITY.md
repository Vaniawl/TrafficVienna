# Security

## Product trust boundaries

- The app consumes fixed public Wiener Linien HTTPS endpoints. Server-provided
  text is decoded as data; it is not executed as HTML or used to construct
  arbitrary outbound URLs.
- Precise location stays in memory for nearby filtering and the system map
  annotation. It is not persisted or logged; denied/error states retain a
  Vienna-centre fallback.
- Favourites, recent searches, widget selections, typed routing handoff, and
  reminder metadata are local UserDefaults/App Group or system-owned data.
- User-created departure reminders use UserNotifications only. They add no APNs
  token, backend, remote-push claim, account, or external network destination.
- Reminder taps accept only the owned notification prefix and a valid station ID,
  then use the typed root router. Scheduling is revalidated after the permission
  prompt so an expired reminder cannot become an immediate misleading alert.
- Live Activities are explicit user actions. Line, destination, stop, and
  departure time become system-managed Lock Screen content. New countdowns are
  blocked for stale departures; existing ActivityKit state is restored and may
  still be stopped.
- The App Group identifier `group.wellbe.TrafficVienna` is shared only by this
  app and its widget. Widget stop identifiers are validated before requesting
  the fixed endpoint.
- The release is account-free. No identity, credential, authorization token,
  analytics SDK, or new dependency is introduced. Legacy identity cleanup is
  bounded to the known historical Keychain item.

## Required review areas

- Location permission wording, denied/restricted states, and data minimisation.
- Fixed URL construction, API decoding, rate limiting, caching, and stale/error
  handling.
- App Group access, notification metadata validation, typed external routing,
  and absence of sensitive values in logs.
- UserNotifications permission timing, cancellation, delivered/pending cleanup,
  and failure disclosure.
- ActivityKit availability, restoration, update/end lifecycle, stale-data
  prevention, and absence of unrelated widget mutation.
- Localisation of privacy-facing and error messages.
- New dependencies, endpoints, entitlements, analytics, or external services.

## Agent boundary

Do not read `.env`, credentials, private keys, tokens, SSH/GitHub configuration,
or unrelated projects. Local implementation, focused `codex/*` branches,
task-owned commits, feature-branch pushes, and draft PR handoff are allowed.
Direct `main` pushes, force pushes, merge, ready-for-review, release, deploy,
and production infrastructure changes require explicit user approval.

## Completion gate

The actual changed files must have zero unresolved Blocking or Important
security findings. These controls are engineering requirements, not claims of
regulatory or App Store compliance.
