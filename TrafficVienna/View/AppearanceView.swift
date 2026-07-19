import SwiftUI

struct AppearanceView: View {
    @EnvironmentObject private var themeManager: ThemeManager
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    private var columns: [GridItem] {
        let count = dynamicTypeSize.isAccessibilitySize ? 1 : 2
        return Array(repeating: GridItem(.flexible(), spacing: 12), count: count)
    }

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(ThemePreset.allCases) { preset in
                    themeCard(preset)
                }
            }
            .padding(18)
        }
        .neoScreen()
        .navigationTitle("Appearance")
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .top) {
            Text("Choose how Traffic Vienna looks on this device.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 18)
                .padding(.vertical, 10)
                .background(.bar)
        }
        .sensoryFeedback(.selection, trigger: themeManager.preset)
    }

    private func themeCard(_ preset: ThemePreset) -> some View {
        let isSelected = themeManager.preset == preset
        return Button {
            themeManager.preset = preset
        } label: {
            VStack(alignment: .leading, spacing: 12) {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [preset.accentColor, preset.accentColor.opacity(0.45)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(height: 86)
                    .overlay(alignment: .topTrailing) {
                        if isSelected {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.title2)
                                .foregroundStyle(.white)
                                .padding(10)
                        }
                    }

                HStack {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(LocalizedStringKey(preset.displayName))
                            .font(.headline)
                            .foregroundStyle(.primary)
                        Text(colorMode(for: preset))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer(minLength: 4)
                }
            }
            .padding(12)
            .background(
                Color(.secondarySystemGroupedBackground),
                in: RoundedRectangle(cornerRadius: 22, style: .continuous)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(isSelected ? preset.accentColor : .clear, lineWidth: 2)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(LocalizedStringKey(preset.displayName)))
        .accessibilityValue(isSelected ? "Selected" : "Not selected")
        .accessibilityIdentifier("appearance.theme.\(preset.rawValue)")
    }

    private func colorMode(for preset: ThemePreset) -> LocalizedStringKey {
        switch preset.colorScheme {
        case .dark: "Dark"
        case .light: "Light"
        case nil: "System"
        @unknown default: "System"
        }
    }
}

#Preview {
    NavigationStack { AppearanceView() }
        .environmentObject(ThemeManager())
}
