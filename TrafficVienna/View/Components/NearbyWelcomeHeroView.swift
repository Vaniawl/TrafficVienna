import SwiftUI

struct NearbyWelcomeHeroView: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: Spacing.md) {
                Text("VIENNA, LIVE")
                    .font(.subheadline)
                    .bold()
                    .foregroundStyle(DesignColor.inverseSecondaryText)

                Text("Where to next?")
                    .font(.largeTitle)
                    .bold()
                    .foregroundStyle(DesignColor.inverseText)
                    .fixedSize(horizontal: false, vertical: true)

                Text("Search stations and see live departures in seconds.")
                    .font(.body)
                    .foregroundStyle(DesignColor.inverseSecondaryText)
                    .fixedSize(horizontal: false, vertical: true)

                Label("Find a station", systemImage: "arrow.right")
                    .font(.headline)
                    .foregroundStyle(DesignColor.inverseText)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(Spacing.xl)
            .background(DesignColor.heroGradient, in: .rect(cornerRadius: CornerRadius.xl))
            .contentShape(.rect(cornerRadius: CornerRadius.xl))
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Where to next? Find a station")
        .accessibilityHint("Opens search")
        .accessibilityInputLabels([Text("Find a station"), Text("Search")])
    }
}

#Preview {
    NearbyWelcomeHeroView(action: {})
        .padding()
        .background(DesignColor.background)
}
