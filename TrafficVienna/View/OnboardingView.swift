//
//  OnboardingView.swift
//  TrafficVienna
//
//  First-launch welcome: introduces the app and primes the location request
//  with context (so the system prompt doesn't appear out of nowhere).
//

import SwiftUI

struct OnboardingView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let onEnableLocation: () -> Void
    let onContinueWithoutLocation: () -> Void
    @State private var hasAppeared = false

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(hex: 0x635BFF).opacity(0.22),
                    Color(.systemBackground),
                    NeoDesign.accent.opacity(0.10)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 28) {
                    hero
                    features
                    actions
                }
                .padding(.horizontal, 22)
                .padding(.top, 42)
                .padding(.bottom, 28)
                .opacity(hasAppeared ? 1 : 0)
                .offset(y: hasAppeared || reduceMotion ? 0 : 18)
            }
            .scrollIndicators(.hidden)
        }
        .onAppear {
            withAnimation(reduceMotion ? nil : .smooth(duration: 0.55)) {
                hasAppeared = true
            }
        }
    }

    private var hero: some View {
        VStack(spacing: 18) {
            Image(systemName: "tram.fill")
                .font(.system(size: 38, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 84, height: 84)
                .background(
                    LinearGradient(
                        colors: [Color(hex: 0x635BFF), NeoDesign.accentDark],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    in: RoundedRectangle(cornerRadius: 27, style: .continuous)
                )
                .shadow(color: Color(hex: 0x4338CA).opacity(0.28), radius: 24, y: 12)
                .symbolEffect(.bounce, options: .nonRepeating, value: hasAppeared)

            VStack(spacing: 7) {
                Text("Vienna, live in your pocket.")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .tracking(-0.8)
                Text("Know what leaves next, save your daily lines, and keep the important part on your Lock Screen.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var features: some View {
        VStack(spacing: 0) {
            feature("location.fill", "Nearby, instantly", "Live stops and walking-aware departure times around you.")
            Divider().padding(.leading, 60)
            feature("star.fill", "Your daily Vienna", "Favourite lines, smart alerts, routines, and accurate widgets.")
            Divider().padding(.leading, 60)
            feature("lock.iphone", "Useful without opening", "Track a departure with Live Activities and Dynamic Island.")
        }
        .neoCard(padding: 8)
    }

    private var actions: some View {
        VStack(spacing: 14) {
            Button(action: onEnableLocation) {
                Label("Use my location", systemImage: "location.fill")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.glassProminent)
            .tint(NeoDesign.accent)
            .controlSize(.large)

            Button("Continue without location", action: onContinueWithoutLocation)
                .font(.subheadline.bold())
                .foregroundStyle(.primary)

            Text("Location is used only to find nearby stops. You can search and use the map without sharing it. Data: Wiener Linien (Stadt Wien, CC BY).")
                .font(.caption)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 8)
        }
    }

    private func feature(
        _ icon: String,
        _ title: LocalizedStringKey,
        _ subtitle: LocalizedStringKey
    ) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(NeoDesign.accent)
                .frame(width: 44, height: 44)
                .background(NeoDesign.accent.opacity(0.10), in: Circle())
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 3) {
                Text(title).font(.headline)
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .padding(10)
    }
}

#Preview {
    OnboardingView(
        onEnableLocation: {},
        onContinueWithoutLocation: {}
    )
}
