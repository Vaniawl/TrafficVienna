import SwiftUI

struct MapLocationBannerView: View {
    let status: MapLocationStatus
    let requestLocation: () -> Void
    let openSettings: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            switch status {
            case .permissionNeeded:
                Label("Showing Vienna centre", systemImage: "location")
                    .font(.headline)
                Text("Use your location to show the closest stops.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Button(
                    "Use my location",
                    systemImage: "location.fill",
                    action: requestLocation
                )
                .buttonStyle(.borderedProminent)
                .controlSize(.large)

            case .permissionDenied:
                Label("Location is off", systemImage: "location.slash")
                    .font(.headline)
                Text("Vienna centre stays available. Enable location in Settings for nearby stops.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Button("Open Settings", systemImage: "gear", action: openSettings)
                    .buttonStyle(.bordered)
                    .controlSize(.large)

            case .locating:
                HStack(spacing: Spacing.sm) {
                    ProgressView()
                    Text("Finding your location…")
                        .font(.headline)
                }

            case .fallback:
                Label("Location unavailable", systemImage: "location.slash.fill")
                    .font(.headline)
                Text("Showing Vienna centre while location recovers.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Button("Retry location", systemImage: "arrow.clockwise", action: requestLocation)
                    .buttonStyle(.bordered)
                    .controlSize(.large)

            case .located:
                EmptyView()
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Spacing.md)
        .background(.regularMaterial, in: .rect(cornerRadius: CornerRadius.lg))
        .shadow(
            color: Shadow.sm.color,
            radius: Shadow.sm.radius,
            x: Shadow.sm.x,
            y: Shadow.sm.y
        )
    }
}
