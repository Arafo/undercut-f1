import Foundation

public struct ProcessorSnapshot: Sendable, Equatable {
    public let name: String
    public let payload: String

    public init(name: String, payload: String) {
        self.name = name
        self.payload = payload
    }
}

public struct ProcessorSnapshotProvider: Sendable {
    private let processors: [TimingProcessor]

    public init(processors: [TimingProcessor]) {
        self.processors = processors
    }

    public func snapshot(at index: Int) -> ProcessorSnapshot? {
        guard processors.indices.contains(index) else { return nil }
        return processors[index].debugSnapshot()
    }

    public func allSnapshots() -> [ProcessorSnapshot] {
        processors.compactMap { $0.debugSnapshot() }
    }
}
