import SwiftUI

struct RaceControlView: View {
    let messages: [RaceControlMessage]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Label("Race Control", systemImage: "megaphone")
                    .font(.headline)
                    .foregroundColor(.white)
                Spacer()
                Text("Latest \(messages.first?.timestamp ?? "Lap 0")")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(messages) { message in
                        RaceControlCard(message: message)
                    }
                }
                .padding(.vertical, 8)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color(hex: 0x14171F))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
    }
}

private struct RaceControlCard: View {
    let message: RaceControlMessage

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(message.timestamp)
                    .font(.caption.monospaced())
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.white.opacity(0.06))
                    )
                Spacer()
                Text(message.category.rawValue)
                    .font(.caption.bold())
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(message.category.color.opacity(0.15))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(message.category.color.opacity(0.4), lineWidth: 1)
                    )
            }
            Text(message.message)
                .font(.body.weight(.medium))
                .foregroundColor(.white)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(hex: 0x1A1E27))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.white.opacity(0.05), lineWidth: 1)
        )
    }
}

#Preview("Race Control") {
    RaceControlView(messages: MockData.controlMessages)
        .padding()
        .background(Color.black)
        .previewLayout(.sizeThatFits)
}
