import Foundation

struct StationDetailNotice: Identifiable {
    let id = UUID()
    let title: String
    let message: String
    let offersSettings: Bool

    init(
        title: String,
        message: String,
        offersSettings: Bool = false
    ) {
        self.title = title
        self.message = message
        self.offersSettings = offersSettings
    }
}
