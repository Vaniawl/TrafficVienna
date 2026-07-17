//
//  TrafficViennaApp.swift
//  TrafficVienna
//
//  Created by Ivan Dovhosheia on 07.11.25.
//

import SwiftUI

@main
struct TrafficViennaApp: App {
    @StateObject private var theme = ThemeEngine()

    var body: some Scene {
        WindowGroup {
            RootTabView()
                .environmentObject(theme)
                .preferredColorScheme(theme.colorScheme)
                .tint(theme.preset.accentColor)
        }
    }
}
