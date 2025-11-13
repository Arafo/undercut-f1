import Foundation

public struct TimingDataPoint: LiveTimingDataPoint {
    public static let dataType: LiveTimingDataType = .timingData
    public var lines: [String: Driver] = [:]

    public init() {}

    public mutating func merge(with other: TimingDataPoint) {
        lines.mergeInPlace(other.lines)
    }

    public struct Driver: Codable, Mergeable, Sendable {
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
        public var sectors: [String: LapSectorTime] = [:]
        public var bestLapTime: BestLap = BestLap()
        public var knockedOut: Bool?
        public var retired: Bool?
        public var stopped: Bool?
        public var status: StatusFlags?

        public init() {}

        public mutating func merge(with other: Driver) {
            if let gapToLeader = other.gapToLeader { self.gapToLeader = gapToLeader }
            intervalToPositionAhead.mergeWithOptional(other.intervalToPositionAhead)
            if let line = other.line { self.line = line }
            if let position = other.position { self.position = position }
            if let inPit = other.inPit { self.inPit = inPit }
            if let pitOut = other.pitOut { self.pitOut = pitOut }
            if let numberOfPitStops = other.numberOfPitStops { self.numberOfPitStops = numberOfPitStops }
            if other.isPitLap { self.isPitLap = true }
            if let numberOfLaps = other.numberOfLaps { self.numberOfLaps = numberOfLaps }
            lastLapTime.mergeWithOptional(other.lastLapTime)
            sectors.mergeInPlace(other.sectors)
            bestLapTime.merge(with: other.bestLapTime)
            if let knockedOut = other.knockedOut { self.knockedOut = knockedOut }
            if let retired = other.retired { self.retired = retired }
            if let stopped = other.stopped { self.stopped = stopped }
            if let status = other.status { self.status = status }
        }

        public struct Interval: Codable, Mergeable, Sendable {
            public var value: String?
            public var catching: Bool?

            public init() {}

            public mutating func merge(with other: Interval) {
                if let value = other.value { self.value = value }
                if let catching = other.catching { self.catching = catching }
            }

            private enum CodingKeys: String, CodingKey {
                case value = "Value"
                case catching = "Catching"
            }
        }

        public struct LapSectorTime: Codable, Mergeable, Sendable {
            public var value: String?
            public var overallFastest: Bool?
            public var personalFastest: Bool?
            public var segments: [Int: Segment]?

            public init() {}

            public mutating func merge(with other: LapSectorTime) {
                if let value = other.value { self.value = value }
                if let overallFastest = other.overallFastest { self.overallFastest = overallFastest }
                if let personalFastest = other.personalFastest { self.personalFastest = personalFastest }
                if var segments = self.segments, let otherSegments = other.segments {
                    for (key, segment) in otherSegments {
                        if var existing = segments[key] {
                            existing.merge(with: segment)
                            segments[key] = existing
                        } else {
                            segments[key] = segment
                        }
                    }
                    self.segments = segments
                } else if let otherSegments = other.segments {
                    self.segments = otherSegments
                }
            }

            public struct Segment: Codable, Mergeable, Sendable {
                public var status: StatusFlags?

                public init() {}

                public mutating func merge(with other: Segment) {
                    if let status = other.status { self.status = status }
                }

                private enum CodingKeys: String, CodingKey {
                    case status = "Status"
                }
            }

            private enum CodingKeys: String, CodingKey {
                case value = "Value"
                case overallFastest = "OverallFastest"
                case personalFastest = "PersonalFastest"
                case segments = "Segments"
            }
        }

        public struct BestLap: Codable, Mergeable, Sendable {
            public var value: String?
            public var lap: Int?

            public init() {}

            public mutating func merge(with other: BestLap) {
                if let value = other.value { self.value = value }
                if let lap = other.lap { self.lap = lap }
            }

            private enum CodingKeys: String, CodingKey {
                case value = "Value"
                case lap = "Lap"
            }
        }

        public struct StatusFlags: OptionSet, Sendable {
            public let rawValue: Int

            public init(rawValue: Int) {
                self.rawValue = rawValue
            }
        }

        private enum CodingKeys: String, CodingKey {
            case gapToLeader = "GapToLeader"
            case intervalToPositionAhead = "IntervalToPositionAhead"
            case line = "Line"
            case position = "Position"
            case inPit = "InPit"
            case pitOut = "PitOut"
            case numberOfPitStops = "NumberOfPitStops"
            case isPitLap = "IsPitLap"
            case numberOfLaps = "NumberOfLaps"
            case lastLapTime = "LastLapTime"
            case sectors = "Sectors"
            case bestLapTime = "BestLapTime"
            case knockedOut = "KnockedOut"
            case retired = "Retired"
            case stopped = "Stopped"
            case status = "Status"
        }
    }

    private enum CodingKeys: String, CodingKey {
        case lines = "Lines"
    }
}

extension TimingDataPoint.Driver.StatusFlags: Codable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let raw = try container.decode(Int.self)
        self.init(rawValue: raw)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }
}
