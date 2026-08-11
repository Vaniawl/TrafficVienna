//
//  TrafficViennaApp.swift
//  TrafficVienna
//
//  Created by Ivan Dovhosheia on 07.11.25.
//

import SwiftUI

@main
struct TrafficViennaApp: App {
    init() {
        UITestLaunchConfiguration.prepare()
    }

    var body: some Scene {
        WindowGroup {
            RootTabView()
                .tint(.appAccent)
                .task {
                    LegacyAccountProfileCleanup.run()
                }
        }
    }
}
