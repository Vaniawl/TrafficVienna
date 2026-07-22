import Foundation
import Combine

nonisolated struct AnnualPass: Codable, Equatable, Sendable {
    let holderName: String
    let cardNumber: String
    let validFrom: Date
    let validUntil: Date

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

    func save(holderName: String, cardNumber: String, validFrom: Date, validUntil: Date) {
        let normalized = AnnualPass(
            holderName: holderName.trimmingCharacters(in: .whitespacesAndNewlines),
            cardNumber: cardNumber.trimmingCharacters(in: .whitespacesAndNewlines),
            validFrom: validFrom,
            validUntil: validUntil
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
