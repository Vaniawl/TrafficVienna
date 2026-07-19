import SwiftUI

enum PollingFeed: CaseIterable {
    case nearbyWithoutResults
    case nearbyDepartures
    case homeDashboard
    case stationDetail
    case serviceAlerts
    case favoriteRoutes

    var normalSeconds: Int {
        switch self {
        case .nearbyWithoutResults: 5
        case .nearbyDepartures, .homeDashboard, .favoriteRoutes: 60
        case .stationDetail: 30
        case .serviceAlerts: 120
        }
    }

    var constrainedSeconds: Int {
        switch self {
        case .nearbyWithoutResults: 15
        case .nearbyDepartures, .homeDashboard, .favoriteRoutes: 180
        case .stationDetail: 90
        case .serviceAlerts: 300
        }
    }

    func seconds(usesConstrainedCadence: Bool) -> Int {
        usesConstrainedCadence ? constrainedSeconds : normalSeconds
    }
}

struct PollingContext: Hashable {
    let isActive: Bool
    let usesConstrainedCadence: Bool
}

private struct LowDataModeKey: EnvironmentKey {
    static let defaultValue = false
}

extension EnvironmentValues {
    var isLowDataMode: Bool {
        get { self[LowDataModeKey.self] }
        set { self[LowDataModeKey.self] = newValue }
    }
}
