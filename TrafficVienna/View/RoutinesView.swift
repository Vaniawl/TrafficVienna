import SwiftUI

struct RoutinesView: View {
    @EnvironmentObject private var routines: CommuteRoutineStore
    @EnvironmentObject private var favoritesVM: FavoritesListViewModel
    @State private var name = ""
    @State private var selectedStationID: Int?
    @State private var time = Calendar.current.date(from: DateComponents(hour: 8)) ?? .now
    @State private var activeWeekdays = Set(CommuteRoutine.everyWeekday)
    @State private var editingRoutine: CommuteRoutine?

    private var stations: [FavoriteStation] { favoritesVM.stations }

    var body: some View {
        List {
            NeoHeader(eyebrow: "Automation", title: "Travel routines", subtitle: "Surface the right station at the right time")
                .listRowBackground(Color.clear).listRowSeparator(.hidden)

            if routines.routines.isEmpty {
                ContentUnavailableView("No routines", systemImage: "clock.arrow.2.circlepath", description: Text("Add a favourite station first, then create a routine."))
                    .listRowBackground(Color.clear)
            } else {
                Section("Your routines") {
                    ForEach(routines.routines) { routine in
                        HStack(spacing: 14) {
                            NeoIcon(systemName: "clock.fill")
                            VStack(alignment: .leading, spacing: 3) {
                                Text(routine.name).font(.headline)
                                Text("\(routine.station.name) · \(routine.timeText)")
                                    .font(.caption).foregroundStyle(.secondary)
                                Text(routine.weekdaySummary)
                                    .font(.caption2).foregroundStyle(.secondary)
                            }
                            Spacer()
                            Button {
                                editingRoutine = routine
                            } label: {
                                Image(systemName: "pencil")
                                    .frame(width: 36, height: 36)
                            }
                            .buttonStyle(.borderless)
                            .accessibilityLabel("Edit routine")
                            Toggle("", isOn: Binding(get: { routine.isEnabled }, set: { _ in routines.toggle(routine.id) }))
                                .labelsHidden()
                        }
                    }
                    .onDelete(perform: routines.remove)
                }
            }

            if !stations.isEmpty {
                Section("New routine") {
                    TextField("Name, e.g. Work", text: $name)
                    Picker("Station", selection: $selectedStationID) {
                        Text("Choose").tag(Int?.none)
                        ForEach(stations) { Text($0.name).tag(Int?.some($0.id)) }
                    }
                    DatePicker("Time", selection: $time, displayedComponents: .hourAndMinute)
                    WeekdayPicker(selection: $activeWeekdays)
                    Button("Add routine") { addRoutine() }
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty || selectedStationID == nil || activeWeekdays.isEmpty)
                }
            }
        }
        .scrollContentBackground(.hidden).neoScreen()
        .navigationTitle("Routines").navigationBarTitleDisplayMode(.inline)
        .sheet(item: $editingRoutine) { routine in
            RoutineEditorView(routine: routine, stations: stations) { name, station, hour, minute, weekdays in
                routines.update(
                    id: routine.id,
                    name: name,
                    station: station,
                    hour: hour,
                    minute: minute,
                    activeWeekdays: weekdays
                )
            }
        }
    }

    private func addRoutine() {
        guard let station = stations.first(where: { $0.id == selectedStationID }) else { return }
        let components = Calendar.current.dateComponents([.hour, .minute], from: time)
        routines.add(
            name: name.trimmingCharacters(in: .whitespaces),
            station: station,
            hour: components.hour ?? 0,
            minute: components.minute ?? 0,
            activeWeekdays: CommuteRoutine.everyWeekday.filter(activeWeekdays.contains)
        )
        name = ""
        activeWeekdays = Set(CommuteRoutine.everyWeekday)
    }
}

private struct RoutineEditorView: View {
    @Environment(\.dismiss) private var dismiss
    let routine: CommuteRoutine
    let stations: [FavoriteStation]
    let onSave: (String, FavoriteStation, Int, Int, [Int]) -> Void

    @State private var name: String
    @State private var selectedStationID: Int?
    @State private var time: Date
    @State private var activeWeekdays: Set<Int>

    init(
        routine: CommuteRoutine,
        stations: [FavoriteStation],
        onSave: @escaping (String, FavoriteStation, Int, Int, [Int]) -> Void
    ) {
        self.routine = routine
        self.stations = stations
        self.onSave = onSave
        _name = State(initialValue: routine.name)
        _selectedStationID = State(initialValue: routine.station.id)
        _time = State(initialValue: Calendar.current.date(
            from: DateComponents(hour: routine.hour, minute: routine.minute)
        ) ?? .now)
        _activeWeekdays = State(initialValue: Set(routine.activeWeekdays))
    }

    private var availableStations: [FavoriteStation] {
        stations.contains(where: { $0.id == routine.station.id })
            ? stations
            : [routine.station] + stations
    }

    private var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        NavigationStack {
            Form {
                TextField("Name, e.g. Work", text: $name)
                Picker("Station", selection: $selectedStationID) {
                    ForEach(availableStations) { station in
                        Text(station.name).tag(Int?.some(station.id))
                    }
                }
                DatePicker("Time", selection: $time, displayedComponents: .hourAndMinute)
                WeekdayPicker(selection: $activeWeekdays)
            }
            .navigationTitle("Edit routine")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(trimmedName.isEmpty || selectedStationID == nil || activeWeekdays.isEmpty)
                }
            }
        }
    }

    private func save() {
        guard let station = availableStations.first(where: { $0.id == selectedStationID }) else { return }
        let components = Calendar.current.dateComponents([.hour, .minute], from: time)
        onSave(
            trimmedName,
            station,
            components.hour ?? 0,
            components.minute ?? 0,
            CommuteRoutine.everyWeekday.filter(activeWeekdays.contains)
        )
        dismiss()
    }
}

private struct WeekdayPicker: View {
    @Binding var selection: Set<Int>

    private var orderedDays: [Int] {
        let first = Calendar.current.firstWeekday
        return (0..<7).map { ((first - 1 + $0) % 7) + 1 }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Active days")
                .font(.subheadline)
            ScrollView(.horizontal) {
                HStack(spacing: 8) {
                    ForEach(orderedDays, id: \.self) { day in
                        Button {
                            if selection.contains(day) {
                                selection.remove(day)
                            } else {
                                selection.insert(day)
                            }
                        } label: {
                            Text(Calendar.current.veryShortStandaloneWeekdaySymbols[day - 1])
                                .font(.caption.bold())
                                .frame(width: 44, height: 44)
                                .foregroundStyle(selection.contains(day) ? .white : .primary)
                                .background(
                                    selection.contains(day) ? Color(hex: 0x635BFF) : Color(.secondarySystemGroupedBackground),
                                    in: Circle()
                                )
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(Calendar.current.standaloneWeekdaySymbols[day - 1])
                        .accessibilityValue(selection.contains(day) ? "Selected" : "Not selected")
                    }
                }
            }
            .scrollIndicators(.hidden)
            if selection.isEmpty {
                Text("Select at least one day")
                    .font(.caption)
                    .foregroundStyle(.red)
            }
        }
    }
}
