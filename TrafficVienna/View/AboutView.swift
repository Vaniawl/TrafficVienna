//
//  AboutView.swift
//  TrafficVienna
//
//  App info + data attribution (Wiener Linien open data is CC BY, so the
//  source must be credited).
//

import SwiftUI

struct AboutView: View {
    @Environment(\.dismiss) private var dismiss

    private var version: String {
        let v = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let b = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(v) (\(b))"
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    VStack(spacing: 12) {
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(NeoDesign.heroGradient)
                            .frame(width: 72, height: 72)
                            .overlay(
                                Image(systemName: "tram.fill")
                                    .font(.system(size: 34, weight: .semibold))
                                    .foregroundStyle(.white)
                            )
                        Text("Traffic Vienna").font(.title2.weight(.semibold))
                        Text("Version \(version)")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .accessibilityIdentifier("about.version")
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .listRowBackground(Color.clear)
                }

                Section("Data") {
                    LabeledContent("Source", value: "Wiener Linien")
                        .accessibilityIdentifier("about.source")
                    LabeledContent("Provider", value: "Stadt Wien")
                    LabeledContent("Licence", value: "CC BY 4.0")
                    Link(destination: URL(string: "https://www.data.gv.at")!) {
                        Label("data.gv.at", systemImage: "safari")
                    }
                }

                Section {
                    Text("Departure times are provided live by Wiener Linien and may differ from actual service.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("About")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .accessibilityIdentifier("about.done")
                }
            }
        }
    }
}

#Preview {
    AboutView()
}
