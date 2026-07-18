import Foundation

enum DisruptionKind: String, CaseIterable, Identifiable {
    case service
    case accessibility
    case stopChange

    var id: Self { self }

    var title: LocalizedStringResource {
        switch self {
        case .service:
            "Service"
        case .accessibility:
            "Accessibility"
        case .stopChange:
            "Stop changes"
        }
    }

    var symbol: String {
        switch self {
        case .service:
            "exclamationmark.triangle.fill"
        case .accessibility:
            "figure.roll"
        case .stopChange:
            "signpost.right.and.left.fill"
        }
    }

    init(categoryID: Int?) {
        switch categoryID {
        case 1:
            self = .accessibility
        case 3:
            self = .stopChange
        default:
            self = .service
        }
    }
}
