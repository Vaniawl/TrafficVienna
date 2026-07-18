enum MapLocationStatus: Equatable {
    case permissionNeeded
    case permissionDenied
    case locating
    case fallback
    case located
}
