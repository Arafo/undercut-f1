import Foundation
import SwiftUI

struct Driver: Identifiable, Hashable {
    let id: UUID = UUID()
    let position: Int
    let code: String
    let name: String
    let teamColor: Color
    let tyre: TyreCompound
    let tyreAge: Int
    let interval: String
    let gapToLeader: String
    let relativeGap: String
    let lastLap: LapTiming
    let bestLap: LapTiming
    let sectorTimes: [SectorTiming]
    let positionChange: Int
}

struct LapTiming {
    let time: String
    let isPersonalBest: Bool
    let isOverallBest: Bool
}

struct SectorTiming: Identifiable {
    enum Sector: Int {
        case one = 1
        case two
        case three

        var label: String { "S\(rawValue)" }
    }

    let id: Sector
    let time: String
    let isPersonalBest: Bool
    let isOverallBest: Bool
}

enum TyreCompound: String {
    case soft = "S"
    case medium = "M"
    case hard = "H"
    case intermediate = "I"
    case wet = "W"

    var color: Color {
        switch self {
        case .soft: return Color(hex: 0xC91F2C)
        case .medium: return Color(hex: 0xFFE314)
        case .hard: return Color(hex: 0xF0F1F1)
        case .intermediate: return Color(hex: 0x16A24A)
        case .wet: return Color(hex: 0x2677C9)
        }
    }
}

struct RaceControlMessage: Identifiable {
    enum Category: String {
        case information = "INFO"
        case investigation = "INV"
        case penalty = "PEN"
        case weather = "WEA"

        var color: Color {
            switch self {
            case .information: return .gray
            case .investigation: return Color(hex: 0xF0B429)
            case .penalty: return Color(hex: 0xE55353)
            case .weather: return Color(hex: 0x4EA8DE)
            }
        }
    }

    let id = UUID()
    let timestamp: String
    let message: String
    let category: Category
}

struct Stint: Identifiable {
    let id = UUID()
    let tyre: TyreCompound
    let laps: Int
    let pitStopTime: String
}

struct DriverStrategy: Identifiable {
    let id = UUID()
    let driver: Driver
    let stints: [Stint]
}

struct TrackerSnapshot {
    struct DriverPosition: Identifiable {
        let id = UUID()
        let driver: Driver
        let progress: CGFloat
        let highlighted: Bool
    }

    let layoutName: String
    let drivers: [DriverPosition]
}

struct SessionSummary {
    let name: String
    let circuit: String
    let sessionType: String
    let lap: Int
    let totalLaps: Int
    let weather: String
    let trackStatus: String
    let controlMessages: [RaceControlMessage]
    let driverStrategies: [DriverStrategy]
    let trackerSnapshot: TrackerSnapshot
}

@MainActor
final class SessionViewModel: ObservableObject {
    @Published var summary: SessionSummary
    @Published var timingDrivers: [Driver]
    @Published var selectedDriver: Driver?
    @Published var selectedTab: SessionTab = .timing

    init(summary: SessionSummary = MockData.sessionSummary, drivers: [Driver] = MockData.drivers) {
        self.summary = summary
        self.timingDrivers = drivers
        selectedDriver = drivers.first
    }

    func select(driver: Driver) {
        withAnimation(.easeInOut(duration: 0.2)) {
            selectedDriver = driver
        }
    }
}

enum SessionTab: String, CaseIterable, Identifiable {
    case timing = "Timing"
    case raceControl = "Race Control"
    case strategy = "Strategy"
    case tracker = "Tracker"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .timing: return "speedometer"
        case .raceControl: return "megaphone"
        case .strategy: return "chart.bar.doc.horizontal"
        case .tracker: return "map"
        }
    }
}

extension Color {
    init(hex: UInt, alpha: Double = 1.0) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: alpha
        )
    }
}
