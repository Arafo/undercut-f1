import SwiftUI

struct DriverTrackerView: View {
    let snapshot: TrackerSnapshot
    let selected: Driver?

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Label("Driver Tracker", systemImage: "map")
                    .font(.headline)
                    .foregroundColor(.white)
                Spacer()
                Text(snapshot.layoutName)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color.white.opacity(0.05))
                    .clipShape(Capsule())
            }

            GeometryReader { proxy in
                ZStack {
                    TrackOutline()
                        .stroke(Color(hex: 0x1F2633), lineWidth: 3)
                        .shadow(color: Color.black.opacity(0.6), radius: 12, x: 0, y: 12)
                        .padding(24)

                    ForEach(snapshot.drivers) { driver in
                        DriverMarker(driver: driver.driver, highlighted: driver.highlighted || driver.driver.id == selected?.id)
                            .position(position(for: driver.progress, in: proxy.size))
                            .animation(.easeInOut(duration: 0.3), value: driver.highlighted)
                    }
                }
                .background(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(Color(hex: 0x11151D))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(Color.white.opacity(0.05), lineWidth: 1)
                )
            }
            .frame(height: 320)

            if let selected {
                RelativeGapsView(selected: selected, drivers: snapshot.drivers.map { $0.driver })
            }
        }
    }

    private func position(for progress: CGFloat, in size: CGSize) -> CGPoint {
        let width = size.width - 80
        let height = size.height - 80
        let angle = progress * .pi * 2
        let x = (cos(angle) * (width / 2)) + (size.width / 2)
        let y = (sin(angle) * (height / 2)) + (size.height / 2)
        return CGPoint(x: x, y: y)
    }
}

private struct TrackOutline: Shape {
    func path(in rect: CGRect) -> Path {
        let insetRect = rect.insetBy(dx: 30, dy: 40)
        return Path { path in
            path.move(to: CGPoint(x: insetRect.midX, y: insetRect.minY))
            path.addQuadCurve(to: CGPoint(x: insetRect.maxX, y: insetRect.midY), control: CGPoint(x: insetRect.maxX, y: insetRect.minY))
            path.addCurve(
                to: CGPoint(x: insetRect.midX, y: insetRect.maxY),
                control1: CGPoint(x: insetRect.maxX + 40, y: insetRect.maxY - 80),
                control2: CGPoint(x: insetRect.midX + 20, y: insetRect.maxY + 20)
            )
            path.addCurve(
                to: CGPoint(x: insetRect.minX, y: insetRect.midY),
                control1: CGPoint(x: insetRect.midX - 80, y: insetRect.maxY - 20),
                control2: CGPoint(x: insetRect.minX - 40, y: insetRect.maxY - 120)
            )
            path.addQuadCurve(to: CGPoint(x: insetRect.midX, y: insetRect.minY), control: CGPoint(x: insetRect.minX, y: insetRect.minY))
            path.closeSubpath()
        }
    }
}

private struct DriverMarker: View {
    let driver: Driver
    let highlighted: Bool

    var body: some View {
        VStack(spacing: 4) {
            Text(driver.code)
                .font(.caption2.bold())
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(highlighted ? driver.teamColor.opacity(0.9) : Color.white.opacity(0.1))
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .stroke(highlighted ? Color.white.opacity(0.8) : Color.white.opacity(0.2), lineWidth: highlighted ? 1.5 : 1)
                )
            Circle()
                .fill(driver.teamColor)
                .frame(width: highlighted ? 16 : 12, height: highlighted ? 16 : 12)
                .shadow(color: driver.teamColor.opacity(0.6), radius: highlighted ? 10 : 4)
        }
    }
}

private struct RelativeGapsView: View {
    let selected: Driver
    let drivers: [Driver]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Relative gaps to \(selected.code)")
                .font(.subheadline.weight(.semibold))
                .foregroundColor(.white)

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 120), spacing: 12)], spacing: 12) {
                ForEach(drivers) { driver in
                    RelativeGapCard(driver: driver, selected: selected, totalDrivers: drivers.count)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color(hex: 0x141821))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.white.opacity(0.05), lineWidth: 1)
        )
    }
}

private struct RelativeGapCard: View {
    let driver: Driver
    let selected: Driver
    let totalDrivers: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(driver.code)
                    .font(.headline)
                    .foregroundColor(.white)
                Spacer()
                Text(driver.relativeGap)
                    .font(.caption.monospaced())
                    .foregroundColor(.secondary)
            }
            Text(driver.name)
                .font(.caption)
                .foregroundColor(.secondary)
            ProgressView(value: progress)
                .progressViewStyle(.linear)
                .tint(driver.teamColor)
                .background(Color.white.opacity(0.08), in: Capsule())
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color(hex: 0x191D26))
        )
    }

    private var progress: Double {
        guard driver.id != selected.id else { return 1.0 }
        let spacing = Double(abs(driver.position - selected.position))
        let divisor = Double(max(1, totalDrivers - 1))
        return max(0.1, 1 - (spacing / divisor))
    }
}

#Preview("Tracker") {
    DriverTrackerView(snapshot: MockData.trackerSnapshot, selected: MockData.drivers.first)
        .padding()
        .background(Color.black)
}
