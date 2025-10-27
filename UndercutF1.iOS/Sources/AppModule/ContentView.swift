import SwiftUI

struct ContentView: View {
    @ObservedObject var viewModel: SessionViewModel

    var body: some View {
        ZStack {
            BackgroundView()
            VStack(alignment: .leading, spacing: 20) {
                SessionHeaderView(summary: viewModel.summary)
                SessionTabPicker(selectedTab: $viewModel.selectedTab)
                TabContent(viewModel: viewModel)
            }
            .padding(24)
        }
    }
}

private struct BackgroundView: View {
    var body: some View {
        LinearGradient(
            gradient: Gradient(colors: [Color(hex: 0x090B0F), Color(hex: 0x13151C)]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }
}

private struct SessionHeaderView: View {
    let summary: SessionSummary

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(summary.name)
                        .font(.title2.bold())
                        .foregroundColor(.white)
                    Text("\(summary.sessionType) • \(summary.circuit)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    Label("Lap \(summary.lap)/\(summary.totalLaps)", systemImage: "flag.checkered")
                        .font(.subheadline.bold())
                        .foregroundColor(Color(hex: 0xFFE314))
                    Text(summary.trackStatus.uppercased())
                        .font(.caption.monospaced())
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Color(hex: 0xF0B429).opacity(0.15))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color(hex: 0xF0B429).opacity(0.7), lineWidth: 1)
                        )
                        .cornerRadius(8)
                }
            }

            Divider()
                .background(Color.white.opacity(0.2))

            HStack(spacing: 16) {
                Label(summary.weather, systemImage: "cloud.drizzle")
                Label("Delay 30s", systemImage: "timer")
                Label("Telemetry Live", systemImage: "antenna.radiowaves.left.and.right")
            }
            .font(.caption)
            .foregroundColor(.secondary)
        }
    }
}

private struct SessionTabPicker: View {
    @Binding var selectedTab: SessionTab

    var body: some View {
        Picker("Session Tab", selection: $selectedTab) {
            ForEach(SessionTab.allCases) { tab in
                Label(tab.rawValue, systemImage: tab.icon)
                    .tag(tab)
            }
        }
        .pickerStyle(.segmented)
        .colorMultiply(Color(hex: 0x22242C))
    }
}

private struct TabContent: View {
    @ObservedObject var viewModel: SessionViewModel

    var body: some View {
        Group {
            switch viewModel.selectedTab {
            case .timing:
                TimingTowerView(drivers: viewModel.timingDrivers, selectedDriver: viewModel.selectedDriver) { driver in
                    viewModel.select(driver: driver)
                }
            case .raceControl:
                RaceControlView(messages: viewModel.summary.controlMessages)
            case .strategy:
                StrategyView(strategies: viewModel.summary.driverStrategies)
            case .tracker:
                DriverTrackerView(snapshot: viewModel.summary.trackerSnapshot, selected: viewModel.selectedDriver)
            }
        }
        .transition(.opacity)
        .animation(.easeInOut(duration: 0.25), value: viewModel.selectedTab)
    }
}

#Preview("UndercutF1") {
    ContentView(viewModel: SessionViewModel())
        .preferredColorScheme(.dark)
}
