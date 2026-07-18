struct StationDepartureGroup: Identifiable, Hashable {
    let line: String
    let destination: String
    let minutes: [Int]
    let isLive: Bool

    var id: StationDepartureID {
        StationDepartureID(line: line, destination: destination)
    }
}
