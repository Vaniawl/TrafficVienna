# Security

## Product trust boundaries

- The app consumes public Wiener Linien transport endpoints.
- Precise location is device data and must remain in the application boundary;
  it must not be logged, committed, or sent to unrelated services.
- Favourites, recent searches, widget data, and theme choices are local
  `UserDefaults` or App Group data.
- The App Group identifier `group.wellbe.TrafficVienna` is used exclusively by this app.
- The widget extension shares only the data required for widget behaviour.

## Required review areas

- Location permission wording, denied/restricted states, and data minimisation.
- URL construction, API decoding, rate limiting, caching, and error handling.
- App Group access and absence of sensitive values in logs.
- Localisation of privacy-facing and error messages.
- New dependencies, network destinations, analytics, or external services.

## Agent boundary

The agent must not read `.env`, credentials, private keys, SSH/GitHub state, or
other projects. No credential is required for local design and refactoring. Git
publication, release, deployment, and production infrastructure are forbidden.

## Completion gate

Security-reviewer must examine the actual changed files and report zero
unresolved Blocking or Important findings. Security controls are requirements,
not claims of regulatory or App Store compliance.

