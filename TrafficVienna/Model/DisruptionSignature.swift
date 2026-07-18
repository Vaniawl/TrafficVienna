struct DisruptionSignature: Hashable {
    let categoryID: Int?
    let title: String
    let description: String?
    let lines: [String]

    init(info: TrafficInfo) {
        categoryID = info.categoryID
        title = info.title
        description = info.description
        lines = (info.relatedLines ?? []).sorted()
    }
}
