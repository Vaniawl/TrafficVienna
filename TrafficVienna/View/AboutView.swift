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
                    VStack(spacing: Spacing.md) {
                        RoundedRectangle(cornerRadius: CornerRadius.lg)
                            .fill(DesignColor.brandGradient)
                            .frame(width: 72, height: 72)
                            .shadow(
                                color: Shadow.lg.color,
                                radius: Shadow.lg.radius,
                                x: Shadow.lg.x,
                                y: Shadow.lg.y
                            )
                            .overlay {
                                Image(systemName: "tram.fill")
                                    .font(.title)
                                    .bold()
                                    .foregroundStyle(.white)
                            }
                        Text("Traffic Vienna")
                            .font(.title2)
                            .bold()
                        Text("Version \(version)")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Spacing.sm)
                    .listRowBackground(Color.clear)
                }

                Section("Data") {
                    LabeledContent("Source", value: "Wiener Linien")
                    LabeledContent("Provider", value: "Stadt Wien")
                    LabeledContent("Licence", value: "CC BY 4.0")
                    if let dataSourceURL = URL(string: "https://www.data.gv.at") {
                        Link(destination: dataSourceURL) {
                            Label("data.gv.at", systemImage: "safari")
                        }
                    }
                }

                Section("Privacy") {
                    NavigationLink("Privacy policy") {
                        PrivacyPolicyView()
                    }

                    if let privacyURL = URL(
                        string: "https://github.com/Vaniawl/TrafficVienna/blob/main/PRIVACY.md"
                    ) {
                        Link(destination: privacyURL) {
                            Label("Online privacy policy", systemImage: "safari")
                        }
                    }
                }

                Section {
                    Text("Departure times are provided live by Wiener Linien and may differ from actual service.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .background(DesignColor.background)
            .navigationTitle("About")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .tint(DesignColor.accentText)
        }
    }
}

#Preview {
    AboutView()
}
