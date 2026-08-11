# Shared UI components

TrafficVienna uses custom SwiftUI components and native iOS controls rather than a third-party component library. The sources below are the reusable visual primitives most relevant to the redesign.

## FilterChip

- File: `TrafficVienna/View/Components/FilterChip.swift`
- Props: title, optional line category, color, selection binding.
- Accessible 44-point capsule filter used in horizontal filter groups.

```swift
import SwiftUI

struct FilterChip: View {
    let title: String
    let category: LineCategory?
    let color: Color
    @Binding var selection: LineCategory?

    private var isSelected: Bool {
        selection == category
    }

    var body: some View {
        Button {
            selection = category
        } label: {
            Text(title)
                .font(.caption)
                .bold(isSelected)
                .padding(.horizontal, Spacing.sm)
                .frame(minHeight: 44)
                .background(isSelected ? color : Color.appChipBg, in: Capsule())
                .foregroundStyle(isSelected ? .white : .secondary)
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .accessibilityLabel(title)
        .accessibilityValue(isSelected ? "Selected" : "Not selected")
    }
}
```

## NearbyStatusCard

- File: `TrafficVienna/View/Components/NearbyStatusCard.swift`
- Props: icon, title, message, optional action title and callback.
- Shared status/permission/error card for the Nearby journey.

```swift
import SwiftUI

struct NearbyStatusCard: View {
    let icon: String?
    let title: LocalizedStringKey
    let message: LocalizedStringKey
    let actionTitle: LocalizedStringKey?
    let action: (() -> Void)?

    var body: some View {
        ContentUnavailableView {
            if let icon {
                Label(title, systemImage: icon)
            } else {
                ProgressView()
                    .accessibilityHidden(true)
                Text(title)
            }
        } description: {
            Text(message)
        } actions: {
            if let actionTitle, let action {
                Button(actionTitle, action: action)
                    .buttonStyle(.borderedProminent)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.lg)
        .background(DesignColor.cardBackground, in: .rect(cornerRadius: CornerRadius.lg))
        .overlay {
            RoundedRectangle(cornerRadius: CornerRadius.lg)
                .stroke(DesignColor.border, lineWidth: 1)
        }
        .accessibilityElement(children: .contain)
    }
}

#Preview {
    NearbyStatusCard(
        icon: "location",
        title: "Find stops near you",
        message: "Allow location access to see live departures around you.",
        actionTitle: "Allow location",
        action: {}
    )
    .padding()
}
```

## OfflineStatusView

- File: `TrafficVienna/View/Components/OfflineStatusView.swift`
- Compact offline status pill layered above the tab shell.

```swift
import SwiftUI

struct OfflineStatusView: View {
    var body: some View {
        Label("Offline", systemImage: "wifi.slash")
            .font(.caption)
            .bold()
            .foregroundStyle(.red)
            .padding(.horizontal, Spacing.sm)
            .padding(.vertical, Spacing.xs)
            .background(.red.opacity(0.12), in: Capsule())
            .padding(.top, Spacing.xs)
            .accessibilityLabel("No connection")
    }
}
```

## ServiceStatusCard

- File: `TrafficVienna/View/Components/ServiceStatusCard.swift`
- Props: dashboard status and action callback.
- Reusable service-health summary with loading, all-clear, alert, saved, and unavailable states.

```swift
import SwiftUI

struct ServiceStatusCard: View {
    let status: ServiceDashboardStatus
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: Spacing.md) {
                statusIcon

                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text("Service status")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    Text(statusMessage)
                        .font(.headline)
                        .fixedSize(horizontal: false, vertical: true)

                    if status.isSaved {
                        Label("Saved data", systemImage: "clock.badge.exclamationmark")
                            .font(.footnote)
                            .foregroundStyle(.orange)
                    }
                }

                Spacer(minLength: Spacing.xs)

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.tertiary)
                    .accessibilityHidden(true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(Spacing.md)
            .background(DesignColor.cardBackground, in: .rect(cornerRadius: CornerRadius.lg))
            .overlay {
                RoundedRectangle(cornerRadius: CornerRadius.lg)
                    .stroke(DesignColor.border, lineWidth: 1)
            }
            .contentShape(.rect(cornerRadius: CornerRadius.lg))
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(accessibilityLabel))
        .accessibilityHint(Text("Opens alerts"))
        .accessibilityInputLabels([Text("Service status"), Text("Alerts")])
    }

    @ViewBuilder
    private var statusIcon: some View {
        ZStack {
            Circle()
                .fill(statusColor.opacity(0.12))

            if status == .loading {
                ProgressView()
                    .controlSize(.small)
            } else {
                Image(systemName: statusSymbol)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(statusColor)
            }
        }
        .frame(width: 44, height: 44)
        .accessibilityHidden(true)
    }

    private var statusMessage: String {
        switch status {
        case .loading:
            String(localized: "Checking service status…")
        case .allClear:
            String(localized: "All lines are running normally.")
        case .alerts(let count, _):
            String(localized: "Service alerts: \(count)")
        case .unavailable:
            String(localized: "Alerts unavailable")
        }
    }

    private var statusSymbol: String {
        switch status {
        case .loading:
            "clock"
        case .allClear:
            "checkmark.circle.fill"
        case .alerts:
            "exclamationmark.triangle.fill"
        case .unavailable:
            "wifi.exclamationmark"
        }
    }

    private var statusColor: Color {
        switch status {
        case .allClear:
            DesignColor.success
        case .alerts:
            DesignColor.warning
        case .loading, .unavailable:
            DesignColor.secondaryText
        }
    }

    private var accessibilityLabel: String {
        var details = [String(localized: "Service status"), statusMessage]
        if status.isSaved {
            details.append(String(localized: "Saved data"))
        }
        return details.joined(separator: ". ")
    }
}
```

## FavoriteNextDepartureCard

- File: `TrafficVienna/View/Components/FavoriteNextDepartureCard.swift`
- Props: featured departure and action callback.
- Dominant Nearby hero with route, destination, stop, countdown, live/saved status, and adaptive Dynamic Type layout.

```swift
import SwiftUI

struct FavoriteNextDepartureCard: View {
    let item: FeaturedDeparture
    let action: () -> Void
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: Spacing.md) {
                header

                Group {
                    if dynamicTypeSize.isAccessibilitySize {
                        VStack(alignment: .leading, spacing: Spacing.md) {
                            route
                            time
                        }
                    } else {
                        HStack(alignment: .center, spacing: Spacing.md) {
                            route
                            Spacer(minLength: Spacing.sm)
                            time
                        }
                    }
                }

                Label(item.stopName, systemImage: "mappin.and.ellipse")
                    .font(.subheadline)
                    .fixedSize(horizontal: false, vertical: true)

                Label("View favourites", systemImage: "arrow.right")
                    .font(.subheadline)
                    .bold()
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(Spacing.lg)
            .foregroundStyle(DesignColor.inverseText)
            .background(DesignColor.brandGradient, in: .rect(cornerRadius: CornerRadius.xl))
            .contentShape(.rect(cornerRadius: CornerRadius.xl))
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(accessibilityLabel))
        .accessibilityHint(Text("Opens favourites"))
        .accessibilityInputLabels([Text("Next departure"), Text("View favourites")])
    }

    private var header: some View {
        Group {
            if dynamicTypeSize.isAccessibilitySize {
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    headerTitle
                    statusLabel
                }
            } else {
                HStack(spacing: Spacing.sm) {
                    headerTitle
                    Spacer(minLength: Spacing.xs)
                    statusLabel
                }
            }
        }
    }

    private var headerTitle: some View {
        Label("Next departure", systemImage: "clock.fill")
            .font(.headline)
            .fixedSize(horizontal: false, vertical: true)
    }

    @ViewBuilder
    private var statusLabel: some View {
        if item.state == .cached {
            Label("Saved data", systemImage: "clock.badge.exclamationmark")
                .font(.footnote)
                .fixedSize()
                .padding(.horizontal, Spacing.sm)
                .padding(.vertical, Spacing.xs)
                .background(.white.opacity(0.16), in: Capsule())
        } else if item.departure.isRealtime {
            Label("Live", systemImage: "dot.radiowaves.left.and.right")
                .font(.footnote)
                .fixedSize()
                .padding(.horizontal, Spacing.sm)
                .padding(.vertical, Spacing.xs)
                .background(.white.opacity(0.16), in: Capsule())
        }
    }

    private var route: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text(item.route.lineName)
                .font(.title2)
                .bold()
                .padding(.horizontal, Spacing.sm)
                .padding(.vertical, Spacing.xs)
                .foregroundStyle(.black)
                .background(.white, in: .rect(cornerRadius: CornerRadius.sm))

            Text(item.route.destination)
                .font(.headline)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var time: some View {
        VStack(
            alignment: dynamicTypeSize.isAccessibilitySize ? .leading : .trailing,
            spacing: Spacing.none
        ) {
            if minutes <= 0 {
                Text("now")
                    .font(.largeTitle)
                    .bold()
            } else {
                Text(minutes, format: .number)
                    .font(.largeTitle)
                    .bold()
                    .monospacedDigit()
                    .contentTransition(
                        reduceMotion
                            ? .identity
                            : .numericText(value: Double(minutes))
                    )
                Text("min")
                    .font(.subheadline)
            }
        }
        .animation(Motion.quick(reduceMotion: reduceMotion), value: minutes)
    }

    private var minutes: Int {
        item.departure.liveMinutes
    }

    private var accessibilityLabel: String {
        var details = [
            String(localized: "Next departure"),
            String(localized: "Line \(item.route.lineName) to \(item.route.destination)"),
            item.stopName
        ]

        if minutes <= 0 {
            details.append(String(localized: "Next departure now"))
        } else {
            let duration = Measurement(value: Double(minutes), unit: UnitDuration.minutes)
                .formatted(
                    .measurement(
                        width: .wide,
                        usage: .asProvided,
                        numberFormatStyle: .number.precision(.fractionLength(0))
                    )
                )
            details.append(String(localized: "Next departure in \(duration)"))
        }

        if item.state == .cached {
            details.append(String(localized: "Saved data"))
        } else if item.departure.isRealtime {
            details.append(String(localized: "Real-time prediction"))
        }

        return details.joined(separator: ". ")
    }
}
```
