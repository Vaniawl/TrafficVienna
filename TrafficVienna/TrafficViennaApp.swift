//
//  TrafficViennaApp.swift
//  TrafficVienna
//
//  Created by Ivan Dovhosheia on 07.11.25.
//

import SwiftUI

@main
struct TrafficViennaApp: App {
    @UIApplicationDelegateAdaptor(TrafficViennaAppDelegate.self) private var appDelegate

    var body: some Scene {
        WindowGroup {
            RootTabView()
                .tint(.appAccent)
                .task {
                    LegacyAccountProfileCleanup.run()
                    LiveActivityController.endExpiredActivities()
                }
        }
    }
}
