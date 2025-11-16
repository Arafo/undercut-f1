import Foundation

public struct MeetingIndexResponse: Codable, Sendable {
    public let year: Int
    public let meetings: [Meeting]

    public init(year: Int, meetings: [Meeting]) {
        self.year = year
        self.meetings = meetings
    }

    enum CodingKeys: String, CodingKey {
        case year = "Year"
        case meetings = "Meetings"
    }

    public struct Meeting: Codable, Sendable {
        public let key: Int
        public let name: String
        public let location: String
        public let sessions: [Session]

        public init(key: Int, name: String, location: String, sessions: [Session]) {
            self.key = key
            self.name = name
            self.location = location
            self.sessions = sessions
        }

        enum CodingKeys: String, CodingKey {
            case key = "Key"
            case name = "Name"
            case location = "Location"
            case sessions = "Sessions"
        }

        public struct Session: Codable, Sendable {
            public let key: Int
            public let name: String
            public let type: String
            public let startDate: Date
            public let endDate: Date
            public let gmtOffset: TimeInterval
            public let path: String?

            public init(
                key: Int,
                name: String,
                type: String,
                startDate: Date,
                endDate: Date,
                gmtOffset: TimeInterval,
                path: String?
            ) {
                self.key = key
                self.name = name
                self.type = type
                self.startDate = startDate
                self.endDate = endDate
                self.gmtOffset = gmtOffset
                self.path = path
            }

            enum CodingKeys: String, CodingKey {
                case key = "Key"
                case name = "Name"
                case type = "Type"
                case startDate = "StartDate"
                case endDate = "EndDate"
                case gmtOffset = "GmtOffset"
                case path = "Path"
            }

            public init(from decoder: Decoder) throws {
                let container = try decoder.container(keyedBy: CodingKeys.self)
                key = try container.decode(Int.self, forKey: .key)
                name = try container.decode(String.self, forKey: .name)
                type = try container.decode(String.self, forKey: .type)
                startDate = try container.decode(Date.self, forKey: .startDate)
                endDate = try container.decode(Date.self, forKey: .endDate)

                let offsetString = try container.decode(String.self, forKey: .gmtOffset)
                gmtOffset = MeetingIndexResponse.decodeGmtOffset(offsetString)
                path = try container.decodeIfPresent(String.self, forKey: .path)
            }

            public func encode(to encoder: Encoder) throws {
                var container = encoder.container(keyedBy: CodingKeys.self)
                try container.encode(key, forKey: .key)
                try container.encode(name, forKey: .name)
                try container.encode(type, forKey: .type)
                try container.encode(startDate, forKey: .startDate)
                try container.encode(endDate, forKey: .endDate)
                try container.encode(MeetingIndexResponse.encodeGmtOffset(gmtOffset), forKey: .gmtOffset)
                try container.encodeIfPresent(path, forKey: .path)
            }
        }
    }

    private static func decodeGmtOffset(_ raw: String) -> TimeInterval {
        guard !raw.isEmpty else { return 0 }
        // TimeSpan c format "[-][d.]hh:mm:ss[.fffffff]"
        let parts = raw.split(separator: ":")
        guard parts.count >= 3 else { return 0 }
        let hourString = parts[0]
        let minuteString = parts[1]
        let secondParts = parts[2].split(separator: ".")
        let secondString = secondParts.first ?? "0"
        let millisecondString = secondParts.count > 1 ? secondParts[1] : "0"

        let hours = Int(hourString) ?? 0
        let minutes = Int(minuteString) ?? 0
        let seconds = Int(secondString) ?? 0
        let milliseconds = Int(millisecondString.prefix(3)) ?? 0
        let sign: Double = raw.starts(with: "-") ? -1 : 1
        let totalSeconds = Double(abs(hours) * 3600 + minutes * 60 + seconds)
        return sign * (totalSeconds + Double(milliseconds) / 1000)
    }

    private static func encodeGmtOffset(_ interval: TimeInterval) -> String {
        var remaining = interval
        let sign = remaining < 0 ? "-" : ""
        remaining = abs(remaining)
        let hours = Int(remaining / 3600)
        remaining -= Double(hours * 3600)
        let minutes = Int(remaining / 60)
        remaining -= Double(minutes * 60)
        let seconds = Int(remaining)
        let milliseconds = Int((remaining - Double(seconds)) * 1000)
        return String(format: "%@%02d:%02d:%02d.%03d", sign, hours, minutes, seconds, milliseconds)
    }
}
