import Foundation

public struct DriverListDataPoint: LiveTimingDataPoint {
    public static let dataType: LiveTimingDataType = .driverList
    public var drivers: [String: Driver] = [:]

    public init() {}

    public mutating func merge(with other: DriverListDataPoint) {
        drivers.mergeInPlace(other.drivers)
    }

    public func isSelected(driverNumber: String) -> Bool {
        drivers[driverNumber]?.isSelected ?? true
    }

    public struct Driver: Codable, Mergeable, Sendable {
        public var racingNumber: String?
        public var broadcastName: String?
        public var fullName: String?
        public var tla: String?
        public var line: Int?
        public var teamName: String?
        public var teamColour: String?
        public var isSelected: Bool = true

        public init() {}

        public mutating func merge(with other: Driver) {
            if let racingNumber = other.racingNumber { self.racingNumber = racingNumber }
            if let broadcastName = other.broadcastName { self.broadcastName = broadcastName }
            if let fullName = other.fullName { self.fullName = fullName }
            if let tla = other.tla { self.tla = tla }
            if let line = other.line { self.line = line }
            if let teamName = other.teamName { self.teamName = teamName }
            if let teamColour = other.teamColour { self.teamColour = teamColour }
            self.isSelected = other.isSelected
        }

        private enum CodingKeys: String, CodingKey {
            case racingNumber = "RacingNumber"
            case broadcastName = "BroadcastName"
            case fullName = "FullName"
            case tla = "Tla"
            case line = "Line"
            case teamName = "TeamName"
            case teamColour = "TeamColour"
            case isSelected = "IsSelected"
        }
    }
}

extension DriverListDataPoint: Codable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        drivers = try container.decode([String: Driver].self)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(drivers)
    }
}
