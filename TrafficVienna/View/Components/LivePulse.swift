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
    @State private var animate = false

    var body: some View {
        Circle()
            .fill(color)
            .frame(width: 7, height: 7)
            .scaleEffect(animate ? 1.3 : 0.9)
            .opacity(animate ? 0.4 : 1)
            .onAppear {
                withAnimation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true)) {
                    animate = true
                }
            }
            .accessibilityHidden(true)
    }
}

#Preview {
    HStack { LivePulse(); Text("live") }.padding()
}
