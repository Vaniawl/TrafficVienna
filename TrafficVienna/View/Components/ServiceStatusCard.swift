import SwiftUI

struct ServiceStatusCard: View {
    let status: ServiceDashboardStatus
    let action: () -> Void
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        Button(action: action) {
            content
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(Spacing.md)
                .premiumSurface()
                .contentShape(.rect(cornerRadius: CornerRadius.lg))
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(accessibilityLabel))
        .accessibilityHint(Text("Opens alerts"))
        .accessibilityInputLabels([Text("Service status"), Text("Alerts")])
    }

    @ViewBuilder
    private var content: some View {
        if dynamicTypeSize.isAccessibilitySize {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                HStack {
                    statusIcon
                    Spacer(minLength: Spacing.sm)
                    disclosureIndicator
                }

                statusDetails
            }
        } else {
            HStack(spacing: Spacing.sm) {
                statusIcon
                statusDetails
                Spacer(minLength: Spacing.xs)
                disclosureIndicator
            }
        }
    }

    private var statusDetails: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text("Service status")
                .font(.caption.weight(.semibold))
                .foregroundStyle(DesignColor.secondaryText)

            Text(statusMessage)
                .font(.body.weight(.semibold))
                .foregroundStyle(DesignColor.primaryText)
                .fixedSize(horizontal: false, vertical: true)

            if status.isSaved {
                Label("Saved data", systemImage: "clock.badge.exclamationmark")
                    .font(.footnote)
                    .foregroundStyle(.orange)
            }
        }
    }

    private var disclosureIndicator: some View {
        Image(systemName: "chevron.right")
            .font(.system(size: 14, weight: .semibold))
            .foregroundStyle(.tertiary)
            .accessibilityHidden(true)
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

#Preview("All clear") {
    ServiceStatusCard(status: .allClear(isSaved: false), action: {})
        .padding()
        .background(DesignColor.background)
}

#Preview("Service alerts") {
    ServiceStatusCard(status: .alerts(count: 3, isSaved: true), action: {})
        .padding()
        .background(DesignColor.background)
}
