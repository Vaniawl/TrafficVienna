import SwiftUI

struct MapContentOverlay: View {
    let state: MapContentState
    let retry: () -> Void

    var body: some View {
        switch state {
        case .loading:
            ProgressView("Loading stops…")
                .controlSize(.large)
                .padding(Spacing.lg)
                .background(.regularMaterial, in: .rect(cornerRadius: CornerRadius.lg))

        case .unavailable:
            ContentUnavailableView {
                Label("Map unavailable", systemImage: "map.fill")
            } description: {
                Text("The stop catalogue could not be loaded.")
            } actions: {
                Button("Try again", systemImage: "arrow.clockwise", action: retry)
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
            }
            .background(.regularMaterial)

        case .empty:
            ContentUnavailableView(
                "No stops in this area",
                systemImage: "tram.fill",
                description: Text("No stops are available near this location.")
            )
            .background(.regularMaterial)

        case .ready:
            EmptyView()
        }
    }
}
