//
//  LivePulse.swift
//  TrafficVienna
//
//  A small pulsing green dot that signals a real-time (not just scheduled)
//  departure — the kind of live cue users expect from a polished transit app.
//

import SwiftUI

struct LivePulse: View {
    var color: Color = .green

    var body: some View {
        Circle()
            .fill(color)
            .frame(width: 7, height: 7)
            .accessibilityHidden(true)
    }
}

#Preview {
    HStack { LivePulse(); Text("live") }.padding()
}
