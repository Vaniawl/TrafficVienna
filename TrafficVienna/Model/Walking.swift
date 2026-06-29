//
//  Walking.swift
//  TrafficVienna
//
//  Shared walking‑time utilities. The speed constant (80 m/min ≈ 4.8 km/h)
//  keeps the formula in one place instead of being duplicated in every view.
//

import CoreLocation

/// Walking speed used for all "X min on foot" estimates.
let walkingSpeed: CLLocationSpeed = 80 // m/min

extension CLLocation {
    /// Minutes needed to walk from this location to `other`, rounded up to 1.
    func walkMinutes(to other: CLLocation) -> Int {
        let distance = other.distance(from: self)
        return max(1, Int((distance / walkingSpeed).rounded()))
    }
}
