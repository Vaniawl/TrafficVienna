import Combine
import Foundation

struct CommuteRoutine: Codable, Identifiable, Equatable {
    let id: UUID
    var name: String
    var station: FavoriteStation
    var hour: Int
    var isEnabled: Bool

    init(id: UUID = UUID(), name: String, station: FavoriteStation, hour: Int, isEnabled: Bool = true) {
        self.id = id
        self.name = name
        self.station = station
        self.hour = hour
        self.isEnabled = isEnabled
    }
}

@MainActor
final class CommuteRoutineStore: ObservableObject {
    @Published private(set) var routines: [CommuteRoutine] = []
    private let defaults: UserDefaults
    private let key = "commute_routines"

    init(defaults: UserDefaults = UserDefaults(suiteName: "group.wellbe.TrafficVienna") ?? .standard) {
        self.defaults = defaults
        if let data = defaults.data(forKey: key) {
            routines = (try? JSONDecoder().decode([CommuteRoutine].self, from: data)) ?? []
        }
    }

    var current: CommuteRoutine? {
        let hour = Calendar.current.component(.hour, from: .now)
        return routines.filter(\.isEnabled).min { abs($0.hour - hour) < abs($1.hour - hour) }
    }

    func add(name: String, station: FavoriteStation, hour: Int) {
        routines.append(CommuteRoutine(name: name, station: station, hour: hour))
        save()
    }

    func toggle(_ id: UUID) {
        guard let index = routines.firstIndex(where: { $0.id == id }) else { return }
        routines[index].isEnabled.toggle()
        save()
    }

    func remove(at offsets: IndexSet) {
        for index in offsets.sorted(by: >) { routines.remove(at: index) }
        save()
    }

    private func save() {
        defaults.set(try? JSONEncoder().encode(routines), forKey: key)
    }
}
