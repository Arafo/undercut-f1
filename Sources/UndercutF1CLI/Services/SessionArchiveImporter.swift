import Foundation
import Logging
import UndercutF1Data

struct SessionArchiveImporter {
    enum ImportError: LocalizedError {
        case invalidIndexURL
        case invalidResponse
        case sessionUnavailable
        case archiveAlreadyExists(URL)
        case snapshotMissing
        case heartbeatMissing
        case heartbeatUtcMissing
        case encodingFailed

        var errorDescription: String? {
            switch self {
            case .invalidIndexURL:
                return "Unable to construct the meeting index URL."
            case .invalidResponse:
                return "Live Timing API returned an unexpected response."
            case .sessionUnavailable:
                return "The selected session is not yet available for download."
            case let .archiveAlreadyExists(url):
                return "Archive already exists at \(url.path). Delete it before importing again."
            case .snapshotMissing:
                return "Unable to locate the initial SessionInfo payload for this session."
            case .heartbeatMissing:
                return "Unable to locate the initial Heartbeat payload for this session."
            case .heartbeatUtcMissing:
                return "Heartbeat payload did not include a valid UTC timestamp."
            case .encodingFailed:
                return "Failed to encode downloaded timing data."
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

    private let httpClient: URLSession
    private let logger: Logger
    private let fileManager: FileManager
    private let dataPointEncoder: JSONEncoder
    private let snapshotEncoder: JSONEncoder
    private let isoFormatter: ISO8601DateFormatter

    init(httpClient: URLSession, logger: Logger, fileManager: FileManager = .default) {
        self.httpClient = httpClient
        self.logger = logger
        self.fileManager = fileManager
        dataPointEncoder = JSONEncoder()
        dataPointEncoder.outputFormatting = [.withoutEscapingSlashes]
        snapshotEncoder = JSONEncoder()
        snapshotEncoder.outputFormatting = [.withoutEscapingSlashes, .prettyPrinted]
        isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    }

    func fetchMeetings(for year: Int) async throws -> MeetingIndex {
        guard let url = URL(string: "https://livetiming.formula1.com/static/\(year)/Index.json") else {
            throw ImportError.invalidIndexURL
        }
        let (data, response) = try await httpClient.data(from: url)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw ImportError.invalidResponse
        }
        let decoder = JSONDecoder()
        return try decoder.decode(MeetingIndex.self, from: data)
    }

    func importSession(
        year: Int,
        meeting: MeetingIndex.Meeting,
        session: MeetingIndex.Session,
        dataDirectory: URL
    ) async throws {
        guard let sessionPath = session.path, !sessionPath.isEmpty else {
            throw ImportError.sessionUnavailable
        }

        let directoryName = archiveDirectoryName(for: year, meeting: meeting, session: session)
        let targetDirectory = dataDirectory.appendingPathComponent(directoryName, isDirectory: true)
        let liveFile = targetDirectory.appendingPathComponent("live.jsonl", isDirectory: false)
        let subscribeFile = targetDirectory.appendingPathComponent("subscribe.json", isDirectory: false)

        try ensureArchiveDoesNotExist(paths: [liveFile, subscribeFile])

        logger.info("Downloading data for session \(year) \(meeting.location) \(session.name)")

        let prefix = sessionURLPrefix(for: sessionPath)
        let bootstrapStartDate = Date(timeIntervalSince1970: 0)
        let sessionInfoSeed = await fetchStream(
            prefix: prefix,
            topic: "SessionInfo",
            startDate: bootstrapStartDate
        )
        guard let sessionSnapshot = sessionInfoSeed.first else {
            throw ImportError.snapshotMissing
        }

        let heartbeatSeed = await fetchStream(
            prefix: prefix,
            topic: "Heartbeat",
            startDate: bootstrapStartDate
        )
        guard let heartbeatSnapshot = heartbeatSeed.first else {
            throw ImportError.heartbeatMissing
        }
        guard
            case let .object(heartbeatObject) = heartbeatSnapshot.json,
            let utcValue = heartbeatObject["Utc"]?.stringValue,
            let heartbeatUtc = isoFormatter.date(from: utcValue)
        else {
            throw ImportError.heartbeatUtcMissing
        }

        let offsetSeconds = heartbeatSnapshot.dateTime.timeIntervalSince1970
        let startDate = heartbeatUtc.addingTimeInterval(-offsetSeconds)
        logger.info("Resolved session start date: \(isoFormatter.string(from: startDate))")

        let topics = session.type.caseInsensitiveCompare("Race") == .orderedSame
            ? Self.raceTopics
            : Self.nonRaceTopics
        var collections: [[RawTimingDataPoint]] = []
        await withTaskGroup(of: [RawTimingDataPoint].self) { group in
            for topic in topics {
                group.addTask {
                    await fetchStream(prefix: prefix, topic: topic, startDate: startDate)
                }
            }
            for await result in group {
                collections.append(result)
            }
        }

        let ordered = collections.flatMap { $0 }.sorted { $0.dateTime < $1.dateTime }
        let lines = try ordered.map { dataPoint -> String in
            let data = try dataPointEncoder.encode(dataPoint)
            guard let text = String(data: data, encoding: .utf8) else {
                throw ImportError.encodingFailed
            }
            return text
        }

        try fileManager.createDirectory(at: targetDirectory, withIntermediateDirectories: true)
        let livePayload = lines.joined(separator: "\n")
        try livePayload.write(to: liveFile, atomically: true, encoding: .utf8)

        let snapshot = SubscribeSnapshot(sessionInfo: sessionSnapshot.json, heartbeat: heartbeatSnapshot.json)
        let snapshotData = try snapshotEncoder.encode(snapshot)
        try snapshotData.write(to: subscribeFile, options: .atomic)

        logger.info("Written \(lines.count) lines of session data to \(liveFile.path)")
        logger.info("Saved subscribe snapshot to \(subscribeFile.path)")
    }

    private func fetchStream(prefix: String, topic: String, startDate: Date) async -> [RawTimingDataPoint] {
        guard let url = streamURL(prefix: prefix, topic: topic) else { return [] }
        do {
            let (data, _) = try await httpClient.data(from: url)
            guard let body = String(data: data, encoding: .utf8) else { return [] }
            return decodeStream(body, topic: topic, startDate: startDate)
        } catch {
            logger.error("Failed to download \(topic) data: \(error.localizedDescription)")
            return []
        }
    }

    private func decodeStream(_ body: String, topic: String, startDate: Date) -> [RawTimingDataPoint] {
        let lines = body.split(whereSeparator: \Character.isNewline)
        var points: [RawTimingDataPoint] = []
        points.reserveCapacity(lines.count)
        for rawLine in lines {
            let trimmed = rawLine.trimmingCharacters(in: .whitespacesAndNewlines)
            guard trimmed.count > 12 else { continue }
            let offsetIndex = trimmed.index(trimmed.startIndex, offsetBy: 12)
            let offsetString = String(trimmed[..<offsetIndex])
            let payload = String(trimmed[offsetIndex...])
            guard let offset = parseDelta(offsetString) else { continue }
            let timestamp = startDate.addingTimeInterval(offset)
            do {
                let dataPoint = try RawTimingDataPoint(type: topic, jsonString: payload, dateTime: timestamp)
                points.append(dataPoint)
            } catch {
                logger.warning("Failed to decode \(topic) payload: \(error.localizedDescription)")
            }
        }
        return points
    }

    private func parseDelta(_ value: String) -> TimeInterval? {
        let components = value.split(separator: ":")
        guard components.count == 3 else { return nil }
        guard let hours = Double(components[0]), let minutes = Double(components[1]) else { return nil }
        let secondParts = components[2].split(separator: ".")
        guard let seconds = Double(secondParts[0]) else { return nil }
        var fractional: Double = 0
        if secondParts.count > 1, let part = Double(secondParts[1]) {
            fractional = part / pow(10, Double(secondParts[1].count))
        }
        return (hours * 3600) + (minutes * 60) + seconds + fractional
    }

    private func streamURL(prefix: String, topic: String) -> URL? {
        var trimmed = prefix
        if !trimmed.hasSuffix("/") {
            trimmed.append("/")
        }
        let path = "\(trimmed)\(topic).jsonStream"
        return URL(string: path)
    }

    private func archiveDirectoryName(
        for year: Int,
        meeting: MeetingIndex.Meeting,
        session: MeetingIndex.Session
    ) -> String {
        let sanitize: (String) -> String = { value in
            value
                .replacingOccurrences(of: " ", with: "_")
                .replacingOccurrences(of: "/", with: "_")
        }
        return "\(year)_\(sanitize(meeting.location))_\(sanitize(session.name))"
    }

    private func sessionURLPrefix(for path: String) -> String {
        "https://livetiming.formula1.com/static/\(path)"
    }

    private func ensureArchiveDoesNotExist(paths: [URL]) throws {
        for path in paths where fileManager.fileExists(atPath: path.path) {
            throw ImportError.archiveAlreadyExists(path)
        }
    }

    private struct SubscribeSnapshot: Codable {
        let sessionInfo: JSONValue
        let heartbeat: JSONValue

        enum CodingKeys: String, CodingKey {
            case sessionInfo = "SessionInfo"
            case heartbeat = "Heartbeat"
        }
    }
}
