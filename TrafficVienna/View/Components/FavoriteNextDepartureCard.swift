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
            .overlay {
                RoundedRectangle(cornerRadius: CornerRadius.xl, style: .continuous)
                    .stroke(.white.opacity(0.22), lineWidth: 1)
            }
            .shadow(
                color: Shadow.lg.color,
                radius: Shadow.lg.radius,
                x: Shadow.lg.x,
                y: Shadow.lg.y
            )
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
            .font(.subheadline.weight(.semibold))
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
                .fontWeight(.bold)
                .padding(.horizontal, Spacing.sm)
                .padding(.vertical, Spacing.xs)
                .foregroundStyle(.black)
                .background(.white, in: .rect(cornerRadius: CornerRadius.sm))

            Text(item.route.destination)
                .font(.title3.weight(.semibold))
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
                    .fontWeight(.bold)
            } else {
                Text(minutes, format: .number)
                    .font(.largeTitle)
                    .fontWeight(.bold)
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

#Preview {
    FavoriteNextDepartureCard(
        item: FeaturedDeparture(
            route: FavoriteRoute(diva: "60201040", lineName: "U1", destination: "Leopoldau"),
            stopName: "Stephansplatz",
            departure: DepartureInfo(countdown: 3, planned: "", real: nil, isRealtime: true),
            state: .available
        ),
        action: {}
    )
    .padding()
    .background(DesignColor.background)
}
