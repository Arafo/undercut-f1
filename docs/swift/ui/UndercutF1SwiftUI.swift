import SwiftUI

// MARK: - Screen definitions

/// Mirrors the Spectre.Console screen navigation used by the C# console app.
public enum ConsoleScreen: String, CaseIterable, Identifiable {
    case main = "Main"
    case manageSession = "Manage Session"
    case startSimulatedSession = "Start Simulated Session"
    case logs = "Logs"
    case timingTower = "Timing Tower"
    case timingHistory = "Timing History"
    case raceControl = "Race Control"
    case driverTracker = "Driver Tracker"
    case championshipStats = "Championship Stats"
    case teamRadio = "Team Radio"
    case tyreStints = "Tyre Stints"
    case debugData = "Debug Data"
    case downloadTranscriptionModel = "Download Transcription Model"
    case info = "Info"
    case selectDriver = "Select Driver"

    public var id: String { rawValue }

    var systemImage: String {
        switch self {
        case .main: return "house"
        case .manageSession: return "play.rectangle"
        case .startSimulatedSession: return "clock.arrow.circlepath"
        case .logs: return "doc.text.magnifyingglass"
        case .timingTower: return "flag.checkered"
        case .timingHistory: return "chart.line.uptrend.xyaxis"
        case .raceControl: return "exclamationmark.triangle"
        case .driverTracker: return "map"
        case .championshipStats: return "trophy"
        case .teamRadio: return "waveform"
        case .tyreStints: return "circle.grid.cross"
        case .debugData: return "wrench.adjustable"
        case .downloadTranscriptionModel: return "tray.and.arrow.down"
        case .info: return "info.circle"
        case .selectDriver: return "person.2"
        }
    }
}

// MARK: - Root app state

/// Shared state that backs the SwiftUI interface.
public final class UndercutF1AppState: ObservableObject {
    @Published public var selectedScreen: ConsoleScreen = .main

    @Published public var timingData: TimingDataPoint
    @Published public var lapCount: LapCountDataPoint
    @Published public var sessionInfo: SessionInfoDataPoint
    @Published public var driverList: DriverListDataPoint
    @Published public var tyreData: TimingAppDataPoint
    @Published public var raceControlMessages: RaceControlMessageDataPoint
    @Published public var positionData: PositionDataPoint

    public init(samples: LiveTimingSampleData = .shared) {
        timingData = samples.timingData
        lapCount = samples.lapCount
        sessionInfo = samples.sessionInfo
        driverList = samples.driverList
        tyreData = samples.tyreData
        raceControlMessages = samples.raceControl
        positionData = samples.positionData
    }

    /// Convenience rows used by the timing tower and session stats.
    public var towerRows: [TimingTowerRow] {
        timingData.lines.compactMap { key, driver -> TimingTowerRow? in
            guard let metadata = driverList.drivers[key] else {
                return nil
            }

            return TimingTowerRow(
                id: key,
                position: driver.position ?? "-",
                racingNumber: metadata.racingNumber ?? key,
                driverName: metadata.broadcastName ?? metadata.fullName ?? "Unknown",
                gapToLeader: driver.gapToLeader ?? "-",
                interval: driver.intervalToPositionAhead?.value ?? "-",
                lastLap: driver.lastLapTime?.value ?? "-",
                bestLap: driver.bestLapTime.value ?? "-",
                teamColour: Color(hex: metadata.teamColour)
            )
        }
        .sorted { lhs, rhs in
            let left = Int(lhs.position) ?? Int.max
            let right = Int(rhs.position) ?? Int.max
            return left < right
        }
    }

    public var tyreRows: [TyreStintRow] {
        tyreData.lines.compactMap { entry in
            guard let driver = driverList.drivers[entry.key] else {
                return nil
            }
            let stints = entry.value.stints.keys.sorted().compactMap { stintKey -> TyreStintRow.Stint? in
                guard let stint = entry.value.stints[stintKey] else { return nil }
                return .init(
                    compound: stint.compound ?? "-",
                    totalLaps: stint.totalLaps ?? 0,
                    startLap: stint.startLaps ?? 0,
                    isNew: stint.isNew ?? false
                )
            }
            return TyreStintRow(
                id: entry.key,
                driverName: driver.broadcastName ?? driver.fullName ?? "Unknown",
                racingNumber: driver.racingNumber ?? entry.key,
                stints: stints
            )
        }
        .sorted { lhs, rhs in
            lhs.racingNumber < rhs.racingNumber
        }
    }

    public var orderedRaceMessages: [RaceControlMessageDataPoint.Message] {
        raceControlMessages.messages.values.sorted { $0.utc > $1.utc }
    }

    public var latestPositions: PositionDataPoint.PositionData? {
        positionData.position.sorted(by: { $0.timestamp > $1.timestamp }).first
    }
}

// MARK: - Root container view

/// Entry point replicating the console navigation using a split view.
public struct UndercutF1RootView: View {
    @StateObject private var appState = UndercutF1AppState()

    public init() {}

    public var body: some View {
        NavigationSplitView {
            List(selection: $appState.selectedScreen) {
                Section("Screens") {
                    ForEach(ConsoleScreen.allCases) { screen in
                        Label(screen.rawValue, systemImage: screen.systemImage)
                            .tag(screen)
                    }
                }
            }
            .navigationTitle("Undercut F1")
        } detail: {
            ScreenDetailView()
                .environmentObject(appState)
        }
    }
}

// MARK: - Detail routing

struct ScreenDetailView: View {
    @EnvironmentObject private var appState: UndercutF1AppState

    var body: some View {
        switch appState.selectedScreen {
        case .main:
            MainScreenView()
        case .manageSession:
            ManageSessionView()
        case .startSimulatedSession:
            StartSimulatedSessionView()
        case .logs:
            LogView()
        case .timingTower:
            TimingTowerView(rows: appState.towerRows, lapCount: appState.lapCount)
        case .timingHistory:
            TimingHistoryView(rows: appState.towerRows)
        case .raceControl:
            RaceControlView(messages: appState.orderedRaceMessages)
        case .driverTracker:
            DriverTrackerView(
                session: appState.sessionInfo,
                latestPosition: appState.latestPositions
            )
        case .championshipStats:
            ChampionshipStatsView()
        case .teamRadio:
            TeamRadioView()
        case .tyreStints:
            TyreStintView(rows: appState.tyreRows)
        case .debugData:
            DebugDataView(sessionInfo: appState.sessionInfo, timingData: appState.timingData)
        case .downloadTranscriptionModel:
            DownloadTranscriptionModelView()
        case .info:
            InfoView(sessionInfo: appState.sessionInfo)
        case .selectDriver:
            SelectDriverView(drivers: appState.towerRows)
        }
    }
}

// MARK: - Main screen

struct MainScreenView: View {
    @EnvironmentObject private var appState: UndercutF1AppState

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                VStack(spacing: 12) {
                    Text("UNDERCUT F1")
                        .font(.system(.largeTitle, design: .monospaced))
                        .fontWeight(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(.thinMaterial)
                        .cornerRadius(12)

                    Text("Welcome to Undercut F1. Start a session to see live timing data streamed from the official Formula 1 SignalR feed. The SwiftUI interface mirrors the console app's navigation and screen layout.")
                        .font(.title3)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Quick start")
                        .font(.title2)
                        .bold()
                    InstructionRow(icon: "keyboard", text: "Press S then L to start a live session.")
                    InstructionRow(icon: "clock.arrow.circlepath", text: "Press S then F to replay a stored session.")
                    InstructionRow(icon: "rectangle.3.offgrid", text: "Use T to jump to the Timing Tower, then ◄/► to cycle pages.")
                    InstructionRow(icon: "speedometer", text: "Use N/M/,/. to adjust stream delay and ▲/▼ to move the cursor.")
                    InstructionRow(icon: "arrow.down.doc", text: "Run `undercutf1 import` to download historical sessions.")
                }

                SessionSummaryView(lapCount: appState.lapCount, sessionInfo: appState.sessionInfo)

                Spacer()
            }
            .padding()
            .frame(maxWidth: 960)
            .frame(maxWidth: .infinity)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Main")
    }
}

struct InstructionRow: View {
    var icon: String
    var text: String

    var body: some View {
        Label(text, systemImage: icon)
            .font(.body)
    }
}

struct SessionSummaryView: View {
    var lapCount: LapCountDataPoint
    var sessionInfo: SessionInfoDataPoint

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Current session")
                .font(.title2)
                .bold()

            HStack(alignment: .top, spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Label(sessionInfo.name ?? "Unknown Session", systemImage: "calendar")
                    Label(sessionInfo.meeting?.circuit?.shortName ?? "Unknown Circuit", systemImage: "flag")
                    if let start = sessionInfo.startDate, let end = sessionInfo.endDate {
                        Label("\(format(date: start)) – \(format(date: end))", systemImage: "clock")
                    }
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 8) {
                    Text("Lap \(lapCount.currentLap ?? 0) / \(lapCount.totalLaps ?? 0)")
                        .font(.title)
                        .bold()
                    Text(sessionInfo.type ?? "")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(12)
    }

    private func format(date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Timing tower

struct TimingTowerRow: Identifiable {
    var id: String
    var position: String
    var racingNumber: String
    var driverName: String
    var gapToLeader: String
    var interval: String
    var lastLap: String
    var bestLap: String
    var teamColour: Color?
}

struct TimingTowerView: View {
    var rows: [TimingTowerRow]
    var lapCount: LapCountDataPoint

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Timing Tower")
                        .font(.largeTitle)
                        .bold()
                    Text("Lap \(lapCount.currentLap ?? 0) / \(lapCount.totalLaps ?? 0)")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()

                VStack(spacing: 0) {
                    TimingTowerHeaderRow()
                        .padding(.horizontal)
                        .padding(.vertical, 4)
                        .background(Color(.secondarySystemBackground))

                    ForEach(rows) { row in
                        TimingTowerDataRow(row: row)
                            .padding(.horizontal)
                            .padding(.vertical, 6)
                        Divider()
                    }
                }
                .background(.ultraThinMaterial)
                .cornerRadius(16)
                .padding()
            }
        }
        .navigationTitle("Timing Tower")
    }
}

struct TimingTowerHeaderRow: View {
    var body: some View {
        HStack {
            Text("Pos").frame(width: 44, alignment: .leading)
            Text("No").frame(width: 44, alignment: .leading)
            Text("Driver").frame(maxWidth: .infinity, alignment: .leading)
            Text("Last Lap").frame(width: 100, alignment: .trailing)
            Text("Best Lap").frame(width: 100, alignment: .trailing)
            Text("Interval").frame(width: 80, alignment: .trailing)
            Text("Gap").frame(width: 80, alignment: .trailing)
        }
        .font(.caption.bold())
        .foregroundStyle(.secondary)
    }
}

struct TimingTowerDataRow: View {
    var row: TimingTowerRow

    var body: some View {
        HStack {
            Text(row.position)
                .frame(width: 44, alignment: .leading)
                .font(.body.monospacedDigit())
            Text(row.racingNumber)
                .frame(width: 44, alignment: .leading)
                .font(.body.monospacedDigit())
            HStack {
                Circle()
                    .fill(row.teamColour ?? .gray)
                    .frame(width: 8, height: 8)
                Text(row.driverName)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            Text(row.lastLap)
                .frame(width: 100, alignment: .trailing)
                .font(.body.monospacedDigit())
            Text(row.bestLap)
                .frame(width: 100, alignment: .trailing)
                .font(.body.monospacedDigit())
            Text(row.interval)
                .frame(width: 80, alignment: .trailing)
                .font(.body.monospacedDigit())
            Text(row.gapToLeader)
                .frame(width: 80, alignment: .trailing)
                .font(.body.monospacedDigit())
        }
    }
}

// MARK: - Timing history

struct TimingHistoryView: View {
    var rows: [TimingTowerRow]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Timing History")
                    .font(.largeTitle)
                    .bold()
                Text("Compare last lap and best lap performance across the grid.")
                    .font(.body)
                    .foregroundStyle(.secondary)

                ChartView(rows: rows)
                    .frame(height: 320)
                    .padding()
                    .background(.ultraThinMaterial)
                    .cornerRadius(16)
            }
            .padding()
        }
        .navigationTitle("Timing History")
    }
}

struct ChartView: View {
    var rows: [TimingTowerRow]

    var body: some View {
        GeometryReader { geo in
            let barWidth = geo.size.width / CGFloat(max(rows.count, 1))
            let maxGap = rows.compactMap { Double($0.gapToLeader.replacingOccurrences(of: ":", with: ".")) }.max() ?? 1

            ZStack(alignment: .bottomLeading) {
                ForEach(Array(rows.enumerated()), id: \.element.id) { index, row in
                    let heightRatio = (Double(row.interval.replacingOccurrences(of: ":", with: ".")) ?? 0) / maxGap
                    RoundedRectangle(cornerRadius: 6)
                        .fill(row.teamColour ?? .blue)
                        .frame(
                            width: max(barWidth - 12, 4),
                            height: max(CGFloat(heightRatio) * geo.size.height, 4)
                        )
                        .position(
                            x: barWidth * CGFloat(index) + barWidth / 2,
                            y: geo.size.height - max(CGFloat(heightRatio) * geo.size.height, 4) / 2
                        )
                        .overlay(
                            Text(row.racingNumber)
                                .font(.caption2)
                                .rotationEffect(.degrees(-90))
                                .offset(y: -20), alignment: .top
                        )
                }
            }
        }
    }
}

// MARK: - Race control

struct RaceControlView: View {
    var messages: [RaceControlMessageDataPoint.Message]

    var body: some View {
        List(messages, id: \.utc) { message in
            VStack(alignment: .leading, spacing: 4) {
                Text(message.message)
                    .font(.body)
                Text(format(date: message.utc))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.vertical, 4)
        }
        .navigationTitle("Race Control")
    }

    private func format(date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .medium
        return formatter.string(from: date)
    }
}

// MARK: - Driver tracker

struct DriverTrackerView: View {
    var session: SessionInfoDataPoint
    var latestPosition: PositionDataPoint.PositionData?

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Driver Tracker")
                .font(.largeTitle)
                .bold()
            Text("Live positions plotted on the circuit map derived from the SignalR feed.")
                .font(.body)
                .foregroundStyle(.secondary)

            TrackMapView(points: session.circuitPoints, positions: latestPosition)
                .frame(minHeight: 320)
                .background(Color(.secondarySystemBackground))
                .cornerRadius(16)
        }
        .padding()
        .navigationTitle("Driver Tracker")
    }
}

struct TrackMapView: View {
    var points: [SessionInfoDataPoint.CircuitPoint]
    var positions: PositionDataPoint.PositionData?

    var body: some View {
        GeometryReader { geo in
            ZStack {
                if points.count > 1 {
                    Path { path in
                        let normalized = normalize(points: points, in: geo.size)
                        path.addLines(normalized)
                        path.closeSubpath()
                    }
                    .stroke(Color.secondary, lineWidth: 3)
                }

                if let entries = positions?.entries {
                    ForEach(Array(entries.keys.sorted()), id: \.self) { key in
                        if let point = entries[key] {
                            let color = Color(hex: driverColour(for: key)) ?? .red
                            let normalized = normalize(position: point, points: points, size: geo.size)
                            VStack(spacing: 4) {
                                Circle()
                                    .fill(color)
                                    .frame(width: 12, height: 12)
                                Text(key)
                                    .font(.caption2)
                            }
                            .position(normalized)
                        }
                    }
                }
            }
        }
    }

    private func normalize(points: [SessionInfoDataPoint.CircuitPoint], in size: CGSize) -> [CGPoint] {
        let xs = points.map(\.x)
        let ys = points.map(\.y)
        guard let minX = xs.min(), let maxX = xs.max(), let minY = ys.min(), let maxY = ys.max() else {
            return []
        }

        let width = CGFloat(maxX - minX)
        let height = CGFloat(maxY - minY)

        return points.map { point in
            let x = (CGFloat(point.x - minX) / max(width, 1)) * (size.width - 32) + 16
            let y = (CGFloat(point.y - minY) / max(height, 1)) * (size.height - 32) + 16
            return CGPoint(x: x, y: y)
        }
    }

    private func normalize(position: PositionDataPoint.PositionData.Entry, points: [SessionInfoDataPoint.CircuitPoint], size: CGSize) -> CGPoint {
        let xs = points.map(\.x)
        let ys = points.map(\.y)
        guard let minX = xs.min(), let maxX = xs.max(), let minY = ys.min(), let maxY = ys.max() else {
            return .init(x: size.width / 2, y: size.height / 2)
        }

        let width = CGFloat(maxX - minX)
        let height = CGFloat(maxY - minY)

        let x = (CGFloat(position.x ?? minX) - CGFloat(minX)) / max(width, 1)
        let y = (CGFloat(position.y ?? minY) - CGFloat(minY)) / max(height, 1)

        return CGPoint(
            x: x * (size.width - 32) + 16,
            y: y * (size.height - 32) + 16
        )
    }

    private func driverColour(for key: String) -> String? {
        switch key {
        case "44": return "00D2BE"
        case "1": return "6CD3BF"
        case "55": return "ED1C24"
        default: return nil
        }
    }
}

// MARK: - Tyre stints

struct TyreStintRow: Identifiable {
    struct Stint: Identifiable {
        var id: UUID = UUID()
        var compound: String
        var totalLaps: Int
        var startLap: Int
        var isNew: Bool
    }

    var id: String
    var driverName: String
    var racingNumber: String
    var stints: [Stint]
}

struct TyreStintView: View {
    var rows: [TyreStintRow]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Tyre Stints")
                    .font(.largeTitle)
                    .bold()
                Text("Aggregated from TimingAppData feed.")
                    .font(.body)
                    .foregroundStyle(.secondary)

                LazyVStack(alignment: .leading, spacing: 12) {
                    ForEach(rows) { row in
                        VStack(alignment: .leading, spacing: 8) {
                            Text("#\(row.racingNumber) \(row.driverName)")
                                .font(.headline)
                            HStack(alignment: .center, spacing: 8) {
                                ForEach(row.stints) { stint in
                                    VStack {
                                        Text(stint.compound)
                                            .font(.caption)
                                            .padding(6)
                                            .background(stint.isNew ? Color.green.opacity(0.2) : Color.orange.opacity(0.2))
                                            .cornerRadius(6)
                                        Text("Laps: \(stint.totalLaps)")
                                            .font(.caption2)
                                        Text("Start: \(stint.startLap)")
                                            .font(.caption2)
                                    }
                                    .padding(8)
                                    .background(Color(.secondarySystemBackground))
                                    .cornerRadius(8)
                                }
                            }
                        }
                        .padding()
                        .background(.ultraThinMaterial)
                        .cornerRadius(12)
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Tyre Stints")
    }
}

// MARK: - Supplementary screens

struct ManageSessionView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Manage Session")
                .font(.largeTitle)
                .bold()
            Text("Start or stop live timing sessions, switch between saved recordings, and manage authentication tokens.")
                .font(.body)
            List {
                Section("Live session") {
                    Button("Start live timing") {}
                    Button("Stop session") {}
                }
                Section("Replays") {
                    Button("Load Imola 2024 Qualifying") {}
                    Button("Load Silverstone 2024 Race") {}
                }
            }
        }
        .padding()
        .navigationTitle("Manage Session")
    }
}

struct StartSimulatedSessionView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Start Simulated Session")
                .font(.largeTitle)
                .bold()
            Text("Use stored telemetry to replay a weekend exactly as it happened. Select a sample session below to begin.")
                .foregroundStyle(.secondary)
            List {
                ForEach(["2024 Imola Qualifying", "2024 Imola Race", "2024 Silverstone Race"], id: \.self) { session in
                    Button(session) {}
                }
            }
        }
        .padding()
        .navigationTitle("Simulated Session")
    }
}

struct LogView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Text("Logs")
                    .font(.largeTitle)
                    .bold()
                ForEach(sampleLogs, id: \.self) { line in
                    Text(line)
                        .font(.system(.body, design: .monospaced))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(4)
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(4)
                }
            }
            .padding()
        }
        .navigationTitle("Logs")
    }

    private var sampleLogs: [String] {
        [
            "[14:03:22] Connected to wss://livetiming.formula1.com/signalr",
            "[14:03:23] Subscribed to TimingData, LapCount, DriverList",
            "[14:03:24] Authenticated as F1 TV Pro subscriber",
            "[14:04:00] Received TimingData update for 20 drivers",
            "[14:04:02] Recorded telemetry snapshot"
        ]
    }
}

struct ChampionshipStatsView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Championship Stats")
                .font(.largeTitle)
                .bold()
            Text("A convenient overview of driver and constructor standings.")
                .foregroundStyle(.secondary)
            Grid(alignment: .leading, horizontalSpacing: 16, verticalSpacing: 12) {
                GridRow {
                    Text("Pos").bold()
                    Text("Driver").bold()
                    Text("Points").bold()
                }
                Divider()
                ForEach(sampleStandings, id: \.position) { standing in
                    GridRow {
                        Text("\(standing.position)")
                        Text(standing.driver)
                        Text("\(standing.points)")
                    }
                }
            }
        }
        .padding()
        .navigationTitle("Championship Stats")
    }

    private var sampleStandings: [(position: Int, driver: String, points: Int)] {
        [
            (1, "Max Verstappen", 255),
            (2, "Lando Norris", 212),
            (3, "Charles Leclerc", 189),
            (4, "Lewis Hamilton", 178)
        ]
    }
}

struct TeamRadioView: View {
    var body: some View {
        List(sampleRadios, id: \.timestamp) { radio in
            VStack(alignment: .leading, spacing: 4) {
                Text(radio.message)
                Text("\(radio.driver) – \(radio.timestamp)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Team Radio")
    }

    private var sampleRadios: [(driver: String, message: String, timestamp: String)] {
        [
            ("HAM", "Tyres feel good, balance is neutral.", "14:12:33"),
            ("VER", "Car bottoming turn 12.", "14:13:10"),
            ("NOR", "Can push for mode seven?", "14:14:52")
        ]
    }
}

struct DebugDataView: View {
    var sessionInfo: SessionInfoDataPoint
    var timingData: TimingDataPoint

    var body: some View {
        Form {
            Section("Session Info") {
                Text("Raw key: \(sessionInfo.key ?? 0)")
                Text("Circuit points: \(sessionInfo.circuitPoints.count)")
                Text("Circuit corners: \(sessionInfo.circuitCorners.count)")
            }

            Section("Timing Data") {
                Text("Drivers with telemetry: \(timingData.lines.count)")
                if let leader = timingData.lines.values.first(where: { $0.position == "1" }) {
                    Text("Leader laps: \(leader.numberOfLaps ?? 0)")
                }
            }
        }
        .navigationTitle("Debug Data")
    }
}

struct DownloadTranscriptionModelView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Download Transcription Model")
                .font(.largeTitle)
                .bold()
            Text("Fetch Whisper or Vosk models used to transcribe Team Radio audio clips.")
            Button("Download base.en model") {}
            Button("Download small.it model") {}
            Spacer()
        }
        .padding()
        .navigationTitle("Download Model")
    }
}

struct InfoView: View {
    var sessionInfo: SessionInfoDataPoint

    var body: some View {
        List {
            Section("Project") {
                Link("GitHub Repository", destination: URL(string: "https://github.com/JustAman62/undercut-f1")!)
                Text("Version: \(Bundle.main.infoDictionary?[\"CFBundleShortVersionString\"] as? String ?? "dev")")
            }

            Section("Session") {
                Text("Type: \(sessionInfo.type ?? "-")")
                Text("Meeting: \(sessionInfo.meeting?.name ?? "-")")
                Text("Circuit: \(sessionInfo.meeting?.circuit?.shortName ?? "-")")
            }
        }
        .navigationTitle("Info")
    }
}

struct SelectDriverView: View {
    var drivers: [TimingTowerRow]

    var body: some View {
        List(drivers) { driver in
            HStack {
                Text(driver.driverName)
                Spacer()
                Text("#\(driver.racingNumber)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Select Driver")
    }
}

// MARK: - Sample data

public final class LiveTimingSampleData {
    public static let shared = LiveTimingSampleData()

    public let timingData: TimingDataPoint
    public let lapCount: LapCountDataPoint
    public let sessionInfo: SessionInfoDataPoint
    public let driverList: DriverListDataPoint
    public let tyreData: TimingAppDataPoint
    public let raceControl: RaceControlMessageDataPoint
    public let positionData: PositionDataPoint

    private init() {
        timingData = Self.decode(TimingDataPoint.self, from: Self.timingDataJSON)
        lapCount = Self.decode(LapCountDataPoint.self, from: Self.lapCountJSON)
        sessionInfo = Self.decode(SessionInfoDataPoint.self, from: Self.sessionInfoJSON)
        driverList = Self.decode(DriverListDataPoint.self, from: Self.driverListJSON)
        tyreData = Self.decode(TimingAppDataPoint.self, from: Self.tyreDataJSON)
        raceControl = Self.decode(RaceControlMessageDataPoint.self, from: Self.raceControlJSON)
        positionData = Self.decode(PositionDataPoint.self, from: Self.positionDataJSON)
    }

    private static func decode<T: Decodable>(_ type: T.Type, from json: String) -> T {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        guard let data = json.data(using: .utf8) else {
            fatalError("Failed to encode sample JSON")
        }
        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            fatalError("Failed to decode sample JSON for \(T.self): \(error)")
        }
    }
}

private extension LiveTimingSampleData {
    static let timingDataJSON = """
    {
      "Lines": {
        "44": {
          "GapToLeader": "LEADER",
          "IntervalToPositionAhead": { "Value": "-", "Catching": false },
          "Line": 1,
          "Position": "1",
          "InPit": false,
          "PitOut": false,
          "NumberOfPitStops": 1,
          "IsPitLap": false,
          "NumberOfLaps": 35,
          "LastLapTime": { "Value": "1:17.345", "OverallFastest": false, "PersonalFastest": false, "Segments": {} },
          "BestLapTime": { "Value": "1:17.001", "Lap": 12 },
          "Status": 0
        },
        "1": {
          "GapToLeader": "+1.203",
          "IntervalToPositionAhead": { "Value": "+1.203", "Catching": true },
          "Line": 2,
          "Position": "2",
          "InPit": false,
          "PitOut": false,
          "NumberOfPitStops": 1,
          "IsPitLap": false,
          "NumberOfLaps": 35,
          "LastLapTime": { "Value": "1:17.912", "OverallFastest": false, "PersonalFastest": false, "Segments": {} },
          "BestLapTime": { "Value": "1:17.120", "Lap": 14 },
          "Status": 0
        },
        "55": {
          "GapToLeader": "+4.602",
          "IntervalToPositionAhead": { "Value": "+3.399", "Catching": false },
          "Line": 3,
          "Position": "3",
          "InPit": false,
          "PitOut": false,
          "NumberOfPitStops": 2,
          "IsPitLap": false,
          "NumberOfLaps": 35,
          "LastLapTime": { "Value": "1:18.004", "OverallFastest": false, "PersonalFastest": true, "Segments": {} },
          "BestLapTime": { "Value": "1:17.500", "Lap": 20 },
          "Status": 0
        }
      }
    }
    """

    static let lapCountJSON = """
    {
      "CurrentLap": 35,
      "TotalLaps": 53
    }
    """

    static let sessionInfoJSON = """
    {
      "Key": 945,
      "Type": "Race",
      "Name": "British Grand Prix",
      "StartDate": "2024-07-07T14:00:00Z",
      "EndDate": "2024-07-07T16:00:00Z",
      "GmtOffset": "+01:00",
      "Path": "silverstone",
      "Meeting": {
        "Name": "British Grand Prix",
        "Circuit": {
          "Key": 5,
          "ShortName": "Silverstone"
        }
      },
      "CircuitPoints": [
        [0, 0], [140, 10], [220, 40], [260, 120], [220, 200], [140, 240], [20, 220], [0, 120]
      ],
      "CircuitCorners": [
        [1, 0.12, 0.18],
        [2, 0.32, 0.38],
        [3, 0.58, 0.44],
        [4, 0.76, 0.72],
        [5, 0.44, 0.88]
      ],
      "CircuitRotation": 0
    }
    """

    static let driverListJSON = """
    {
      "44": {
        "RacingNumber": "44",
        "BroadcastName": "Hamilton",
        "FullName": "Lewis Hamilton",
        "Tla": "HAM",
        "Line": 1,
        "TeamName": "Mercedes",
        "TeamColour": "00D2BE",
        "IsSelected": true
      },
      "1": {
        "RacingNumber": "1",
        "BroadcastName": "Verstappen",
        "FullName": "Max Verstappen",
        "Tla": "VER",
        "Line": 2,
        "TeamName": "Red Bull Racing",
        "TeamColour": "1E5BC6",
        "IsSelected": true
      },
      "55": {
        "RacingNumber": "55",
        "BroadcastName": "Sainz",
        "FullName": "Carlos Sainz",
        "Tla": "SAI",
        "Line": 3,
        "TeamName": "Ferrari",
        "TeamColour": "ED1C24",
        "IsSelected": true
      }
    }
    """

    static let tyreDataJSON = """
    {
      "Lines": {
        "44": {
          "GridPos": "P2",
          "Line": 1,
          "Stints": {
            "1": { "LapFlags": 0, "Compound": "Medium", "New": true, "TotalLaps": 18, "StartLaps": 1, "LapTime": "1:18.111" },
            "2": { "LapFlags": 0, "Compound": "Hard", "New": false, "TotalLaps": 17, "StartLaps": 19, "LapTime": "1:17.890" }
          }
        },
        "1": {
          "GridPos": "P1",
          "Line": 2,
          "Stints": {
            "1": { "LapFlags": 0, "Compound": "Soft", "New": true, "TotalLaps": 12, "StartLaps": 1, "LapTime": "1:17.750" },
            "2": { "LapFlags": 0, "Compound": "Medium", "New": false, "TotalLaps": 23, "StartLaps": 13, "LapTime": "1:18.010" }
          }
        },
        "55": {
          "GridPos": "P3",
          "Line": 3,
          "Stints": {
            "1": { "LapFlags": 0, "Compound": "Medium", "New": true, "TotalLaps": 20, "StartLaps": 1, "LapTime": "1:18.200" },
            "2": { "LapFlags": 0, "Compound": "Hard", "New": true, "TotalLaps": 15, "StartLaps": 21, "LapTime": "1:17.950" }
          }
        }
      }
    }
    """

    static let raceControlJSON = """
    {
      "Messages": {
        "1": { "Utc": "2024-07-07T14:15:12Z", "Message": "DRS enabled." },
        "2": { "Utc": "2024-07-07T14:32:44Z", "Message": "Yellow flag in sector 2." },
        "3": { "Utc": "2024-07-07T14:40:05Z", "Message": "Incident involving cars 1 and 55 noted." }
      }
    }
    """

    static let positionDataJSON = """
    {
      "Position": [
        {
          "Timestamp": "2024-07-07T14:35:00Z",
          "Entries": {
            "44": { "Status": "OnTrack", "X": 220, "Y": 60, "Z": 0 },
            "1": { "Status": "OnTrack", "X": 200, "Y": 120, "Z": 0 },
            "55": { "Status": "OnTrack", "X": 150, "Y": 200, "Z": 0 }
          }
        }
      ]
    }
    """
}

// MARK: - Helpers

extension Color {
    init?(hex: String?) {
        guard let hex, let rgb = UInt64(hex, radix: 16) else {
            return nil
        }
        let r = Double((rgb >> 16) & 0xFF) / 255.0
        let g = Double((rgb >> 8) & 0xFF) / 255.0
        let b = Double(rgb & 0xFF) / 255.0
        self = Color(red: r, green: g, blue: b)
    }
}

// MARK: - Preview

struct UndercutF1RootView_Previews: PreviewProvider {
    static var previews: some View {
        UndercutF1RootView()
    }
}
