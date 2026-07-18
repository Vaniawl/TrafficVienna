enum SearchStatus: Hashable {
    case idle
    case loadingCatalog
    case searching
    case results
    case noResults
    case unavailable
}
