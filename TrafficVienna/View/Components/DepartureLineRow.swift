//
//  DepartureLineRow.swift
//  TrafficVienna
//
//  One line's row in the "signage" style: rectangular line badge, destination,
//  a large next-departure time and a smaller follow-up. Shared by the nearby
//  card, station detail and favourites screens.
//
//  When `walkMinutes` is supplied (e.g. on the Nearby tab, where we know the
//  walking distance), the next departure is annotated with whether you can
//  still catch it: comfortable, hurry, or missed.
//

import SwiftUI

struct DepartureLineRow: View {
    let lineName: String
    let destination: String
    var minutes: [Int] = []
    var hasDisruption: Bool = false
    var walkMinutes: Int? = nil
    var nextIsLive: Bool = false
    var showFollowUp: Bool = true
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    private enum CatchStatus { case comfortable, hurry, missed }

    // Fixed columns align the compact layout. Accessibility sizes switch to
    // the flexible vertical layout below so text is never forced into them.
    private let badgeColumn: CGFloat = 48
    private let glyphColumn: CGFloat = 16
    private let nextColumn: CGFloat = 60
    private let followColumn: CGFloat = 48

    var body: some View {
        let next = minutes.first
        let status = next.map(catchStatus(next:)) ?? nil

        Group {
            if dynamicTypeSize.isAccessibilitySize {
                accessibilitySizeLayout(next: next, status: status)
            } else {
                compactLayout(next: next, status: status)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(accessibilityLabel))
        .accessibilityValue(Text(accessibilityValue(next: next, status: status)))
        .animation(Motion.quick(reduceMotion: reduceMotion), value: minutes)
    }

    private func compactLayout(next: Int?, status: CatchStatus?) -> some View {
        HStack(spacing: Spacing.sm) {
            LineBadge(line: lineName)
                .frame(width: badgeColumn, alignment: .center)

            Text(destination)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(1)

            Spacer(minLength: 4)

            if hasDisruption {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.caption)
                    .foregroundStyle(.orange)
            }

            glyph(status: status, next: next)
                .frame(width: glyphColumn)

            nextTime(next: next, status: status)
                .frame(width: nextColumn, alignment: .trailing)

            if showFollowUp {
                followUp
                    .frame(width: followColumn, alignment: .trailing)
            }
        }
    }

    private func accessibilitySizeLayout(next: Int?, status: CatchStatus?) -> some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack(alignment: .firstTextBaseline, spacing: Spacing.sm) {
                LineBadge(line: lineName)

                Text(destination)
                    .font(.headline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                Spacer(minLength: 0)

                if hasDisruption {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.orange)
                }
            }

            HStack(alignment: .firstTextBaseline, spacing: Spacing.sm) {
                glyph(status: status, next: next)

                nextTime(next: next, status: status)

                if showFollowUp {
                    followUp
                }
            }
        }
    }

    @ViewBuilder
    private func nextTime(next: Int?, status: CatchStatus?) -> some View {
        if let next {
            if next <= 0 {
                Text("now")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.green)
            } else {
                HStack(alignment: .firstTextBaseline, spacing: Spacing.xxs) {
                    Text("\(next)")
                        .font(.title2.weight(.semibold))
                        .monospacedDigit()
                        .contentTransition(
                            reduceMotion
                                ? .identity
                                : .numericText(value: Double(next))
                        )
                        .foregroundStyle(timeColor(status))
                    Text("min")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        } else {
            Text("—").foregroundStyle(.tertiary)
        }
    }

    @ViewBuilder
    private func glyph(status: CatchStatus?, next: Int?) -> some View {
        if let icon = statusIcon(status) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(statusColor(status))
        } else if nextIsLive, let n = next, n > 0 {
            LivePulse()
        }
    }

    @ViewBuilder
    private var followUp: some View {
        let rest = Array(minutes.dropFirst().prefix(2))
        if !rest.isEmpty {
            Text(rest.map(String.init).joined(separator: " · "))
                .font(.caption)
                .monospacedDigit()
                .foregroundStyle(.tertiary)
        }
    }

    // MARK: - Accessibility

    private var accessibilityLabel: String {
        String(localized: "Line \(lineName) to \(destination)")
    }

    private func accessibilityValue(next: Int?, status: CatchStatus?) -> String {
        var details: [String] = []

        if let next {
            if next <= 0 {
                details.append(String(localized: "Next departure now"))
            } else {
                let duration = formattedMinutes(next)
                details.append(String(localized: "Next departure in \(duration)"))
            }
        } else {
            details.append(String(localized: "No departure time available"))
        }

        let following = minutes.dropFirst().prefix(2).map(formattedMinutes)
        if showFollowUp, !following.isEmpty {
            let list = ListFormatter.localizedString(byJoining: following)
            details.append(String(localized: "Following departures in \(list)"))
        }

        if hasDisruption {
            details.append(String(localized: "Service alert"))
        }

        if nextIsLive, next.map({ $0 > 0 }) == true {
            details.append(String(localized: "Real-time prediction"))
        }

        switch status {
        case .comfortable:
            details.append(String(localized: "Enough time to walk"))
        case .hurry:
            details.append(String(localized: "Hurry to catch this departure"))
        case .missed:
            details.append(String(localized: "Not enough time to walk"))
        case nil:
            break
        }

        return details.joined(separator: ". ")
    }

    private func formattedMinutes(_ minutes: Int) -> String {
        Measurement(value: Double(minutes), unit: UnitDuration.minutes)
            .formatted(
                .measurement(
                    width: .wide,
                    usage: .asProvided,
                    numberFormatStyle: .number.precision(.fractionLength(0))
                )
            )
    }

    // MARK: - Catch status

    private func catchStatus(next: Int) -> CatchStatus? {
        guard let walk = walkMinutes, next > 0 else { return nil }
        if next < walk { return .missed }
        if next <= walk + 1 { return .hurry }
        return .comfortable
    }

    private func statusIcon(_ status: CatchStatus?) -> String? {
        switch status {
        case .comfortable: return "figure.walk"
        case .hurry:       return "figure.run"
        case .missed:      return "nosign"
        case nil:          return nil
        }
    }

    private func statusColor(_ status: CatchStatus?) -> Color {
        switch status {
        case .comfortable: return .green
        case .hurry:       return .orange
        case .missed:      return .secondary
        case nil:          return .secondary
        }
    }

    private func timeColor(_ status: CatchStatus?) -> Color {
        switch status {
        case .missed: return .secondary
        case .hurry:  return .orange
        default:      return .primary
        }
    }
}

#Preview {
    List {
        DepartureLineRow(lineName: "U1", destination: "Leopoldau", minutes: [2, 9])
        DepartureLineRow(lineName: "U4", destination: "Heiligenstadt", minutes: [4, 11], hasDisruption: true)
        DepartureLineRow(lineName: "62", destination: "Lainz", minutes: [0, 13])
        DepartureLineRow(lineName: "13A", destination: "Skodagasse", minutes: [3, 12], walkMinutes: 5) // missed
        DepartureLineRow(lineName: "2", destination: "Friedrich-Engels-Platz", minutes: [6, 14], walkMinutes: 5) // hurry
        DepartureLineRow(lineName: "D", destination: "Nußdorf", minutes: [12, 20], walkMinutes: 5) // comfortable
    }
}
