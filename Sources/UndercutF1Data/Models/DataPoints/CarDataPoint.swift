import Foundation

public struct CarDataPoint: LiveTimingDataPoint {
    public static let dataType: LiveTimingDataType = .carData
    public var entries: [Entry] = []

    public init() {}

    public mutating func merge(with other: CarDataPoint) {
        entries.append(contentsOf: other.entries)
    }

    public struct Entry: Codable, Mergeable, Sendable {
        public var utc: Date?
        public var cars: [String: Car] = [:]

        public init() {}

        public mutating func merge(with other: Entry) {
            if let utc = other.utc { self.utc = utc }
            cars.mergeInPlace(other.cars)
        }

        public struct Car: Codable, Mergeable, Sendable {
            public var channels: Channel = .init()

            public init() {}

            public mutating func merge(with other: Car) {
                channels.merge(with: other.channels)
            }

            public struct Channel: Codable, Mergeable, Sendable {
                public var rpm: Int?
                public var speed: Int?
                public var ngear: Int?
                public var throttle: Int?
                public var brake: Int?
                public var drs: Int?

                public init() {}

                public mutating func merge(with other: Channel) {
                    if let rpm = other.rpm { self.rpm = rpm }
                    if let speed = other.speed { self.speed = speed }
                    if let ngear = other.ngear { self.ngear = ngear }
                    if let throttle = other.throttle { self.throttle = throttle }
                    if let brake = other.brake { self.brake = brake }
                    if let drs = other.drs { self.drs = drs }
                }

                private enum CodingKeys: String, CodingKey {
                    case rpm = "0"
                    case speed = "2"
                    case ngear = "3"
                    case throttle = "4"
                    case brake = "5"
                    case drs = "45"
                }
            }

            private enum CodingKeys: String, CodingKey {
                case channels = "Channels"
            }
        }

        private enum CodingKeys: String, CodingKey {
            case utc = "Utc"
            case cars = "Cars"
        }
    }

    private enum CodingKeys: String, CodingKey {
        case entries = "Entries"
    }
}
