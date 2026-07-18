# Decisions

## 2026-07-18 - Search owns a cancellable view model and local catalogue state

Search query state, debouncing, results, retry, and recent-history projection are
owned by an injectable `SearchViewModel`; the SwiftUI view only renders states and
routes selected `Station` values. The local `StationStore` exposes a minimal
loading/loaded/failed state plus reload so a missing or invalid bundled catalogue
is visible and recoverable instead of silently becoming an empty search.

Filtering remains local and anonymous. Recent station identifiers remain in the
existing App Group defaults because they are non-sensitive UI history, while the
store protocol makes ordering, limits, persistence, and clearing testable.

## 2026-07-18 - Store only a minimal device-local Apple profile

The optional Apple account surface uses `AuthenticationServices` directly. The
app stores only the stable Apple user identifier and the one-time name/email
profile fields in Keychain using a device-only accessibility class. It does not
store or log identity tokens or authorization codes and does not present this
local profile as a server session.

Credential state is validated on launch through an injectable boundary. Revoked,
missing, transferred, or unknown states clear the local session. Email login,
cross-device identity, and remote account deletion remain outside this slice
until a backend/provider is explicitly selected and configured.

## 2026-07-18 - One adaptive visual identity; accounts require a real identity boundary

TrafficVienna uses one minimalist Vienna-red visual system and follows the
device's light/dark appearance. Runtime accent presets and user-selectable design
themes are removed because they fragment hierarchy, complicate testing, and now
conflict with the explicit product request.

Accounts remain optional so transport data and local favourites work without
registration. Do not represent `UserDefaults`, a locally stored email, or an
unverified token as authentication. Sign in with Apple may use the native
AuthenticationServices flow, but email sign-in and cross-device account data
require an explicitly selected backend/provider, secure token validation,
Keychain storage, migration, and sign-out/delete-account behaviour.

## 2026-07-16 - Use global native OpenCode ownership

TrafficVienna no longer defines project-local agents, models, permissions,
plugins, or GitHub workflow. The global orchestrator owns coordination;
specialists use the global `gpt-oss-120b` and implementer uses global
`coder-next`. The repository binds only its context and template skills. This
prevents project history from reactivating obsolete routes or permissions.

## 2026-07-16 - Local implementation with explicit Git boundaries

Autonomous work may read and edit the active workspace and run defined local
checks. Local feature branches and local commits are allowed when they contain
only task-owned files. TrafficVienna uses the personal Git identity and personal
remote only; other projects use the work identity. Push, PR, merge, release, and
deployment still require a separate user request. Historical files under
`memory/` remain context only and do not override root state files.

## 2026-07-17 - Native conversational workflow

Agents infer technical acceptance criteria from evidence and ask the user only
about material product ambiguity. A direct request to build, redesign, refactor,
fix, or continue authorizes routine local implementation. Project Markdown
preserves context and progress but does not act as an authorization database.

## 2026-07-17 - Adopt minimalist UI redesign and new feature set (superseded)

The user requested a clean, minimalist visual style with a unified colour
palette and consistent typography, plus multi-favourite selection and an
explicit theme mode control. Preserve core journeys and MVVM boundaries; deliver
the work as small, testable product slices.

Superseded on 2026-07-18 by the user's request to remove design selection.

## 2026-07-17 - Use one runtime theme owner (superseded)

`TrafficViennaApp` owns and injects one `ThemeEngine`. It persists appearance
mode and accent preset. Views consume semantic SwiftUI colours and the shared
environment instead of polling `UITraitCollection` or creating local theme
singletons. Obsolete theme owners and empty compatibility files are removed.

Superseded on 2026-07-18: runtime theme ownership was removed entirely.

## Existing product architecture

Preserve SwiftUI, async/await, the MVVM-style view/view-model split,
`MonitorService` actor, protocol-based network boundary, and shared widget logic
unless discovery proves a concrete reason to change them and the current plan
records the migration and regression coverage.
