import SwiftUI

struct StationAlertsView: View {
    let infos: [TrafficInfo]

    var body: some View {
        List(infos) { info in
            NavigationLink(value: info) {
                DisruptionRow(info: info)
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Service alerts")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(for: TrafficInfo.self, destination: DisruptionDetailView.init)
    }
}

struct StationAlertsSummaryRow: View {
    let infos: [TrafficInfo]

    var body: some View {
        Label {
            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text("Service alerts: \(infos.count)")
                    .font(.headline)

                if let title = infos.first?.title {
                    Text(title)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
            }
        } icon: {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.orange)
                .frame(width: 36, height: 36)
                .background(.orange.opacity(0.12), in: Circle())
                .accessibilityHidden(true)
        }
        .padding(.vertical, Spacing.xs)
        .accessibilityElement(children: .combine)
    }
}
