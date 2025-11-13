import Foundation

public struct PitLaneTimeCollectionDataPoint: LiveTimingDataPoint {
    public static let dataType: LiveTimingDataType = .pitLaneTimeCollection
    public var pitTimes: [String: PitTime] = [:]
    public var pitTimesList: [String: [PitTime]] = [:]

    public init() {}

    public mutating func merge(with other: PitLaneTimeCollectionDataPoint) {
        for (driver, pitTime) in other.pitTimes {
            pitTimes[driver] = pitTime
            var list = pitTimesList[driver] ?? []
            list.append(pitTime)
            pitTimesList[driver] = list
        }
    }

    public struct PitTime: Codable, Mergeable, Sendable, Equatable {
        public var duration: String?
        public var lap: String?

        public init(duration: String? = nil, lap: String? = nil) {
            self.duration = duration
            self.lap = lap
        }

        public mutating func merge(with other: PitTime) {
            if let duration = other.duration { self.duration = duration }
            if let lap = other.lap { self.lap = lap }
        }

        private enum CodingKeys: String, CodingKey {
            case duration = "Duration"
            case lap = "Lap"
        }
    }

    private enum CodingKeys: String, CodingKey {
        case pitTimes = "PitTimes"
    }
}
