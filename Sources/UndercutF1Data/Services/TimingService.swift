import Foundation

public actor TimingService {
    private struct QueueItem: Sendable {
        let type: String
        let data: String?
        let timestamp: Date
    }

    private let dateTimeProvider: DateTimeProviding
    private let processors: [TimingProcessor]
    private let clock: () -> Date
    private var workItems: [QueueItem] = []
    private var recent: [QueueItem] = []
    private var processingTask: Task<Void, Never>?

    public init(
        dateTimeProvider: DateTimeProviding = DateTimeProvider(),
        processors: [TimingProcessor] = [],
        clock: @escaping () -> Date = Date.init
    ) {
        self.dateTimeProvider = dateTimeProvider
        self.processors = processors
        self.clock = clock
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
    }

    public func getQueueSnapshot() -> [(String, String?, Date)] {
        recent.map { ($0.type, $0.data, $0.timestamp) }
    }

    public func snapshotPendingItems() -> [(String, String?, Date)] {
        workItems.map { ($0.type, $0.data, $0.timestamp) }
    }

    public func getRemainingWorkItems() -> Int {
        workItems.count
    }

    public func processSubscriptionData(_ data: String) {
        guard let json = try? JSONValue.parse(from: data), let object = json.objectValue else {
            return
        }

        let now = clock()
        for topic in LiveTimingClient.topics {
            guard let value = object[topic] else { continue }
            let payloadData = (try? JSONEncoder().encode(value)).flatMap { String(data: $0, encoding: .utf8) }
            enqueue(type: topic, data: payloadData, timestamp: now)
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

        for processor in processors {
            await processor.process(type: enumType, payload: payload, timestamp: item.timestamp)
        }
    }
}
