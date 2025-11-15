import Foundation
import UndercutF1Data

struct SessionImporter {
    enum ImporterError: LocalizedError {
        case invalidResponse
        case httpError(Int)
        case meetingNotFound(Int)
        case sessionNotFound(Int)
        case sessionUnavailable
        case missingHeartbeat
        case malformedHeartbeat

        var errorDescription: String? {
            switch self {
            case .invalidResponse:
                return "The live timing service returned an unexpected response."
            case let .httpError(code):
                return "The live timing service rejected the request with status code \(code)."
            case let .meetingNotFound(key):
                return "Unable to find a meeting with key \(key)."
            case let .sessionNotFound(key):
                return "Unable to find a session with key \(key)."
            case .sessionUnavailable:
                return "This session cannot be imported because it does not expose a static archive yet."
            case .missingHeartbeat:
                return "Failed to locate the first heartbeat datapoint for the session."
            case .malformedHeartbeat:
                return "Heartbeat data was missing the UTC timestamp required to align session data."
            }
        }
    }

    private static let raceTopics: [String] = [
        "Heartbeat",
        "CarData.z",
        "Position.z",
        "ExtrapolatedClock",
        "TopThree",
        "TimingStats",
        "TimingAppData",
        "WeatherData",
        "TrackStatus",
        "DriverList",
        "RaceControlMessages",
        "SessionData",
        "LapCount",
        "TimingData",
        "ChampionshipPrediction",
        "TeamRadio",
        "PitLaneTimeCollection",
        "PitStopSeries",
        "PitStop",
    ]

    private static let nonRaceTopics: [String] = [
        "Heartbeat",
        "CarData.z",
        "Position.z",
        "ExtrapolatedClock",
        "TopThree",
        "TimingStats",
        "TimingAppData",
        "WeatherData",
        "TrackStatus",
        "DriverList",
        "RaceControlMessages",
        "SessionData",
        "TimingData",
        "TeamRadio",
        "PitLaneTimeCollection",
        "PitStopSeries",
        "PitStop",
    ]

    private let services: ServiceContainer
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder
    private let isoFormatter: ISO8601DateFormatter
    private let fileManager: FileManager

    init(services: ServiceContainer, fileManager: FileManager = .default) {
        self.services = services
        self.fileManager = fileManager

        decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        encoder = JSONEncoder()
        encoder.outputFormatting = [.withoutEscapingSlashes]

        isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    }

    func meetingIndex(for year: Int) async throws -> MeetingIndexResponse {
        let url = URL(string: "https://livetiming.formula1.com/static/\(year)/Index.json")!
        let (data, response) = try await services.httpClient.data(from: url)
        guard let http = response as? HTTPURLResponse else {
            throw ImporterError.invalidResponse
        }
        guard (200..<300).contains(http.statusCode) else {
            throw ImporterError.httpError(http.statusCode)
        }
        return try decoder.decode(MeetingIndexResponse.self, from: data)
    }

    func importSession(year: Int, meetingKey: Int, sessionKey: Int, response: MeetingIndexResponse) async throws {
        guard let meeting = response.meetings.first(where: { $0.key == meetingKey }) else {
            throw ImporterError.meetingNotFound(meetingKey)
        }
        guard let session = meeting.sessions.first(where: { $0.key == sessionKey }) else {
            throw ImporterError.sessionNotFound(sessionKey)
        }
        guard let path = session.path, !path.isEmpty else {
            throw ImporterError.sessionUnavailable
        }

        services.logger.info("Downloading data for session year=\(year) meeting=\(meetingKey) session=\(sessionKey)")

        let sanitizedDirectoryName = directoryName(year: year, location: meeting.location, session: session.name)
        let outputDirectory = services.options.dataDirectory.appendingPathComponent(sanitizedDirectoryName, isDirectory: true)
        try prepareOutputDirectory(outputDirectory)

        let liveFile = outputDirectory.appendingPathComponent("live.jsonl", isDirectory: false)
        let subscribeFile = outputDirectory.appendingPathComponent("subscribe.json", isDirectory: false)

        try ensureFileDoesNotExist(liveFile)
        try ensureFileDoesNotExist(subscribeFile)

        let prefix = makePrefixURL(for: path)

        services.logger.debug("Fetching session metadata stream")
        let sessionInfo = try await loadStream(prefix: prefix, topic: "SessionInfo", baseline: .init(timeIntervalSince1970: 0))
        services.logger.debug("Fetching heartbeat stream")
        let heartbeat = try await loadStream(prefix: prefix, topic: "Heartbeat", baseline: .init(timeIntervalSince1970: 0))

        guard let firstHeartbeat = heartbeat.first else {
            throw ImporterError.missingHeartbeat
        }
        guard case let .object(json) = firstHeartbeat.json,
              let utcString = json["Utc"]?.stringValue,
              let utcDate = isoFormatter.date(from: utcString) else {
            throw ImporterError.malformedHeartbeat
        }

        let sessionStart = utcDate.addingTimeInterval(-firstHeartbeat.dateTime.timeIntervalSince1970)
        services.logger.debug("Aligned session start to \(isoFormatter.string(from: sessionStart))")

        let topics = (session.type == "Race") ? Self.raceTopics : Self.nonRaceTopics
        var topicData: [RawTimingDataPoint] = []
        for topic in topics {
            services.logger.debug("Downloading \(topic) stream")
            let values = try await loadStream(prefix: prefix, topic: topic, baseline: sessionStart)
            topicData.append(contentsOf: values)
        }

        services.logger.info("Writing \(topicData.count) datapoints to \(liveFile.path)")
        try writeLiveFile(topicData.sorted(by: { $0.dateTime < $1.dateTime }), to: liveFile)

        if let sessionSnapshot = sessionInfo.first, let heartbeatSnapshot = heartbeat.first {
            try writeSubscribeFile(session: sessionSnapshot, heartbeat: heartbeatSnapshot, to: subscribeFile)
        }
    }

    private func makePrefixURL(for path: String) -> URL {
        if path.hasPrefix("http") {
            return URL(string: path)!
        }
        let trimmed = path.hasPrefix("/") ? String(path.dropFirst()) : path
        return URL(string: "https://livetiming.formula1.com/static/\(trimmed)")!
    }

    private func directoryName(year: Int, location: String, session: String) -> String {
        let raw = "\(year)_\(location)_\(session)"
        let invalid = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-_")).inverted
        return raw
            .components(separatedBy: invalid)
            .filter { !$0.isEmpty }
            .joined(separator: "_")
    }

    private func prepareOutputDirectory(_ url: URL) throws {
        if !fileManager.fileExists(atPath: url.path) {
            try fileManager.createDirectory(at: url, withIntermediateDirectories: true)
        }
    }

    private func ensureFileDoesNotExist(_ url: URL) throws {
        if fileManager.fileExists(atPath: url.path) {
            throw NSError(domain: "dev.justaman.undercutf1.cli", code: 1, userInfo: [
                NSLocalizedDescriptionKey: "File already exists at \(url.path). Delete it before importing again."
            ])
        }
    }

    private func loadStream(prefix: URL, topic: String, baseline: Date) async throws -> [RawTimingDataPoint] {
        let url = prefix.appendingPathComponent("\(topic).jsonStream", isDirectory: false)
        let (data, response) = try await services.httpClient.data(from: url)
        guard let http = response as? HTTPURLResponse else {
            throw ImporterError.invalidResponse
        }
        guard (200..<300).contains(http.statusCode) else {
            throw ImporterError.httpError(http.statusCode)
        }
        guard let body = String(data: data, encoding: .utf8) else {
            return []
        }

        var result: [RawTimingDataPoint] = []
        for line in body.split(whereSeparator: \.isNewline) {
            guard line.count > 12 else { continue }
            let offsetString = line.prefix(12)
            let payload = line.dropFirst(12)
            guard let offset = parseOffset(offsetString) else { continue }
            let timestamp = baseline.addingTimeInterval(offset)
            do {
                let point = try RawTimingDataPoint(type: topic, jsonString: String(payload), dateTime: timestamp)
                result.append(point)
            } catch {
                services.logger.error("Failed to decode \(topic) payload: \(error.localizedDescription)")
            }
        }

        return result
    }

    private func parseOffset(_ value: Substring) -> TimeInterval? {
        guard value.count == 12 else { return nil }
        let hours = Int(value.prefix(2)) ?? 0
        let minuteStart = value.index(value.startIndex, offsetBy: 3)
        let minuteEnd = value.index(minuteStart, offsetBy: 2)
        let minutes = Int(value[minuteStart..<minuteEnd]) ?? 0
        let secondStart = value.index(value.startIndex, offsetBy: 6)
        let secondEnd = value.index(secondStart, offsetBy: 2)
        let seconds = Int(value[secondStart..<secondEnd]) ?? 0
        let millisecondsStart = value.index(value.startIndex, offsetBy: 9)
        let milliseconds = Int(value[millisecondsStart...]) ?? 0
        return Double(hours * 3600 + minutes * 60 + seconds) + Double(milliseconds) / 1000
    }

    private func writeLiveFile(_ data: [RawTimingDataPoint], to url: URL) throws {
        let lines = try data.map { point -> String in
            let encoded = try encoder.encode(point)
            guard let string = String(data: encoded, encoding: .utf8) else {
                throw ImporterError.invalidResponse
            }
            return string
        }
        let joined = lines.joined(separator: "\n")
        try joined.write(to: url, atomically: true, encoding: .utf8)
    }

    private func writeSubscribeFile(session: RawTimingDataPoint, heartbeat: RawTimingDataPoint, to url: URL) throws {
        struct Snapshot: Codable {
            let SessionInfo: JSONValue
            let Heartbeat: JSONValue
        }
        let payload = Snapshot(SessionInfo: session.json, Heartbeat: heartbeat.json)
        let data = try encoder.encode(payload)
        try data.write(to: url, options: .atomic)
    }
}
