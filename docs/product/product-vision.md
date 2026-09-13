# Product Vision

TrafficVienna helps residents and visitors make quick, informed public-transport
decisions in Vienna. It combines nearby stops, station search, live departures,
disruptions, saved routes, widgets, reminders, and Live Activities in a native,
accessible iOS experience.

The product remains account-free and uses fixed Wiener Linien public endpoints.
Precise location is used only for nearby results and is not persisted or logged.
The complete active product scope and audience are maintained in `PROJECT.md`; this
document supplies the framework's stable product-vision entry point without replacing
that history.

## Principles

- Keep departure and disruption information timely, clear, and honest about freshness.
- Preserve native accessibility, localization, and reduced-motion behavior.
- Keep transport use anonymous and local preferences on the device or App Group.
- Require explicit user action for reminders and Live Activities.
- Improve the established SwiftUI and MVVM boundaries through focused changes.

## Strategic non-goals

Android, ticket sales, route planning, remote disruption push, accounts, and production
deployment remain outside the current scope unless approved in the product backlog.
