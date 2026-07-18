//
//  Shimmer.swift
//  TrafficVienna
//
//  A subtle moving highlight for redacted placeholder content while data loads.
//

import SwiftUI

private struct ShimmerModifier: ViewModifier {
    @State private var isPresented = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        content
            .overlay {
                GeometryReader { geo in
                    let width = geo.size.width
                    LinearGradient(
                        colors: [.clear, Color.primary.opacity(0.08), .clear],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: width)
                    .offset(x: (isPresented ? 1 : -1) * width)
                    .opacity(reduceMotion ? 0 : 1)
                    .mask(content)
                    .allowsHitTesting(false)
                }
            }
            .animation(
                reduceMotion ? nil : Motion.shimmer.repeatForever(autoreverses: false),
                value: isPresented
            )
            .task(id: reduceMotion) {
                isPresented = !reduceMotion
            }
    }
}

extension View {
    /// Adds an animated shimmer sweep — pair with `.redacted(reason: .placeholder)`.
    func shimmer() -> some View {
        modifier(ShimmerModifier())
    }
}
