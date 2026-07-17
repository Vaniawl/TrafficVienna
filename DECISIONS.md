# Decisions

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

## 2026-07-17 - Adopt minimalist UI redesign and new feature set

The user requested a clean, minimalist visual style with a unified colour
palette and consistent typography, plus multi-favourite selection and an
explicit theme mode control. Preserve core journeys and MVVM boundaries; deliver
the work as small, testable product slices.

## 2026-07-17 - Use one runtime theme owner

`TrafficViennaApp` owns and injects one `ThemeEngine`. It persists appearance
mode and accent preset. Views consume semantic SwiftUI colours and the shared
environment instead of polling `UITraitCollection` or creating local theme
singletons. Obsolete theme owners and empty compatibility files are removed.

## Existing product architecture

Preserve SwiftUI, async/await, the MVVM-style view/view-model split,
`MonitorService` actor, protocol-based network boundary, and shared widget logic
unless discovery proves a concrete reason to change them and the current plan
records the migration and regression coverage.
