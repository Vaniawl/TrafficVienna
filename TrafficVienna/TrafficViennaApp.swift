//
//  TrafficViennaApp.swift
//  TrafficVienna
//
//  Created by Ivan Dovhosheia on 07.11.25.
//

import SwiftUI

@main
struct TrafficViennaApp: App {
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var auth = AuthStore()
    @StateObject private var appLock = AppLockStore()
    @StateObject private var router = AppRouter()
    @StateObject private var routines = CommuteRoutineStore()

    init() {
#if DEBUG
        if ProcessInfo.processInfo.arguments.contains("-ui-testing-reset") {
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
                } else if appLock.isLocked {
                    AppLockView()
                        .transition(.opacity)
                } else {
                    RootTabView()
                        .transition(.opacity)
                }
            }
            .animation(.easeInOut, value: auth.session)
            .environmentObject(auth)
            .environmentObject(appLock)
            .environmentObject(router)
            .environmentObject(routines)
            .onOpenURL(perform: router.open)
            .task { await auth.validateStoredAppleCredential() }
            .task(id: auth.session) {
                guard auth.session != nil else {
                    appLock.clearLockForSignedOutSession()
                    return
                }
                await appLock.unlock()
            }
            .onChange(of: scenePhase) { _, phase in
                if phase != .active {
                    appLock.lockIfNeeded(hasSession: auth.session != nil)
                }
            }
        }
    }
}
