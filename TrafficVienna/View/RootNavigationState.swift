import SwiftUI

struct RootNavigationState {
    var selectedTab: AppTab = .nearby
    var nearbyPath = NavigationPath()
    var discoverPath = NavigationPath()
    var alertsPath = NavigationPath()
    var favouritesPath = NavigationPath()

    mutating func select(_ tab: AppTab) {
        selectedTab = tab
    }

    mutating func openExternalDestination(
        _ destination: TrafficViennaDestination
    ) {
        let tab = destination.appTab
        resetPath(for: tab)
        selectedTab = tab
    }

    mutating func openExternalStation(_ station: Station?) {
        discoverPath = NavigationPath()
        if let station {
            discoverPath.append(station)
        }
        selectedTab = .search
    }

    private mutating func resetPath(for tab: AppTab) {
        switch tab {
        case .nearby:
            nearbyPath = NavigationPath()
        case .search:
            discoverPath = NavigationPath()
        case .alerts:
            alertsPath = NavigationPath()
        case .favourites:
            favouritesPath = NavigationPath()
        }
    }
}
