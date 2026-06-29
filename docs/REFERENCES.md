# References

## Build

```sh
# Build
xcodebuild -scheme TrafficVienna -project TrafficVienna.xcodeproj -destination 'platform=iOS Simulator,name=iPhone 17' build

# Test
xcodebuild -scheme TrafficVienna -project TrafficVienna.xcodeproj -destination 'platform=iOS Simulator,name=iPhone 17' test

# Build widget extension only
xcodebuild -scheme TrafficViennaWidgetExtension -project TrafficVienna.xcodeproj -destination 'platform=iOS Simulator,name=iPhone 17' build
```

## API

- [Wiener Linien Echtzeitdaten (OGD)](https://www.wienerlinien.at/ogd_realtime/)
- Monitor endpoint: `https://www.wienerlinien.at/ogd_realtime/monitor?diva=…&aArea=1&activateTrafficInfo=…`
- Traffic info list: `https://www.wienerlinien.at/ogd_realtime/trafficInfoList`
- Stop finder (routing): `https://www.wienerlinien.at/ogd_routing/XML_STOPFINDER_REQUEST?…`

## Data

- Bundled station JSON: `TrafficVienna/wienerlinien-ogd-haltestellen.json`

## Code style

- `nonisolated` on pure DTO structs that cross actor boundaries.
- `@MainActor` on ViewModel load methods.
- `@StateObject` for ViewModels owned by a view; `@ObservedObject` for injected shared objects.
- `Task.sleep` loops in `.task` for periodic refresh (cancelled on disappear).
- `ContentUnavailableView` for empty/error states.
- `sensoryFeedback` modifier for interactive feedback (favourite toggles).
- `List` with `.listStyle(.insetGrouped)` for content screens.
- `ScrollView` + `LazyVStack` for custom-layout feeds (Nearby cards).
- `shimmer()` modifier on skeleton loading placeholders.
- `StationDetailView` uses a URL-based `init` to receive `Station` (no DI container).
