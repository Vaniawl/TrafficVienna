import Foundation

struct DepartureShareContent: Equatable {
    let subject: String
    let text: String

    nonisolated static func make(
        line: String,
        destination: String,
        station: String,
        minutes: Int
    ) -> DepartureShareContent {
        let subject = String(
            format: String(localized: "Live departure: %@ to %@"),
            locale: .current,
            line,
            destination
        )
        let text: String
        if minutes <= 0 {
            text = String(
                format: String(localized: "%@ to %@ is departing now from %@. — Traffic Vienna"),
                locale: .current,
                line,
                destination,
                station
            )
        } else {
            text = String(
                format: String(localized: "%@ to %@ departs from %@ in %lld min. — Traffic Vienna"),
                locale: .current,
                line,
                destination,
                station,
                Int64(minutes)
            )
        }
        return DepartureShareContent(subject: subject, text: text)
    }
}
