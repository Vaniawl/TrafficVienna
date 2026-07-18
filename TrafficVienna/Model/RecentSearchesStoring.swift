protocol RecentSearchesStoring: AnyObject {
    var ids: [Int] { get }
    func record(_ id: Int)
    func clear()
}
