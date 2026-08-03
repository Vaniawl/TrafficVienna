# Active specification

## Goal

Audit and improve TrafficVienna with a coherent professional UI/UX and focused
correctness, accessibility, performance, security, and documentation fixes while
preserving its native SwiftUI architecture and transport journeys.

## Active requirements

### REQ-TV-001 - Preserve core journeys

Home/nearby, Discover search and map, Alerts, Saved, Station Detail, widget,
Live Activity, onboarding, localisation, and location-denied behaviour must
remain functional.

### REQ-TV-002 - Deliver a coherent accessible design

Key screens must use consistent hierarchy, spacing, typography, colour,
components, and loading/empty/error states. They must support light/dark
appearance, Dynamic Type, VoiceOver, and relevant reduced-motion behaviour.

### REQ-TV-003 - Refactor only proven code-health problems

Keep views focused, preserve suitable service and MVVM boundaries, and avoid
speculative abstractions. Behavioural fixes require focused regression coverage.

### REQ-TV-004 - Make failure and localisation behaviour complete

User-facing strings must be localisable. Permission denial, empty datasets,
network failure, API throttling, stale data, and retry paths need clear,
non-destructive feedback.

### REQ-TV-005 - Protect runtime and network performance

Visible refresh work must cancel when appropriate, avoid redundant requests,
respect API throttling, and avoid unnecessary body-time allocations. Performance
claims require a reproducible measurement or focused code evidence.

### REQ-TV-006 - Establish sufficient validation evidence

Repository validation, OpenCode validation, Swift compilation, XCTest/XCUITest,
widget checks, static analysis, localisation extraction, and proportional
simulator inspection must pass without failure masking.

### REQ-TV-007 - Finish with synchronized review-ready state

State files must reflect observed evidence. Architecture, security, and
release-readiness review must have no unresolved Blocking or Important finding
for the task-owned change set.

### REQ-TV-008 - Keep system surfaces truthful

Local reminders, widgets, notification routing, App Intents, and Live Activities
must use typed destinations and explicit user actions. New countdowns may start
only from live departure data; active ActivityKit state must be restorable after
view-model recreation.

### REQ-TV-009 - Preserve the account-free privacy boundary

All transport features remain anonymous. The app must not collect identity or
simulate a local account. Legacy identity cleanup remains idempotent; identity
requires a separate approved product and security decision.

## Definition of Done

- Focused regressions and the full simulator suite pass.
- App and widget build without new warnings; static checks pass.
- Core journeys are exercised in Simulator with light/dark and accessibility
  evidence for changed or high-risk screens.
- English/German catalogues cover compiler-extracted strings.
- State, privacy, security, and release documentation agree with the code.
- Any external App Store/TestFlight gates are reported, not masked.
