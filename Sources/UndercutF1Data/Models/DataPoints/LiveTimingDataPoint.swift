import Foundation

public protocol Mergeable {
    mutating func merge(with other: Self)
}

public protocol LiveTimingDataPoint: Codable, Mergeable, Sendable {
    static var dataType: LiveTimingDataType { get }
    init()
}

public enum LiveTimingDecoding {
    public static let isoFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [
            .withInternetDateTime,
            .withFractionalSeconds
        ]
        return formatter
    }()

    public static func decoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let string = try container.decode(String.self)
            if let date = LiveTimingDecoding.isoFormatter.date(from: string) {
                return date
            }
            if let date = ISO8601DateFormatter().date(from: string) {
                return date
            }
            throw DecodingError.dataCorrupted(
                .init(
                    codingPath: decoder.codingPath,
                    debugDescription: "Invalid ISO8601 date: \(string)"
                )
            )
        }
        return decoder
    }

    static let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        return encoder
    }()
}

extension Dictionary where Value: Mergeable {
    mutating func mergeInPlace(_ other: [Key: Value]) {
        for (key, value) in other {
            if var existing = self[key] {
                existing.merge(with: value)
                self[key] = existing
            } else {
                self[key] = value
            }
        }
    }
}

extension Dictionary where Value: Mergeable, Value: ExpressibleByDictionaryLiteral {
    mutating func mergeNested(_ other: [Key: Value]) {
        for (key, value) in other {
            if var existing = self[key] {
                existing.merge(with: value)
                self[key] = existing
            } else {
                self[key] = value
            }
        }
    }
}

extension JSONValue {
    func encodedData() throws -> Data {
        try LiveTimingDecoding.encoder.encode(self)
    }
}

extension Optional where Wrapped: Mergeable {
    mutating func mergeWithOptional(_ other: Wrapped?) {
        guard let other else { return }
        if let existing = self {
            var copy = existing
            copy.merge(with: other)
            self = copy
        } else {
            self = other
        }
    }
}
