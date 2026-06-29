import SwiftUI

struct LineBadge: View {
    let line: String
    var size: Size = .regular

    enum Size { case small, regular }

    var body: some View {
        Text(line)
            .font(size == .small ? .caption.bold() : .subheadline.bold())
            .foregroundStyle(.white)
            .lineLimit(1)
            .fixedSize()
            .padding(.horizontal, size == .small ? 7 : 9)
            .padding(.vertical, size == .small ? 2 : 3)
            .background(LineColors.color(for: line), in: RoundedRectangle(cornerRadius: 6))
    }
}

#Preview {
    HStack {
        ForEach(["U1", "U2", "U3", "U4", "U6", "62", "D", "59A", "N25"], id: \.self) {
            LineBadge(line: $0)
        }
    }
    .padding()
}
