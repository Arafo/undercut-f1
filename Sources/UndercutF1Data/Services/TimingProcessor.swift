import Foundation

public protocol TimingProcessor: Sendable {
    func process(type: LiveTimingDataType, payload: JSONValue, timestamp: Date) async
}

public struct LoggingTimingProcessor: TimingProcessor {
    public init() {}

    public func process(type: LiveTimingDataType, payload: JSONValue, timestamp: Date) async {
        print("Processing \(type.rawValue) at \(timestamp): \(payload)")
    }
}
