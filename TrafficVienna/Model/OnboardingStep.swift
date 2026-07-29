import SwiftUI

enum OnboardingStep: Int, CaseIterable, Identifiable {
    case departures
    case disruptions
    case personal

    var id: Self { self }

    var next: Self? {
        switch self {
        case .departures: .disruptions
        case .disruptions: .personal
        case .personal: nil
        }
    }

    var icon: String {
        switch self {
        case .departures: "tram.fill"
        case .disruptions: "exclamationmark.triangle.fill"
        case .personal: "star.fill"
        }
    }

    var eyebrow: LocalizedStringKey {
        switch self {
        case .departures: "LIVE DEPARTURES"
        case .disruptions: "TRAVEL SMARTER"
        case .personal: "MADE FOR YOU"
        }
    }

    var title: LocalizedStringKey {
        switch self {
        case .departures: "Vienna at a glance"
        case .disruptions: "Know before you go"
        case .personal: "Your commute, one tap away"
        }
    }

    var message: LocalizedStringKey {
        switch self {
        case .departures: "See nearby stops and real-time departures without digging through timetables."
        case .disruptions: "Check service alerts and the map before you leave, then adapt in seconds."
        case .personal: "Save stations, follow favourite lines, and keep the next departure on your Lock Screen."
        }
    }
}
