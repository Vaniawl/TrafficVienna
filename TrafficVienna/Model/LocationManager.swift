//
//  LocationManager.swift
//  TrafficVienna
//
//  Created by Ivan Dovhosheia on 04.12.25.
//

import Foundation
import Combine
import CoreLocation
import OSLog

private let log = Logger(subsystem: "at.wellbe.TrafficVienna", category: "location")

//to find users location
final class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var userLocation: CLLocation?
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var errorMessage: String?

    private var isRequestInFlight = false

    private let isPreview: Bool
    private let manager: any LocationManaging

    override init() {
        isPreview = ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"
        manager = CLLocationManager()
        super.init()
        configure()
    }

    init(
        manager: any LocationManaging,
        isPreview: Bool = false
    ) {
        self.manager = manager
        self.isPreview = isPreview
        super.init()
        configure()
    }

    private func configure() {
        guard !isPreview else {
            userLocation = CLLocation(latitude: 48.2082, longitude: 16.3738) // Відень
            authorizationStatus = .authorizedWhenInUse
            return
        }
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
        authorizationStatus = manager.authorizationStatus
    }
    
    func requestLocationIfNeeded() {
        guard !isPreview else { return }
        switch manager.authorizationStatus {
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse, .authorizedAlways:
            requestCurrentLocation()
        default:
            break
        }
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus
        
        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            requestCurrentLocation()
        case .denied, .restricted:
            isRequestInFlight = false
            errorMessage = "Location access denied"
        default:
            break
        }
    }
    
    func locationManager(_ manager: CLLocationManager,
                         didUpdateLocations locations: [CLLocation]) {
        if isPreview { return }
        isRequestInFlight = false
        guard let loc = locations.last else { return }
        userLocation = loc
        errorMessage = nil
    }
    
    func locationManager(_ manager: CLLocationManager,
                         didFailWithError error: Error) {
        if let clError = error as? CLError, clError.code == .locationUnknown {
            isRequestInFlight = false
            log.debug("locationUnknown, ignoring")
            return
        }

        isRequestInFlight = false
        errorMessage = error.localizedDescription
    }

    private func requestCurrentLocation() {
        guard !isRequestInFlight else { return }
        isRequestInFlight = true
        errorMessage = nil
        manager.requestLocation()
    }
}
