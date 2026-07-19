import Foundation
import SwiftUI
import UniformTypeIdentifiers

struct TravelDataExport: Codable, Equatable {
    struct Account: Codable, Equatable {
        let provider: String
        let email: String?
        let displayName: String?
    }

    struct Preferences: Codable, Equatable {
        let appearance: String
        let visibleHomeModules: [String]
        let homeModuleOrder: [String]
        let appLockEnabled: Bool
        let appLockTimeoutSeconds: Int
    }

    let schemaVersion: Int
    let exportedAt: Date
    let account: Account?
    let preferences: Preferences
    let favoriteStations: [FavoriteStation]
    let favoriteRoutes: [FavoriteRoute]
    let routines: [CommuteRoutine]
    let recentStationIDs: [Int]

    init(
        exportedAt: Date = .now,
        session: AuthSession?,
        preferences: Preferences,
        favoriteStations: [FavoriteStation],
        favoriteRoutes: [FavoriteRoute],
        routines: [CommuteRoutine],
        recentStationIDs: [Int]
    ) {
        schemaVersion = 1
        self.exportedAt = exportedAt
        account = session.map {
            Account(provider: $0.provider.rawValue, email: $0.email, displayName: $0.displayName)
        }
        self.preferences = preferences
        self.favoriteStations = favoriteStations
        self.favoriteRoutes = favoriteRoutes
        self.routines = routines
        self.recentStationIDs = recentStationIDs
    }

    func encoded() throws -> Data {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try encoder.encode(self)
    }
}

struct TravelDataExportDocument: FileDocument {
    static let readableContentTypes: [UTType] = [.json]

    private let data: Data

    init(export: TravelDataExport) throws {
        data = try export.encoded()
    }

    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents else {
            throw CocoaError(.fileReadCorruptFile)
        }
        self.data = data
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: data)
    }
}
