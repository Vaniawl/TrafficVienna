//
//  NearbyView.swift
//  TrafficVienna
//
//  "Nearby" tab: stations around the user, each shown as a card with its next
//  departures. Loading is coordinated by NearbyViewModel (sequential, shared
//  "last updated", manual refresh) to stay within the API limit.
//

import SwiftUI
import CoreLocation

struct NearbyView: View {
    @StateObject private var vm: NearbyViewModel
    @ObservedObject private var locationManager: LocationManager
    @Environment(\.openURL) private var openURL

    init(store: StationStore, locationManager: LocationManager) {
        _vm = StateObject(wrappedValue: NearbyViewModel(store: store, location: locationManager))
        _locationManager = ObservedObject(wrappedValue: locationManager)
    }

    var body: some View {
        Group {
            switch locationManager.authorizationStatus {
            case .denied, .restricted:
                placeholder(
                    icon: "location.slash",
                    title: "Location is off",
                    subtitle: "Allow location access in Settings to see stops near you.",
                    action: ("Open Settings", openSettings)
                )
            case .notDetermined:
                placeholder(
                    icon: "location",
                    title: "Find stops near you",
                    subtitle: "Allow location access to see live departures around you.",
                    action: ("Allow location", locationManager.requestLocationIfNeeded)
                )
            default:
                if !vm.hasLocation {
                    locatingView
                } else if vm.items.isEmpty && !vm.isLoading {
                    placeholder(
                        icon: "tram",
                        title: "No stops nearby",
                        subtitle: "There are no stations within 500 m."
                    )
                } else {
                    stationList
                }
            }
        }
        .navigationTitle("Nearby")
        .toolbar {
            if vm.hasLocation && !vm.items.isEmpty {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Task { await vm.load(force: true) }
                    } label: {
                        if vm.isRefreshing {
                            ProgressView().controlSize(.small)
                        } else {
                            Image(systemName: "arrow.clockwise")
                        }
                    }
                    .disabled(vm.isRefreshing)
                    .accessibilityLabel("Refresh departures")
                }
            }
        }
        .task {
            while !Task.isCancelled {
                await vm.load(force: false)
                try? await Task.sleep(for: .seconds(vm.items.isEmpty ? 5 : 60))
            }
        }
    }

    private var stationList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(vm.items) { item in
                    NavigationLink {
                        StationDetailView(station: item.station)
                    } label: {
                        StationCardView(
                            station: item.station,
                            distance: item.distance,
                            lines: item.lines,
                            failed: item.failed,
                            updatedAt: item.updatedAt
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
        .background(Color(.systemGroupedBackground))
        .refreshable { await vm.load(force: true) }
    }

    private var locatingView: some View {
        VStack(spacing: 12) {
            ProgressView()
            Text("Locating you…")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func openSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            openURL(url)
        }
    }

    private func placeholder(
        icon: String,
        title: String,
        subtitle: String,
        action: (title: String, perform: () -> Void)? = nil
    ) -> some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 44))
                .foregroundStyle(.secondary)
            Text(title).font(.title3.weight(.semibold))
            Text(subtitle)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            if let action {
                Button(action.title, action: action.perform)
                    .buttonStyle(.borderedProminent)
                    .padding(.top, 4)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(32)
    }
}

#Preview {
    let lm = LocationManager()
    lm.userLocation = CLLocation(latitude: 48.200832, longitude: 16.369505)
    return NavigationStack {
        NearbyView(store: StationStore(), locationManager: lm)
    }
}
