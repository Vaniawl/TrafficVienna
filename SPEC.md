# Active specification

## Goal

Audit and improve TrafficVienna with a coherent professional UI/UX and focused
code refactoring while preserving its useful transport functionality and native
SwiftUI architecture.

## Execution state

The user has directly requested this redesign, refactoring, and feature work.
Routine local implementation may continue immediately. Ask only when a material
product choice cannot be inferred safely.

## Active requirements

### REQ-TV-001 - Preserve core journeys

Nearby stops, station search, map browsing, disruptions, favourites, station
details, widget data, Live Activity, onboarding, localisation, and
location-denied behaviour must remain functional unless the requested design
explicitly replaces a flow.

### REQ-TV-002 - Deliver a coherent accessible design

The key screens must use a consistent visual hierarchy, spacing, typography,
colour, components, loading/empty/error states, and navigation. The result must
support light/dark appearance, Dynamic Type, VoiceOver labels, and relevant
reduced-motion behaviour without fixed-size text that breaks accessibility.

### REQ-TV-003 - Refactor only proven code-health problems

Remove confirmed duplication and unclear ownership, keep UI components focused,
preserve the existing service and MVVM boundaries where they remain suitable,
and avoid speculative abstractions or broad rewrites. Every behavioural change
requires focused regression coverage.

### REQ-TV-004 - Make failure and localisation behaviour complete

User-facing strings must be localisable. Location denial, empty datasets,
network failure, API throttling, stale widget data, and retry paths must have
clear, non-destructive user feedback.

### REQ-TV-005 - Protect runtime and network performance

Periodic refresh work must cancel when views disappear, avoid redundant calls,
respect API throttling, and avoid unnecessary work when location access is not
available. Performance claims require a reproducible measurement or test.

### REQ-TV-006 - Establish sufficient validation evidence

Repository validation, OpenCode inheritance validation, Swift compilation,
unit tests, and the applicable widget target checks must pass without failure
masking. Visual or accessibility requirements require simulator/UI evidence in
addition to compilation. An Ubuntu Xcode skip is never completion evidence.

### REQ-TV-007 - Finish with synchronized review-ready state

All state files must be synchronized, all checks must pass, and the actual
changes must pass reviewer and security-reviewer validation before marking
`COMPLETE`.

### REQ-TV-008 - Add focused product improvements with the redesign

The app should adopt a clean, minimalist visual style with a unified colour
palette, consistent typography, and ample whitespace. Remove selectable design
and accent presets and follow the system light/dark appearance. Audit the
existing favourites flow before
adding behaviour: the app already stores multiple favourite stations, so add a
quick-switching interaction only when discovery identifies a concrete missing
user journey. New features must preserve current journeys and MVVM boundaries
and must be delivered as small, testable slices.

### REQ-TV-009 - Add optional, truthful account access

Anonymous use remains available. Add native Sign in with Apple and email access
only through a real identity boundary with secure credential storage, error and
revocation handling, sign-out, and delete-account behaviour. Email sign-in must
not be simulated locally; it requires a selected provider/backend.


`PROJECT.md`, `SPEC.md`, `BACKLOG.md`, `STATUS.md`, `CHECKS.md`,
`DECISIONS.md`, `JOURNAL.md`, `SECURITY.md`, and `RESTRICTIONS.md` must agree.
Independent reviewer and security-reviewer passes must have zero Blocking or
Important findings before `COMPLETE`.

## Definition of Done

- Every requested `REQ-TV-*` item is checked in `BACKLOG.md` with fresh evidence.
- No required TODO, placeholder, mock-only behaviour, or deferred MVP item
  remains.
- All exact checks in `CHECKS.md` pass on a suitable macOS/Xcode environment.
- Core user journeys are exercised, not inferred from file existence.
- Reviewer and security-reviewer report no unresolved Blocking or Important
  findings.
- `STATUS.md` is `COMPLETE` only after all preceding conditions are observed.
