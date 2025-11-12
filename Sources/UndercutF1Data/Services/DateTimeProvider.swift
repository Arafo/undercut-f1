import Foundation

public protocol DateTimeProviding: Sendable {
    func currentUTC() async -> Date
    func setDelay(_ delay: TimeInterval) async
    func getDelay() async -> TimeInterval
    func togglePause() async
    func isPaused() async -> Bool
}

public actor DateTimeProvider: DateTimeProviding {
    private var delay: TimeInterval = 0
    private var pausedAt: Date?

    public init() {}

    public func currentUTC() -> Date {
        if let pausedAt {
            return pausedAt
        }
        return Date().addingTimeInterval(-delay)
    }

    public func setDelay(_ delay: TimeInterval) {
        self.delay = delay
    }

    public func getDelay() -> TimeInterval {
        delay
    }

    public func togglePause() {
        if let pausedAt {
            let now = Date()
            let oldDelay = delay
            delay = now.timeIntervalSince(pausedAt)
            self.pausedAt = nil
            print("Resuming clock with previous delay: \(oldDelay) and new delay: \(delay)")
        } else {
            pausedAt = currentUTC()
            if let pausedAt {
                print("Paused clock at \(pausedAt)")
            }
        }
    }

    public func isPaused() -> Bool {
        pausedAt != nil
    }
}
