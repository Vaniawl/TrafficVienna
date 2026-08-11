import SwiftUI

struct ServiceStatusCard: View {
    let status: ServiceDashboardStatus
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: Spacing.sm) {
                statusIcon

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

                Spacer(minLength: Spacing.xs)

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.tertiary)
                    .accessibilityHidden(true)
            }
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
