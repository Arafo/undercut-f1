import Foundation

public struct RawTimingDataPoint: Codable, Sendable {
    public let type: String
    public let json: JSONValue
    public let dateTime: Date

    private static let dateFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    public init(type: String, jsonString: String, dateTime: Date) throws {
        self.type = type
        self.json = try JSONValue.parse(from: jsonString)
        self.dateTime = dateTime
    }

    enum CodingKeys: String, CodingKey {
        case type = "Type"
        case json = "Json"
        case dateTime = "DateTime"
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        type = try container.decode(String.self, forKey: .type)
        json = try container.decode(JSONValue.self, forKey: .json)
        let dateString = try container.decode(String.self, forKey: .dateTime)
        guard let date = RawTimingDataPoint.dateFormatter.date(from: dateString) else {
            throw DecodingError.dataCorruptedError(
                forKey: .dateTime,
                in: container,
                debugDescription: "Invalid ISO8601 date"
            )
        }
        dateTime = date
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(type, forKey: .type)
        try container.encode(json, forKey: .json)
        let dateString = RawTimingDataPoint.dateFormatter.string(from: dateTime)
        try container.encode(dateString, forKey: .dateTime)
    }
}
