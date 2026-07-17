import SwiftUI

struct ThemePickerView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var theme: ThemeEngine
    
    var body: some View {
        NavigationStack {
            List {
                Section("Appearance") {
                    ForEach(ThemeEngine.ThemeMode.allCases) { mode in
                        let isSelected = theme.mode == mode

                        Button {
                            theme.mode = mode
                        } label: {
                            HStack {
                                Text(mode.displayName)
                                    .foregroundStyle(isSelected ? Color.primary : Color.secondary)
                                Spacer()
                                if isSelected {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(Color.accentColor)
                                }
                            }
                            .contentShape(Rectangle())
                        }
                        .accessibilityLabel(Text("Select \(mode.displayName) appearance"))
                    }
                }
                
                Section("Accent colour") {
                    ForEach(ThemePreset.allCases) { preset in
                        Button {
                            theme.preset = preset
                        } label: {
                            HStack {
                                Circle()
                                    .fill(preset.accentColor)
                                    .frame(width: 22, height: 22)
                                Text(preset.displayName)
                                    .foregroundStyle(Color.primary)
                                Spacer()
                                if theme.preset == preset {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(Color.accentColor)
                                }
                            }
                        }
                        .accessibilityLabel(Text("Select \(preset.displayName) accent colour"))
                    }
                }
            }
            .navigationTitle("Appearance")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

#Preview {
    ThemePickerView()
        .environmentObject(ThemeEngine())
}

#Preview("System mode preview") {
    ThemePickerView()
        .environmentObject(ThemeEngine())
        .environment(\.colorScheme, .light)
}

#Preview("Light mode preview") {
    let engine = ThemeEngine()
    engine.mode = .light
    return ThemePickerView()
        .environmentObject(engine)
        .environment(\.colorScheme, .light)
}

#Preview("Dark mode preview") {
    let engine = ThemeEngine()
    engine.mode = .dark
    return ThemePickerView()
        .environmentObject(engine)
        .environment(\.colorScheme, .dark)
}
