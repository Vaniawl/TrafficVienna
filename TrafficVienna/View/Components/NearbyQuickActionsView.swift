import SwiftUI

struct NearbyQuickActionsView: View {
    let onSearch: () -> Void
    let onMap: () -> Void
    let onFavourites: () -> Void
    let onAlerts: () -> Void
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        Group {
            if dynamicTypeSize.isAccessibilitySize {
                LazyVGrid(
                    columns: [GridItem(.flexible()), GridItem(.flexible())],
                    spacing: Spacing.sm
                ) {
                    actions
                }
            } else {
                HStack(alignment: .top, spacing: Spacing.xs) {
                    actions
                }
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Quick actions")
    }

    @ViewBuilder
    private var actions: some View {
        NearbyQuickActionButton(
            title: "Search",
            systemImage: "magnifyingglass",
            action: onSearch
        )
        NearbyQuickActionButton(
            title: "Map",
            systemImage: "map.fill",
            action: onMap
        )
        NearbyQuickActionButton(
            title: "Favourites",
            systemImage: "star.fill",
            action: onFavourites
        )
        NearbyQuickActionButton(
            title: "Alerts",
            systemImage: "exclamationmark.triangle.fill",
            action: onAlerts
        )
    }
}

#Preview {
    NearbyQuickActionsView(
        onSearch: {},
        onMap: {},
        onFavourites: {},
        onAlerts: {}
    )
    .padding()
    .background(DesignColor.background)
}
