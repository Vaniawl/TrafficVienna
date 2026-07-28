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
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @StateObject private var auth = AuthStore()
    @StateObject private var appLock = AppLockStore()
    @StateObject private var router = AppRouter()
    @StateObject private var routines = CommuteRoutineStore()
    @StateObject private var shortcutRouter = TrafficViennaShortcutRouter.shared

    init() {
#if DEBUG
        if ProcessInfo.processInfo.arguments.contains("-ui-testing-reset") {
            let defaults = trafficViennaSharedDefaults
            UserDefaults.standard.set(true, forKey: "hasOnboarded")
            UserDefaultsFavoritesRepository().removeAll()
            UserDefaultsFavoriteStationsRepository().removeAll()
            defaults.removeObject(forKey: "annual_pass")
            defaults.removeObject(forKey: "recent_search_ids")
            defaults.removeObject(forKey: "themePreset")
        }
#endif
    }

    var body: some Scene {
        WindowGroup {
            Group {
                if auth.session == nil {
                    AuthenticationView()
                        .transition(reduceMotion ? .identity : .opacity)
                } else {
                    SignedInSessionView()
                        .transition(reduceMotion ? .identity : .opacity)
                }
            }
            .animation(reduceMotion ? nil : .easeInOut, value: auth.session)
            .symbolEffectsRemoved(reduceMotion)
            .environmentObject(auth)
            .environmentObject(appLock)
            .environmentObject(router)
            .environmentObject(routines)
            .onOpenURL(perform: router.open)
            .onChange(of: shortcutRouter.pendingDestination, initial: true) { _, destination in
                guard let destination else { return }
                router.navigate(to: destination.appDestination)
                shortcutRouter.consume()
            }
            .task { await auth.validateStoredAppleCredential() }
            .task(id: auth.session) {
                guard auth.session != nil else {
                    appLock.clearLockForSignedOutSession()
                    return
                }
                await appLock.unlock()
            }
            .onChange(of: scenePhase) { _, phase in
                if phase == .active {
                    Task {
                        if appLock.resumeAfterInactivity() {
                            await appLock.unlock()
                        }
                    }
                } else {
                    appLock.protectForInactivity(hasSession: auth.session != nil)
                }
            }
        }
    }
}

private struct SignedInSessionView: View {
    @EnvironmentObject private var appLock: AppLockStore
    @StateObject private var rootState = RootTabState()

    var body: some View {
        if appLock.isLocked || appLock.isPrivacyShieldVisible {
            AppLockView()
        } else {
            RootTabView(state: rootState)
        }
    }
}
