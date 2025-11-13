import Foundation

public actor SessionCache {
    public struct Snapshot: Sendable, Codable, Equatable {
        public let name: String?
        public let isRunning: Bool

        public init(name: String?, isRunning: Bool) {
            self.name = name
            self.isRunning = isRunning
        }
    }

    private var snapshot: Snapshot

    public init(snapshot: Snapshot = Snapshot(name: nil, isRunning: false)) {
        self.snapshot = snapshot
    }

    public func update(name: String?, isRunning: Bool) {
        snapshot = Snapshot(name: name, isRunning: isRunning)
    }

    public func update(_ snapshot: Snapshot) {
        self.snapshot = snapshot
    }

    public func current() -> Snapshot {
        snapshot
    }
}
