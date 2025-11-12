import Foundation

public final class CancellationToken {
    private let lock = NSLock()
    private var _isCancelled = false

    public var isCancelled: Bool {
        lock.lock(); defer { lock.unlock() }
        return _isCancelled
    }

    public init() {}

    public func cancel() {
        lock.lock(); defer { lock.unlock() }
        _isCancelled = true
    }
}
