import SwiftUI

struct ThemePickerView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var theme: ThemeEngine
    
    var body: some View {
        NavigationStack {
            List {
                Section("Appearance") {
                    ForEach(ThemeEngine.ThemeMode.allCases) { mode in
                        Button {
                            theme.mode = mode
                        } label: {
                            HStack {
                                Text(mode.displayName)
                                    .foregroundStyle(theme.mode == mode ? .primary : .secondary)
                                Spacer()
                                if theme.mode == mode {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(.accentColor)
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
                                    .foregroundStyle(.primary)
                                Spacer()
                                if theme.preset == preset {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(.tint)
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
