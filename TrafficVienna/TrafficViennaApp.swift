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
            .onOpenURL(perform: router.open)
            .task { await auth.validateStoredAppleCredential() }
        }
    }
}
