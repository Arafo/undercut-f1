import Foundation

public struct RaceControlMessageDataPoint: LiveTimingDataPoint {
    public static let dataType: LiveTimingDataType = .raceControlMessages
    public var messages: [String: RaceControlMessage] = [:]

    public init() {}

    public mutating func merge(with other: RaceControlMessageDataPoint) {
        for (key, value) in other.messages {
            if messages[key] == nil {
                messages[key] = value
            }
        }
    }

    public struct RaceControlMessage: Codable, Mergeable, Sendable, Equatable {
        public var utc: Date
        public var message: String

        public init(utc: Date, message: String) {
            self.utc = utc
            self.message = message
        }

        public mutating func merge(with other: RaceControlMessage) {
            utc = other.utc
            message = other.message
        }

        private enum CodingKeys: String, CodingKey {
            case utc = "Utc"
            case message = "Message"
        }
    }

    private enum CodingKeys: String, CodingKey {
        case messages = "Messages"
    }
}
