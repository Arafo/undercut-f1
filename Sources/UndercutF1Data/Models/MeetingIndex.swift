import Foundation

public struct MeetingIndex: Codable, Sendable {
    public let year: Int
    public let meetings: [Meeting]

    public struct Meeting: Codable, Sendable {
        public let key: Int
        public let name: String
        public let location: String
        public let sessions: [Session]

        enum CodingKeys: String, CodingKey {
            case key = "Key"
            case name = "Name"
            case location = "Location"
            case sessions = "Sessions"
        }
    }

    public struct Session: Codable, Sendable {
        public let key: Int
        public let name: String
        public let type: String
        public let startDateText: String?
        public let endDateText: String?
        public let gmtOffsetText: String?
        public let path: String?

        enum CodingKeys: String, CodingKey {
            case key = "Key"
            case name = "Name"
            case type = "Type"
            case startDateText = "StartDate"
            case endDateText = "EndDate"
            case gmtOffsetText = "GmtOffset"
            case path = "Path"
        }

        public var startDateUTC: Date? {
            guard let startDate = MeetingIndex.parseSessionDate(from: startDateText),
                  let gmtOffsetSeconds = MeetingIndex.parseOffset(from: gmtOffsetText)
            else { return nil }
            return startDate.addingTimeInterval(-gmtOffsetSeconds)
        }

        public var startDateUTCText: String? {
            guard let startDateUTC else { return nil }
            return MeetingIndex.utcString(from: startDateUTC)
        }
    }

    enum CodingKeys: String, CodingKey {
        case year = "Year"
        case meetings = "Meetings"
    }

    private static func parseSessionDate(from value: String?) -> Date? {
        guard let value else { return nil }
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = isoFormatter.date(from: value) {
            return date
        }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        return formatter.date(from: value)
    }

    private static func parseOffset(from value: String?) -> TimeInterval? {
        guard var value, !value.isEmpty else { return nil }
        var sign: Double = 1
        if value.hasPrefix("-") {
            sign = -1
            value.removeFirst()
        } else if value.hasPrefix("+") {
            value.removeFirst()
        }
        let parts = value.split(separator: ":")
        guard parts.count == 3,
              let hours = Double(parts[0]),
              let minutes = Double(parts[1])
        else { return nil }
        let secondParts = parts[2].split(separator: ".")
        guard let seconds = Double(secondParts[0]) else { return nil }
        var fractional: Double = 0
        if secondParts.count > 1, let millis = Double(secondParts[1]) {
            fractional = millis / pow(10, Double(secondParts[1].count))
        }
        let totalSeconds = (hours * 3600) + (minutes * 60) + seconds + fractional
        return sign * totalSeconds
    }

    private static func utcString(from date: Date) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.string(from: date)
    }
}
