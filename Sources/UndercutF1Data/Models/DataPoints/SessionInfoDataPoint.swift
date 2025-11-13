import Foundation

public struct SessionInfoDataPoint: LiveTimingDataPoint {
    public static let dataType: LiveTimingDataType = .sessionInfo

    public var key: Int?
    public var type: String?
    public var name: String?
    public var startDate: Date?
    public var endDate: Date?
    public var gmtOffset: String?
    public var path: String?
    public var meeting: MeetingDetail?
    public var circuitPoints: [CircuitPoint] = []
    public var circuitCorners: [CircuitCorner] = []
    public var circuitRotation: Int = 0

    public init() {}

    public mutating func merge(with other: SessionInfoDataPoint) {
        if let key = other.key { self.key = key }
        if let type = other.type { self.type = type }
        if let name = other.name { self.name = name }
        if let startDate = other.startDate { self.startDate = startDate }
        if let endDate = other.endDate { self.endDate = endDate }
        if let gmtOffset = other.gmtOffset { self.gmtOffset = gmtOffset }
        if let path = other.path { self.path = path }
        meeting.mergeWithOptional(other.meeting)
        if !other.circuitPoints.isEmpty { self.circuitPoints = other.circuitPoints }
        if !other.circuitCorners.isEmpty { self.circuitCorners = other.circuitCorners }
        if other.circuitRotation != 0 || circuitRotation == 0 {
            self.circuitRotation = other.circuitRotation
        }
    }

    public struct CircuitPoint: Codable, Sendable, Equatable {
        public var x: Int
        public var y: Int

        public init(x: Int, y: Int) {
            self.x = x
            self.y = y
        }
    }

    public struct CircuitCorner: Codable, Sendable, Equatable {
        public var number: Int
        public var x: Float
        public var y: Float

        public init(number: Int, x: Float, y: Float) {
            self.number = number
            self.x = x
            self.y = y
        }
    }

    public struct MeetingDetail: Codable, Mergeable, Sendable {
        public var name: String?
        public var circuit: CircuitDetail?

        public init() {}

        public mutating func merge(with other: MeetingDetail) {
            if let name = other.name { self.name = name }
            circuit.mergeWithOptional(other.circuit)
        }

        public struct CircuitDetail: Codable, Mergeable, Sendable {
            public var key: Int?
            public var shortName: String?

            public init() {}

            public mutating func merge(with other: CircuitDetail) {
                if let key = other.key { self.key = key }
                if let shortName = other.shortName { self.shortName = shortName }
            }

            private enum CodingKeys: String, CodingKey {
                case key = "Key"
                case shortName = "ShortName"
            }
        }

        private enum CodingKeys: String, CodingKey {
            case name = "Name"
            case circuit = "Circuit"
        }
    }

    private enum CodingKeys: String, CodingKey {
        case key = "Key"
        case type = "Type"
        case name = "Name"
        case startDate = "StartDate"
        case endDate = "EndDate"
        case gmtOffset = "GmtOffset"
        case path = "Path"
        case meeting = "Meeting"
    }
}
