enum StationDetailState: Equatable {
    case loading
    case loaded
    case empty
    case failed(String)
}
