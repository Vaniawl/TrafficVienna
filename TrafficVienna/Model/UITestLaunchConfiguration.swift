import SwiftUI

enum UITestLaunchConfiguration {
    private static let arguments = ProcessInfo.processInfo.arguments

    static var initialTab: AppTab {
#if DEBUG
        guard isRunning,
              let value = value(after: "-ui-testing-tab"),
              let tab = AppTab(rawValue: value)
        else {
            return .nearby
        }
        return tab
#else
        .nearby
#endif
    }

    static var shouldRequestLocation: Bool {
#if DEBUG
        isRunning && arguments.contains("-ui-testing-request-location")
#else
        false
#endif
    }

    static var disablesAnimations: Bool {
#if DEBUG
        isRunning
#else
        false
#endif
    }

    static func prepare() {
#if DEBUG
        guard isRunning else { return }

        UIView.setAnimationsEnabled(false)

        if arguments.contains("-ui-testing-reset") {
            resetLocalState()
            UserDefaults.standard.set(
                arguments.contains("-ui-testing-skip-onboarding"),
                forKey: "hasOnboarded"
            )
        }

        if !arguments.contains("-ui-testing-reset"),
           arguments.contains("-ui-testing-skip-onboarding") {
            UserDefaults.standard.set(true, forKey: "hasOnboarded")
        }

        if arguments.contains("-ui-testing-seed-favourites") {
            seedFavourites()
        }
#endif
    }

#if DEBUG
    private static var isRunning: Bool {
        arguments.contains("-ui-testing")
    }

    private static func value(after flag: String) -> String? {
        guard let index = arguments.firstIndex(of: flag) else { return nil }
        let valueIndex = arguments.index(after: index)
        guard valueIndex < arguments.endIndex else { return nil }
        return arguments[valueIndex]
    }

    private static func resetLocalState() {
        UserDefaults.standard.removeObject(forKey: "hasOnboarded")
        UserDefaults.standard.removeObject(
            forKey: TrafficViennaShortcutRouter.pendingDestinationKey
        )

        guard let sharedDefaults = UserDefaults(suiteName: TrafficViennaStorage.appGroupID) else {
            return
        }
        resetSharedState(in: sharedDefaults)
    }

    static func resetSharedState(in defaults: UserDefaults) {
        TrafficViennaStorage.resettableSharedKeys.forEach(defaults.removeObject(forKey:))
    }

    private static func seedFavourites() {
        guard let sharedDefaults = UserDefaults(suiteName: TrafficViennaStorage.appGroupID) else {
            return
        }

        let station = FavoriteStation(
            id: 1_085_621_741,
            diva: 60_201_320,
            name: "Stephansplatz"
        )
        let route = FavoriteRoute(
            diva: "60201320",
            lineName: "U1",
            destination: "Leopoldau"
        )

        sharedDefaults.set(
            try? JSONEncoder().encode([station]),
            forKey: TrafficViennaStorage.favoriteStations
        )
        sharedDefaults.set(
            try? JSONEncoder().encode(Set([route])),
            forKey: TrafficViennaStorage.favoriteRoutes
        )
    }
#endif
}
