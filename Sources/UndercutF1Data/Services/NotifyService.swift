import Foundation

public protocol NotificationHandling: Sendable {
    func onNotification() async
}

public struct NotifyService: Sendable {
    private let handlers: [NotificationHandling]
    private let options: LiveTimingOptions

    public init(handlers: [NotificationHandling], options: LiveTimingOptions) {
        self.handlers = handlers
        self.options = options
    }

    public func sendNotification() {
        guard options.notify else { return }
        for handler in handlers {
            Task { await handler.onNotification() }
        }
    }
}

public struct BellNotificationHandler: NotificationHandling {
    public init() {}

    public func onNotification() async {
        fputs("\u{0007}", stdout)
        fflush(stdout)
    }
}
