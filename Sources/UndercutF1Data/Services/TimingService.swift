import Foundation

public actor TimingService {
    private struct QueueItem: Sendable {
        let type: String
        let data: String?
        let timestamp: Date
    }

    private let dateTimeProvider: DateTimeProviding
    private let processors: [TimingProcessor]
    private var workItems: [QueueItem] = []
    private var recent: [QueueItem] = []
    private var processingTask: Task<Void, Never>?
    private let notifyService: NotifyService?
    private let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.outputFormatting = []
        return encoder
    }()

    public init(
        dateTimeProvider: DateTimeProviding = DateTimeProvider(),
        processors: [TimingProcessor] = [],
        notifyService: NotifyService? = nil
    ) {
        self.dateTimeProvider = dateTimeProvider
        self.processors = processors
        self.notifyService = notifyService
    }

    public func start() {
        guard processingTask == nil else { return }
        processingTask = Task { await runLoop() }
    }

    public func stop() {
        processingTask?.cancel()
        processingTask = nil
    }

    public func enqueue(type: String, data: String?, timestamp: Date) {
        workItems.append(.init(type: type, data: data, timestamp: timestamp))
        workItems.sort { $0.timestamp < $1.timestamp }
    }

    public func getQueueSnapshot() -> [(String, String?, Date)] {
        recent.map { ($0.type, $0.data, $0.timestamp) }
    }

    public func getRemainingWorkItems() -> Int {
        workItems.count
    }

    public func processSubscriptionData(_ data: String) {
        guard let json = try? JSONValue.parse(from: data), let object = json.objectValue else {
            return
        }

        let now = Date()
        for topic in LiveTimingClient.topics {
            guard let value = object[topic] else { continue }
            guard let payloadData = try? encoder.encode(value),
                  let payloadString = String(data: payloadData, encoding: .utf8) else { continue }
            enqueue(type: topic, data: payloadString, timestamp: now)
        }
    }

    private func runLoop() async {
        while !Task.isCancelled {
            guard var first = workItems.first else {
                try? await Task.sleep(nanoseconds: 500_000_000)
                continue
            }

            let current = await dateTimeProvider.currentUTC()
            let delta = first.timestamp.timeIntervalSince(current)
            if delta > 1.0 {
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                continue
            } else if delta > 0 {
                let nanos = UInt64(delta * 1_000_000_000)
                try? await Task.sleep(nanoseconds: nanos)
            }

            first = workItems.removeFirst()
            recent.append(first)
            if recent.count > 5 {
                recent.removeFirst()
            }

            await process(item: first)
        }
    }

    private func process(item: QueueItem) async {
        var type = item.type
        guard var data = item.data else { return }

        if type.hasSuffix(".z") {
            type = String(type.dropLast(2))
            do {
                data = try CompressionUtilities.inflateBase64Data(data)
            } catch {
                print("Failed to decompress payload for type \(type): \(error)")
                return
            }
        }

        guard let enumType = LiveTimingDataType(rawValue: type) else {
            return
        }

        guard let payload = try? JSONValue.parse(from: data) else {
            return
        }

        let normalized = normalizePayload(type: enumType, payload: payload)

        for processor in processors {
            await processor.process(type: enumType, payload: normalized, timestamp: item.timestamp)
        }

        if enumType == .raceControlMessages {
            notifyService?.sendNotification()
        }
    }

    private func normalizePayload(type: LiveTimingDataType, payload: JSONValue) -> JSONValue {
        switch type {
        case .raceControlMessages:
            guard var root = payload.objectValue else { return payload }
            if let messages = root["Messages"], let normalized = arrayToIndexedDictionary(messages) {
                root["Messages"] = normalized
            }
            return .object(root)
        case .timingData:
            guard var root = payload.objectValue else { return payload }
            if var lines = root["Lines"]?.objectValue {
                for (driver, value) in lines {
                    guard var lineObject = value.objectValue else { continue }
                    if let sectorsValue = lineObject["Sectors"],
                       let sectorsDictionary = arrayToIndexedDictionary(sectorsValue)?.objectValue {
                        var normalizedSectors: [String: JSONValue] = [:]
                        for (sectorKey, sectorValue) in sectorsDictionary {
                            if var sectorObject = sectorValue.objectValue {
                                if let segments = sectorObject["Segments"],
                                   let normalizedSegments = arrayToIndexedDictionary(segments) {
                                    sectorObject["Segments"] = normalizedSegments
                                }
                                normalizedSectors[sectorKey] = .object(sectorObject)
                            } else {
                                normalizedSectors[sectorKey] = sectorValue
                            }
                        }
                        lineObject["Sectors"] = .object(normalizedSectors)
                    }
                    lines[driver] = .object(lineObject)
                }
                root["Lines"] = .object(lines)
            }
            return .object(root)
        case .timingAppData:
            guard var root = payload.objectValue else { return payload }
            if var lines = root["Lines"]?.objectValue {
                for (driver, value) in lines {
                    guard var lineObject = value.objectValue else { continue }
                    if let stints = lineObject["Stints"], let normalized = arrayToIndexedDictionary(stints) {
                        lineObject["Stints"] = normalized
                    }
                    lines[driver] = .object(lineObject)
                }
                root["Lines"] = .object(lines)
            }
            return .object(root)
        case .teamRadio:
            guard var root = payload.objectValue else { return payload }
            if let captures = root["Captures"], let normalized = arrayToIndexedDictionary(captures) {
                root["Captures"] = normalized
            }
            return .object(root)
        case .topThree:
            guard var root = payload.objectValue else { return payload }
            if let lines = root["Lines"], let normalized = arrayToIndexedDictionary(lines) {
                root["Lines"] = normalized
            }
            return .object(root)
        case .pitStopSeries:
            guard var root = payload.objectValue else { return payload }
            if var pitTimes = root["PitTimes"]?.objectValue {
                for (driver, value) in pitTimes {
                    if let normalized = arrayToIndexedDictionary(value) {
                        pitTimes[driver] = normalized
                    }
                }
                root["PitTimes"] = .object(pitTimes)
            }
            return .object(root)
        default:
            return payload
        }
    }

    private func arrayToIndexedDictionary(_ value: JSONValue) -> JSONValue? {
        guard case let .array(array) = value else { return value }
        var dictionary: [String: JSONValue] = [:]
        for (index, element) in array.enumerated() {
            dictionary[String(index)] = element
        }
        return .object(dictionary)
    }
}
