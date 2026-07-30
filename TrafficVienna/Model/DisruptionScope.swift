import Foundation

enum DisruptionScope: String, CaseIterable, Identifiable {
    case relevant
    case all

    var id: Self { self }

    var title: String {
        switch self {
        case .relevant:
            String(localized: "For you")
        case .all:
            String(localized: "All Vienna")
        }
    }

    var symbol: String {
        switch self {
        case .relevant:
            "person.crop.circle"
        case .all:
            "tram.fill"
        }
    }
}
