import Foundation

public protocol LiveTimingDataPoint: Codable, Sendable {
    static var liveTimingDataType: LiveTimingDataType { get }
}

public struct TimingDataPoint: LiveTimingDataPoint {
    public static let liveTimingDataType: LiveTimingDataType = .timingData

    public var lines: [String: Driver] = [:]

    public struct Driver: Codable, Sendable {
        public var gapToLeader: String?
        public var intervalToPositionAhead: Interval?
        public var line: Int?
        public var position: String?
        public var inPit: Bool?
        public var pitOut: Bool?
        public var numberOfPitStops: Int?
        public var isPitLap: Bool = false
        public var numberOfLaps: Int?
        public var lastLapTime: LapSectorTime?
        public var sectors: [String: LapSectorTime]? = nil
        public var bestLapTime: BestLap = .init()
        public var knockedOut: Bool?
        public var retired: Bool?
        public var stopped: Bool?
        public var status: StatusFlags?

        public init(
            gapToLeader: String? = nil,
            intervalToPositionAhead: Interval? = nil,
            line: Int? = nil,
            position: String? = nil,
            inPit: Bool? = nil,
            pitOut: Bool? = nil,
            numberOfPitStops: Int? = nil,
            isPitLap: Bool = false,
            numberOfLaps: Int? = nil,
            lastLapTime: LapSectorTime? = nil,
            sectors: [String: LapSectorTime]? = nil,
            bestLapTime: BestLap = .init(),
            knockedOut: Bool? = nil,
            retired: Bool? = nil,
            stopped: Bool? = nil,
            status: StatusFlags? = nil
        ) {
            self.gapToLeader = gapToLeader
            self.intervalToPositionAhead = intervalToPositionAhead
            self.line = line
            self.position = position
            self.inPit = inPit
            self.pitOut = pitOut
            self.numberOfPitStops = numberOfPitStops
            self.isPitLap = isPitLap
            self.numberOfLaps = numberOfLaps
            self.lastLapTime = lastLapTime
            self.sectors = sectors
            self.bestLapTime = bestLapTime
            self.knockedOut = knockedOut
            self.retired = retired
            self.stopped = stopped
            self.status = status
        }

        public struct Interval: Codable, Sendable {
            public var value: String?
            public var catching: Bool?

            public init(value: String? = nil, catching: Bool? = nil) {
                self.value = value
                self.catching = catching
            }
        }

        public struct LapSectorTime: Codable, Sendable {
            public var value: String?
            public var overallFastest: Bool?
            public var personalFastest: Bool?
            public var segments: [Int: Segment]?

            public init(
                value: String? = nil,
                overallFastest: Bool? = nil,
                personalFastest: Bool? = nil,
                segments: [Int: Segment]? = nil
            ) {
                self.value = value
                self.overallFastest = overallFastest
                self.personalFastest = personalFastest
                self.segments = segments
            }

            public struct Segment: Codable, Sendable {
                public var status: StatusFlags?

                public init(status: StatusFlags? = nil) {
                    self.status = status
                }
            }
        }

        public struct BestLap: Codable, Sendable {
            public var value: String?
            public var lap: Int?

            public init(value: String? = nil, lap: Int? = nil) {
                self.value = value
                self.lap = lap
            }
        }

        public struct LapTime: Codable, Sendable {
            public var time: LapSectorTime?
            public var sectors: [String: LapSectorTime]?

            public init(time: LapSectorTime? = nil, sectors: [String: LapSectorTime]? = nil) {
                self.time = time
                self.sectors = sectors
            }
        }

        public struct Stint: Codable, Sendable {
            public var compound: String?
            public var tyreLife: Int?
            public var new: Bool?
            public var stint: Int?

            public init(compound: String? = nil, tyreLife: Int? = nil, new: Bool? = nil, stint: Int? = nil) {
                self.compound = compound
                self.tyreLife = tyreLife
                self.new = new
                self.stint = stint
            }
        }

        public struct StatusFlags: OptionSet, Codable, Sendable {
            public let rawValue: Int

            public init(rawValue: Int) {
                self.rawValue = rawValue
            }

            public static let personalBest = StatusFlags(rawValue: 1)
            public static let overallBest = StatusFlags(rawValue: 2)
            public static let pitLane = StatusFlags(rawValue: 16)
            public static let chequeredFlag = StatusFlags(rawValue: 1024)
            public static let segmentComplete = StatusFlags(rawValue: 2048)
        }
    }
}

public struct HeartbeatDataPoint: LiveTimingDataPoint {
    public static let liveTimingDataType: LiveTimingDataType = .heartbeat
    public var utc: Date?
    public var sequenceNumber: Int?
}

public struct RaceControlMessageDataPoint: LiveTimingDataPoint {
    public static let liveTimingDataType: LiveTimingDataType = .raceControlMessages

    public struct Message: Codable, Sendable {
        public var message: String?
        public var category: String?
        public var flag: String?
        public var scope: String?
        public var lap: Int?
        public var sector: Int?
        public var date: Date?
        public var dismissed: Bool?
    }

    public var messages: [String: Message] = [:]
}

public struct TimingStatsDataPoint: LiveTimingDataPoint {
    public static let liveTimingDataType: LiveTimingDataType = .timingStats
    public var lines: [String: Line] = [:]

    public struct Line: Codable, Sendable {
        public var bestLapTime: TimingDataPoint.Driver.LapSectorTime?
        public var lastLapTime: TimingDataPoint.Driver.LapSectorTime?
        public var personalBestLapTime: TimingDataPoint.Driver.LapSectorTime?
        public var personalBestSectors: [String: TimingDataPoint.Driver.LapSectorTime]?
    }
}

public struct TopThreeDataPoint: LiveTimingDataPoint {
    public static let liveTimingDataType: LiveTimingDataType = .topThree
    public var withheld: Bool?
    public var lines: [String: Line] = [:]

    public struct Line: Codable, Sendable {
        public var position: String?
        public var showPosition: Bool?
        public var racingNumber: String?
        public var driverTla: String?
        public var gapToLeader: String?
        public var intervalToPositionAhead: String?
        public var timeDifferenceToLeader: String?
    }
}

public struct ExtrapolatedClockDataPoint: LiveTimingDataPoint {
    public static let liveTimingDataType: LiveTimingDataType = .extrapolatedClock
    public var trackTime: String?
    public var trackTimeOfDay: String?
    public var systemTime: String?
    public var paused: Bool?
    public var remaining: String?
    public var sessionTime: String?
    public var session: String?
}

public struct WeatherDataPoint: LiveTimingDataPoint {
    public static let liveTimingDataType: LiveTimingDataType = .weatherData
    public var airTemp: Double?
    public var humidity: Double?
    public var pressure: Double?
    public var rainfall: String?
    public var trackTemp: Double?
    public var windSpeed: Double?
    public var windDirection: Double?
}

public struct TrackStatusDataPoint: LiveTimingDataPoint {
    public static let liveTimingDataType: LiveTimingDataType = .trackStatus
    public var status: String?
    public var message: String?
    public var signal: String?
}

public struct DriverListDataPoint: LiveTimingDataPoint {
    public static let liveTimingDataType: LiveTimingDataType = .driverList

    public struct Driver: Codable, Sendable {
        public var racingNumber: String?
        public var broadcastName: String?
        public var fullName: String?
        public var teamName: String?
        public var teamColour: String?
        public var firstName: String?
        public var lastName: String?
        public var countryCode: String?
    }

    public var drivers: [String: Driver] = [:]
}

public struct SessionInfoDataPoint: LiveTimingDataPoint {
    public static let liveTimingDataType: LiveTimingDataType = .sessionInfo

    public struct Meeting: Codable, Sendable {
        public var key: Int?
        public var location: String?
        public var country: String?
        public var circuit: String?
    }

    public struct Session: Codable, Sendable {
        public var key: Int?
        public var name: String?
        public var type: String?
        public var startDate: Date?
        public var endDate: Date?
    }

    public var meeting: Meeting?
    public var session: Session?
    public var path: String?
    public var gmtOffset: String?
}

public struct LapCountDataPoint: LiveTimingDataPoint {
    public static let liveTimingDataType: LiveTimingDataType = .lapCount
    public var currentLap: Int?
    public var totalLaps: Int?
}

public struct TeamRadioDataPoint: LiveTimingDataPoint {
    public static let liveTimingDataType: LiveTimingDataType = .teamRadio

    public struct Capture: Codable, Sendable {
        public var utc: Date?
        public var path: String?
        public var meetingKey: Int?
        public var sessionKey: Int?
        public var driverNumber: String?
    }

    public var captures: [String: Capture] = [:]
}

public struct ChampionshipPredictionDataPoint: LiveTimingDataPoint {
    public static let liveTimingDataType: LiveTimingDataType = .championshipPrediction
    public var items: [String: JSONValue] = [:]
}

public struct CarDataPoint: LiveTimingDataPoint {
    public static let liveTimingDataType: LiveTimingDataType = .carData

    public struct Car: Codable, Sendable {
        public var rpm: Int?
        public var speed: Int?
        public var throttle: Double?
        public var brake: Double?
        public var gear: Int?
        public var drs: Int?
    }

    public var cars: [String: Car] = [:]
}

public struct PositionDataPoint: LiveTimingDataPoint {
    public static let liveTimingDataType: LiveTimingDataType = .position

    public struct Position: Codable, Sendable {
        public var status: Int?
        public var x: Double?
        public var y: Double?
        public var z: Double?
    }

    public var positions: [String: Position] = [:]
}

public struct TimingAppDataPoint: LiveTimingDataPoint {
    public static let liveTimingDataType: LiveTimingDataType = .timingAppData

    public struct Line: Codable, Sendable {
        public var stints: [String: TimingDataPoint.Driver.Stint]?
        public var bestLapTime: TimingDataPoint.Driver.LapSectorTime?
        public var lastLapTime: TimingDataPoint.Driver.LapSectorTime?
        public var personalBestLapTime: TimingDataPoint.Driver.LapSectorTime?
    }

    public var lines: [String: Line] = [:]
}

public struct PitLaneTimeCollectionDataPoint: LiveTimingDataPoint {
    public static let liveTimingDataType: LiveTimingDataType = .pitLaneTimeCollection

    public struct Entry: Codable, Sendable {
        public var pitInTime: String?
        public var pitOutTime: String?
    }

    public var pitTimes: [String: Entry] = [:]
}

public struct PitStopSeriesDataPoint: LiveTimingDataPoint {
    public static let liveTimingDataType: LiveTimingDataType = .pitStopSeries

    public struct PitStop: Codable, Sendable {
        public var lap: Int?
        public var time: String?
        public var total: String?
        public var stopped: String?
    }

    public var pitTimes: [String: [String: PitStop]] = [:]
}

public struct PitStopDataPoint: LiveTimingDataPoint {
    public static let liveTimingDataType: LiveTimingDataType = .pitStop
    public var items: [String: JSONValue] = [:]
}

public struct SessionDataPoint: LiveTimingDataPoint {
    public static let liveTimingDataType: LiveTimingDataType = .sessionData
    public var properties: [String: JSONValue] = [:]
}

// MARK: - Merging helpers

extension TimingDataPoint {
    public mutating func merge(with partial: TimingDataPoint) {
        for (driverNumber, driverUpdate) in partial.lines {
            var existing = lines[driverNumber] ?? Driver()
            existing.merge(with: driverUpdate)
            lines[driverNumber] = existing
        }
    }
}

extension TimingDataPoint.Driver {
    public mutating func merge(with partial: TimingDataPoint.Driver) {
        if let gap = partial.gapToLeader {
            gapToLeader = gap
        }
        if let interval = partial.intervalToPositionAhead {
            if intervalToPositionAhead == nil {
                intervalToPositionAhead = interval
            } else {
                intervalToPositionAhead?.merge(with: interval)
            }
        }
        if let line = partial.line {
            self.line = line
        }
        if let position = partial.position {
            self.position = position
        }
        if let inPit = partial.inPit {
            self.inPit = inPit
        }
        if let pitOut = partial.pitOut {
            self.pitOut = pitOut
        }
        if let pitStops = partial.numberOfPitStops {
            numberOfPitStops = pitStops
        }
        if partial.isPitLap {
            isPitLap = true
        }
        if let laps = partial.numberOfLaps {
            numberOfLaps = laps
        }
        if let lastLap = partial.lastLapTime {
            if lastLapTime == nil {
                lastLapTime = lastLap
            } else {
                lastLapTime?.merge(with: lastLap)
            }
        }
        if let newSectors = partial.sectors {
            var merged = sectors ?? [:]
            for (key, value) in newSectors {
                var existing = merged[key] ?? LapSectorTime()
                existing.merge(with: value)
                merged[key] = existing
            }
            sectors = merged
        }
        if partial.bestLapTime.value != nil || partial.bestLapTime.lap != nil {
            bestLapTime.merge(with: partial.bestLapTime)
        }
        if let knockedOut = partial.knockedOut {
            self.knockedOut = knockedOut
        }
        if let retired = partial.retired {
            self.retired = retired
        }
        if let stopped = partial.stopped {
            self.stopped = stopped
        }
        if let status = partial.status {
            self.status = status
        }
    }
}

extension TimingDataPoint.Driver.Interval {
    mutating func merge(with other: TimingDataPoint.Driver.Interval) {
        if let value = other.value {
            self.value = value
        }
        if let catching = other.catching {
            self.catching = catching
        }
    }
}

extension TimingDataPoint.Driver.LapSectorTime {
    mutating func merge(with other: TimingDataPoint.Driver.LapSectorTime) {
        if let value = other.value {
            self.value = value
        }
        if let overallFastest = other.overallFastest {
            self.overallFastest = overallFastest
        }
        if let personalFastest = other.personalFastest {
            self.personalFastest = personalFastest
        }
        if let otherSegments = other.segments {
            var merged = segments ?? [:]
            for (key, segment) in otherSegments {
                var existing = merged[key] ?? Segment()
                existing.merge(with: segment)
                merged[key] = existing
            }
            segments = merged
        }
    }
}

extension TimingDataPoint.Driver.LapSectorTime.Segment {
    mutating func merge(with other: TimingDataPoint.Driver.LapSectorTime.Segment) {
        if let status = other.status {
            self.status = status
        }
    }
}

extension TimingDataPoint.Driver.BestLap {
    mutating func merge(with other: TimingDataPoint.Driver.BestLap) {
        if let value = other.value {
            self.value = value
        }
        if let lap = other.lap {
            self.lap = lap
        }
    }

    public func timeInterval() -> TimeInterval? {
        guard let value else { return nil }
        return value.lapTimeInterval()
    }
}

extension TimingDataPoint.Driver.LapSectorTime {
    public func timeInterval() -> TimeInterval? {
        guard let value else { return nil }
        return value.lapTimeInterval()
    }
}

private extension String {
    func lapTimeInterval() -> TimeInterval? {
        let sanitized = replacingOccurrences(of: ",", with: ".")
        let components = sanitized.split(separator: ":")
        switch components.count {
        case 3:
            guard
                let hours = Int(components[0]),
                let minutes = Int(components[1]),
                let seconds = Double(components[2])
            else {
                return nil
            }
            return (Double(hours) * 3600) + (Double(minutes) * 60) + seconds
        case 2:
            guard
                let minutes = Int(components[0]),
                let seconds = Double(components[1])
            else {
                return nil
            }
            return (Double(minutes) * 60) + seconds
        case 1:
            return Double(components[0])
        default:
            return nil
        }
    }
}
