import Foundation

public struct TeamRadioDataPoint: LiveTimingDataPoint {
    public static let dataType: LiveTimingDataType = .teamRadio
    public var captures: [String: Capture] = [:]

    public init() {}

    public mutating func merge(with other: TeamRadioDataPoint) {
        for (key, value) in other.captures {
            if var existing = captures[key] {
                existing.merge(with: value)
                captures[key] = existing
            } else {
                captures[key] = value
            }
        }
    }

    public var ordered: [String: Capture] {
        captures.sorted { lhs, rhs in
            (lhs.value.utc ?? .distantPast) > (rhs.value.utc ?? .distantPast)
        }.reduce(into: [:]) { result, element in
            result[element.key] = element.value
        }
    }

    public struct Capture: Codable, Mergeable, Sendable {
        public var utc: Date?
        public var racingNumber: String?
        public var path: String?
        public var downloadedFilePath: String?
        public var transcription: String?

        public init() {}

        public mutating func merge(with other: Capture) {
            if let utc = other.utc { self.utc = utc }
            if let racingNumber = other.racingNumber { self.racingNumber = racingNumber }
            if let path = other.path { self.path = path }
            if let downloadedFilePath = other.downloadedFilePath {
                self.downloadedFilePath = downloadedFilePath
            }
            if let transcription = other.transcription {
                self.transcription = transcription
            }
        }

        private enum CodingKeys: String, CodingKey {
            case utc = "Utc"
            case racingNumber = "RacingNumber"
            case path = "Path"
            case downloadedFilePath = "DownloadedFilePath"
            case transcription = "Transcription"
        }
    }

    private enum CodingKeys: String, CodingKey {
        case captures = "Captures"
    }
}
