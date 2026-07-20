import Foundation

struct TravelDataResetService {
    static let auxiliaryKeys = [
        "recent_search_ids",
        "widget_departure",
        "widget_last_updated",
        "widget_last_fetch_attempt",
        "widget_refresh_requested_at"
    ]

    private let defaults: UserDefaults

    init(defaults: UserDefaults = trafficViennaSharedDefaults) {
        self.defaults = defaults
    }

    func clearAuxiliaryData() {
        Self.auxiliaryKeys.forEach(defaults.removeObject(forKey:))
    }
}
