//
//  Shimmer.swift
//  TrafficVienna
//
//  A subtle moving highlight for redacted placeholder content while data loads.
//

import SwiftUI

private struct ShimmerModifier: ViewModifier {
    @State private var phase: CGFloat = -1
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        content
            .overlay {
                if !reduceMotion { GeometryReader { geo in
                    let width = geo.size.width
                    LinearGradient(
                        colors: [.clear, Color.primary.opacity(0.08), .clear],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: width)
                    .offset(x: phase * width)
                    .mask(content)
                    .allowsHitTesting(false)
                } }
            }
            .onAppear {
                guard !reduceMotion else { return }
                withAnimation(.linear(duration: 1.25).repeatForever(autoreverses: false)) {
                    phase = 1
                }
            }
    }
}

extension View {
    /// Adds an animated shimmer sweep — pair with `.redacted(reason: .placeholder)`.
    func shimmer() -> some View {
        modifier(ShimmerModifier())
    }
}
