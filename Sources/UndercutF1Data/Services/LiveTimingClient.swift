import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

public actor LiveTimingClient {
    public static let topics: [String] = [
        "Heartbeat",
        "ExtrapolatedClock",
        "TimingStats",
        "TimingAppData",
        "WeatherData",
        "TrackStatus",
        "DriverList",
        "RaceControlMessages",
        "SessionInfo",
        "SessionData",
        "LapCount",
        "TimingData",
        "TeamRadio",
        "CarData.z",
        "Position.z",
        "ChampionshipPrediction",
        "PitLaneTimeCollection",
        "PitStopSeries",
        "PitStop",
    ]

    private let timingService: TimingService
    private let options: LiveTimingOptions
    private let formula1Account: Formula1Account?
    private let session: URLSession
    private var task: URLSessionWebSocketTask?
    private var receiveTask: Task<Void, Never>?
    private var reconnectTask: Task<Void, Never>?
    private var pingTask: Task<Void, Never>?
    private var sessionKey: String = "UnknownSession"
    private var invocationId: String = UUID().uuidString
    private var backoffSeconds: TimeInterval = 2
    private var isRunning = false
    private let subscribedTopics = Set(LiveTimingClient.topics)
    private let backPressureWatermark = 400
    private let backPressureBaseDelay: TimeInterval = 0.1
    private let backPressureMultiplierLimit: Double = 4
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    private let handshake = "{\"protocol\":\"json\",\"version\":1}\u{1e}"
    private let isoFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    public init(
        timingService: TimingService,
        options: LiveTimingOptions,
        formula1Account: Formula1Account?
    ) {
        self.timingService = timingService
        self.options = options
        self.formula1Account = formula1Account
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 30
        self.session = URLSession(configuration: configuration)
        encoder.outputFormatting = [.withoutEscapingSlashes]
    }

    public func start() async {
        isRunning = true
        await timingService.start()
        await establishConnection()
    }

    public func stop() {
        isRunning = false
        receiveTask?.cancel()
        reconnectTask?.cancel()
        reconnectTask = nil
        pingTask?.cancel()
        pingTask = nil
        if let task {
            task.cancel(with: .goingAway, reason: nil)
        }
        task = nil
        Task { await timingService.stop() }
    }

    private func establishConnection() async {
        guard isRunning else { return }
        reconnectTask?.cancel()
        reconnectTask = nil
        pingTask?.cancel()
        pingTask = nil

        var components = URLComponents(string: "wss://livetiming.formula1.com/signalrcore")!
        if let token = formula1Account?.accessToken, !token.isEmpty {
            components.queryItems = [URLQueryItem(name: "access_token", value: token)]
        }
        guard let url = components.url else { return }

        let task = session.webSocketTask(with: url)
        self.task = task
        task.resume()

        do {
            try await send(text: handshake)
            try await sendSubscribe()
            listen()
            startPingLoop()
            backoffSeconds = 2
        } catch {
            scheduleReconnect(after: backoffSeconds)
        }
    }

    private func send(text: String) async throws {
        guard let task else { throw LiveTimingError.notConnected }
        try await task.send(.string(text))
    }

    private func sendSubscribe() async throws {
        invocationId = UUID().uuidString
        let message = SignalRInvocationMessage(
            type: 1,
            target: "Subscribe",
            arguments: [LiveTimingClient.topics],
            invocationId: invocationId
        )
        let data = try encoder.encode(message)
        guard let payload = String(data: data, encoding: .utf8) else {
            throw LiveTimingError.encodingFailed
        }
        try await send(text: payload + "\u{1e}")
    }

    private func listen() {
        receiveTask?.cancel()
        receiveTask = Task { [weak self] in
            await self?.receiveLoop()
        }
    }

    private func receiveLoop() async {
        while let task = self.task, !Task.isCancelled {
            do {
                let message = try await task.receive()
                await handle(message: message)
                await applyBackpressureIfNeeded()
            } catch {
                await handleReceiveError(error)
                break
            }
        }
    }

    private func handle(message: URLSessionWebSocketTask.Message) async {
        switch message {
        case let .string(text):
            await handle(text: text)
        case let .data(data):
            if let text = String(data: data, encoding: .utf8) {
                await handle(text: text)
            }
        @unknown default:
            break
        }
    }

    private func handle(text: String) async {
        let frames = text.split(separator: "\u{1e}").map(String.init)
        for frame in frames {
            guard !frame.isEmpty else { continue }
            if frame == "{}" { continue }
            guard let data = frame.data(using: .utf8) else { continue }
            do {
                let envelope = try decoder.decode(SignalRMessage.self, from: data)
                try await handle(envelope: envelope)
            } catch {
                print("Failed to decode SignalR message: \(error) -> \(frame)")
            }
        }
    }

    private func handle(envelope: SignalRMessage) async throws {
        switch envelope.type {
        case 1:
            try await handleInvocation(envelope)
        case 3:
            try await handleCompletion(envelope)
        case 6:
            break
        case 7:
            scheduleReconnect(after: backoffSeconds)
        default:
            break
        }
    }

    private func handleInvocation(_ message: SignalRMessage) async throws {
        guard message.target == "feed", let arguments = message.arguments, arguments.count >= 3 else {
            return
        }
        guard case let .string(type) = arguments[0] else { return }
        guard subscribedTopics.contains(type) else { return }
        let payloadValue = arguments[1]
        let payloadData = try encoder.encode(payloadValue)
        guard let payload = String(data: payloadData, encoding: .utf8) else { return }
        guard case let .string(timestampString) = arguments[2] else { return }

        let timestamp = isoFormatter.date(from: timestampString) ?? Date()
        let raw = try RawTimingDataPoint(type: type, jsonString: payload, dateTime: timestamp)
        try persist(raw: raw)
        await timingService.enqueue(type: type, data: payload, timestamp: timestamp)
    }

    private func handleCompletion(_ message: SignalRMessage) async throws {
        guard message.invocationId == invocationId else { return }
        guard let result = message.result else { return }
        let data = try encoder.encode(result)
        guard let jsonString = String(data: data, encoding: .utf8) else { return }

        let object = try JSONValue.parse(from: jsonString)
        if let sessionKey = deriveSessionKey(from: object) {
            self.sessionKey = sessionKey
        }
        try persistSubscription(json: data)
        await timingService.processSubscriptionData(jsonString)
    }

    private func deriveSessionKey(from value: JSONValue) -> String? {
        guard
            case let .object(root) = value,
            let sessionInfo = root["SessionInfo"]?.objectValue,
            let meeting = sessionInfo["Meeting"]?.objectValue,
            let location = meeting["Location"]?.stringValue,
            let sessionName = sessionInfo["Name"]?.stringValue
        else {
            return nil
        }

        let path = sessionInfo["Path"]?.stringValue ?? ""
        let year = path.split(separator: "/").first.map(String.init) ?? String(Calendar.current.component(.year, from: Date()))
        let key = "\(year)_\(location)_\(sessionName)".replacingOccurrences(of: " ", with: "_")
        return key
    }

    private func persist(raw: RawTimingDataPoint) throws {
        let directory = options.dataDirectory.appendingPathComponent(sessionKey, isDirectory: true)
        try FileManager.default.createDirectory(
            at: directory,
            withIntermediateDirectories: true,
            attributes: nil
        )
        let file = directory.appendingPathComponent("live.jsonl")
        let data = try encoder.encode(raw)
        if let handle = try? FileHandle(forWritingTo: file) {
            try handle.seekToEnd()
            handle.write(data)
            handle.write("\n".data(using: .utf8)!)
            try handle.close()
        } else {
            let newline = data + "\n".data(using: .utf8)!
            _ = FileManager.default.createFile(
                atPath: file.path,
                contents: newline,
                attributes: nil
            )
        }
    }

    private func persistSubscription(json: Data) throws {
        let directory = options.dataDirectory.appendingPathComponent(sessionKey, isDirectory: true)
        try FileManager.default.createDirectory(
            at: directory,
            withIntermediateDirectories: true,
            attributes: nil
        )
        let file = directory.appendingPathComponent("subscribe.json")
        if FileManager.default.fileExists(atPath: file.path) { return }
        if let pretty = try? JSONSerialization.jsonObject(with: json),
           let data = try? JSONSerialization.data(withJSONObject: pretty, options: [.prettyPrinted, .sortedKeys]) {
            _ = FileManager.default.createFile(atPath: file.path, contents: data, attributes: nil)
        } else {
            _ = FileManager.default.createFile(atPath: file.path, contents: json, attributes: nil)
        }
    }

    private func handleReceiveError(_ error: Error) async {
        print("Live timing client receive error: \(error)")
        pingTask?.cancel()
        pingTask = nil
        scheduleReconnect(after: backoffSeconds)
    }

    private func scheduleReconnect(after delay: TimeInterval) {
        guard isRunning else { return }
        reconnectTask?.cancel()
        reconnectTask = Task { [weak self] in
            guard let self else { return }
            try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            await self.establishConnection()
        }
        backoffSeconds = min(delay * 2, 120)
    }

    private func startPingLoop() {
        pingTask?.cancel()
        pingTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 30_000_000_000)
                guard !Task.isCancelled else { break }
                guard let self else { break }
                do {
                    try await self.sendPing()
                } catch {
                    await self.handleReceiveError(error)
                    break
                }
            }
        }
    }

    private func sendPing() async throws {
        guard let task else { throw LiveTimingError.notConnected }
        try await withCheckedThrowingContinuation { continuation in
            task.sendPing { error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: ())
                }
            }
        }
    }

    private func applyBackpressureIfNeeded() async {
        let queueDepth = await timingService.getRemainingWorkItems()
        guard queueDepth >= backPressureWatermark else { return }
        let multiplier = min(Double(queueDepth) / Double(backPressureWatermark), backPressureMultiplierLimit)
        let delay = backPressureBaseDelay * multiplier
        try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
    }
}

private struct SignalRInvocationMessage: Encodable {
    let type: Int
    let target: String
    let arguments: [[String]]
    let invocationId: String
}

private struct SignalRMessage: Decodable {
    let type: Int
    let target: String?
    let arguments: [JSONValue]?
    let invocationId: String?
    let result: JSONValue?
}

public enum LiveTimingError: Error {
    case notConnected
    case encodingFailed
}
