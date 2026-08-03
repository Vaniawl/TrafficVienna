import SwiftUI

struct FavoriteNextDepartureCard: View {
    let item: FeaturedDeparture
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
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

            Label("View departures", systemImage: "arrow.right")
                .font(.subheadline)
                .bold()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Spacing.md)
        .foregroundStyle(DesignColor.inverseText)
        .background(DesignColor.brandGradient, in: .rect(cornerRadius: CornerRadius.lg))
        .contentShape(.rect(cornerRadius: CornerRadius.lg))
        .shadow(
            color: Shadow.sm.color,
            radius: Shadow.sm.radius,
            x: Shadow.sm.x,
            y: Shadow.sm.y
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(accessibilityLabel))
        .accessibilityHint(Text("Opens live departures"))
        .accessibilityInputLabels([Text("Next departure"), Text("View departures")])
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
            if let minutes, minutes <= 0 {
                Text("now")
                    .font(.largeTitle)
                    .bold()
            } else if let minutes {
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
            } else {
                Text("—")
                    .font(.largeTitle)
                    .bold()
            }
        }
        .animation(Motion.quick(reduceMotion: reduceMotion), value: minutes)
    }

    private var minutes: Int? {
        item.departure.liveMinutes(anchoredAt: item.updatedAt)
    }

    private var accessibilityLabel: String {
        var details = [
            String(localized: "Next departure"),
            String(localized: "Line \(item.route.lineName) to \(item.route.destination)"),
            item.stopName
        ]

        if let minutes, minutes <= 0 {
            details.append(String(localized: "Next departure now"))
        } else if let minutes {
            let duration = Measurement(value: Double(minutes), unit: UnitDuration.minutes)
                .formatted(
                    .measurement(
                        width: .wide,
                        usage: .asProvided,
                        numberFormatStyle: .number.precision(.fractionLength(0))
                    )
                )
            details.append(String(localized: "Next departure in \(duration)"))
        } else {
            details.append(String(localized: "No departure time available"))
        }

        if item.state == .cached {
            details.append(String(localized: "Saved data"))
        } else if item.departure.isRealtime {
            details.append(String(localized: "Real-time prediction"))
        }

        return details.joined(separator: ". ")
    }
}

#Preview {
    FavoriteNextDepartureCard(
        item: FeaturedDeparture(
            route: FavoriteRoute(diva: "60201040", lineName: "U1", destination: "Leopoldau"),
            stopName: "Stephansplatz",
            departure: DepartureInfo(countdown: 3, planned: "", real: nil, isRealtime: true),
            state: .available
        )
    )
    .padding()
    .background(DesignColor.background)
}
