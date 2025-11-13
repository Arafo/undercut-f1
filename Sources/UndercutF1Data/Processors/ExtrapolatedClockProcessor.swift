import Foundation

public final class ExtrapolatedClockProcessor: ProcessorBase<ExtrapolatedClockDataPoint> {
    private let dateTimeProvider: DateTimeProviding

    public init(dateTimeProvider: DateTimeProviding) {
        self.dateTimeProvider = dateTimeProvider
        super.init()
    }

    public func extrapolatedRemaining() async -> TimeInterval? {
        guard let remaining = TimeUtilities.parseTimeSpan(latest.remaining) else {
            return nil
        }
        guard latest.extrapolating, let utc = latest.utc else {
            return remaining
        }
        let now = await dateTimeProvider.currentUTC()
        return remaining - now.timeIntervalSince(utc)
    }
}
