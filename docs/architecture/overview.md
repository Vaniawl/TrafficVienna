# Architecture Overview

TrafficVienna is a native SwiftUI application with observable MVVM-style view models,
protocol boundaries for external capabilities, and an actor-owned transport monitor.
The app and widget share routing and departure model code under
`TrafficVienna/WidgetShared/`. XCTest and XCUITest targets are included in the shared
`TrafficVienna` scheme.

`PROJECT.md` describes the maintained architecture and product boundaries. The source
tree and focused tests remain authoritative for implementation details. Structural
changes require an accepted ADR before implementation.
