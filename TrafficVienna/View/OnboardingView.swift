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
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(.appAccent)
                    .frame(width: 80, height: 80)
                    .overlay(
                        Image(systemName: "tram.fill")
                            .font(.system(size: 36, weight: .semibold))
                            .foregroundStyle(.white)
                    )

                VStack(spacing: 4) {
                    Text("Traffic Vienna")
                        .font(.title.weight(.semibold))
                    Text("Live departures, wherever you are.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
            }

            Spacer(minLength: 32)

            VStack(alignment: .leading, spacing: 20) {
                feature("location.fill", "Stops near you", "Live departures around your location.")
                feature("star.fill", "Favourites", "Pin the lines and stations you use daily.")
                feature("figure.walk", "Make it or miss it", "See if you can still catch the next one.")
            }
            .padding(.horizontal, 8)

            Spacer()

            VStack(spacing: 12) {
                Button(action: onGetStarted) {
                    Text("Get started")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)

                Text("Data: Wiener Linien (Stadt Wien, CC BY).")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(32)
    }

    private func feature(_ icon: String, _ title: String, _ subtitle: String) -> some View {
        HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(.appAccent)
                    .frame(width: 32)
            VStack(alignment: .leading, spacing: 4) {
                Text(title).font(.subheadline.weight(.semibold))
                Text(subtitle).font(.subheadline).foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
        }
    }
}

#Preview {
    OnboardingView(onGetStarted: {})
}
