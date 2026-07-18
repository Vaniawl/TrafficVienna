import SwiftUI

enum OnboardingStep: Int, CaseIterable, Identifiable {
    case departures
    case disruptions
    case personal
    case account

    var id: Self { self }

    var next: Self? {
        switch self {
        case .departures: .disruptions
        case .disruptions: .personal
        case .personal: .account
        case .account: nil
        }
    }

    var icon: String {
        switch self {
        case .departures: "tram.fill"
        case .disruptions: "exclamationmark.triangle.fill"
        case .personal: "star.fill"
        case .account: "person.crop.circle.badge.checkmark"
        }
    }

    var eyebrow: LocalizedStringKey {
        switch self {
        case .departures: "LIVE DEPARTURES"
        case .disruptions: "TRAVEL SMARTER"
        case .personal: "MADE FOR YOU"
        case .account: "OPTIONAL ACCOUNT"
        }
    }

    var title: LocalizedStringKey {
        switch self {
        case .departures: "Vienna at a glance"
        case .disruptions: "Know before you go"
        case .personal: "Your commute, one tap away"
        case .account: "Continue your way"
        }
    }

    var message: LocalizedStringKey {
        switch self {
        case .departures: "See nearby stops and real-time departures without digging through timetables."
        case .disruptions: "Check service alerts and the map before you leave, then adapt in seconds."
        case .personal: "Save stations, follow favourite lines, and keep the next departure on your Lock Screen."
        case .account: "Use a verified Apple profile, or continue with every transport feature without an account."
        }
    }
}
