import Foundation

public struct PitStopSeriesDataPoint: LiveTimingDataPoint {
    public static let dataType: LiveTimingDataType = .pitStopSeries
    public var pitTimes: [String: [String: PitTime]] = [:]

    public init() {}

    public mutating func merge(with other: PitStopSeriesDataPoint) {
        for (driver, stops) in other.pitTimes {
            var existing = pitTimes[driver] ?? [:]
            for (key, stop) in stops {
                if var current = existing[key] {
                    current.merge(with: stop)
                    existing[key] = current
                } else {
                    existing[key] = stop
                }
            }
            pitTimes[driver] = existing
        }
    }

    public struct PitTime: Codable, Mergeable, Sendable {
        public var timestamp: Date?
        public var pitStop: PitStopEntry?

        public init() {}

        public mutating func merge(with other: PitTime) {
            if let timestamp = other.timestamp { self.timestamp = timestamp }
            pitStop.mergeWithOptional(other.pitStop)
        }

        public struct PitStopEntry: Codable, Mergeable, Sendable {
            public var racingNumber: String?
            public var pitStopTime: String?
            public var pitLaneTime: String?
            public var lap: String?

            public init() {}

            public mutating func merge(with other: PitStopEntry) {
                if let racingNumber = other.racingNumber { self.racingNumber = racingNumber }
                if let pitStopTime = other.pitStopTime { self.pitStopTime = pitStopTime }
                if let pitLaneTime = other.pitLaneTime { self.pitLaneTime = pitLaneTime }
                if let lap = other.lap { self.lap = lap }
            }

            private enum CodingKeys: String, CodingKey {
                case racingNumber = "RacingNumber"
                case pitStopTime = "PitStopTime"
                case pitLaneTime = "PitLaneTime"
                case lap = "Lap"
            }
        }

        private enum CodingKeys: String, CodingKey {
            case timestamp = "Timestamp"
            case pitStop = "PitStop"
        }
    }

    private enum CodingKeys: String, CodingKey {
        case pitTimes = "PitTimes"
    }
}
