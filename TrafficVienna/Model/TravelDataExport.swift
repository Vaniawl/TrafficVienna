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

enum TravelDataRestoreError: LocalizedError, Equatable {
    case fileTooLarge
    case invalidBackup
    case unsupportedVersion
    case applyFailed
    case rollbackFailed

    var errorDescription: String? {
        switch self {
        case .fileTooLarge: String(localized: "The backup file is too large.")
        case .invalidBackup: String(localized: "This isn’t a valid Traffic Vienna backup.")
        case .unsupportedVersion: String(localized: "This backup version isn’t supported.")
        case .applyFailed: String(localized: "The backup couldn’t be restored. Your previous data was kept.")
        case .rollbackFailed: String(localized: "The backup couldn’t be restored completely. Review your local data before trying again.")
        }
    }
}

struct TravelDataRestorePlan: Equatable {
    static let maximumFileSize = 1_000_000

    let appearance: ThemePreset
    let homeModuleOrder: [HomeModule]
    let visibleHomeModules: Set<HomeModule>
    let favoriteStations: [FavoriteStation]
    let favoriteRoutes: [FavoriteRoute]
    let routines: [CommuteRoutine]
    let recentStationIDs: [Int]

    static func decode(_ data: Data) throws -> TravelDataRestorePlan {
        guard data.count <= maximumFileSize else { throw TravelDataRestoreError.fileTooLarge }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let export: TravelDataExport
        do {
            export = try decoder.decode(TravelDataExport.self, from: data)
        } catch {
            throw TravelDataRestoreError.invalidBackup
        }
        guard export.schemaVersion == 1 else { throw TravelDataRestoreError.unsupportedVersion }
        guard let appearance = ThemePreset(rawValue: export.preferences.appearance),
              export.favoriteStations.count <= 1_000,
              export.favoriteRoutes.count <= 500,
              export.routines.count <= 100,
              export.recentStationIDs.count <= 100
        else { throw TravelDataRestoreError.invalidBackup }

        let orderValues = export.preferences.homeModuleOrder
        let visibleValues = export.preferences.visibleHomeModules
        let order = orderValues.compactMap(HomeModule.init(rawValue:))
        let visible = visibleValues.compactMap(HomeModule.init(rawValue:))
        guard order.count == orderValues.count,
              visible.count == visibleValues.count,
              Set(order).count == order.count,
              Set(visible).count == visible.count,
              Set(order) == Set(HomeModule.allCases),
              Set(visible).isSubset(of: Set(HomeModule.allCases)),
              export.favoriteStations.allSatisfy(isValid),
              export.favoriteRoutes.allSatisfy(isValid),
              export.routines.allSatisfy(isValid),
              export.recentStationIDs.allSatisfy({ $0 > 0 })
        else { throw TravelDataRestoreError.invalidBackup }

        return TravelDataRestorePlan(
            appearance: appearance,
            homeModuleOrder: order,
            visibleHomeModules: Set(visible),
            favoriteStations: unique(export.favoriteStations, by: \FavoriteStation.id),
            favoriteRoutes: unique(export.favoriteRoutes, by: \FavoriteRoute.self),
            routines: unique(export.routines, by: \CommuteRoutine.id),
            recentStationIDs: Array(unique(export.recentStationIDs, by: \Int.self).prefix(8))
        )
    }

    @MainActor
    static func current(
        favorites: FavoritesListViewModel,
        routines: CommuteRoutineStore,
        recentSearches: RecentSearchesStore,
        theme: ThemeManager,
        homePreferences: HomePreferences
    ) -> TravelDataRestorePlan {
        TravelDataRestorePlan(
            appearance: theme.preset,
            homeModuleOrder: homePreferences.moduleOrder,
            visibleHomeModules: Set(homePreferences.moduleOrder.filter(homePreferences.isVisible)),
            favoriteStations: favorites.stations,
            favoriteRoutes: favorites.favoriteRoutes,
            routines: routines.routines,
            recentStationIDs: recentSearches.ids
        )
    }

    @MainActor
    @discardableResult
    func apply(
        favorites: FavoritesListViewModel,
        routines routineStore: CommuteRoutineStore,
        recentSearches: RecentSearchesStore,
        theme: ThemeManager,
        homePreferences: HomePreferences
    ) -> Bool {
        favorites.replaceTravelFavorites(stations: favoriteStations, routes: favoriteRoutes)
        routineStore.replaceAll(with: routines)
        recentSearches.replaceAll(with: recentStationIDs)
        theme.preset = appearance
        homePreferences.apply(order: homeModuleOrder, visible: visibleHomeModules)
        return Self.current(
            favorites: favorites,
            routines: routineStore,
            recentSearches: recentSearches,
            theme: theme,
            homePreferences: homePreferences
        ) == self
    }

    private static func isValid(_ station: FavoriteStation) -> Bool {
        guard station.id > 0,
              station.diva.map({ $0 > 0 }) ?? true,
              !station.name.isEmpty,
              station.name.count <= 200
        else { return false }
        switch (station.lat, station.lon) {
        case (nil, nil): return true
        case let (lat?, lon?): return (-90...90).contains(lat) && (-180...180).contains(lon)
        default: return false
        }
    }

    private static func isValid(_ route: FavoriteRoute) -> Bool {
        (Int(route.diva).map { $0 > 0 } ?? false)
            && !route.lineName.isEmpty && route.lineName.count <= 100
            && !route.destination.isEmpty && route.destination.count <= 200
    }

    private static func isValid(_ routine: CommuteRoutine) -> Bool {
        !routine.name.isEmpty && routine.name.count <= 200
            && (0...23).contains(routine.hour)
            && (0...59).contains(routine.minute)
            && isValid(routine.station)
    }

    private static func unique<Element, Key: Hashable>(
        _ values: [Element],
        by keyPath: KeyPath<Element, Key>
    ) -> [Element] {
        var seen = Set<Key>()
        return values.filter { seen.insert($0[keyPath: keyPath]).inserted }
    }
}
