//
//  TrafficViennaApp.swift
//  TrafficVienna
//
//  Created by Ivan Dovhosheia on 07.11.25.
//

import AuthenticationServices
import SwiftUI

@main
struct TrafficViennaApp: App {
    @State private var accountSession = AccountSession()

    var body: some Scene {
        WindowGroup {
            RootTabView()
                .tint(.appAccent)
                .environment(accountSession)
                .task {
                    await accountSession.validateCredential()
                }
                .onReceive(
                    NotificationCenter.default.publisher(
                        for: ASAuthorizationAppleIDProvider.credentialRevokedNotification
                    )
                ) { _ in
                    accountSession.handleAppleCredentialRevoked()
                }
        }
    }
}
