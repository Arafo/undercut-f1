import SwiftUI

struct StrategyView: View {
    let strategies: [DriverStrategy]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("Tyre Strategy", systemImage: "chart.bar.doc.horizontal")
                .font(.headline)
                .foregroundColor(.white)

            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(strategies) { strategy in
                        DriverStrategyRow(strategy: strategy)
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

private struct DriverStrategyRow: View {
    let strategy: DriverStrategy

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .center, spacing: 12) {
                Text(strategy.driver.code)
                    .font(.title3.bold())
                    .foregroundColor(.white)
                    .frame(width: 54)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(strategy.driver.teamColor.opacity(0.25))
                    )
                VStack(alignment: .leading, spacing: 4) {
                    Text(strategy.driver.name)
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.white)
                    Text("Last stop: Lap \(strategy.driver.tyreAge - 1) • \(strategy.driver.relativeGap) gap")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
                Text("\(strategy.driver.interval) to ahead")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            StrategyTimeline(stints: strategy.stints)
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

private struct StrategyTimeline: View {
    let stints: [Stint]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .center, spacing: 12) {
                ForEach(stints) { stint in
                    VStack(alignment: .leading, spacing: 6) {
                        Text("\(stint.laps) laps")
                            .font(.caption.bold())
                            .foregroundColor(.white)
                        RoundedRectangle(cornerRadius: 10)
                            .fill(stint.tyre.color.opacity(0.85))
                            .frame(height: 12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
                            )
                        Label("Pit \(stint.pitStopTime)s", systemImage: "clock")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .padding(.vertical, 4)
        }
    }
}

#Preview("Strategy") {
    StrategyView(strategies: MockData.strategies)
        .padding()
        .background(Color.black)
        .previewLayout(.sizeThatFits)
}
