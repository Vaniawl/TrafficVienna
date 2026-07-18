import Combine
import Foundation

struct CommuteRoutine: Codable, Identifiable, Equatable {
    let id: UUID
    var name: String
    var station: FavoriteStation
    var hour: Int
    var minute: Int
    var isEnabled: Bool

    init(id: UUID = UUID(), name: String, station: FavoriteStation, hour: Int, minute: Int = 0, isEnabled: Bool = true) {
        self.id = id
        self.name = name
        self.station = station
        self.hour = hour
        self.minute = minute
        self.isEnabled = isEnabled
    }

    private enum CodingKeys: String, CodingKey {
        case id, name, station, hour, minute, isEnabled
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        station = try container.decode(FavoriteStation.self, forKey: .station)
        hour = try container.decode(Int.self, forKey: .hour)
        minute = try container.decodeIfPresent(Int.self, forKey: .minute) ?? 0
        isEnabled = try container.decode(Bool.self, forKey: .isEnabled)
    }

    var minutesSinceMidnight: Int {
        let rawValue = hour * 60 + minute
        return (rawValue % 1_440 + 1_440) % 1_440
    }

    var timeText: String {
        let components = DateComponents(
            hour: minutesSinceMidnight / 60,
            minute: minutesSinceMidnight % 60
        )
        guard let date = Calendar.current.date(from: components) else { return "" }
        return date.formatted(date: .omitted, time: .shortened)
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
        current(at: .now)
    }

    func current(at date: Date, calendar: Calendar = .current) -> CommuteRoutine? {
        let components = calendar.dateComponents([.hour, .minute], from: date)
        let currentMinutes = (components.hour ?? 0) * 60 + (components.minute ?? 0)
        return routines.filter(\.isEnabled).min {
            circularDistance(from: $0.minutesSinceMidnight, to: currentMinutes)
                < circularDistance(from: $1.minutesSinceMidnight, to: currentMinutes)
        }
    }

    func add(name: String, station: FavoriteStation, hour: Int, minute: Int = 0) {
        routines.append(CommuteRoutine(name: name, station: station, hour: hour, minute: minute))
        save()
    }

    func toggle(_ id: UUID) {
        guard let index = routines.firstIndex(where: { $0.id == id }) else { return }
        routines[index].isEnabled.toggle()
        save()
    }

    func update(
        id: UUID,
        name: String,
        station: FavoriteStation,
        hour: Int,
        minute: Int
    ) {
        guard let index = routines.firstIndex(where: { $0.id == id }) else { return }
        routines[index].name = name
        routines[index].station = station
        routines[index].hour = hour
        routines[index].minute = minute
        save()
    }

    func remove(at offsets: IndexSet) {
        for index in offsets.sorted(by: >) { routines.remove(at: index) }
        save()
    }

    func removeAll() {
        routines = []
        defaults.removeObject(forKey: key)
    }

    private func save() {
        defaults.set(try? JSONEncoder().encode(routines), forKey: key)
    }

    private func circularDistance(from lhs: Int, to rhs: Int) -> Int {
        let distance = abs(lhs - rhs)
        return min(distance, 1_440 - distance)
    }
}
