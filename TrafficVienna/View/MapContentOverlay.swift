import SwiftUI

struct MapContentOverlay: View {
    let state: MapContentState
    let retry: () -> Void
    let showVienna: () -> Void

    var body: some View {
        switch state {
        case .loading:
            ProgressView("Loading stops…")
                .controlSize(.large)
                .padding(Spacing.lg)
                .background(.regularMaterial, in: .rect(cornerRadius: CornerRadius.lg))

        case .unavailable:
            MapRecoveryCard(
                title: "Map unavailable",
                message: "The stop catalogue could not be loaded.",
                symbol: "map.fill"
            ) {
                Button("Try again", systemImage: "arrow.clockwise", action: retry)
                    .buttonStyle(.borderedProminent)
            }

        case .empty:
            MapRecoveryCard(
                title: "Outside the service area",
                message: "Traffic Vienna covers public transport stops in Vienna.",
                symbol: "location.slash"
            ) {
                Button("Show Vienna", systemImage: "location.fill", action: showVienna)
                    .buttonStyle(.borderedProminent)
                    .accessibilityIdentifier("map.showVienna")
            }

        case .ready:
            EmptyView()
        }
    }
}

private struct MapRecoveryCard<Actions: View>: View {
    let title: LocalizedStringKey
    let message: LocalizedStringKey
    let symbol: String
    let actions: Actions

    init(
        title: LocalizedStringKey,
        message: LocalizedStringKey,
        symbol: String,
        @ViewBuilder actions: () -> Actions
    ) {
        self.title = title
        self.message = message
        self.symbol = symbol
        self.actions = actions()
    }

    var body: some View {
        VStack(spacing: Spacing.md) {
            Image(systemName: symbol)
                .font(.title2)
                .foregroundStyle(.appAccent)
                .accessibilityHidden(true)

            VStack(spacing: Spacing.xs) {
                Text(title)
                    .font(.headline)
                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            actions
        }
        .frame(maxWidth: 300)
        .padding(Spacing.lg)
        .background(.regularMaterial, in: .rect(cornerRadius: CornerRadius.xl))
        .overlay {
            RoundedRectangle(cornerRadius: CornerRadius.xl)
                .stroke(DesignColor.border.opacity(0.7), lineWidth: 1)
        }
        .shadow(
            color: Shadow.md.color,
            radius: Shadow.md.radius,
            x: Shadow.md.x,
            y: Shadow.md.y
        )
        .padding(Spacing.lg)
        .accessibilityElement(children: .contain)
    }
}
