import Foundation

public struct TimingAppDataPoint: LiveTimingDataPoint {
    public static let dataType: LiveTimingDataType = .timingAppData
    public var lines: [String: Driver] = [:]

    public init() {}

    public mutating func merge(with other: TimingAppDataPoint) {
        lines.mergeInPlace(other.lines)
    }

    public struct Driver: Codable, Mergeable, Sendable {
        public var gridPos: String?
        public var line: Int?
        public var stints: [String: Stint] = [:]

        public init() {}

        public mutating func merge(with other: Driver) {
            if let gridPos = other.gridPos { self.gridPos = gridPos }
            if let line = other.line { self.line = line }
            stints.mergeInPlace(other.stints)
        }

        public struct Stint: Codable, Mergeable, Sendable {
            public var lapFlags: Int?
            public var compound: String?
            public var isNew: Bool?
            public var totalLaps: Int?
            public var startLaps: Int?
            public var lapTime: String?

            public init() {}

            public mutating func merge(with other: Stint) {
                if let lapFlags = other.lapFlags { self.lapFlags = lapFlags }
                if let compound = other.compound { self.compound = compound }
                if let isNew = other.isNew { self.isNew = isNew }
                if let totalLaps = other.totalLaps { self.totalLaps = totalLaps }
                if let startLaps = other.startLaps { self.startLaps = startLaps }
                if let lapTime = other.lapTime { self.lapTime = lapTime }
            }

            public init(from decoder: Decoder) throws {
                let container = try decoder.container(keyedBy: CodingKeys.self)
                lapFlags = try container.decodeIfPresent(Int.self, forKey: .lapFlags)
                compound = try container.decodeIfPresent(String.self, forKey: .compound)
                if let boolValue = try container.decodeIfPresent(Bool.self, forKey: .isNew) {
                    isNew = boolValue
                } else if let stringValue = try container.decodeIfPresent(String.self, forKey: .isNew) {
                    isNew = (stringValue as NSString).boolValue
                }
                totalLaps = try container.decodeIfPresent(Int.self, forKey: .totalLaps)
                startLaps = try container.decodeIfPresent(Int.self, forKey: .startLaps)
                lapTime = try container.decodeIfPresent(String.self, forKey: .lapTime)
            }
        }

        private enum CodingKeys: String, CodingKey {
            case gridPos = "GridPos"
            case line = "Line"
            case stints = "Stints"
        }
    }

    private enum CodingKeys: String, CodingKey {
        case lines = "Lines"
    }
}

private extension TimingAppDataPoint.Driver.Stint {
    enum CodingKeys: String, CodingKey {
        case lapFlags = "LapFlags"
        case compound = "Compound"
        case isNew = "New"
        case totalLaps = "TotalLaps"
        case startLaps = "StartLaps"
        case lapTime = "LapTime"
    }
}

extension TimingAppDataPoint.Driver.Stint {
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(lapFlags, forKey: .lapFlags)
        try container.encodeIfPresent(compound, forKey: .compound)
        if let isNew {
            try container.encode(isNew, forKey: .isNew)
        }
        try container.encodeIfPresent(totalLaps, forKey: .totalLaps)
        try container.encodeIfPresent(startLaps, forKey: .startLaps)
        try container.encodeIfPresent(lapTime, forKey: .lapTime)
    }
}
