import SwiftUI

enum NeoDesign {
    // A single cool accent keeps secondary screens calm and financial-app-like.
    // The Home hero intentionally retains its richer violet gradient.
    static let accent = Color(hex: 0x246BFD)
    static let accentDark = Color(hex: 0x123A8C)
    static let favorite = Color(hex: 0xF5A623)
    static let background = Color(.systemGroupedBackground)
    static let surface = Color(.systemBackground)
    static let subtleSurface = Color(.secondarySystemGroupedBackground)
    static let hairline = Color.primary.opacity(0.07)
    static let cornerRadius: CGFloat = 22
}

struct NeoHeader: View {
    let eyebrow: LocalizedStringKey
    let title: LocalizedStringKey
    var subtitle: LocalizedStringKey?

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(eyebrow)
                .font(.caption2.bold())
                .tracking(1.4)
                .textCase(.uppercase)
                .foregroundStyle(NeoDesign.accent)
            Text(title)
                .font(.system(size: 34, weight: .bold, design: .rounded))
                .tracking(-0.6)
            if let subtitle {
                Text(subtitle).font(.subheadline).foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct NeoIcon: View {
    let systemName: String
    var tint = NeoDesign.accent

    var body: some View {
        Image(systemName: systemName)
            .font(.system(size: 18, weight: .semibold))
            .foregroundStyle(tint)
            .frame(width: 46, height: 46)
            .background(tint.opacity(0.10), in: Circle())
            .accessibilityHidden(true)
    }
}

struct StaleDataBanner: View {
    let message: String

    var body: some View {
        Label {
            VStack(alignment: .leading, spacing: 2) {
                Text("Showing saved data").font(.subheadline.bold())
                Text(message).font(.caption).foregroundStyle(.secondary)
            }
        } icon: {
            Image(systemName: "wifi.slash")
                .foregroundStyle(.orange)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(.orange.opacity(0.12), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .accessibilityElement(children: .combine)
    }
}

extension View {
    func neoCard(padding: CGFloat = 18) -> some View {
        self
            .padding(padding)
            .background {
                RoundedRectangle(cornerRadius: NeoDesign.cornerRadius, style: .continuous)
                    .fill(NeoDesign.surface)
                    .overlay {
                        RoundedRectangle(cornerRadius: NeoDesign.cornerRadius, style: .continuous)
                            .stroke(NeoDesign.hairline, lineWidth: 1)
                    }
            }
            .shadow(color: .black.opacity(0.035), radius: 10, y: 4)
    }

    func neoScreen() -> some View {
        self.background(NeoDesign.background.ignoresSafeArea())
    }
}
