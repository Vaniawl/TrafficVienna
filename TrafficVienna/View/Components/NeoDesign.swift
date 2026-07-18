import SwiftUI

enum NeoDesign {
    static let accent = Color(hex: 0x635BFF)
    static let accentDark = Color(hex: 0x211A72)
    static let background = Color(.systemGroupedBackground)
    static let surface = Color(.secondarySystemGroupedBackground)
    static let cornerRadius: CGFloat = 24
}

struct NeoHeader: View {
    let eyebrow: String
    let title: String
    var subtitle: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(eyebrow.uppercased())
                .font(.caption2.bold())
                .tracking(1.4)
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
            .background(tint.opacity(0.12), in: Circle())
    }
}

extension View {
    func neoCard(padding: CGFloat = 18) -> some View {
        self
            .padding(padding)
            .background(NeoDesign.surface, in: RoundedRectangle(cornerRadius: NeoDesign.cornerRadius, style: .continuous))
    }

    func neoScreen() -> some View {
        self.background(NeoDesign.background.ignoresSafeArea())
    }
}
