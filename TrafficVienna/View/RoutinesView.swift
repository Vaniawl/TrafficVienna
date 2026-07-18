import SwiftUI

struct RoutinesView: View {
    @EnvironmentObject private var routines: CommuteRoutineStore
    @State private var stations = UserDefaultsFavoriteStationsRepository().all()
    @State private var name = ""
    @State private var selectedStationID: Int?
    @State private var time = Calendar.current.date(from: DateComponents(hour: 8)) ?? .now

    var body: some View {
        List {
            NeoHeader(eyebrow: "Automation", title: "Travel routines", subtitle: "Surface the right station at the right time")
                .listRowBackground(Color.clear).listRowSeparator(.hidden)

            if routines.routines.isEmpty {
                ContentUnavailableView("No routines", systemImage: "clock.arrow.2.circlepath", description: Text("Add a favourite station first, then create a daily routine."))
                    .listRowBackground(Color.clear)
            } else {
                Section("Your routines") {
                    ForEach(routines.routines) { routine in
                        HStack(spacing: 14) {
                            NeoIcon(systemName: "clock.fill")
                            VStack(alignment: .leading, spacing: 3) {
                                Text(routine.name).font(.headline)
                                Text("\(routine.station.name) · \(routine.hour.formatted(.number.precision(.integerLength(2)))):00")
                                    .font(.caption).foregroundStyle(.secondary)
                            }
                            Spacer()
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
                    Button("Add routine") { addRoutine() }
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty || selectedStationID == nil)
                }
            }
        }
        .scrollContentBackground(.hidden).neoScreen()
        .navigationTitle("Routines").navigationBarTitleDisplayMode(.inline)
    }

    private func addRoutine() {
        guard let station = stations.first(where: { $0.id == selectedStationID }) else { return }
        routines.add(name: name.trimmingCharacters(in: .whitespaces), station: station, hour: Calendar.current.component(.hour, from: time))
        name = ""
    }
}
