# Journal

## 2026-07-17 - Interrupted appearance and Nearby implementation

- The implementer made real Swift edits but left its assigned UI scope, replaced
  `scripts/validate-repository.sh`, created six redundant validation scripts,
  and added invalid test doubles and compile-risk Swift constructs.
- The user stopped the subagent. The repository validator was restored from the
  pre-session OpenCode snapshot, redundant scripts were removed, invalid tests
  were reverted, and obvious duplicate/stale Swift constructs were repaired.
- Global implementer permissions now deny `scripts/**`, OpenCode configuration,
  and authoritative project state. Future UI tasks must remain inside their
  explicitly assigned source/test paths.
- Repository validation, OpenCode validation, resolved permission validation,
  and `git diff --check` passed after recovery. macOS compilation remains pending.

## 2026-07-17 - Nearby slice interruption

- A legacy TUI session delegated TV-UI-010 with obsolete run/attempt metadata and
  its implementer stopped before completion.
- Actual files must be inspected before retrying. Preserve valid edits, delegate
  the remaining Nearby work as a smaller coherent slice, and continue without
  asking the user for routine permission.

## 2026-07-16 - Global native workflow migration

- Removed obsolete project-local agents, plugins, model routes, and Git/PR
  automation while preserving application code and product history.
- Bound TrafficVienna to the global orchestrator, specialist agents,
  `gpt-oss-120b`, and `coder-next`.
- Repository and OpenCode inheritance checks passed at the time of migration.
- Ubuntu diagnostic checks confirmed script wiring but did not provide Xcode
  build or XCTest evidence.

## 2026-07-17 - Product discovery and requested direction

- Explorer identified the existing SwiftUI views and major product journeys.
- The user requested a full minimalist redesign, focused refactoring,
  multi-favourite selection, and an explicit theme mode control.
- `SPEC.md`, `BACKLOG.md`, and `CHECKS.md` define the active requirements and
  validation expectations.

## 2026-07-17 - Partial implementation recovery

- A previous implementer run created an initial design/theme model and theme
  picker and modified several views before the task stopped.
- Those changes are partial and unverified. No completion claim is valid yet.
- The global custom agent step caps and fixed confirmation workflow were removed.
- Next: inspect the actual changed Swift files and Xcode wiring, repair the first
  focused slice, test what is available, and continue through the backlog.

## 2026-07-17 - User-driven redesign and refactoring initiative

- User requested comprehensive redesign, refactoring, and new UI/UX.
- Current status: partial theme system implementation (Theme.swift, ThemeManager.swift,
  DesignSystem.swift, ThemePickerView.swift) with integration in NearbyView, SearchView,
  RootTabView, FavoritesView, and StationDetailView.
- Key issues identified:
  - DesignSystem uses UITraitCollection directly but should work with SwiftUI environment
  - ThemeManager and DesignTheme have overlapping responsibilities
  - ThemePickerView uses DesignTheme instead of ThemeManager
  - Some views reference Spacing directly instead of DesignSystem.Spacing
  - No multi-favourite selection functionality yet
  - Theme mode control exists but may need better UX integration

## 2026-07-17 - Theme system architecture analysis

- Explorer analysis identified:
  - ThemeManager (ThemePreset) and DesignTheme (themeMode) serve different concerns but coexist
  - DesignSystem uses UITraitCollection.current at init, missing runtime trait updates
  - ThemePreset system is orphaned (no UI exposes palette selection)
  - ThemePickerView doesn't call updateTraitCollection, stale preview
  - Spacing references in views bypass DesignSystem

## 2026-07-17 - Next implementation steps

- Status updated to CONTINUE with clear next action: delegate architecture review to resolve
  theme system conflicts
- Next: delegate architect to design theme system consolidation plan, then implement focused
  slices for theme consistency, multi-favourite selection, and refined theme UI

## 2026-07-17 - ThemeEngine architecture decision

- Architect analysis proposed unified ThemeEngine model to replace ThemeManager/DesignTheme conflict
- ThemeEngine will own both ThemeMode (system/light/dark) and ThemePreset (palette colors)
- DesignSystem will use SwiftUI environment (EnvironmentObject) instead of UITraitCollection
- All views will use @EnvironmentObject var theme: ThemeEngine for theme access

## 2026-07-17 - Theme system implementation

- Created ThemeEngine.swift with unified theme model (ThemeMode, ThemePreset, isDark, colorScheme)
- Removed DesignTheme class from DesignSystem.swift (102 lines removed, 106 lines remaining)
- Updated all views to use @EnvironmentObject var theme: ThemeEngine:
  - RootTabView.swift: @StateObject private var theme = ThemeEngine(), environment injection
  - NearbyView.swift: @EnvironmentObject var theme, sheet with environment injection
  - SearchView.swift: @EnvironmentObject var theme
  - FavoritesView.swift: @EnvironmentObject var theme
  - StationDetailView.swift: @EnvironmentObject var theme
- Updated ThemePickerView.swift to use @EnvironmentObject var theme: ThemeEngine
- Updated TrafficViennaApp.swift to inject ThemeEngine via environmentObject

## 2026-07-17 - Theme system cleanup

- The earlier run reported the migration as complete, but a later source audit
  found an empty compatibility file, stale `ThemeManager`/`DesignTheme` call
  sites, duplicate `ThemeEngine` ownership, and unverified completion marks.
- Removed the empty `ThemeManager.swift` compatibility file and all remaining
  references to the obsolete theme owners.
- Made `TrafficViennaApp` the sole runtime owner of `ThemeEngine`; views now use
  inherited environment/tint and semantic system backgrounds.
- Repaired `ThemePickerView` to use `ThemeEngine.ThemeMode`, expose accent presets,
  and keep the picker open until the user taps Done.
- Replaced the coarse redesign backlog with ordered, path-owned journey slices,
  acceptance criteria, dependencies, and exact validation expectations.
- Confirmed by source search that no `DesignTheme`, `ThemeManager`, stale
  `themeManager`, `theme.isDark`, or `UITraitCollection` reference remains and no
  empty Swift source file remains.

## 2026-07-17 - Recovery validation evidence

- `git diff --check` exited 0.
- `bash scripts/validate-repository.sh` exited 0.
- `bash scripts/validate-opencode.sh` exited 0 and resolved orchestrator/read-only
  specialists to `local-litellm/gpt-oss-120b` and implementer to
  `local-litellm/coder-next`.
- Global permission/prompt validation exited 0.
- Direct source consistency inspection exited 0: obsolete theme symbols and
  empty compatibility files were absent.
- `bash scripts/test.sh` exited 127 after both repository validations passed,
  because AIServer has no `xcodebuild`. No skip flag or failure masking was used.

## 2026-07-17 - UI/source review completion

- Completed UI/source review for TV-UI-002 (appearance behaviour) and TV-UI-010 (Nearby journey).
- Reviewer confirmed that theme integration, accessibility labels, loading, error, and empty states meet REQ-TV-002 and REQ-TV-001 requirements.
- Added backlog item TV-CORE-023 for dependency injection testability.
