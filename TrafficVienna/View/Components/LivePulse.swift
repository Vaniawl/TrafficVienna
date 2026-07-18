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
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Circle()
            .fill(color)
            .frame(width: 7, height: 7)
            .scaleEffect(reduceMotion ? 1 : (animate ? 1.3 : 0.9))
            .opacity(reduceMotion ? 1 : (animate ? 0.4 : 1))
            .onAppear {
                guard !reduceMotion else { return }
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
