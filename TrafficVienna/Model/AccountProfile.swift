import Foundation

struct AccountProfile: Codable, Equatable, Sendable {
    enum Provider: String, Codable, Sendable {
        case apple
    }

    let id: String
    let displayName: String?
    let email: String?
    let provider: Provider

    var preferredName: String {
        if let displayName, !displayName.isEmpty {
            displayName
        } else if let email, !email.isEmpty {
            email
        } else {
            String(localized: "Apple account")
        }
    }
}
