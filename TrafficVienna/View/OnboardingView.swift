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
        VStack(spacing: 0) {
            Spacer(minLength: 24)

            VStack(spacing: 16) {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(Color(hex: 0xE20917))
                    .frame(width: 88, height: 88)
                    .overlay(
                        Image(systemName: "tram.fill")
                            .font(.system(size: 42, weight: .semibold))
                            .foregroundStyle(.white)
                    )

                VStack(spacing: 6) {
                    Text("Traffic Vienna")
                        .font(.largeTitle.weight(.bold))
                    Text("Live Wiener Linien departures, wherever you are.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
            }

            Spacer(minLength: 32)

            VStack(alignment: .leading, spacing: 22) {
                feature("location.fill", "Stops near you", "Live departures around your location.")
                feature("star.fill", "Favourites", "Pin the lines and stations you use daily.")
                feature("figure.walk", "Make it or miss it", "See if you can still catch the next one.")
            }
            .padding(.horizontal, 8)

            Spacer()

            VStack(spacing: 10) {
                Button(action: onGetStarted) {
                    Text("Get started")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .tint(Color(hex: 0xE20917))

                Text("Data: Wiener Linien (Stadt Wien, CC BY).")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(28)
    }

    private func feature(_ icon: String, _ title: String, _ subtitle: String) -> some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(Color(hex: 0xE20917))
                .frame(width: 36)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.headline)
                Text(subtitle).font(.subheadline).foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
        }
    }
}

#Preview {
    OnboardingView(onGetStarted: {})
}
