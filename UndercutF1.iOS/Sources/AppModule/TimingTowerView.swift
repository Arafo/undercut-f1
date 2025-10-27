import SwiftUI

struct TimingTowerView: View {
    let drivers: [Driver]
    let selectedDriver: Driver?
    var onSelect: (Driver) -> Void

    var body: some View {
        VStack(spacing: 16) {
            TimingTowerHeader(selectedDriver: selectedDriver)
            ScrollView {
                LazyVStack(spacing: 8) {
                    ForEach(drivers) { driver in
                        DriverRowView(driver: driver, isSelected: driver.id == selectedDriver?.id)
                            .onTapGesture {
                                onSelect(driver)
                            }
                    }
                }
                .padding(.vertical, 4)
            }
        }
        .padding()
        .background(TowerBackground())
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
    }
}

private struct TowerBackground: View {
    var body: some View {
        LinearGradient(
            gradient: Gradient(colors: [Color(hex: 0x171A23), Color(hex: 0x10121A)]),
            startPoint: .top,
            endPoint: .bottom
        )
    }
}

private struct TimingTowerHeader: View {
    let selectedDriver: Driver?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Timing Tower", systemImage: "list.number")
                    .font(.headline)
                    .foregroundColor(.white)
                Spacer()
                if let driver = selectedDriver {
                    Text("Relative to \(driver.code)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            HStack {
                Text("POS")
                Text("DRIVER")
                Spacer()
                Text("LAP")
                Text("INT")
                Text("GAP")
            }
            .font(.caption.monospaced())
            .foregroundColor(.secondary)
        }
    }
}

private struct DriverRowView: View {
    let driver: Driver
    let isSelected: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline, spacing: 12) {
                Text("\(driver.position)")
                    .font(.system(.footnote, design: .monospaced).bold())
                    .frame(width: 32)
                    .foregroundColor(.white)
                    .padding(.vertical, 6)
                    .background(positionBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 12) {
                        Text(driver.code)
                            .font(.system(.title3, design: .rounded).bold())
                            .foregroundColor(.white)
                        Text(driver.name)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        if driver.positionChange != 0 {
                            Label("\(driver.positionChange > 0 ? "+" : "")\(driver.positionChange)", systemImage: driver.positionChange > 0 ? "arrowtriangle.up.fill" : "arrowtriangle.down.fill")
                                .font(.caption2)
                                .foregroundColor(driver.positionChange > 0 ? Color(hex: 0x58D68D) : Color(hex: 0xE55353))
                        }
                        Spacer()
                        TyreBadge(compound: driver.tyre, age: driver.tyreAge)
                    }

                    HStack(spacing: 16) {
                        SectorTimesView(sectors: driver.sectorTimes)
                        Spacer()
                        VStack(alignment: .leading, spacing: 2) {
                            TimingDetail(title: "Last", timing: driver.lastLap)
                            TimingDetail(title: "Best", timing: driver.bestLap)
                        }
                        VStack(alignment: .trailing, spacing: 2) {
                            TimingMetric(label: "INT", value: driver.interval)
                            TimingMetric(label: "GAP", value: driver.gapToLeader)
                            TimingMetric(label: "REL", value: driver.relativeGap)
                        }
                    }
                    .font(.caption.monospaced())
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(rowBackground)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
    }

    private var rowBackground: some View {
        RoundedRectangle(cornerRadius: 12, style: .continuous)
            .fill(
                (isSelected ? Color(hex: 0x233047) : Color(hex: 0x161922))
                    .opacity(isSelected ? 0.9 : 0.7)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(Color.white.opacity(isSelected ? 0.2 : 0.05), lineWidth: 1)
            )
    }

    private var positionBackground: some ShapeStyle {
        LinearGradient(
            colors: [driver.teamColor.opacity(0.9), driver.teamColor.opacity(0.3)],
            startPoint: .top,
            endPoint: .bottom
        )
    }
}

private struct SectorTimesView: View {
    let sectors: [SectorTiming]

    var body: some View {
        HStack(spacing: 12) {
            ForEach(sectors) { sector in
                VStack(spacing: 2) {
                    Text(sector.id.label)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Text(sector.time)
                        .foregroundColor(color(for: sector))
                }
            }
        }
    }

    private func color(for sector: SectorTiming) -> Color {
        if sector.isOverallBest { return Color(hex: 0xBB86FC) }
        if sector.isPersonalBest { return Color(hex: 0x58D68D) }
        return .white
    }
}

private struct TimingDetail: View {
    let title: String
    let timing: LapTiming

    var body: some View {
        HStack(spacing: 6) {
            Text(title)
                .foregroundColor(.secondary)
            Text(timing.time)
                .foregroundColor(color)
        }
    }

    private var color: Color {
        if timing.isOverallBest { return Color(hex: 0xBB86FC) }
        if timing.isPersonalBest { return Color(hex: 0x58D68D) }
        return .white
    }
}

private struct TimingMetric: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(.secondary)
            Text(value)
                .foregroundColor(.white)
        }
    }
}

private struct TyreBadge: View {
    let compound: TyreCompound
    let age: Int

    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .strokeBorder(Color.white.opacity(0.3), lineWidth: 1)
                .background(Circle().fill(compound.color))
                .frame(width: 22, height: 22)
                .overlay(
                    Text(compound.rawValue)
                        .font(.caption2.bold())
                        .foregroundColor(compound == .hard ? .black : .white)
                )
            Text("\(age)L")
                .font(.caption.bold())
                .foregroundColor(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.white.opacity(0.08))
                .clipShape(Capsule())
        }
    }
}

#Preview("Timing Tower") {
    TimingTowerView(drivers: MockData.drivers, selectedDriver: MockData.drivers.first) { _ in }
        .padding()
        .background(Color.black)
        .previewLayout(.sizeThatFits)
}
