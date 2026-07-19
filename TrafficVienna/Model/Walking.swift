//
//  Walking.swift
//  TrafficVienna
//
//  Shared walking‑time utilities. The speed constant (80 m/min ≈ 4.8 km/h)
//  keeps the formula in one place instead of being duplicated in every view.
//

import CoreLocation
import Foundation

/// Walking speed used for all "X min on foot" estimates.
let walkingSpeed: CLLocationSpeed = 80 // m/min

struct WalkingEstimate: Equatable, Sendable {
    let distanceMeters: CLLocationDistance
    let minutes: Int

    init(distanceMeters: CLLocationDistance) {
        let normalizedDistance = max(0, distanceMeters)
        self.distanceMeters = normalizedDistance
        minutes = max(1, Int((normalizedDistance / walkingSpeed).rounded()))
    }

    var distanceText: String {
        if distanceMeters < 1_000 {
            return "\(Int(distanceMeters)) m"
        }
        return String(format: "%.1f km", distanceMeters / 1_000)
    }

    var text: String { "\(minutes) min · \(distanceText)" }
}

extension CLLocation {
    /// Minutes needed to walk from this location to `other`, rounded up to 1.
    func walkMinutes(to other: CLLocation) -> Int {
        WalkingEstimate(distanceMeters: other.distance(from: self)).minutes
    }
}
