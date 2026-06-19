//
//  Shimmer.swift
//  TrafficVienna
//
//  A subtle moving highlight for redacted placeholder content while data loads.
//

import SwiftUI

private struct ShimmerModifier: ViewModifier {
    @State private var phase: CGFloat = -1

    func body(content: Content) -> some View {
        content
            .overlay {
                GeometryReader { geo in
                    let width = geo.size.width
                    LinearGradient(
                        colors: [.clear, Color.white.opacity(0.55), .clear],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: width)
                    .offset(x: phase * width)
                    .mask(content)
                    .allowsHitTesting(false)
                }
            }
            .onAppear {
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
