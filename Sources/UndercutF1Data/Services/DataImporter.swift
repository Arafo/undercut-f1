import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

public struct DataImporter {
    public enum ImportError: Error, CustomStringConvertible {
        case meetingNotFound(Int)
        case sessionNotFound(Int)
        case sessionUnavailable
        case existingFile(URL)
        case missingHeartbeat
        case malformedResponse(URL)

        public var description: String {
            switch self {
            case let .meetingNotFound(key):
                return "Meeting with key \(key) not found"
            case let .sessionNotFound(key):
                return "Session with key \(key) not found"
            case .sessionUnavailable:
                return "Session cannot be imported because it has no data path yet"
            case let .existingFile(url):
                return "File already exists at \(url.path)"
            case .missingHeartbeat:
                return "Unable to determine session start from heartbeat data"
            case let .malformedResponse(url):
                return "Unable to decode response from \(url.absoluteString)"
            }
        }
    }

    private let session: URLSession
    private let options: LiveTimingOptions
    private let fileManager: FileManager
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder
    private let isoFormatter: ISO8601DateFormatter

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

    public init(
        options: LiveTimingOptions,
        session: URLSession = .shared,
        fileManager: FileManager = .default
    ) {
        self.options = options
        self.session = session
        self.fileManager = fileManager
        self.encoder = JSONEncoder()
        self.decoder = JSONDecoder()
        self.isoFormatter = ISO8601DateFormatter()
        decoder.dateDecodingStrategy = .iso8601
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        encoder.outputFormatting = [.withoutEscapingSlashes]
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    }

    public func getMeetings(year: Int) async throws -> ListMeetingsApiResponse {
        let url = URL(string: "https://livetiming.formula1.com/static/\(year)/Index.json")!
        let (data, response) = try await session.data(from: url)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw ImportError.malformedResponse(url)
        }
        return try decoder.decode(ListMeetingsApiResponse.self, from: data)
    }

    public func importSession(year: Int, meetingKey: Int, sessionKey: Int) async throws {
        let response = try await getMeetings(year: year)
        guard let meeting = response.meetings.first(where: { $0.key == meetingKey }) else {
            throw ImportError.meetingNotFound(meetingKey)
        }
        try await importSession(year: year, meeting: meeting, sessionKey: sessionKey)
    }

    public func importSession(
        year: Int,
        meeting: ListMeetingsApiResponse.Meeting,
        sessionKey: Int
    ) async throws {
        guard let sessionInfo = meeting.sessions.first(where: { $0.key == sessionKey }) else {
            throw ImportError.sessionNotFound(sessionKey)
        }
        guard let path = sessionInfo.path, !path.isEmpty else {
            throw ImportError.sessionUnavailable
        }

        let directoryName = "\(year)_\(meeting.location)_\(sessionInfo.name)".replacingOccurrences(of: " ", with: "_")
        let directory = options.dataDirectory.appendingPathComponent(directoryName, isDirectory: true)
        let liveFile = directory.appendingPathComponent("live.jsonl")
        let subscribeFile = directory.appendingPathComponent("subscribe.json")

        if fileManager.fileExists(atPath: liveFile.path) {
            throw ImportError.existingFile(liveFile)
        }
        if fileManager.fileExists(atPath: subscribeFile.path) {
            throw ImportError.existingFile(subscribeFile)
        }

        let prefix = URL(string: "https://livetiming.formula1.com/static/\(path)")!

        let sessionData = try await getData(prefix: prefix, type: "SessionInfo", start: Date(timeIntervalSince1970: 0))
        let heartbeatData = try await getData(prefix: prefix, type: "Heartbeat", start: Date(timeIntervalSince1970: 0))

        guard
            let firstHeartbeat = heartbeatData.first,
            let heartbeatUtcString = firstHeartbeat.json.objectValue?["Utc"]?.stringValue,
            let heartbeatUtcDate = isoFormatter.date(from: heartbeatUtcString)
        else {
            throw ImportError.missingHeartbeat
        }

        let offsetSeconds = firstHeartbeat.dateTime.timeIntervalSince1970
        let startDate = heartbeatUtcDate.addingTimeInterval(-offsetSeconds)

        let topics = (sessionInfo.type == "Race") ? Self.raceTopics : Self.nonRaceTopics
        let allData = try await withThrowingTaskGroup(of: [RawTimingDataPoint].self) { group -> [[RawTimingDataPoint]] in
            for topic in topics {
                group.addTask {
                    try await self.getData(prefix: prefix, type: topic, start: startDate)
                }
            }
            var results: [[RawTimingDataPoint]] = []
            for try await result in group {
                results.append(result)
            }
            return results
        }

        let lines = allData
            .flatMap { $0 }
            .sorted(by: { $0.dateTime < $1.dateTime })
            .compactMap { dataPoint -> String? in
                guard let data = try? encoder.encode(dataPoint),
                      let line = String(data: data, encoding: .utf8) else { return nil }
                return line
            }
        try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        let liveContents = lines.joined(separator: "\n") + "\n"
        try liveContents.write(to: liveFile, atomically: true, encoding: .utf8)

        var subscribePayload: [String: JSONValue] = [:]
        if let sessionValue = sessionData.first?.json {
            subscribePayload["SessionInfo"] = sessionValue
        }
        if let heartbeatValue = heartbeatData.first?.json {
            subscribePayload["Heartbeat"] = heartbeatValue
        }

        let subscribeValue = JSONValue.object(subscribePayload)
        let subscribeData = try encoder.encode(subscribeValue)
        if let jsonObject = try? JSONSerialization.jsonObject(with: subscribeData),
           let pretty = try? JSONSerialization.data(withJSONObject: jsonObject, options: [.prettyPrinted, .sortedKeys]) {
            try pretty.write(to: subscribeFile)
        } else {
            try subscribeData.write(to: subscribeFile)
        }
    }

    private func getData(prefix: URL, type: String, start: Date) async throws -> [RawTimingDataPoint] {
        let url = prefix.appendingPathComponent("\(type).jsonStream")
        let (data, response) = try await session.data(from: url)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw ImportError.malformedResponse(url)
        }
        guard let rawString = String(data: data, encoding: .utf8) else {
            throw ImportError.malformedResponse(url)
        }

        let lines = rawString.split(whereSeparator: { $0.isNewline })
        var results: [RawTimingDataPoint] = []
        results.reserveCapacity(lines.count)
        for line in lines {
            guard line.count > 12 else { continue }
            let offsetString = String(line.prefix(12))
            let jsonString = String(line.dropFirst(12))
            guard let offset = parseOffset(offsetString) else { continue }
            let timestamp = start.addingTimeInterval(offset)
            if let dataPoint = try? RawTimingDataPoint(type: type, jsonString: jsonString, dateTime: timestamp) {
                results.append(dataPoint)
            }
        }
        return results
    }

    private func parseOffset(_ value: String) -> TimeInterval? {
        let sanitized = value.trimmingCharacters(in: .whitespacesAndNewlines)
        let components = sanitized.split(separator: ":")
        switch components.count {
        case 3:
            guard
                let hours = Int(components[0]),
                let minutes = Int(components[1]),
                let seconds = Double(components[2])
            else { return nil }
            return (Double(hours) * 3600) + (Double(minutes) * 60) + seconds
        case 2:
            guard
                let minutes = Int(components[0]),
                let seconds = Double(components[1])
            else { return nil }
            return (Double(minutes) * 60) + seconds
        case 1:
            return Double(components[0])
        default:
            return nil
        }
    }
}
