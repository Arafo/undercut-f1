import Foundation
import UndercutF1Data

public struct ApplicationServices: Sendable {
    public let dateTimeProvider: DateTimeProviding
    public let timingService: TimingService
    public let sessionCache: SessionCache
    public let timingDataRegistry: TimingDataRegistry

    public init(
        dateTimeProvider: DateTimeProviding = DateTimeProvider(),
        processors: [TimingProcessor] = [],
        notifyService: NotifyService? = nil,
        sessionCache: SessionCache = SessionCache(),
        timingDataRegistry: TimingDataRegistry = TimingDataRegistry()
    ) {
        self.dateTimeProvider = dateTimeProvider
        self.sessionCache = sessionCache
        self.timingDataRegistry = timingDataRegistry
        self.timingService = TimingService(
            dateTimeProvider: dateTimeProvider,
            processors: processors,
            notifyService: notifyService
        )
    }
}
