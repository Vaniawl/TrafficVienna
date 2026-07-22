import Foundation
import Combine

nonisolated enum AnnualPassFormat: String, Codable, CaseIterable, Sendable {
    case digital
    case plastic

    var title: String {
        switch self {
        case .digital: "Digital"
        case .plastic: "Plastic card"
        }
    }
}

nonisolated enum AnnualPassCategory: String, Codable, CaseIterable, Sendable {
    case standard
    case youth
    case senior
    case special
    case jobticket

    var title: String {
        switch self {
        case .standard: "Standard"
        case .youth: "Youth"
        case .senior: "Senior"
        case .special: "Special"
        case .jobticket: "Jobticket"
        }
    }
}

nonisolated struct AnnualPass: Codable, Equatable, Sendable {
    let holderName: String
    let cardNumber: String
    let validFrom: Date
    let validUntil: Date
    let format: AnnualPassFormat
    let category: AnnualPassCategory

    init(
        holderName: String,
        cardNumber: String,
        validFrom: Date,
        validUntil: Date,
        format: AnnualPassFormat = .digital,
        category: AnnualPassCategory = .standard
    ) {
        self.holderName = holderName
        self.cardNumber = cardNumber
        self.validFrom = validFrom
        self.validUntil = validUntil
        self.format = format
        self.category = category
    }

    private enum CodingKeys: String, CodingKey {
        case holderName, cardNumber, validFrom, validUntil, format, category
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        holderName = try container.decode(String.self, forKey: .holderName)
        cardNumber = try container.decode(String.self, forKey: .cardNumber)
        validFrom = try container.decode(Date.self, forKey: .validFrom)
        validUntil = try container.decode(Date.self, forKey: .validUntil)
        format = try container.decodeIfPresent(AnnualPassFormat.self, forKey: .format) ?? .digital
        category = try container.decodeIfPresent(AnnualPassCategory.self, forKey: .category) ?? .standard
    }

    var maskedCardNumber: String {
        let compact = cardNumber.filter(\.isNumber)
        guard compact.count > 4 else { return cardNumber }
        return "•••• \(compact.suffix(4))"
    }
}

nonisolated enum AnnualPassState: Equatable, Sendable {
    case upcoming(days: Int)
    case active(daysRemaining: Int)
    case expired

    static func evaluate(
        _ pass: AnnualPass,
        on date: Date,
        calendar: Calendar = .current
    ) -> AnnualPassState {
        let today = calendar.startOfDay(for: date)
        let start = calendar.startOfDay(for: pass.validFrom)
        let end = calendar.startOfDay(for: pass.validUntil)

        if today < start {
            return .upcoming(days: max(1, calendar.dateComponents([.day], from: today, to: start).day ?? 1))
        }
        guard today <= end else { return .expired }
        return .active(daysRemaining: max(0, calendar.dateComponents([.day], from: today, to: end).day ?? 0))
    }
}

@MainActor
final class AnnualPassStore: ObservableObject {
    @Published private(set) var pass: AnnualPass?

    private let defaults: UserDefaults
    private let key = "annual_pass"

    init(defaults: UserDefaults = trafficViennaSharedDefaults) {
        self.defaults = defaults
        pass = defaults.data(forKey: key).flatMap { try? JSONDecoder().decode(AnnualPass.self, from: $0) }
    }

    func save(
        holderName: String,
        cardNumber: String,
        validFrom: Date,
        validUntil: Date,
        format: AnnualPassFormat = .digital,
        category: AnnualPassCategory = .standard
    ) {
        let normalized = AnnualPass(
            holderName: holderName.trimmingCharacters(in: .whitespacesAndNewlines),
            cardNumber: cardNumber.trimmingCharacters(in: .whitespacesAndNewlines),
            validFrom: validFrom,
            validUntil: validUntil,
            format: format,
            category: category
        )
        pass = normalized
        if let data = try? JSONEncoder().encode(normalized) {
            defaults.set(data, forKey: key)
        }
    }

    func remove() {
        pass = nil
        defaults.removeObject(forKey: key)
    }
}
