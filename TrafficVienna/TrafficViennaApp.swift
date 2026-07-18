//
//  TrafficViennaApp.swift
//  TrafficVienna
//
//  Created by Ivan Dovhosheia on 07.11.25.
//

import SwiftUI

@main
struct TrafficViennaApp: App {
    @StateObject private var auth = AuthStore()
    @StateObject private var router = AppRouter()
    @StateObject private var routines = CommuteRoutineStore()

    init() {
#if DEBUG
        if ProcessInfo.processInfo.arguments.contains("-ui-testing-reset") {
            UserDefaults.standard.removeObject(forKey: "auth.session")
            UserDefaults.standard.set(true, forKey: "hasOnboarded")
        }
#endif
    }

    var body: some Scene {
        WindowGroup {
            Group {
                if auth.session == nil {
                    AuthenticationView()
                        .transition(.opacity)
                } else {
                    RootTabView()
                        .transition(.opacity)
                }
            }
            .animation(.easeInOut, value: auth.session)
            .environmentObject(auth)
            .environmentObject(router)
            .environmentObject(routines)
            .onOpenURL(perform: router.open)
            .task { await auth.validateStoredAppleCredential() }
        }
    }
}
