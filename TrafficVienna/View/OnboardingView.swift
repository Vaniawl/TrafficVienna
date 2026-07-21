//
//  OnboardingView.swift
//  TrafficVienna
//
//  First-launch welcome: introduces the app and primes the location request
//  with context (so the system prompt doesn't appear out of nowhere).
//

import SwiftUI

struct OnboardingView: View {
    var onGetStarted: () -> Void

    var body: some View {
        ZStack {
            NeoDesign.background.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 18) {
                    hero

                    VStack(spacing: 10) {
                        feature("location.fill", "Stops near you", "Live departures around your location.")
                        feature("star.fill", "Favourites", "Pin the lines and stations you use daily.")
                        feature("figure.walk", "Make it or miss it", "See if you can still catch the next one.")
                    }

                    Button(action: onGetStarted) {
                        HStack {
                            Text("Get started")
                                .font(.headline)
                            Spacer()
                            Image(systemName: "arrow.right")
                        }
                        .foregroundStyle(NeoDesign.primaryActionText)
                        .padding(.horizontal, 20)
                        .frame(maxWidth: .infinity, minHeight: 56)
                        .background(NeoDesign.primaryAction, in: Capsule())
                    }
                    .buttonStyle(.plain)

                    Text("Data: Wiener Linien (Stadt Wien, CC BY).")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
                .padding(20)
            }
        }
        .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
    }

    private var hero: some View {
        VStack(alignment: .leading, spacing: 22) {
            HStack {
                Image(systemName: "tram.fill")
                    .font(.system(size: 24, weight: .semibold))
                    .frame(width: 52, height: 52)
                    .background(.white.opacity(0.18), in: Circle())
                Spacer()
                Image(systemName: "location.fill")
                    .font(.title2)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Traffic Vienna")
                    .font(.largeTitle.bold())
                    .tracking(-0.6)
                Text("Live departures, wherever you are.")
                    .font(.title3)
                    .foregroundStyle(.white.opacity(0.82))
            }
        }
        .foregroundStyle(.white)
        .padding(24)
        .frame(maxWidth: .infinity, minHeight: 260, alignment: .leading)
        .background(NeoDesign.heroGradient, in: RoundedRectangle(cornerRadius: 26))
        .shadow(color: NeoDesign.accentDark.opacity(0.14), radius: 16, y: 8)
    }

    private func feature(_ icon: String, _ title: LocalizedStringKey, _ subtitle: LocalizedStringKey) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.headline)
                .foregroundStyle(NeoDesign.accent)
                .frame(width: 44, height: 44)
                .background(NeoDesign.accent.opacity(0.12), in: Circle())
            VStack(alignment: .leading, spacing: 4) {
                Text(title).font(.subheadline.weight(.semibold))
                Text(subtitle).font(.subheadline).foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
        }
        .padding(16)
        .background(NeoDesign.surface, in: RoundedRectangle(cornerRadius: NeoDesign.cornerRadius))
        .overlay {
            RoundedRectangle(cornerRadius: NeoDesign.cornerRadius)
                .stroke(NeoDesign.hairline, lineWidth: 1)
        }
    }
}

#Preview {
    OnboardingView(onGetStarted: {})
}
