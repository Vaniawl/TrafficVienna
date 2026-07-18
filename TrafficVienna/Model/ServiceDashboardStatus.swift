enum ServiceDashboardStatus: Equatable {
    case loading
    case allClear(isSaved: Bool)
    case alerts(count: Int, isSaved: Bool)
    case unavailable

    var isSaved: Bool {
        switch self {
        case .allClear(let isSaved), .alerts(_, let isSaved):
            isSaved
        case .loading, .unavailable:
            false
        }
    }
}
