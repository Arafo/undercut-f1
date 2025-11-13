import Foundation

public struct PositionDataPoint: LiveTimingDataPoint {
    public static let dataType: LiveTimingDataType = .position
    public var position: [PositionData] = [PositionData()]

    public init() {}

    public mutating func merge(with other: PositionDataPoint) {
        position.append(contentsOf: other.position)
    }

    public struct PositionData: Codable, Mergeable, Sendable {
        public var timestamp: Date?
        public var entries: [String: Entry] = [:]

        public init() {}

        public mutating func merge(with other: PositionData) {
            if let timestamp = other.timestamp { self.timestamp = timestamp }
            entries.mergeInPlace(other.entries)
        }

        public struct Entry: Codable, Mergeable, Sendable {
            public var status: Status?
            public var x: Int?
            public var y: Int?
            public var z: Int?

            public init() {}

            public mutating func merge(with other: Entry) {
                if let status = other.status { self.status = status }
                if let x = other.x { self.x = x }
                if let y = other.y { self.y = y }
                if let z = other.z { self.z = z }
            }

            public enum Status: String, Codable, Sendable {
                case onTrack = "OnTrack"
                case offTrack = "OffTrack"
            }

            private enum CodingKeys: String, CodingKey {
                case status = "Status"
                case x = "X"
                case y = "Y"
                case z = "Z"
            }
        }

        private enum CodingKeys: String, CodingKey {
            case timestamp = "Timestamp"
            case entries = "Entries"
        }
    }

    private enum CodingKeys: String, CodingKey {
        case position = "Position"
    }
}
