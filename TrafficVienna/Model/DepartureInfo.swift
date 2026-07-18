struct DepartureInfo: Hashable {
    let countdown: Int
    let planned: String
    let real: String?
    let isRealtime: Bool
}
