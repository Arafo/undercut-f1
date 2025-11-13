import Foundation

public protocol TimingProcessor: Sendable {
    func process(type: LiveTimingDataType, payload: JSONValue, timestamp: Date) async
}

open class ProcessorBase<T: LiveTimingDataPoint>: TimingProcessor, @unchecked Sendable {
    public private(set) var latest: T
    private let decoder: JSONDecoder

    public init(initial: T = T(), decoder: JSONDecoder = LiveTimingDecoding.decoder()) {
        self.latest = initial
        self.decoder = decoder
    }

    open func willMerge(update: inout T, timestamp: Date) async {}

    open func didMerge(update: T, timestamp: Date) async {}

    public func mutateLatest(_ body: (inout T) -> Void) {
        body(&latest)
    }

    public func process(type: LiveTimingDataType, payload: JSONValue, timestamp: Date) async {
        guard type == T.dataType else { return }
        do {
            var update = try decoder.decode(T.self, from: payload.encodedData())
            await willMerge(update: &update, timestamp: timestamp)
            latest.merge(with: update)
            await didMerge(update: update, timestamp: timestamp)
        } catch {
            print("Failed to process \(type.rawValue): \(error)")
        }
    }
}
